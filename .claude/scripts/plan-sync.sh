#!/bin/bash
# Plan Sync Script - Manages plan status in plan frontmatter
# TODO.md sync is now handled by task-bridge.sh
#
# Usage:
#   plan-sync.sh start <plan>      - Set plan to in_progress
#   plan-sync.sh complete <plan>   - Set plan to completed
#   plan-sync.sh block <plan> <reason> - Set plan to blocked
#   plan-sync.sh status            - JSON output of current state

set -e

# Find project root
project_root="$PWD"
while [ "$project_root" != "/" ]; do
  if [ -d "$project_root/.claude" ]; then
    break
  fi
  project_root=$(dirname "$project_root")
done

plans_dir="$project_root/.claude/plans"
mkdir -p "$plans_dir"

#=============================================================================
# Helper Functions
#=============================================================================

update_plan_status() {
  local plan_file="$1"
  local new_status="$2"

  if [ ! -f "$plan_file" ]; then
    echo "Error: Plan file not found: $plan_file" >&2
    exit 1
  fi

  sed -i.bak "s/^> Status:.*$/> Status: $new_status/" "$plan_file"
  rm -f "${plan_file}.bak"
}

get_plan_status() {
  local plan_file="$1"
  grep -E '^> Status:' "$plan_file" 2>/dev/null | head -1 | sed 's/> Status:[[:space:]]*//' | tr -d '[:space:]'
}

resolve_plan_file() {
  local plan="$1"
  if [[ "$plan" == *.md ]]; then
    if [[ "$plan" == /* ]]; then
      echo "$plan"
    else
      echo "$project_root/$plan"
    fi
    return
  fi
  echo "$plans_dir/${plan}.md"
}

#=============================================================================
# Commands
#=============================================================================

cmd_start() {
  local plan_file=$(resolve_plan_file "$1")
  local plan_name=$(basename "$plan_file" .md)

  [ ! -f "$plan_file" ] && { echo "Error: Plan not found: $plan_file" >&2; exit 1; }

  update_plan_status "$plan_file" "in_progress"
  echo "Started plan: $plan_name"
}

cmd_complete() {
  local plan_file=$(resolve_plan_file "$1")
  local plan_name=$(basename "$plan_file" .md)

  [ ! -f "$plan_file" ] && { echo "Error: Plan not found: $plan_file" >&2; exit 1; }

  update_plan_status "$plan_file" "completed"
  echo "Completed plan: $plan_name"
}

cmd_block() {
  local plan="$1"
  local reason="${2:-No reason provided}"
  local plan_file=$(resolve_plan_file "$plan")
  local plan_name=$(basename "$plan_file" .md)

  [ ! -f "$plan_file" ] && { echo "Error: Plan not found: $plan_file" >&2; exit 1; }

  update_plan_status "$plan_file" "blocked"

  if ! grep -q "^> Blocked:" "$plan_file"; then
    sed -i.bak "/^> Status:/a\\
> Blocked: $reason" "$plan_file"
    rm -f "${plan_file}.bak"
  else
    sed -i.bak "s/^> Blocked:.*$/> Blocked: $reason/" "$plan_file"
    rm -f "${plan_file}.bak"
  fi

  echo "Blocked plan: $plan_name — $reason"
}

cmd_status() {
  echo "{"
  echo "  \"project_root\": \"$project_root\","
  echo "  \"plans\": ["

  local first=true
  if [ -d "$plans_dir" ]; then
    for plan_file in "$plans_dir"/*.md; do
      [ -f "$plan_file" ] || continue
      local plan_name=$(basename "$plan_file" .md)
      local status=$(get_plan_status "$plan_file")
      local created=$(grep -E '^> Created:' "$plan_file" 2>/dev/null | head -1 | sed 's/> Created:[[:space:]]*//')

      if [ "$first" = true ]; then
        first=false
      else
        echo ","
      fi

      printf '    {"name": "%s", "status": "%s", "created": "%s"}' \
        "$plan_name" "$status" "$created"
    done
  fi

  echo ""
  echo "  ]"
  echo "}"
}

#=============================================================================
# Main
#=============================================================================

case "${1:-status}" in
  start)
    [ -z "$2" ] && { echo "Usage: plan-sync.sh start <plan>" >&2; exit 1; }
    cmd_start "$2"
    ;;
  complete)
    [ -z "$2" ] && { echo "Usage: plan-sync.sh complete <plan>" >&2; exit 1; }
    cmd_complete "$2"
    ;;
  block)
    [ -z "$2" ] && { echo "Usage: plan-sync.sh block <plan> [reason]" >&2; exit 1; }
    cmd_block "$2" "$3"
    ;;
  status)
    cmd_status
    ;;
  *)
    echo "Usage: plan-sync.sh <start|complete|block|status>"
    exit 1
    ;;
esac
