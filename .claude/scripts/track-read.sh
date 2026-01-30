#!/bin/bash
# Track Read - Records files that have been read
# PostToolUse hook for Read tool

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
STATE_DIR="$PROJECT_ROOT/.claude/state"
READ_FILE="$STATE_DIR/.files-read"

mkdir -p "$STATE_DIR"

# Read tool input from stdin
INPUT=$(cat)

# Extract file path from Read tool
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
[ -z "$FILE_PATH" ] && exit 0

# Normalize path
if [[ "$FILE_PATH" = /* ]]; then
    NORMALIZED="${FILE_PATH#$PROJECT_ROOT/}"
else
    NORMALIZED="$FILE_PATH"
fi

# Record as read (if not already)
if ! grep -Fxq "$NORMALIZED" "$READ_FILE" 2>/dev/null; then
    echo "$NORMALIZED" >> "$READ_FILE"
fi

exit 0
