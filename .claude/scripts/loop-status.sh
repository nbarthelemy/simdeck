#!/bin/bash
# Loop Status Script - JSON output for Claude to format

# Always resolve paths relative to repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STATE_FILE="$REPO_ROOT/.claude/loop/state.json"

collect_loop_status() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"active": false}'
        return
    fi

    # Read all state values
    PROMPT=$(jq -r '.prompt // ""' "$STATE_FILE" 2>/dev/null)
    STATUS=$(jq -r '.status // "unknown"' "$STATE_FILE" 2>/dev/null)
    CURRENT=$(jq -r '.current_iteration // 0' "$STATE_FILE" 2>/dev/null)
    MAX=$(jq -r '.max_iterations // 20' "$STATE_FILE" 2>/dev/null)
    START_TIME=$(jq -r '.start_time // ""' "$STATE_FILE" 2>/dev/null)
    CONDITION_TYPE=$(jq -r '.condition.type // ""' "$STATE_FILE" 2>/dev/null)
    CONDITION_TARGET=$(jq -r '.condition.target // ""' "$STATE_FILE" 2>/dev/null)
    CONDITION_MET=$(jq -r '.condition_met // false' "$STATE_FILE" 2>/dev/null)
    MAX_TIME=$(jq -r '.max_time // "2h"' "$STATE_FILE" 2>/dev/null)
    FILES_MODIFIED=$(jq -r '.files_modified // 0' "$STATE_FILE" 2>/dev/null)

    # Calculate elapsed
    ELAPSED_MINS=0
    if [ -n "$START_TIME" ] && [ "$START_TIME" != "null" ]; then
        START_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${START_TIME%%.*}" "+%s" 2>/dev/null || echo "0")
        if [ "$START_EPOCH" -gt 0 ]; then
            NOW_EPOCH=$(date "+%s")
            ELAPSED_MINS=$(( (NOW_EPOCH - START_EPOCH) / 60 ))
        fi
    fi

    # Calculate percentage
    PCT=0
    [ "$MAX" -gt 0 ] && PCT=$((CURRENT * 100 / MAX))

    cat << JSONEOF
{
  "active": true,
  "prompt": "$PROMPT",
  "status": "$STATUS",
  "current": $CURRENT,
  "max": $MAX,
  "percentage": $PCT,
  "elapsedMinutes": $ELAPSED_MINS,
  "maxTime": "$MAX_TIME",
  "condition": {
    "type": "$CONDITION_TYPE",
    "target": "$CONDITION_TARGET",
    "met": $CONDITION_MET
  },
  "filesModified": $FILES_MODIFIED
}
JSONEOF
}

collect_loop_status
