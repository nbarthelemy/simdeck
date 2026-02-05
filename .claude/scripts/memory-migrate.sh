#!/bin/bash
# Memory Migration Script
# Migrates existing JSON/MD files to SQLite database
# Usage: memory-migrate.sh [--dry-run]

set -e

# Find project root
find_project_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.claude" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

PROJECT_ROOT=$(find_project_root) || {
    echo '{"error": true, "message": "Not in a claudenv project"}'
    exit 1
}
cd "$PROJECT_ROOT" || exit 1

MEMORY_DIR=".claude/memory"
DB_FILE="$MEMORY_DIR/memory.db"
ARCHIVE_DIR="$MEMORY_DIR/.archive/$(date +%Y-%m-%d)"
DRY_RUN="${1:-}"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    echo '{"error": true, "message": "Database not initialized. Run memory-init.sh first"}'
    exit 1
fi

# Initialize counters
DECISIONS_MIGRATED=0
SESSIONS_MIGRATED=0
USAGE_MIGRATED=0
PATTERNS_MIGRATED=0
LOOP_MIGRATED=0

# Create archive directory
if [ "$DRY_RUN" != "--dry-run" ]; then
    mkdir -p "$ARCHIVE_DIR"
fi

# Helper: escape string for SQLite
escape_sql() {
    echo "$1" | sed "s/'/''/g"
}

# Helper: truncate text to max chars
truncate_text() {
    local text="$1"
    local max="${2:-2000}"
    echo "${text:0:$max}"
}

