#!/bin/bash
# Phase Manager Script - Status reporting for TODO.md phases and tasks
# In-session task tracking is now handled by native TaskCreate/TaskUpdate/TaskList
#
# Usage: phase-manager.sh <action> [args]

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Find TODO.md
find_todo() {
    if [ -f "$REPO_ROOT/.claude/TODO.md" ]; then
        echo "$REPO_ROOT/.claude/TODO.md"
    elif [ -f "$REPO_ROOT/TODO.md" ]; then
        echo "$REPO_ROOT/TODO.md"
    else
        echo ""
    fi
}

# Get status of phases and tasks
get_status() {
    local file="${1:-$(find_todo)}"

    if [ -z "$file" ] || [ ! -f "$file" ]; then
        echo '{"error": true, "message": "TODO.md not found"}'
        return 1
    fi

    local pending=$(grep -c "\- \[ \]" "$file" 2>/dev/null || echo "0")
    local in_progress=$(grep -c "\- \[~\]" "$file" 2>/dev/null || echo "0")
    local blocked=$(grep -c "\- \[!\]" "$file" 2>/dev/null || echo "0")
    local completed=$(grep -c "\- \[x\]" "$file" 2>/dev/null || echo "0")

    local total=$((pending + in_progress + blocked + completed))

    cat << JSONEOF
{
  "file": "$file",
  "tasks": {
    "total": $total,
    "pending": $pending,
    "inProgress": $in_progress,
    "blocked": $blocked,
    "completed": $completed
  },
  "progress": $([ "$total" -gt 0 ] && echo "$((completed * 100 / total))" || echo "0")
}
JSONEOF
}

# List all tasks
list_tasks() {
    local file="${1:-$(find_todo)}"

    if [ -z "$file" ] || [ ! -f "$file" ]; then
        echo '{"error": true, "message": "TODO.md not found"}'
        return 1
    fi

    grep -n "\- \[.\]" "$file" | while read -r line; do
        local line_num=$(echo "$line" | cut -d: -f1)
        local content=$(echo "$line" | cut -d: -f2-)
        local status="pending"

        if echo "$content" | grep -q "\[x\]"; then
            status="completed"
        elif echo "$content" | grep -q "\[~\]"; then
            status="in_progress"
        elif echo "$content" | grep -q "\[!\]"; then
            status="blocked"
        fi

        local name=$(echo "$content" | sed 's/.*\] //' | sed 's/ *→.*//' | head -c 80)

        echo "{\"line\": $line_num, \"status\": \"$status\", \"name\": $(echo "$name" | jq -Rs .)}"
    done | jq -s '{"tasks": .}'
}

# Main dispatcher
case "${1:-status}" in
    status)
        shift 2>/dev/null || true
        get_status "$@"
        ;;
    list)
        shift 2>/dev/null || true
        list_tasks "$@"
        ;;
    --help|-h)
        echo "Usage: phase-manager.sh <action>"
        echo ""
        echo "Actions:"
        echo "  status   Show phase/task counts (default)"
        echo "  list     List all tasks with status"
        echo ""
        echo "Note: Task manipulation is now handled by native"
        echo "      TaskCreate/TaskUpdate/TaskList tools."
        ;;
    *)
        get_status "$@"
        ;;
esac
