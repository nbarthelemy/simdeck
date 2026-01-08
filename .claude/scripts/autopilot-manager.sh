#!/bin/bash
# Autopilot Manager - State management for autonomous feature completion
# Usage: autopilot-manager.sh <action> [args]

set -e

# Always resolve paths relative to repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

LOOP_DIR="$REPO_ROOT/.claude/loop"
STATE_FILE="$LOOP_DIR/autopilot-state.json"
HISTORY_DIR="$LOOP_DIR/history"
TODO_FILE="$REPO_ROOT/.claude/TODO.md"

# Ensure directories exist
init_dirs() {
    mkdir -p "$LOOP_DIR" "$HISTORY_DIR"
}

# Generate autopilot ID
generate_id() {
    echo "autopilot_$(date +%Y%m%d_%H%M%S)"
}

# Get current timestamp
timestamp() {
    date -Iseconds
}

# Check if autopilot is active
is_active() {
    if [ -f "$STATE_FILE" ]; then
        status=$(jq -r '.status' "$STATE_FILE" 2>/dev/null || echo "none")
        if [ "$status" = "running" ] || [ "$status" = "paused" ]; then
            return 0
        fi
    fi
    return 1
}

# Get current status
get_status() {
    if [ -f "$STATE_FILE" ]; then
        jq -r '.status' "$STATE_FILE" 2>/dev/null || echo "none"
    else
        echo "none"
    fi
}

# Count features in TODO.md
count_features() {
    if [ ! -f "$TODO_FILE" ]; then
        echo "0"
        return
    fi

    # Count unchecked items (- [ ])
    local available=$(grep -c "^- \[ \]" "$TODO_FILE" 2>/dev/null || echo "0")
    # Count in-progress items (- [~])
    local in_progress=$(grep -c "^- \[~\]" "$TODO_FILE" 2>/dev/null || echo "0")
    # Count completed items (- [x])
    local completed=$(grep -c "^- \[x\]" "$TODO_FILE" 2>/dev/null || echo "0")

    echo "$available:$in_progress:$completed"
}

# Get next uncompleted feature from TODO.md
get_next_feature() {
    if [ ! -f "$TODO_FILE" ]; then
        echo "TODO_MISSING"
        return 1
    fi

    # Find first unchecked item
    local feature_line=$(grep -n "^- \[ \]" "$TODO_FILE" | head -1)

    if [ -z "$feature_line" ]; then
        echo "ALL_COMPLETE"
        return 0
    fi

    # Extract line number and content
    local line_num=$(echo "$feature_line" | cut -d: -f1)
    local feature_text=$(echo "$feature_line" | cut -d: -f2- | sed 's/^- \[ \] //')

    echo "{\"lineNumber\": $line_num, \"feature\": $(echo "$feature_text" | jq -Rs .)}"
}

# Initialize autopilot session
init_autopilot() {
    local max_features="${1:-null}"
    local max_time="${2:-4h}"
    local max_cost="${3:-\$50}"
    local pause_on_failure="${4:-false}"
    local skip_validation="${5:-false}"

    init_dirs

    if is_active; then
        echo '{"error": true, "message": "Autopilot already active. Use cancel first."}'
        return 1
    fi

    if [ ! -f "$TODO_FILE" ]; then
        echo '{"error": true, "message": "TODO.md not found. Run /spec first."}'
        return 1
    fi

    local autopilot_id=$(generate_id)
    local now=$(timestamp)
    local counts=$(count_features)
    local available=$(echo "$counts" | cut -d: -f1)
    local in_progress=$(echo "$counts" | cut -d: -f2)
    local completed=$(echo "$counts" | cut -d: -f3)
    local total=$((available + in_progress + completed))

    cat > "$STATE_FILE" << JSONEOF
{
  "id": "$autopilot_id",
  "status": "running",
  "startedAt": "$now",
  "features": {
    "total": $total,
    "completed": $completed,
    "failed": 0,
    "skipped": 0,
    "remaining": $available
  },
  "limits": {
    "maxFeatures": $max_features,
    "maxTime": "$max_time",
    "maxCost": "$max_cost"
  },
  "options": {
    "pauseOnFailure": $pause_on_failure,
    "skipValidation": $skip_validation
  },
  "currentFeature": null,
  "history": [],
  "metrics": {
    "elapsedTime": "0s",
    "estimatedCost": "\$0.00",
    "tasksCompleted": 0,
    "filesModified": 0,
    "startTime": $(date +%s)
  }
}
JSONEOF

    echo "{\"id\": \"$autopilot_id\", \"totalFeatures\": $total, \"available\": $available}"
}

# Start working on a feature
start_feature() {
    local feature_name="$1"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active autopilot" >&2
        return 1
    fi

    local now=$(timestamp)

    jq ".currentFeature = $(echo "$feature_name" | jq -Rs .) | .currentFeatureStarted = \"$now\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "AUTOPILOT_FEATURE_START: $feature_name"
}

