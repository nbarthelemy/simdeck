#!/bin/bash
# LSP New Language Check - Triggered on file modifications
# Checks if a new language was introduced and needs LSP setup

# Get the file that was modified from environment
FILE="${CLAUDE_TOOL_INPUT:-}"

# Skip if no file or if it's in ignored directories
if [ -z "$FILE" ]; then
    exit 0
fi

# Skip common non-code paths
case "$FILE" in
    *node_modules*|*.git*|*vendor*|*venv*|*.venv*|*target*|*build*|*dist*|*__pycache__*)
        exit 0
        ;;
esac

# Get file extension
EXT=".${FILE##*.}"

# Skip if no extension or common non-code files
case "$EXT" in
    .|.md|.txt|.json|.yaml|.yml|.toml|.lock|.log|.env|.gitignore)
        exit 0
        ;;
esac

# Check if this is a new language that needs LSP
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT=$("$SCRIPT_DIR/lsp-setup.sh" check-new "$FILE" 2>/dev/null)

if [[ "$RESULT" == NEW_LANGUAGE:* ]]; then
    # Extract language and server
    LANG=$(echo "$RESULT" | cut -d: -f2)
    SERVER=$(echo "$RESULT" | cut -d: -f3)

    # Log the detection
    mkdir -p "$(dirname "$SCRIPT_DIR")/logs"
    echo "[$(date -Iseconds)] New language detected: $LANG (needs $SERVER)" >> "$(dirname "$SCRIPT_DIR")/logs/lsp-setup.log"

    # Mark for LSP setup
    echo "$LANG:$SERVER" >> "$(dirname "$SCRIPT_DIR")/.lsp-pending"
fi

exit 0
