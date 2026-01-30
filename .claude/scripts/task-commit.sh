#!/bin/bash
# Task Commit Script - Create atomic commits for completed tasks
# Usage: task-commit.sh <phase> <task_id> <description>

set -e

# Always resolve paths relative to repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STATE_FILE="$REPO_ROOT/.claude/loop/state.json"

# Arguments
PHASE="${1:-1}"
TASK_ID="${2:-1.1}"
DESCRIPTION="${3:-Task completed}"

# Check if we're in a git repo
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo '{"error": true, "message": "Not in a git repository"}'
    exit 1
fi

# Check if there are changes to commit
if [ -z "$(git status --porcelain)" ]; then
    echo '{"error": false, "message": "No changes to commit", "committed": false}'
    exit 0
fi

# Stage all changes
git add -A

# Create commit message
# Format: feat(P{phase}-T{task}): {description}
COMMIT_MSG="feat(P${PHASE}-T${TASK_ID}): ${DESCRIPTION}

Completed task ${TASK_ID} in phase ${PHASE}.

Co-Authored-By: Claude <noreply@anthropic.com>"

# Create commit
if git commit -m "$COMMIT_MSG" > /dev/null 2>&1; then
    COMMIT_HASH=$(git rev-parse HEAD)
    COMMIT_SHORT=$(git rev-parse --short HEAD)

    # Record commit in state if state file exists
    if [ -f "$STATE_FILE" ]; then
        NOW=$(date -Iseconds)
        jq ".commits = (.commits // []) + [{
            \"taskId\": \"${TASK_ID}\",
            \"phase\": \"${PHASE}\",
            \"hash\": \"${COMMIT_HASH}\",
            \"shortHash\": \"${COMMIT_SHORT}\",
            \"message\": $(echo "$DESCRIPTION" | jq -Rs .),
            \"timestamp\": \"${NOW}\"
        }]" "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
    fi

    cat << JSONEOF
{
  "error": false,
  "committed": true,
  "hash": "$COMMIT_HASH",
  "shortHash": "$COMMIT_SHORT",
  "message": "feat(P${PHASE}-T${TASK_ID}): ${DESCRIPTION}"
}
JSONEOF
else
    cat << JSONEOF
{
  "error": true,
  "committed": false,
  "message": "Commit failed"
}
JSONEOF
    exit 1
fi
