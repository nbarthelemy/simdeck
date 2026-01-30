#!/bin/bash
# Read Tracker - Tracks files read in current session
# Usage: read-tracker.sh <command> [args]
#
# Commands:
#   record <file>    - Record a file as read
#   check <file>     - Check if file was read (exit 0=yes, 1=no)
#   list             - List all read files
#   clear            - Clear read files (new session)
#   status           - JSON status output

set -e

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

# Normalize path (remove project root prefix, resolve relative)
normalize_path() {
    local path="$1"
    # Remove project root prefix if absolute
    if [[ "$path" = /* ]]; then
        path="${path#$PROJECT_ROOT/}"
    fi
    echo "$path"
}

cmd_record() {
    local file=$(normalize_path "$1")
    [ -z "$file" ] && exit 0

    # Add to read files if not already there
    if ! grep -Fxq "$file" "$READ_FILE" 2>/dev/null; then
        echo "$file" >> "$READ_FILE"
    fi
}

cmd_check() {
    local file=$(normalize_path "$1")
    [ -z "$file" ] && exit 0

    # Check if file was read
    if grep -Fxq "$file" "$READ_FILE" 2>/dev/null; then
        exit 0  # File was read
    else
        exit 1  # File not read
    fi
}

cmd_list() {
    if [ -f "$READ_FILE" ]; then
        cat "$READ_FILE"
    fi
}

cmd_clear() {
    rm -f "$READ_FILE"
    echo '{"error": false, "message": "Read tracking cleared"}'
}

cmd_status() {
    local count=0
    if [ -f "$READ_FILE" ]; then
        count=$(wc -l < "$READ_FILE" | tr -d ' ')
    fi
    echo "{\"filesRead\": $count, \"trackingFile\": \"$READ_FILE\"}"
}

case "${1:-status}" in
    record)
        cmd_record "$2"
        ;;
    check)
        cmd_check "$2"
        ;;
    list)
        cmd_list
        ;;
    clear)
        cmd_clear
        ;;
    status)
        cmd_status
        ;;
    *)
        echo "Unknown command: $1" >&2
        exit 1
        ;;
esac
