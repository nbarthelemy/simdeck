#!/bin/bash
# Memory Context Injection
# Generates context to inject at session start based on current focus and recent activity
# Usage: memory-inject.sh
#
# Output: JSON with relevant memories for context injection (~2000 tokens max)

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
STATE_FILE=".claude/state/session-state.json"
FILES_READ=".claude/state/.files-read"
ACTIVE_PLAN=""

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    echo '{"error": false, "hasMemory": false, "message": "Memory not initialized"}'
    exit 0
fi

# Get current focus context
FOCUS_KEYWORDS=""
if [ -f "$STATE_FILE" ] && command -v jq &> /dev/null; then
    ACTIVE_PLAN=$(jq -r '.focus.activePlan // empty' "$STATE_FILE")
    CURRENT_TASK=$(jq -r '.focus.currentTask // empty' "$STATE_FILE")

    # Extract keywords from focus
    if [ -n "$CURRENT_TASK" ]; then
        FOCUS_KEYWORDS="$CURRENT_TASK"
    fi
fi

# Get recently read files for context
RECENT_FILES=""
if [ -f "$FILES_READ" ]; then
    RECENT_FILES=$(tail -20 "$FILES_READ" 2>/dev/null | tr '\n' ' ')
fi

# Get active plan keywords if available
PLAN_KEYWORDS=""
if [ -n "$ACTIVE_PLAN" ] && [ -f ".claude/plans/$ACTIVE_PLAN" ]; then
    # Extract key terms from plan title and first section
    PLAN_KEYWORDS=$(head -20 ".claude/plans/$ACTIVE_PLAN" | grep -oE '\b[A-Za-z]{4,}\b' | sort -u | head -10 | tr '\n' ' ')
fi

# 1. Get last session summary (if exists)
LAST_SESSION=$(sqlite3 "$DB_FILE" "
    SELECT json_object(
        'id', id,
        'started_at', started_at,
        'observation_count', observation_count,
        'session_summary', session_summary
    )
    FROM sessions
    WHERE session_summary IS NOT NULL
    ORDER BY started_at DESC
    LIMIT 1;
" 2>/dev/null || echo "null")

# 2. Get recent high-importance observations
HIGH_IMPORTANCE=$(sqlite3 "$DB_FILE" "
    SELECT json_group_array(json_object(
        'id', id,
        'summary', summary,
        'timestamp', timestamp,
        'tool_name', tool_name
    ))
    FROM (
        SELECT id, summary, timestamp, tool_name
        FROM observations
        WHERE importance >= 2
        ORDER BY timestamp DESC
        LIMIT 5
    );
")

# 3. Get focus-relevant observations (if we have focus keywords)
FOCUS_RELEVANT="[]"
if [ -n "$FOCUS_KEYWORDS" ]; then
    # Use FTS5 to find relevant memories
    FOCUS_KEYWORDS_ESCAPED=$(echo "$FOCUS_KEYWORDS" | sed "s/'/''/g")
    FOCUS_RELEVANT=$(sqlite3 "$DB_FILE" "
        SELECT json_group_array(json_object(
            'id', id,
            'summary', summary,
            'timestamp', timestamp,
            'tool_name', tool_name
        ))
        FROM (
            SELECT o.id, o.summary, o.timestamp, o.tool_name
            FROM observations o
            JOIN observations_fts fts ON o.id = fts.rowid
            WHERE observations_fts MATCH '$FOCUS_KEYWORDS_ESCAPED'
            ORDER BY bm25(observations_fts)
            LIMIT 5
        );
    " 2>/dev/null || echo "[]")
fi

# 4. Get observations related to recent files
FILE_RELEVANT="[]"
if [ -n "$RECENT_FILES" ]; then
    # Extract just filenames for search
    FILENAMES=$(echo "$RECENT_FILES" | tr ' ' '\n' | xargs -I{} basename {} 2>/dev/null | sort -u | head -5 | tr '\n' ' ')
    if [ -n "$FILENAMES" ]; then
        FILENAMES_ESCAPED=$(echo "$FILENAMES" | sed "s/'/''/g")
        FILE_RELEVANT=$(sqlite3 "$DB_FILE" "
            SELECT json_group_array(json_object(
                'id', id,
                'summary', summary,
                'timestamp', timestamp,
                'files', files_involved
            ))
            FROM (
                SELECT o.id, o.summary, o.timestamp, o.files_involved
                FROM observations o
                JOIN observations_fts fts ON o.id = fts.rowid
                WHERE observations_fts MATCH '$FILENAMES_ESCAPED'
                ORDER BY bm25(observations_fts)
                LIMIT 5
            );
        " 2>/dev/null || echo "[]")
    fi
fi

# 5. Count pending observations
PENDING_COUNT=0
PENDING_FILE="$MEMORY_DIR/.pending-observations.jsonl"
if [ -f "$PENDING_FILE" ]; then
    PENDING_COUNT=$(wc -l < "$PENDING_FILE" | tr -d ' ')
fi

# Build output
cat << JSONEOF
{
  "error": false,
  "hasMemory": true,
  "context": {
    "activePlan": $([ -n "$ACTIVE_PLAN" ] && echo "\"$ACTIVE_PLAN\"" || echo "null"),
    "focusKeywords": $([ -n "$FOCUS_KEYWORDS" ] && echo "\"$FOCUS_KEYWORDS\"" || echo "null"),
    "lastSession": $LAST_SESSION,
    "highImportance": $HIGH_IMPORTANCE,
    "focusRelevant": $FOCUS_RELEVANT,
    "fileRelevant": $FILE_RELEVANT
  },
  "pending": $PENDING_COUNT,
  "tokenBudget": {
    "estimated": $(echo "$HIGH_IMPORTANCE $FOCUS_RELEVANT $FILE_RELEVANT" | wc -w | awk '{print int($1 * 1.5)}'),
    "target": 2000
  }
}
JSONEOF