# Record feature completion
record_complete() {
    local feature_name="$1"
    local tasks_done="${2:-0}"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active autopilot" >&2
        return 1
    fi

    local now=$(timestamp)
    local started=$(jq -r '.currentFeatureStarted' "$STATE_FILE")

    # Calculate duration
    local start_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${started%+*}" "+%s" 2>/dev/null || date -d "$started" "+%s" 2>/dev/null || echo "0")
    local end_ts=$(date +%s)
    local duration_sec=$((end_ts - start_ts))
    local duration="${duration_sec}s"
    if [ $duration_sec -ge 60 ]; then
        duration="$((duration_sec / 60))m"
    fi

    # Update state
    jq ".features.completed += 1 | .features.remaining -= 1 | .currentFeature = null | .metrics.tasksCompleted += $tasks_done | .history += [{\"feature\": $(echo "$feature_name" | jq -Rs .), \"status\": \"complete\", \"duration\": \"$duration\", \"completedAt\": \"$now\"}]" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "AUTOPILOT_FEATURE_COMPLETE: $feature_name"
}

# Record feature failure
record_failed() {
    local feature_name="$1"
    local error_msg="$2"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active autopilot" >&2
        return 1
    fi

    local now=$(timestamp)

    jq ".features.failed += 1 | .features.remaining -= 1 | .currentFeature = null | .history += [{\"feature\": $(echo "$feature_name" | jq -Rs .), \"status\": \"failed\", \"error\": $(echo "$error_msg" | jq -Rs .), \"failedAt\": \"$now\"}]" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "AUTOPILOT_FEATURE_FAILED: $feature_name"
}

# Record feature skipped
record_skipped() {
    local feature_name="$1"
    local reason="$2"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active autopilot" >&2
        return 1
    fi

    local now=$(timestamp)

    jq ".features.skipped += 1 | .features.remaining -= 1 | .currentFeature = null | .history += [{\"feature\": $(echo "$feature_name" | jq -Rs .), \"status\": \"skipped\", \"reason\": $(echo "$reason" | jq -Rs .), \"skippedAt\": \"$now\"}]" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "AUTOPILOT_FEATURE_SKIPPED: $feature_name"
}

# Check if limits exceeded
check_limits() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "no_autopilot"
        return
    fi

    # Check max features
    local completed=$(jq -r '.features.completed' "$STATE_FILE")
    local max_features=$(jq -r '.limits.maxFeatures' "$STATE_FILE")

    if [ "$max_features" != "null" ] && [ "$completed" -ge "$max_features" ]; then
        echo "max_features"
        return
    fi

    # Check time limit
    local start_time=$(jq -r '.metrics.startTime' "$STATE_FILE")
    local max_time=$(jq -r '.limits.maxTime' "$STATE_FILE")
    local now=$(date +%s)
    local elapsed=$((now - start_time))

    # Parse max_time (e.g., "4h" -> 14400)
    local max_seconds=14400
    if [[ "$max_time" =~ ([0-9]+)h ]]; then
        max_seconds=$((${BASH_REMATCH[1]} * 3600))
    elif [[ "$max_time" =~ ([0-9]+)m ]]; then
        max_seconds=$((${BASH_REMATCH[1]} * 60))
    fi

    if [ "$elapsed" -ge "$max_seconds" ]; then
        echo "time_limit"
        return
    fi

    # Check remaining features
    local remaining=$(jq -r '.features.remaining' "$STATE_FILE")
    if [ "$remaining" -le 0 ]; then
        echo "all_complete"
        return
    fi

    echo "ok"
}

# Update elapsed time
update_metrics() {
    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi

    local start_time=$(jq -r '.metrics.startTime' "$STATE_FILE")
    local now=$(date +%s)
    local elapsed=$((now - start_time))
    local elapsed_human=$(printf '%dh %dm %ds' $((elapsed/3600)) $((elapsed%3600/60)) $((elapsed%60)))

    # Get files modified count
    local files_modified=$(git diff --name-only HEAD~1 2>/dev/null | wc -l | tr -d ' ')

    jq ".metrics.elapsedTime = \"$elapsed_human\" | .metrics.filesModified = $files_modified" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
}

# Pause autopilot
pause_autopilot() {
    local reason="${1:-user_requested}"

    if [ ! -f "$STATE_FILE" ]; then
        echo '{"error": true, "message": "No active autopilot"}'
        return 1
    fi

    local status=$(get_status)
    if [ "$status" != "running" ]; then
        echo "{\"error\": true, \"message\": \"Autopilot not running (status: $status)\"}"
        return 1
    fi

    local now=$(timestamp)
    jq ".status = \"paused\" | .pausedAt = \"$now\" | .pauseReason = \"$reason\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo '{"status": "paused"}'
}

# Resume autopilot
resume_autopilot() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"error": true, "message": "No active autopilot"}'
        return 1
    fi

    local status=$(get_status)
    if [ "$status" != "paused" ]; then
        echo "{\"error\": true, \"message\": \"Autopilot not paused (status: $status)\"}"
        return 1
    fi

    local now=$(timestamp)
    jq ".status = \"running\" | .resumedAt = \"$now\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo '{"status": "resumed"}'
}

