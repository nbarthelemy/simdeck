#!/bin/bash
# State Manager - Maintains session state for focus, decisions, and handoff
# Usage: state-manager.sh <command> [args]
#
# Commands:
#   status              - Show current state as JSON
#   get <field>         - Get a specific field (focus, decisions, blockers, handoff)
#   set-focus           - Set focus (reads JSON from stdin)
#   clear-focus         - Clear current focus
#   lock-focus          - Lock focus to prevent switching
#   unlock-focus        - Unlock focus
#   add-decision        - Add a decision (reads JSON from stdin)
#   add-blocker         - Add a blocker (reads JSON from stdin)
#   clear-blocker <id>  - Remove a blocker by index
#   set-handoff         - Set handoff notes (reads JSON from stdin)
#   init                - Initialize state file if missing
#   set-thinking        - Set thinking level (reads JSON from stdin)
#   get-thinking        - Get current thinking level

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

PROJECT_ROOT=$(find_project_root) || exit 1
STATE_FILE="$PROJECT_ROOT/.claude/state/session-state.json"
STATE_DIR="$PROJECT_ROOT/.claude/state"

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Initialize state file if missing
init_state() {
    if [ ! -f "$STATE_FILE" ]; then
        cat > "$STATE_FILE" << 'EOF'
{
  "focus": {
    "activePlan": null,
    "currentTask": null,
    "startedAt": null,
    "filesInScope": [],
    "locked": false
  },
  "decisions": [],
  "blockers": [],
  "handoff": {
    "lastSession": null,
    "completedTasks": [],
    "nextSteps": [],
    "notes": null
  },
  "thinking": {
    "level": "medium",
    "setAt": null
  },
  "metadata": {
    "createdAt": null,
    "lastUpdated": null,
    "sessionCount": 0
  }
}
EOF
        # Set creation timestamp
        local now=$(date -Iseconds)
        local tmp=$(mktemp)
        jq --arg ts "$now" '.metadata.createdAt = $ts | .metadata.lastUpdated = $ts' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    fi
}

# Update lastUpdated timestamp
update_timestamp() {
    local now=$(date -Iseconds)
    local tmp=$(mktemp)
    jq --arg ts "$now" '.metadata.lastUpdated = $ts' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
}

# Commands
cmd_status() {
    init_state
    cat "$STATE_FILE"
}

cmd_get() {
    init_state
    local field="$1"
    case "$field" in
        focus|decisions|blockers|handoff|metadata|thinking)
            jq ".$field" "$STATE_FILE"
            ;;
        *)
            echo "Unknown field: $field" >&2
            exit 1
            ;;
    esac
}

cmd_set_focus() {
    init_state

    # Check if focus is locked
    local locked=$(jq -r '.focus.locked' "$STATE_FILE")
    if [ "$locked" = "true" ]; then
        echo '{"error": true, "message": "Focus is locked. Use unlock-focus first or complete current task."}'
        exit 1
    fi

    # Read focus data from stdin
    local focus_data=$(cat)
    local now=$(date -Iseconds)

    local tmp=$(mktemp)
    echo "$focus_data" | jq --arg ts "$now" '{
        activePlan: .activePlan,
        currentTask: .currentTask,
        startedAt: $ts,
        filesInScope: (.filesInScope // []),
        locked: false
    }' > "$tmp"

    local focus_json=$(cat "$tmp")
    rm "$tmp"

    tmp=$(mktemp)
    jq --argjson focus "$focus_json" --arg ts "$now" '
        .focus = $focus |
        .metadata.lastUpdated = $ts
    ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"

    echo '{"error": false, "message": "Focus set successfully"}'
}

