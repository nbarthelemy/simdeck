#!/bin/bash
# Unified Post-Write Hook - Single PostToolUse hook for Write|Edit|MultiEdit
# Replaces 3 separate hooks: learning-observer, decision-reminder, quick-fix cleanup
#
# Runs all post-write checks in one process:
#   1. Quick-fix marker cleanup (auto-delete one-time bypass)
#   2. Learning observer (track file edit patterns)
#   3. Decision reminder (prompt after significant changes)

# Find project root
project_root="$PWD"
while [ "$project_root" != "/" ]; do
  if [ -d "$project_root/.claude" ]; then
    break
  fi
  project_root=$(dirname "$project_root")
done

if [ ! -d "$project_root/.claude" ]; then
  exit 0
fi

cd "$project_root" || exit 0

# Read tool input from stdin
INPUT=$(cat)

#=============================================================================
# 1. Quick-fix marker cleanup (auto-delete after one use)
#=============================================================================

if [ -f ".claude/quick-fix" ]; then
  rm -f ".claude/quick-fix"
fi

#=============================================================================
# 2. Learning observer — track file edit patterns
#=============================================================================

LEARNING_DIR=".claude/learning"
PATTERNS_FILE="$LEARNING_DIR/patterns.json"
THRESHOLDS_FILE="$LEARNING_DIR/.thresholds_reached"

mkdir -p "$LEARNING_DIR"

# Initialize patterns file if missing or invalid
if [ ! -f "$PATTERNS_FILE" ] || ! jq empty "$PATTERNS_FILE" 2>/dev/null; then
  cat > "$PATTERNS_FILE" << 'PATEOF'
{
  "version": 1,
  "last_updated": null,
  "file_patterns": {},
  "directory_patterns": {},
  "extension_patterns": {},
  "thresholds": {
    "skill_creation": 3,
    "agent_creation": 5
  }
}
PATEOF
fi

TIMESTAMP=$(date -Iseconds)
TODAY=$(date +%Y-%m-%d)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

if [ -n "$FILE_PATH" ]; then
  dir_path=$(dirname "$FILE_PATH")
  extension="${FILE_PATH##*.}"

  # Update patterns.json
  tmp_file=$(mktemp)
  jq --arg fp "$FILE_PATH" \
     --arg dp "$dir_path" \
     --arg ext "$extension" \
     --arg ts "$TIMESTAMP" \
     --arg today "$TODAY" '
      .file_patterns[$fp] = (
          (.file_patterns[$fp] // {"count": 0, "first_seen": $today, "last_seen": null, "dates": []}) |
          .count += 1 |
          .last_seen = $today |
          .dates = ((.dates + [$today]) | unique | .[-10:])
      ) |
      .directory_patterns[$dp] = (
          (.directory_patterns[$dp] // {"count": 0, "first_seen": $today, "files": []}) |
          .count += 1 |
          .files = ((.files + [$fp]) | unique | .[-20:])
      ) |
      .extension_patterns[$ext] = (
          (.extension_patterns[$ext] // {"count": 0, "first_seen": $today}) |
          .count += 1
      ) |
      .last_updated = $ts
  ' "$PATTERNS_FILE" > "$tmp_file" 2>/dev/null && mv "$tmp_file" "$PATTERNS_FILE" || rm -f "$tmp_file"

  # Check thresholds
  skill_threshold=$(jq -r '.thresholds.skill_creation // 3' "$PATTERNS_FILE" 2>/dev/null)
  triggered=$(jq -r --argjson threshold "${skill_threshold:-3}" '
      .directory_patterns | to_entries |
      map(select(.value.count >= $threshold)) |
      map(.key) | join("\n")
  ' "$PATTERNS_FILE" 2>/dev/null)

  if [ -n "$triggered" ]; then
    echo "$triggered" | while read -r dir; do
      if [ -n "$dir" ] && ! grep -q "^$dir$" "$THRESHOLDS_FILE" 2>/dev/null; then
        echo "$dir" >> "$THRESHOLDS_FILE"
      fi
    done
  fi
fi

#=============================================================================
# 3. Decision reminder — prompt after significant changes
#=============================================================================

if [ -n "$FILE_PATH" ]; then
  STATE_DIR=".claude/state"
  EDIT_TRACKER="$STATE_DIR/.edits-this-session"
  DECISION_PROMPT_SHOWN="$STATE_DIR/.decision-prompt-shown"

  mkdir -p "$STATE_DIR"

  # Normalize path
  if [[ "$FILE_PATH" = /* ]]; then
    NORMALIZED="${FILE_PATH#$project_root/}"
  else
    NORMALIZED="$FILE_PATH"
  fi

  # Track the edit
  echo "$NORMALIZED" >> "$EDIT_TRACKER"

  # Count unique files edited this session
  EDIT_COUNT=$(sort -u "$EDIT_TRACKER" 2>/dev/null | wc -l | tr -d ' ')

  # Check for critical file patterns
  IS_CRITICAL=false
  case "$NORMALIZED" in
    package.json|requirements.txt|Cargo.toml|go.mod|pyproject.toml|tsconfig.json)
      IS_CRITICAL=true ;;
    .env*|docker-compose*|Dockerfile|schema.prisma)
      IS_CRITICAL=true ;;
    *.config.js|*.config.ts|.claude/settings*.json)
      IS_CRITICAL=true ;;
    migrations/*)
      IS_CRITICAL=true ;;
  esac

  # Decide if we should prompt
  SHOULD_PROMPT=false
  if [ "$EDIT_COUNT" -ge 5 ] || [ "$IS_CRITICAL" = true ]; then
    if [ -f "$DECISION_PROMPT_SHOWN" ]; then
      LAST_PROMPT_COUNT=$(cat "$DECISION_PROMPT_SHOWN")
      if [ $((EDIT_COUNT - LAST_PROMPT_COUNT)) -ge 5 ]; then
        SHOULD_PROMPT=true
      fi
    else
      SHOULD_PROMPT=true
    fi
  fi

  if [ "$SHOULD_PROMPT" = true ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Decision Recording Reminder"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    if [ "$IS_CRITICAL" = true ]; then
      echo "Critical file modified: $NORMALIZED"
    else
      echo "Significant changes made ($EDIT_COUNT files)"
    fi
    echo ""
    echo "Consider recording key decisions:"
    echo "   /ce:focus decision \"why this approach\""
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo "$EDIT_COUNT" > "$DECISION_PROMPT_SHOWN"
  fi
fi

exit 0
