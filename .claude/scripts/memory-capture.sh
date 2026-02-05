#!/bin/bash
# Memory Capture Hook
# Queues tool observations to pending file for later processing
# Called by PostToolUse hook - must be fast and non-blocking
# Usage: memory-capture.sh (reads TOOL_* environment variables)

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

PROJECT_ROOT=$(find_project_root)
if [ -z "$PROJECT_ROOT" ]; then
    exit 0  # Silently exit if not in a project
fi
cd "$PROJECT_ROOT" || exit 0

MEMORY_DIR=".claude/memory"
PENDING_FILE="$MEMORY_DIR/.pending-observations.jsonl"
SESSION_FILE=".claude/state/session-state.json"

# Ensure memory directory exists
mkdir -p "$MEMORY_DIR"

# Get tool information from environment or stdin
TOOL_NAME="${TOOL_NAME:-}"
TOOL_INPUT="${TOOL_INPUT:-}"
TOOL_OUTPUT="${TOOL_OUTPUT:-}"
FILE_PATH="${FILE_PATH:-}"

# Read from Claude's hook format if env vars not set
if [ -z "$TOOL_NAME" ]; then
    # Try to read from stdin (hook passes JSON)
    if read -t 0.1 -r hook_data 2>/dev/null; then
        if command -v jq &> /dev/null; then
            TOOL_NAME=$(echo "$hook_data" | jq -r '.tool_name // empty' 2>/dev/null)
            TOOL_INPUT=$(echo "$hook_data" | jq -r '.tool_input // empty' 2>/dev/null | head -c 1000)
            TOOL_OUTPUT=$(echo "$hook_data" | jq -r '.tool_output // empty' 2>/dev/null | head -c 2000)
            FILE_PATH=$(echo "$hook_data" | jq -r '.file_path // empty' 2>/dev/null)
        fi
    fi
fi

# Exit if no tool information
if [ -z "$TOOL_NAME" ]; then
    exit 0
fi

# Determine importance based on tool type
case "$TOOL_NAME" in
    Write|Edit|MultiEdit)
        IMPORTANCE=2
        ;;
    Bash)
        # Check for significant commands
        if echo "$TOOL_INPUT" | grep -qE '(git commit|npm publish|deploy|migration)'; then
            IMPORTANCE=3
        else
            IMPORTANCE=1
        fi
        ;;
    Read|Glob|Grep)
        IMPORTANCE=1
        ;;
    *)
        IMPORTANCE=1
        ;;
esac

# Get session ID
SESSION_ID="unknown"
if [ -f "$SESSION_FILE" ] && command -v jq &> /dev/null; then
    SESSION_ID=$(jq -r '.metadata.sessionId // "unknown"' "$SESSION_FILE" 2>/dev/null)
fi

# Get current timestamp
TIMESTAMP=$(date -Iseconds)

# Truncate large outputs
truncate_text() {
    local text="$1"
    local max="${2:-2000}"
    echo "${text:0:$max}"
}

TOOL_OUTPUT_TRUNCATED=$(truncate_text "$TOOL_OUTPUT" 2000)
TOOL_INPUT_TRUNCATED=$(truncate_text "$TOOL_INPUT" 1000)

# Build files involved array
FILES_INVOLVED="[]"
if [ -n "$FILE_PATH" ]; then
    FILES_INVOLVED="[\"$FILE_PATH\"]"
elif echo "$TOOL_INPUT" | grep -qE '(file_path|path)'; then
    # Try to extract file path from input
    if command -v jq &> /dev/null; then
        EXTRACTED_PATH=$(echo "$TOOL_INPUT_TRUNCATED" | jq -r '.file_path // .path // empty' 2>/dev/null)
        if [ -n "$EXTRACTED_PATH" ]; then
            FILES_INVOLVED="[\"$EXTRACTED_PATH\"]"
        fi
    fi
fi

# Escape for JSON
escape_json() {
    echo "$1" | sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g' | tr '\n' ' ' | head -c "${2:-2000}"
}

TOOL_INPUT_ESCAPED=$(escape_json "$TOOL_INPUT_TRUNCATED" 1000)
TOOL_OUTPUT_ESCAPED=$(escape_json "$TOOL_OUTPUT_TRUNCATED" 2000)

# Append to pending file (JSONL format - one JSON per line)
cat >> "$PENDING_FILE" << EOF
{"session_id":"$SESSION_ID","timestamp":"$TIMESTAMP","tool_name":"$TOOL_NAME","tool_input":"$TOOL_INPUT_ESCAPED","tool_output":"$TOOL_OUTPUT_ESCAPED","files_involved":$FILES_INVOLVED,"importance":$IMPORTANCE}
EOF

exit 0
