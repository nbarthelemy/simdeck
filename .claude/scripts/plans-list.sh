#!/bin/bash
# Plans List Script
# Outputs JSON with all plans grouped by status
#
# Usage: plans-list.sh
# Output format:
# {
#   "draft": [...],
#   "ready": [...],
#   "in_progress": [...],
#   "completed": [...],
#   "blocked": [...]
# }

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

#=============================================================================
# Helper Functions
#=============================================================================

# Get plan status from a plan file
get_plan_status() {
  local plan_file="$1"
  grep -E '^> Status:' "$plan_file" 2>/dev/null | head -1 | sed 's/> Status:[[:space:]]*//' | tr -d '[:space:]'
}

# Get plan created date from a plan file
get_plan_created() {
  local plan_file="$1"
  grep -E '^> Created:' "$plan_file" 2>/dev/null | head -1 | sed 's/> Created:[[:space:]]*//'
}

# Get plan title from a plan file (first H1)
get_plan_title() {
  local plan_file="$1"
  grep -E '^# ' "$plan_file" 2>/dev/null | head -1 | sed 's/^# //'
}

# Escape JSON string
json_escape() {
  local str="$1"
  str="${str//\\/\\\\}"
  str="${str//\"/\\\"}"
  str="${str//$'\n'/\\n}"
  str="${str//$'\r'/\\r}"
  str="${str//$'\t'/\\t}"
  echo "$str"
}

#=============================================================================
# Collect Plans by Status
#=============================================================================

# Use simple variables instead of associative arrays for bash 3 compatibility
plans_draft=""
plans_ready=""
plans_in_progress=""
plans_completed=""
plans_blocked=""

# Collect all plans
if [ -d "$plans_dir" ]; then
  for plan_file in "$plans_dir"/*.md; do
    [ -f "$plan_file" ] || continue

    plan_name=$(basename "$plan_file" .md)
    status=$(get_plan_status "$plan_file")
    created=$(get_plan_created "$plan_file")
    title=$(get_plan_title "$plan_file")

    # Default to draft if no status found
    if [ -z "$status" ]; then
      status="draft"
    fi

    # Build plan JSON entry
    entry=$(printf '{"name": "%s", "title": "%s", "status": "%s", "created": "%s", "file_path": "%s"}' \
      "$(json_escape "$plan_name")" \
      "$(json_escape "$title")" \
      "$(json_escape "$status")" \
      "$(json_escape "$created")" \
      "$(json_escape "$plan_file")")

    # Add to appropriate status variable
    case "$status" in
      draft)
        if [ -n "$plans_draft" ]; then
          plans_draft="$plans_draft,$entry"
        else
          plans_draft="$entry"
        fi
        ;;
      ready)
        if [ -n "$plans_ready" ]; then
          plans_ready="$plans_ready,$entry"
        else
          plans_ready="$entry"
        fi
        ;;
      in_progress)
        if [ -n "$plans_in_progress" ]; then
          plans_in_progress="$plans_in_progress,$entry"
        else
          plans_in_progress="$entry"
        fi
        ;;
      completed)
        if [ -n "$plans_completed" ]; then
          plans_completed="$plans_completed,$entry"
        else
          plans_completed="$entry"
        fi
        ;;
      blocked)
        if [ -n "$plans_blocked" ]; then
          plans_blocked="$plans_blocked,$entry"
        else
          plans_blocked="$entry"
        fi
        ;;
    esac
  done
fi

#=============================================================================
# Output JSON
#=============================================================================

cat << JSONEOF
{
  "error": false,
  "project_root": "$project_root",
  "plans_dir": "$plans_dir",
  "draft": [$plans_draft],
  "ready": [$plans_ready],
  "in_progress": [$plans_in_progress],
  "completed": [$plans_completed],
  "blocked": [$plans_blocked]
}
JSONEOF
