#!/bin/bash
# Task Bridge - Bridges TODO.md ↔ Claude Code native TaskCreate/TaskUpdate
#
# Subcommands:
#   import  - Parse TODO.md, output JSON array of tasks with status mapping
#   export  - Accept task state JSON on stdin, update TODO.md markers
#
# Status mapping:
#   [ ] → pending
#   [~] → in_progress
#   [x] → completed
#   [!] → blocked

set -e

# Find project root
project_root="$PWD"
while [ "$project_root" != "/" ]; do
  if [ -d "$project_root/.claude" ]; then
    break
  fi
  project_root=$(dirname "$project_root")
done

# Find TODO.md
if [ -f "$project_root/.claude/TODO.md" ]; then
  TODO_FILE="$project_root/.claude/TODO.md"
elif [ -f "$project_root/TODO.md" ]; then
  TODO_FILE="$project_root/TODO.md"
else
  TODO_FILE=""
fi

#=============================================================================
# Import: Parse TODO.md → JSON
#=============================================================================

cmd_import() {
  if [ -z "$TODO_FILE" ] || [ ! -f "$TODO_FILE" ]; then
    echo '{"error": false, "tasks": [], "message": "No TODO.md found"}'
    return 0
  fi

  local current_phase=""
  local task_id=0
  local tasks=""

  while IFS= read -r line; do
    # Detect phase headers (## P0, ## Phase 1, etc.)
    if [[ "$line" =~ ^##[[:space:]]+(.*) ]]; then
      current_phase="${BASH_REMATCH[1]}"
      continue
    fi

    # Detect tasks with checkboxes
    if [[ "$line" =~ ^[[:space:]]*-[[:space:]]\[(.)\][[:space:]]+(.*) ]]; then
      local marker="${BASH_REMATCH[1]}"
      local text="${BASH_REMATCH[2]}"
      task_id=$((task_id + 1))

      local status="pending"
      case "$marker" in
        " ") status="pending" ;;
        "~") status="in_progress" ;;
        "x") status="completed" ;;
        "!") status="blocked" ;;
      esac

      # Extract plan reference if present (e.g., "Feature name → plan-name")
      local plan_ref=""
      if [[ "$text" =~ →[[:space:]]*(.*) ]]; then
        plan_ref="${BASH_REMATCH[1]}"
        text="${text%% →*}"
      fi

      # Build JSON entry
      if [ -n "$tasks" ]; then
        tasks="$tasks,"
      fi

      # Use jq for safe JSON encoding
      local json_text=$(echo "$text" | jq -Rs '.')
      local json_phase=$(echo "$current_phase" | jq -Rs '.')
      local json_plan=$(echo "$plan_ref" | jq -Rs '.')

      tasks="$tasks{\"id\":$task_id,\"subject\":$json_text,\"status\":\"$status\",\"phase\":$json_phase,\"planRef\":$json_plan}"
    fi
  done < "$TODO_FILE"

  cat << JSONEOF
{
  "error": false,
  "file": "$TODO_FILE",
  "taskCount": $task_id,
  "tasks": [$tasks]
}
JSONEOF
}

#=============================================================================
# Export: JSON on stdin → Update TODO.md markers
#=============================================================================

cmd_export() {
  if [ -z "$TODO_FILE" ] || [ ! -f "$TODO_FILE" ]; then
    echo '{"error": true, "message": "No TODO.md found"}'
    return 1
  fi

  # Read JSON from stdin
  local input=$(cat)

  if [ -z "$input" ]; then
    echo '{"error": true, "message": "No input provided"}'
    return 1
  fi

  local updated=0

  # Process each task update
  echo "$input" | jq -c '.tasks[]' 2>/dev/null | while IFS= read -r task; do
    local subject=$(echo "$task" | jq -r '.subject')
    local new_status=$(echo "$task" | jq -r '.status')

    # Map status to marker
    local marker=" "
    case "$new_status" in
      pending) marker=" " ;;
      in_progress) marker="~" ;;
      completed) marker="x" ;;
      blocked) marker="!" ;;
    esac

    # Find the task in TODO.md by subject text and update its marker
    # Escape special regex characters in subject
    local escaped_subject=$(echo "$subject" | sed 's/[[\.*^$()+?{|]/\\&/g')

    if grep -q "$escaped_subject" "$TODO_FILE" 2>/dev/null; then
      if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/\(- \)\[.\]\(.*${escaped_subject}\)/\1[${marker}]\2/" "$TODO_FILE"
      else
        sed -i "s/\(- \)\[.\]\(.*${escaped_subject}\)/\1[${marker}]\2/" "$TODO_FILE"
      fi
      updated=$((updated + 1))
    fi
  done

  echo "{\"error\": false, \"updated\": $updated, \"file\": \"$TODO_FILE\"}"
}

#=============================================================================
# Summary: Quick status overview
#=============================================================================

cmd_summary() {
  if [ -z "$TODO_FILE" ] || [ ! -f "$TODO_FILE" ]; then
    echo '{"error": false, "hasTodo": false}'
    return 0
  fi

  local pending=$(grep -c "\- \[ \]" "$TODO_FILE" 2>/dev/null || echo "0")
  local in_progress=$(grep -c "\- \[~\]" "$TODO_FILE" 2>/dev/null || echo "0")
  local blocked=$(grep -c "\- \[!\]" "$TODO_FILE" 2>/dev/null || echo "0")
  local completed=$(grep -c "\- \[x\]" "$TODO_FILE" 2>/dev/null || echo "0")
  local total=$((pending + in_progress + blocked + completed))

  cat << JSONEOF
{
  "error": false,
  "hasTodo": true,
  "file": "$TODO_FILE",
  "pending": $pending,
  "inProgress": $in_progress,
  "blocked": $blocked,
  "completed": $completed,
  "total": $total,
  "progress": $([ "$total" -gt 0 ] && echo "$((completed * 100 / total))" || echo "0")
}
JSONEOF
}

#=============================================================================
# Main
#=============================================================================

case "${1:-summary}" in
  import)
    cmd_import
    ;;
  export)
    cmd_export
    ;;
  summary)
    cmd_summary
    ;;
  *)
    echo "Usage: task-bridge.sh <import|export|summary>"
    echo ""
    echo "Commands:"
    echo "  import   Parse TODO.md to JSON task array"
    echo "  export   Update TODO.md from JSON on stdin"
    echo "  summary  Quick status counts"
    exit 1
    ;;
esac