cmd_clear_focus() {
    init_state
    local now=$(date -Iseconds)
    local tmp=$(mktemp)

    # Move current task to completed if there was one
    local current_task=$(jq -r '.focus.currentTask // empty' "$STATE_FILE")

    if [ -n "$current_task" ]; then
        jq --arg task "$current_task" --arg ts "$now" '
            .handoff.completedTasks += [$task] |
            .focus = {
                activePlan: null,
                currentTask: null,
                startedAt: null,
                filesInScope: [],
                locked: false
            } |
            .metadata.lastUpdated = $ts
        ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    else
        jq --arg ts "$now" '
            .focus = {
                activePlan: null,
                currentTask: null,
                startedAt: null,
                filesInScope: [],
                locked: false
            } |
            .metadata.lastUpdated = $ts
        ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    fi

    echo '{"error": false, "message": "Focus cleared"}'
}

cmd_lock_focus() {
    init_state
    local tmp=$(mktemp)
    jq '.focus.locked = true' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    update_timestamp
    echo '{"error": false, "message": "Focus locked"}'
}

cmd_unlock_focus() {
    init_state
    local tmp=$(mktemp)
    jq '.focus.locked = false' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
    update_timestamp
    echo '{"error": false, "message": "Focus unlocked"}'
}

cmd_add_decision() {
    init_state
    local decision_data=$(cat)
    local now=$(date +%Y-%m-%d)
    local tmp=$(mktemp)

    echo "$decision_data" | jq --arg date "$now" '{
        date: $date,
        decision: .decision,
        reason: .reason
    }' > "$tmp"

    local decision_json=$(cat "$tmp")
    rm "$tmp"

    tmp=$(mktemp)
    jq --argjson decision "$decision_json" '
        .decisions += [$decision]
    ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"

    update_timestamp

    # Also append to memory/decisions.md for persistent storage
    local MEMORY_DIR="$PROJECT_ROOT/.claude/memory"
    mkdir -p "$MEMORY_DIR"
    local DECISIONS_FILE="$MEMORY_DIR/decisions.md"

    # Initialize file if missing
    if [ ! -f "$DECISIONS_FILE" ]; then
        cat > "$DECISIONS_FILE" << 'DECEOF'
# Architectural Decisions

Project decisions captured via `/ce:focus decision`. Auto-populated.

---

DECEOF
    fi

    # Extract decision text and reason
    local decision_text=$(echo "$decision_json" | jq -r '.decision')
    local reason_text=$(echo "$decision_json" | jq -r '.reason // "No reason provided"')

    # Append to decisions file
    echo "## $now: $decision_text" >> "$DECISIONS_FILE"
    echo "" >> "$DECISIONS_FILE"
    echo "**Reason:** $reason_text" >> "$DECISIONS_FILE"
    echo "" >> "$DECISIONS_FILE"
    echo "---" >> "$DECISIONS_FILE"
    echo "" >> "$DECISIONS_FILE"

    echo '{"error": false, "message": "Decision recorded"}'
}

cmd_add_blocker() {
    init_state
    local blocker_data=$(cat)
    local now=$(date +%Y-%m-%d)
    local tmp=$(mktemp)

    echo "$blocker_data" | jq --arg date "$now" '{
        issue: .issue,
        since: $date,
        owner: (.owner // "unknown")
    }' > "$tmp"

    local blocker_json=$(cat "$tmp")
    rm "$tmp"

    tmp=$(mktemp)
    jq --argjson blocker "$blocker_json" '
        .blockers += [$blocker]
    ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"

    update_timestamp
    echo '{"error": false, "message": "Blocker recorded"}'
}

cmd_clear_blocker() {
    init_state
    local index="$1"
    local tmp=$(mktemp)

    jq --argjson idx "$index" '
        .blockers = (.blockers[:$idx] + .blockers[$idx+1:])
    ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"

    update_timestamp
    echo '{"error": false, "message": "Blocker removed"}'
}

