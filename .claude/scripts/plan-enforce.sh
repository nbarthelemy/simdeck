#!/bin/bash
# Plan Enforcement Hook
# Blocks writes to implementation files unless a plan exists
#
# Called by PreToolUse hook with JSON input containing tool_input.file_path
# Exit 0 = allow, Exit 2 = block with message

set -e

# Read JSON input from stdin
input=$(cat)

# Extract file path from tool input
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.files[0].file_path // empty' 2>/dev/null)

if [ -z "$file_path" ]; then
  # No file path found, allow the operation
  exit 0
fi

# Get absolute path
if [[ "$file_path" != /* ]]; then
  file_path="$(pwd)/$file_path"
fi

# Normalize path (only if directory exists)
dir_path=$(dirname "$file_path")
if [ -d "$dir_path" ]; then
  file_path="$(cd "$dir_path" && pwd)/$(basename "$file_path")"
fi

#=============================================================================
# CHECK: Find project root
#=============================================================================

project_root="$PWD"
while [ "$project_root" != "/" ]; do
  if [ -d "$project_root/.claude" ]; then
    break
  fi
  project_root=$(dirname "$project_root")
done

# No .claude directory found
if [ ! -d "$project_root/.claude" ]; then
  exit 0
fi

#=============================================================================
# CHECK: Is plan enforcement disabled?
#=============================================================================

if [ -f "$project_root/.claude/plans-disabled" ]; then
  exit 0
fi

if [ -f "$project_root/.claude/settings.local.json" ]; then
  if jq -e '.plans.enabled == false' "$project_root/.claude/settings.local.json" 2>/dev/null | grep -q true; then
    exit 0
  fi
fi

#=============================================================================
# CHECK: Is quick-fix mode enabled? (one-time bypass)
#=============================================================================

if [ -f "$project_root/.claude/quick-fix" ]; then
  # Allow this edit - the PostToolUse hook will delete the marker
  exit 0
fi

#=============================================================================
# CHECK: Is this an exempt file? (test, config, docs, etc.)
#=============================================================================

filename=$(basename "$file_path")
dirname_path=$(dirname "$file_path")

is_exempt_file() {
  local f="$1"
  local name=$(basename "$f")
  local dir=$(dirname "$f")

  # Test files - always allowed
  [[ "$name" == *.test.* ]] && return 0
  [[ "$name" == *.spec.* ]] && return 0
  [[ "$name" == test_* ]] && return 0
  [[ "$name" == *_test.* ]] && return 0

  # Test directories
  [[ "$dir" == */__tests__/* ]] && return 0
  [[ "$dir" == */tests/* ]] && return 0
  [[ "$dir" == */test/* ]] && return 0
  [[ "$dir" == */__mocks__/* ]] && return 0

  # Config files
  [[ "$name" == *.config.* ]] && return 0
  [[ "$name" == *.d.ts ]] && return 0
  [[ "$name" == tsconfig.json ]] && return 0
  [[ "$name" == package.json ]] && return 0
  [[ "$name" == *.lock ]] && return 0
  [[ "$name" == *.yaml ]] && return 0
  [[ "$name" == *.yml ]] && return 0
  [[ "$name" == *.md ]] && return 0
  [[ "$name" == *.json ]] && return 0
  [[ "$name" == .* ]] && return 0

  # Type-only files
  [[ "$name" == types.ts ]] && return 0
  [[ "$name" == types.tsx ]] && return 0
  [[ "$name" == constants.ts ]] && return 0
  [[ "$name" == index.ts ]] && return 0

  # Non-testable directories
  [[ "$dir" == */config/* ]] && return 0
  [[ "$dir" == */types/* ]] && return 0
  [[ "$dir" == */public/* ]] && return 0
  [[ "$dir" == */assets/* ]] && return 0
  [[ "$dir" == */styles/* ]] && return 0
  [[ "$dir" == */.claude/* ]] && return 0
  [[ "$dir" == */scripts/* ]] && return 0
  [[ "$dir" == */migrations/* ]] && return 0
  [[ "$dir" == */drizzle/* ]] && return 0
  [[ "$dir" == */prisma/* ]] && return 0

  return 1
}

if is_exempt_file "$file_path"; then
  exit 0
fi

#=============================================================================
# CHECK: Is there an active plan (in_progress)?
#=============================================================================

plans_dir="$project_root/.claude/plans"

if [ -d "$plans_dir" ]; then
  # Check for any in_progress plan
  for plan_file in "$plans_dir"/*.md; do
    [ -f "$plan_file" ] || continue
    # Extract status from plan file
    status=$(grep -E '^> Status:' "$plan_file" 2>/dev/null | head -1 | sed 's/> Status:[[:space:]]*//' | tr -d '[:space:]')
    if [ "$status" = "in_progress" ]; then
      # Active plan found, allow edit
      exit 0
    fi
  done
fi

#=============================================================================
# CHECK: Is this file listed in a ready plan?
#=============================================================================

if [ -d "$plans_dir" ]; then
  # Get relative path from project root for matching
  rel_path="${file_path#$project_root/}"

  for plan_file in "$plans_dir"/*.md; do
    [ -f "$plan_file" ] || continue
    status=$(grep -E '^> Status:' "$plan_file" 2>/dev/null | head -1 | sed 's/> Status:[[:space:]]*//' | tr -d '[:space:]')
    if [ "$status" = "ready" ]; then
      # Check if file is mentioned in the plan
      if grep -q "$rel_path" "$plan_file" 2>/dev/null || grep -q "$(basename "$file_path")" "$plan_file" 2>/dev/null; then
        exit 0
      fi
    fi
  done
fi

#=============================================================================
# BLOCK: No plan found
#=============================================================================

# List existing plans for the error message
existing_plans=""
if [ -d "$plans_dir" ]; then
  for plan_file in "$plans_dir"/*.md; do
    [ -f "$plan_file" ] || continue
    plan_name=$(basename "$plan_file" .md)
    status=$(grep -E '^> Status:' "$plan_file" 2>/dev/null | head -1 | sed 's/> Status:[[:space:]]*//' | tr -d '[:space:]')
    existing_plans="$existing_plans    - $plan_name ($status)\n"
  done
fi

echo "PLAN ENFORCEMENT: Create a plan first!"
echo ""
echo "  Editing: $file_path"
echo ""
echo "  Options:"
echo "    1. Create a plan: /ce:feature \"Feature description\""
echo "    2. Execute existing plan: /ce:execute .claude/plans/<name>.md"
echo "    3. Quick fix: touch .claude/quick-fix (auto-deleted)"
echo "    4. Disable: touch .claude/plans-disabled"
echo ""
if [ -n "$existing_plans" ]; then
  echo "  Existing plans:"
  echo -e "$existing_plans"
fi

# Exit code 2 = block with message shown to user
exit 2
