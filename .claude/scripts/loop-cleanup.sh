#!/bin/bash
# Loop Cleanup Script
# Called when autonomous-loop skill stops (via skill hook)

# Always resolve paths relative to repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Exit gracefully if not in a project with claudenv
if [ ! -d "$REPO_ROOT/.claude" ]; then
    exit 0
fi

LOOP_DIR="$REPO_ROOT/.claude/loop"
STATE_FILE="$LOOP_DIR/state.json"

# Check if loop state exists
if [ ! -f "$STATE_FILE" ]; then
    exit 0
fi

# Check if loop is running
STATUS=$(jq -r '.status // "unknown"' "$STATE_FILE" 2>/dev/null)

if [ "$STATUS" = "running" ]; then
    # Mark loop as stopped
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

    # Update state to stopped
    jq --arg ts "$TIMESTAMP" '.status = "stopped" | .ended_at = $ts' "$STATE_FILE" > "${STATE_FILE}.tmp" && \
        mv "${STATE_FILE}.tmp" "$STATE_FILE"

    # Log the cleanup
    LOOP_ID=$(jq -r '.id // "unknown"' "$STATE_FILE")
    LOG_FILE="$LOOP_DIR/logs/loop_${LOOP_ID}.log"

    if [ -f "$LOG_FILE" ]; then
        echo "" >> "$LOG_FILE"
        echo "[$TIMESTAMP] Loop stopped by skill hook" >> "$LOG_FILE"
    fi
fi

exit 0