# Migrate decisions.md
migrate_decisions() {
    local decisions_file="$MEMORY_DIR/decisions.md"
    if [ ! -f "$decisions_file" ]; then
        return
    fi

    local session_id="migration_$(date +%s)"
    local now=$(date -Iseconds)

    # Parse decisions: format is "## YYYY-MM-DD: Decision title"
    # followed by "**Reason:** explanation"
    while IFS= read -r line; do
        if [[ "$line" =~ ^##\ ([0-9]{4}-[0-9]{2}-[0-9]{2}):\ (.+)$ ]]; then
            local decision_date="${BASH_REMATCH[1]}"
            local decision_title="${BASH_REMATCH[2]}"
            local decision_reason=""

            # Read next non-empty line for reason
            while IFS= read -r reason_line; do
                if [[ "$reason_line" =~ ^\*\*Reason:\*\*\ (.+)$ ]]; then
                    decision_reason="${BASH_REMATCH[1]}"
                    break
                elif [[ "$reason_line" =~ ^---$ ]]; then
                    break
                fi
            done

            # Create summary
            local summary="Architectural decision: $decision_title. $(escape_sql "$decision_reason")"
            local keywords="decision architecture $decision_title"

            if [ "$DRY_RUN" = "--dry-run" ]; then
                echo "Would migrate decision: $decision_title ($decision_date)"
            else
                sqlite3 "$DB_FILE" << EOF
INSERT INTO observations (session_id, timestamp, tool_name, tool_input, summary, keywords, importance, created_at)
VALUES ('$session_id', '${decision_date}T12:00:00', 'decision', '$(escape_sql "$decision_title")', '$(escape_sql "$summary")', '$(escape_sql "$keywords")', 3, '$now');
EOF
            fi
            ((DECISIONS_MIGRATED++)) || true
        fi
    done < "$decisions_file"

    # Archive original file
    if [ "$DRY_RUN" != "--dry-run" ] && [ "$DECISIONS_MIGRATED" -gt 0 ]; then
        cp "$decisions_file" "$ARCHIVE_DIR/decisions.md"
    fi
}

# Migrate daily session logs
migrate_daily_logs() {
    local daily_dir="$MEMORY_DIR/daily"
    if [ ! -d "$daily_dir" ]; then
        return
    fi

    local now=$(date -Iseconds)

    for daily_file in "$daily_dir"/*.md; do
        [ -f "$daily_file" ] || continue

        local filename=$(basename "$daily_file" .md)
        # filename is YYYY-MM-DD

        # Parse sessions: format is "## Session @ HH:MM"
        local session_time=""
        local in_session=false

        while IFS= read -r line; do
            if [[ "$line" =~ ^##\ Session\ @\ ([0-9]{2}:[0-9]{2})$ ]]; then
                session_time="${BASH_REMATCH[1]}"
                in_session=true
                local session_id="session_${filename}_${session_time//:/-}"

                if [ "$DRY_RUN" = "--dry-run" ]; then
                    echo "Would migrate session: $filename @ $session_time"
                else
                    sqlite3 "$DB_FILE" << EOF
INSERT OR IGNORE INTO sessions (id, project_path, started_at, observation_count, created_at)
VALUES ('$session_id', '$PROJECT_ROOT', '${filename}T${session_time}:00', 0, '$now');
EOF
                fi
                ((SESSIONS_MIGRATED++)) || true
            fi
        done < "$daily_file"

        # Archive original file
        if [ "$DRY_RUN" != "--dry-run" ]; then
            mkdir -p "$ARCHIVE_DIR/daily"
            cp "$daily_file" "$ARCHIVE_DIR/daily/"
        fi
    done
}

# Migrate usage data
migrate_usage() {
    local usage_file=".claude/state/usage.json"
    local history_file=".claude/state/usage-history.json"
    local now=$(date -Iseconds)

    # Migrate current usage
    if [ -f "$usage_file" ] && command -v jq &> /dev/null; then
        local input_tokens=$(jq -r '.session.inputTokens // 0' "$usage_file")
        local output_tokens=$(jq -r '.session.outputTokens // 0' "$usage_file")
        local tool_calls=$(jq -r '.session.toolCalls // 0' "$usage_file")
        local started=$(jq -r '.session.started // empty' "$usage_file")

        if [ "$input_tokens" -gt 0 ] 2>/dev/null; then
            if [ "$DRY_RUN" = "--dry-run" ]; then
                echo "Would migrate current usage: $input_tokens input, $output_tokens output"
            else
                sqlite3 "$DB_FILE" << EOF
INSERT INTO usage_records (session_id, timestamp, input_tokens, output_tokens, tool_name, created_at)
VALUES ('current', '${started:-$now}', $input_tokens, $output_tokens, 'session_total', '$now');
EOF
            fi
            ((USAGE_MIGRATED++)) || true
        fi
    fi

    # Migrate usage history
    if [ -f "$history_file" ] && command -v jq &> /dev/null; then
        local sessions=$(jq -c '.sessions[]' "$history_file" 2>/dev/null)

        while IFS= read -r session; do
            [ -n "$session" ] || continue

            local date=$(echo "$session" | jq -r '.date')
            local input=$(echo "$session" | jq -r '.inputTokens // 0')
            local output=$(echo "$session" | jq -r '.outputTokens // 0')
            local tools=$(echo "$session" | jq -r '.toolCalls // 0')

            if [ "$DRY_RUN" = "--dry-run" ]; then
                echo "Would migrate historical usage: $date - $input input, $output output"
            else
                sqlite3 "$DB_FILE" << EOF
INSERT INTO usage_records (session_id, timestamp, input_tokens, output_tokens, tool_name, created_at)
VALUES ('history', '$date', $input, $output, 'session_total', '$now');
EOF
            fi
            ((USAGE_MIGRATED++)) || true
        done <<< "$sessions"
    fi

    # Archive original files
    if [ "$DRY_RUN" != "--dry-run" ]; then
        mkdir -p "$ARCHIVE_DIR/state"
        [ -f "$usage_file" ] && cp "$usage_file" "$ARCHIVE_DIR/state/"
        [ -f "$history_file" ] && cp "$history_file" "$ARCHIVE_DIR/state/"
    fi
}

# Migrate patterns.json
migrate_patterns() {
    local patterns_file=".claude/learning/patterns.json"
    if [ ! -f "$patterns_file" ] || ! command -v jq &> /dev/null; then
        return
    fi

    local now=$(date -Iseconds)
    local session_id="migration_patterns_$(date +%s)"

    # Migrate file patterns as observations
    local file_patterns=$(jq -r '.file_patterns | keys[]' "$patterns_file" 2>/dev/null)

    while IFS= read -r file_path; do
        [ -n "$file_path" ] || continue

        local count=$(jq -r ".file_patterns[\"$file_path\"].count // 0" "$patterns_file")
        local first_seen=$(jq -r ".file_patterns[\"$file_path\"].first_seen // empty" "$patterns_file")
        local last_seen=$(jq -r ".file_patterns[\"$file_path\"].last_seen // empty" "$patterns_file")

        # Only migrate files with significant activity
        if [ "$count" -ge 3 ] 2>/dev/null; then
            local filename=$(basename "$file_path")
            local summary="Frequently accessed file: $filename. Accessed $count times between $first_seen and $last_seen."
            local keywords="pattern file $filename frequent"

            if [ "$DRY_RUN" = "--dry-run" ]; then
                echo "Would migrate pattern: $filename ($count accesses)"
            else
                sqlite3 "$DB_FILE" << EOF
INSERT INTO observations (session_id, timestamp, tool_name, files_involved, summary, keywords, importance, created_at)
VALUES ('$session_id', '$last_seen', 'pattern', '["$(escape_sql "$file_path")"]', '$(escape_sql "$summary")', '$(escape_sql "$keywords")', 2, '$now');
EOF
            fi
            ((PATTERNS_MIGRATED++)) || true
        fi
    done <<< "$file_patterns"

    # Archive original file
    if [ "$DRY_RUN" != "--dry-run" ] && [ "$PATTERNS_MIGRATED" -gt 0 ]; then
        mkdir -p "$ARCHIVE_DIR/learning"
        cp "$patterns_file" "$ARCHIVE_DIR/learning/"
    fi
}

# Migrate loop history
migrate_loops() {
    local history_dir=".claude/loop/history"
    if [ ! -d "$history_dir" ]; then
        return
    fi

    local now=$(date -Iseconds)

    for loop_file in "$history_dir"/*.json; do
        [ -f "$loop_file" ] || continue

        if ! command -v jq &> /dev/null; then
            continue
        fi

        local loop_id=$(jq -r '.id // empty' "$loop_file")
        [ -n "$loop_id" ] || continue

        local task=$(jq -r '.prompt // empty' "$loop_file")
        local status=$(jq -r '.status // "unknown"' "$loop_file")
        local started=$(jq -r '.started_at // empty' "$loop_file")
        local ended=$(jq -r '.completed_at // .cancelled_at // empty' "$loop_file")
        local iterations=$(jq -r '.iterations.current // 0' "$loop_file")
        local max_iterations=$(jq -r '.iterations.max // 20' "$loop_file")
        local until_condition=$(jq -r '.completion.condition // empty' "$loop_file")

        if [ "$DRY_RUN" = "--dry-run" ]; then
            echo "Would migrate loop: $loop_id ($status, $iterations iterations)"
        else
            sqlite3 "$DB_FILE" << EOF
INSERT INTO loop_runs (task, status, started_at, ended_at, iterations, max_iterations, until_condition, created_at)
VALUES ('$(escape_sql "$task")', '$status', '$started', '$ended', $iterations, $max_iterations, '$(escape_sql "$until_condition")', '$now');
EOF
        fi
        ((LOOP_MIGRATED++)) || true
    done

    # Archive original files
    if [ "$DRY_RUN" != "--dry-run" ] && [ "$LOOP_MIGRATED" -gt 0 ]; then
        mkdir -p "$ARCHIVE_DIR/loop/history"
        cp -r "$history_dir"/*.json "$ARCHIVE_DIR/loop/history/" 2>/dev/null || true
    fi
}

# Run migrations
migrate_decisions
migrate_daily_logs
migrate_usage
migrate_patterns
migrate_loops

# Output results
cat << JSONEOF
{
  "error": false,
  "dryRun": $([ "$DRY_RUN" = "--dry-run" ] && echo "true" || echo "false"),
  "migrated": {
    "decisions": $DECISIONS_MIGRATED,
    "sessions": $SESSIONS_MIGRATED,
    "usage": $USAGE_MIGRATED,
    "patterns": $PATTERNS_MIGRATED,
    "loops": $LOOP_MIGRATED
  },
  "total": $((DECISIONS_MIGRATED + SESSIONS_MIGRATED + USAGE_MIGRATED + PATTERNS_MIGRATED + LOOP_MIGRATED)),
  "archiveDir": "$ARCHIVE_DIR"
}
JSONEOF