# Cancel autopilot
cancel_autopilot() {
    local reason="${1:-user_requested}"

    if [ ! -f "$STATE_FILE" ]; then
        echo '{"error": true, "message": "No active autopilot"}'
        return 1
    fi

    local now=$(timestamp)
    local autopilot_id=$(jq -r '.id' "$STATE_FILE")

    update_metrics

    jq ".status = \"cancelled\" | .cancelledAt = \"$now\" | .cancelReason = \"$reason\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    # Archive
    mv "$STATE_FILE" "$HISTORY_DIR/${autopilot_id}.json"

    echo '{"status": "cancelled"}'
}

# Complete autopilot session
complete_autopilot() {
    local reason="${1:-all_complete}"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active autopilot" >&2
        return 1
    fi

    local now=$(timestamp)
    local autopilot_id=$(jq -r '.id' "$STATE_FILE")

    update_metrics

    jq ".status = \"complete\" | .completedAt = \"$now\" | .completionReason = \"$reason\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "AUTOPILOT_COMPLETE"
}

# Archive completed autopilot
archive_autopilot() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No state to archive" >&2
        return 1
    fi

    local autopilot_id=$(jq -r '.id' "$STATE_FILE")

    mv "$STATE_FILE" "$HISTORY_DIR/${autopilot_id}.json"

    echo "archived"
}

# Get full state as JSON
get_state() {
    if [ -f "$STATE_FILE" ]; then
        update_metrics 2>/dev/null
        cat "$STATE_FILE"
    else
        echo '{"error": true, "message": "No active autopilot"}'
    fi
}

# Get status info for display
status_info() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"active": false}'
        return
    fi

    update_metrics 2>/dev/null

    jq '{
        active: true,
        id: .id,
        status: .status,
        currentFeature: .currentFeature,
        completed: .features.completed,
        failed: .features.failed,
        remaining: .features.remaining,
        elapsedTime: .metrics.elapsedTime,
        limits: .limits
    }' "$STATE_FILE"
}

# Generate summary report
generate_report() {
    if [ ! -f "$STATE_FILE" ]; then
        local latest=$(ls -t "$HISTORY_DIR"/autopilot_*.json 2>/dev/null | head -1)
        if [ -z "$latest" ]; then
            echo '{"error": true, "message": "No autopilot history found"}'
            return 1
        fi
        cat "$latest"
    else
        update_metrics 2>/dev/null
        cat "$STATE_FILE"
    fi
}

# List history
list_history() {
    init_dirs

    if [ -z "$(ls -A "$HISTORY_DIR"/autopilot_*.json 2>/dev/null)" ]; then
        echo "[]"
        return
    fi

    local result="["
    local first=true

    for f in "$HISTORY_DIR"/autopilot_*.json; do
        if [ "$first" = true ]; then
            first=false
        else
            result="$result,"
        fi
        result="$result$(jq '{id: .id, status: .status, completedAt: .completedAt, features: .features}' "$f")"
    done

    result="$result]"
    echo "$result"
}

# Main dispatcher
case "${1:-}" in
    init)
        shift
        init_autopilot "$@"
        ;;
    next_feature)
        get_next_feature
        ;;
    start_feature)
        shift
        start_feature "$@"
        ;;
    complete)
        shift
        record_complete "$@"
        ;;
    failed)
        shift
        record_failed "$@"
        ;;
    skipped)
        shift
        record_skipped "$@"
        ;;
    check)
        check_limits
        ;;
    pause)
        shift
        pause_autopilot "$@"
        ;;
    resume)
        resume_autopilot
        ;;
    cancel)
        shift
        cancel_autopilot "$@"
        ;;
    finish)
        shift
        complete_autopilot "$@"
        ;;
    archive)
        archive_autopilot
        ;;
    status)
        status_info
        ;;
    state)
        get_state
        ;;
    report)
        generate_report
        ;;
    history)
        list_history
        ;;
    active)
        is_active && echo "true" || echo "false"
        ;;
    *)
        echo "Usage: autopilot-manager.sh <action> [args]"
        echo ""
        echo "Actions:"
        echo "  init [max_features] [max_time] [max_cost]  Initialize autopilot"
        echo "  next_feature                               Get next uncompleted feature"
        echo "  start_feature <name>                       Mark feature as started"
        echo "  complete <name> [tasks]                    Record feature completion"
        echo "  failed <name> <error>                      Record feature failure"
        echo "  skipped <name> <reason>                    Record feature skipped"
        echo "  check                                      Check limits"
        echo "  pause [reason]                             Pause autopilot"
        echo "  resume                                     Resume autopilot"
        echo "  cancel [reason]                            Cancel autopilot"
        echo "  finish [reason]                            Complete autopilot"
        echo "  archive                                    Archive to history"
        echo "  status                                     Get status summary"
        echo "  state                                      Get full state JSON"
        echo "  report                                     Generate summary report"
        echo "  history                                    List past autopilots"
        echo "  active                                     Check if autopilot active"
        exit 1
        ;;
esac
