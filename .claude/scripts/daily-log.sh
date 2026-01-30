#!/bin/bash
# Daily Log Generator
# Creates a daily summary in .claude/memory/daily/YYYY-MM-DD.md
# Called by session-end.sh

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

PROJECT_ROOT=$(find_project_root) || exit 0
cd "$PROJECT_ROOT" || exit 0

# Ensure daily log directory exists
mkdir -p ".claude/memory/daily"

# Get today's date
TODAY=$(date +%Y-%m-%d)
LOG_FILE=".claude/memory/daily/$TODAY.md"

# If log already exists, we'll append to it
if [ ! -f "$LOG_FILE" ]; then
    # Create new daily log with header
    cat > "$LOG_FILE" << EOF
# $TODAY

EOF
fi

# Collect session data
NOW=$(date +%H:%M)
SESSION_MARKER="## Session @ $NOW"

# Start building session entry
SESSION_ENTRY="$SESSION_MARKER\n\n"

# Get focus info from session state
if [ -f ".claude/state/session-state.json" ] && command -v jq &> /dev/null; then
    STATE_FILE=".claude/state/session-state.json"

    # Current focus/task
    CURRENT_TASK=$(jq -r '.focus.currentTask // empty' "$STATE_FILE")
    ACTIVE_PLAN=$(jq -r '.focus.activePlan // empty' "$STATE_FILE")

    if [ -n "$CURRENT_TASK" ]; then
        SESSION_ENTRY+="**Focus:** $CURRENT_TASK\n"
    fi
    if [ -n "$ACTIVE_PLAN" ]; then
        SESSION_ENTRY+="**Plan:** $ACTIVE_PLAN\n"
    fi

    # Decisions made this session
    DECISION_COUNT=$(jq -r '.decisions | length' "$STATE_FILE")
    if [ "$DECISION_COUNT" -gt 0 ]; then
        SESSION_ENTRY+="\n**Decisions:**\n"
        jq -r '.decisions[-3:][] | "- " + .decision + " (" + .reason + ")"' "$STATE_FILE" 2>/dev/null | while read -r line; do
            SESSION_ENTRY+="$line\n"
        done
    fi

    # Blockers
    BLOCKER_COUNT=$(jq -r '.blockers | length' "$STATE_FILE")
    if [ "$BLOCKER_COUNT" -gt 0 ]; then
        SESSION_ENTRY+="\n**Blockers:**\n"
        jq -r '.blockers[] | "- " + .issue' "$STATE_FILE" 2>/dev/null | while read -r line; do
            SESSION_ENTRY+="$line\n"
        done
    fi

    # Handoff notes
    HANDOFF_NOTES=$(jq -r '.handoff.notes // empty' "$STATE_FILE")
    if [ -n "$HANDOFF_NOTES" ]; then
        SESSION_ENTRY+="\n**Notes:** $HANDOFF_NOTES\n"
    fi
fi

# Git activity (if in a repo)
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Files changed today
    CHANGED_FILES=$(git diff --name-only 2>/dev/null | wc -l | tr -d ' ')
    STAGED_FILES=$(git diff --cached --name-only 2>/dev/null | wc -l | tr -d ' ')

    if [ "$CHANGED_FILES" -gt 0 ] || [ "$STAGED_FILES" -gt 0 ]; then
        SESSION_ENTRY+="\n**Files Modified:** $((CHANGED_FILES + STAGED_FILES))\n"
    fi

    # Recent commits (last hour)
    RECENT_COMMITS=$(git log --oneline --since="1 hour ago" 2>/dev/null | head -5)
    if [ -n "$RECENT_COMMITS" ]; then
        SESSION_ENTRY+="\n**Commits:**\n"
        echo "$RECENT_COMMITS" | while read -r line; do
            SESSION_ENTRY+="- $line\n"
        done
    fi
fi

SESSION_ENTRY+="\n---\n\n"

# Append to daily log
echo -e "$SESSION_ENTRY" >> "$LOG_FILE"

# Cleanup old logs (keep last 30 days)
find ".claude/memory/daily" -name "*.md" -mtime +30 -delete 2>/dev/null || true

echo "Daily log updated: $LOG_FILE"