cmd_set_handoff() {
    init_state
    local handoff_data=$(cat)
    local now=$(date -Iseconds)
    local tmp=$(mktemp)

    echo "$handoff_data" | jq --arg ts "$now" '{
        lastSession: $ts,
        completedTasks: (.completedTasks // []),
        nextSteps: (.nextSteps // []),
        notes: .notes
    }' > "$tmp"

    local handoff_json=$(cat "$tmp")
    rm "$tmp"

    tmp=$(mktemp)
    jq --argjson handoff "$handoff_json" --arg ts "$now" '
        .handoff = $handoff |
        .metadata.lastUpdated = $ts |
        .metadata.sessionCount += 1
    ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"

    echo '{"error": false, "message": "Handoff notes saved"}'
}

cmd_init() {
    init_state
    echo '{"error": false, "message": "State initialized", "path": "'"$STATE_FILE"'"}'
}

cmd_set_thinking() {
    init_state
    local thinking_data=$(cat)
    local now=$(date -Iseconds)

    # Validate level
    local level=$(echo "$thinking_data" | jq -r '.level')
    case "$level" in
        off|low|medium|high|max)
            ;;
        *)
            echo '{"error": true, "message": "Invalid thinking level. Use: off, low, medium, high, max"}'
            exit 1
            ;;
    esac

    local tmp=$(mktemp)
    jq --arg level "$level" --arg ts "$now" '
        .thinking.level = $level |
        .thinking.setAt = $ts |
        .metadata.lastUpdated = $ts
    ' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"

    echo '{"error": false, "message": "Thinking level set to '"$level"'"}'
}

cmd_get_thinking() {
    init_state
    local level=$(jq -r '.thinking.level // "medium"' "$STATE_FILE")
    local setAt=$(jq -r '.thinking.setAt // empty' "$STATE_FILE")

    if [ -n "$setAt" ]; then
        echo '{"level": "'"$level"'", "setAt": "'"$setAt"'"}'
    else
        echo '{"level": "'"$level"'", "setAt": null}'
    fi
}

cmd_check_focus() {
    # Check if a file is within current focus scope
    # Used by focus-enforce hook
    init_state

    local file_path="$1"

    # Get current focus state
    local active_plan=$(jq -r '.focus.activePlan // empty' "$STATE_FILE")
    local locked=$(jq -r '.focus.locked' "$STATE_FILE")
    local files_in_scope=$(jq -r '.focus.filesInScope[]' "$STATE_FILE" 2>/dev/null)

    # If no active focus or not locked, allow all
    if [ -z "$active_plan" ] || [ "$locked" != "true" ]; then
        echo '{"allowed": true, "reason": "No locked focus"}'
        exit 0
    fi

    # If files in scope is empty, allow all (focus is on plan, not specific files)
    if [ -z "$files_in_scope" ]; then
        echo '{"allowed": true, "reason": "No file restrictions"}'
        exit 0
    fi

    # Normalize file path
    local normalized_path="$file_path"
    if [[ "$file_path" = /* ]]; then
        normalized_path="${file_path#$PROJECT_ROOT/}"
    fi

    # Check if file is in scope
    for scope_file in $files_in_scope; do
        if [ "$normalized_path" = "$scope_file" ] || [[ "$normalized_path" == $scope_file* ]]; then
            echo '{"allowed": true, "reason": "File in scope"}'
            exit 0
        fi
    done

    # File not in scope
    echo '{"allowed": false, "reason": "File outside current focus", "activePlan": "'"$active_plan"'", "filesInScope": '"$(jq '.focus.filesInScope' "$STATE_FILE")"'}'
    exit 0
}

# Main
case "${1:-status}" in
    status)
        cmd_status
        ;;
    get)
        cmd_get "$2"
        ;;
    set-focus)
        cmd_set_focus
        ;;
    clear-focus)
        cmd_clear_focus
        ;;
    lock-focus)
        cmd_lock_focus
        ;;
    unlock-focus)
        cmd_unlock_focus
        ;;
    add-decision)
        cmd_add_decision
        ;;
    add-blocker)
        cmd_add_blocker
        ;;
    clear-blocker)
        cmd_clear_blocker "$2"
        ;;
    set-handoff)
        cmd_set_handoff
        ;;
    init)
        cmd_init
        ;;
    set-thinking)
        cmd_set_thinking
        ;;
    get-thinking)
        cmd_get_thinking
        ;;
    check-focus)
        cmd_check_focus "$2"
        ;;
    *)
        echo "Unknown command: $1" >&2
        echo "Usage: state-manager.sh <command> [args]" >&2
        exit 1
        ;;
esac
