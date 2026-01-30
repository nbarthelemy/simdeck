#!/bin/bash
# Hooks Manager - List and manage Claude Code hooks
# Usage: hooks-manager.sh <command> [args]
#
# Commands:
#   list              - List all hooks with status
#   info <name>       - Show details for a specific hook
#   toggle <name>     - Enable/disable a hook

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

PROJECT_ROOT=$(find_project_root) || {
    echo '{"error": true, "message": "Not in a claudenv project"}'
    exit 1
}
cd "$PROJECT_ROOT" || exit 1

SCRIPTS_DIR=".claude/scripts"
DISABLED_DIR=".claude/scripts/.disabled"

# Get hook description (function instead of associative array for bash 3 compat)
get_hook_desc() {
    case "$1" in
        session-start.sh) echo "Runs when a new Claude session begins" ;;
        session-end.sh) echo "Runs when Claude session ends" ;;
        unified-gate.sh) echo "Plan, TDD, focus lock, and read-before-write enforcement" ;;
        block-no-verify.sh) echo "Prevents git commits with --no-verify" ;;
        track-read.sh) echo "Tracks file read operations" ;;
        post-write.sh) echo "Learning observer, decision reminders, quick-fix cleanup" ;;
        *) echo "Unknown hook" ;;
    esac
}

# Get hook trigger
get_hook_trigger() {
    case "$1" in
        session-start.sh) echo "SessionStart" ;;
        session-end.sh) echo "Stop" ;;
        unified-gate.sh) echo "PreToolUse:Write|Edit|MultiEdit" ;;
        block-no-verify.sh) echo "PreToolUse:Bash" ;;
        track-read.sh) echo "PostToolUse:Read" ;;
        post-write.sh) echo "PostToolUse:Write|Edit|MultiEdit" ;;
        *) echo "Unknown" ;;
    esac
}

# Check if script is a hook (not utility)
is_hook() {
    case "$1" in
        detect-stack.sh|propose-*.sh|state-manager.sh|daily-log.sh|hooks-manager.sh|usage-tracker.sh)
            return 1 ;;
        audit.sh|apply-update.sh|check-update.sh|claudenv-status.sh|cleanup-*.sh)
            return 1 ;;
        debug-*.sh|dependency-graph.sh|generate-*.sh|get-*.sh|git-*.sh|health-check.sh)
            return 1 ;;
        incremental-validate.sh|learn-review.sh|list-backups.sh|loop-*.sh|lsp-*.sh)
            return 1 ;;
        map-codebase.sh|mcp-setup.sh|phase-manager.sh|plan-*.sh|plans-list.sh)
            return 1 ;;
        post-commit.sh|pre-commit.sh|read-tracker.sh|skills-triggers.sh|agents-triggers.sh)
            return 1 ;;
        task-commit.sh|task-bridge.sh|validate*.sh|autopilot-manager.sh|bootstrap.sh)
            return 1 ;;
        *)
            return 0 ;;
    esac
}

cmd_list() {
    # Output JSON for Claude to format
    echo "{"
    echo '  "error": false,'
    echo '  "hooks": ['

    first=true
    for script in "$SCRIPTS_DIR"/*.sh; do
        [ -f "$script" ] || continue
        script_name=$(basename "$script")

        # Skip non-hook scripts
        if ! is_hook "$script_name"; then
            continue
        fi

        # Check if disabled
        enabled="true"
        if [ -f "$DISABLED_DIR/$script_name" ]; then
            enabled="false"
        fi

        # Get description
        desc=$(get_hook_desc "$script_name")
        trigger=$(get_hook_trigger "$script_name")

        if [ "$first" = true ]; then
            first=false
        else
            echo ","
        fi

        printf '    {"name": "%s", "enabled": %s, "description": "%s", "trigger": "%s"}' \
            "$script_name" "$enabled" "$desc" "$trigger"
    done

    echo ""
    echo "  ]"
    echo "}"
}

cmd_info() {
    local name="$1"

    # Add .sh if missing
    [[ "$name" != *.sh ]] && name="$name.sh"

    local script_path="$SCRIPTS_DIR/$name"

    if [ ! -f "$script_path" ]; then
        echo '{"error": true, "message": "Hook not found: '"$name"'"}'
        exit 1
    fi

    # Check if disabled
    enabled="true"
    if [ -f "$DISABLED_DIR/$name" ]; then
        enabled="false"
    fi

    # Get description
    desc=$(get_hook_desc "$name")
    trigger=$(get_hook_trigger "$name")

    # Get file stats
    if [[ "$OSTYPE" == "darwin"* ]]; then
        modified=$(stat -f "%Sm" -t "%Y-%m-%d" "$script_path" 2>/dev/null || echo "unknown")
        size=$(stat -f "%z" "$script_path" 2>/dev/null || echo "0")
    else
        modified=$(stat -c "%y" "$script_path" 2>/dev/null | cut -d' ' -f1 || echo "unknown")
        size=$(stat -c "%s" "$script_path" 2>/dev/null || echo "0")
    fi

    cat << EOF
{
  "error": false,
  "hook": {
    "name": "$name",
    "enabled": $enabled,
    "description": "$desc",
    "trigger": "$trigger",
    "path": "$script_path",
    "modified": "$modified",
    "size": $size
  }
}
EOF
}

cmd_toggle() {
    local name="$1"

    # Add .sh if missing
    [[ "$name" != *.sh ]] && name="$name.sh"

    local script_path="$SCRIPTS_DIR/$name"
    local disabled_path="$DISABLED_DIR/$name"

    if [ ! -f "$script_path" ]; then
        echo '{"error": true, "message": "Hook not found: '"$name"'"}'
        exit 1
    fi

    mkdir -p "$DISABLED_DIR"

    if [ -f "$disabled_path" ]; then
        # Enable by removing from disabled
        rm -f "$disabled_path"
        echo '{"error": false, "message": "Hook enabled: '"$name"'", "enabled": true}'
    else
        # Disable by creating marker
        touch "$disabled_path"
        echo '{"error": false, "message": "Hook disabled: '"$name"'", "enabled": false}'
    fi
}

# Main
case "${1:-list}" in
    list)
        cmd_list
        ;;
    info)
        cmd_info "$2"
        ;;
    toggle)
        cmd_toggle "$2"
        ;;
    *)
        echo '{"error": true, "message": "Unknown command: '"$1"'"}'
        exit 1
        ;;
esac
