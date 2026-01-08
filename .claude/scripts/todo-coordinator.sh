#!/bin/bash
# TODO Coordinator - Shared state for parallel agent coordination
# Manages task claiming, status tracking, and conflict prevention

# Always resolve paths relative to repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Look for TODO.md in .claude first, then root
if [ -f "$REPO_ROOT/.claude/TODO.md" ]; then
    TODO_FILE="$REPO_ROOT/.claude/TODO.md"
elif [ -f "$REPO_ROOT/TODO.md" ]; then
    TODO_FILE="$REPO_ROOT/TODO.md"
else
    TODO_FILE="$REPO_ROOT/.claude/TODO.md"  # Default location for new files
fi

STATE_FILE="$REPO_ROOT/.claude/loop/coordination.json"
LOCK_FILE="$REPO_ROOT/.claude/loop/.coordination.lock"

# Initialize state file if missing
init_state() {
    mkdir -p "$(dirname "$STATE_FILE")"
    if [ ! -f "$STATE_FILE" ]; then
        cat > "$STATE_FILE" << 'EOF'
{
  "version": 1,
  "agents": {},
  "tasks": {},
  "lastUpdate": ""
}
EOF
    fi
}

# Acquire lock (with timeout)
acquire_lock() {
    local timeout=10
    local count=0
    while [ -f "$LOCK_FILE" ] && [ $count -lt $timeout ]; do
        sleep 0.5
        count=$((count + 1))
    done
    if [ $count -ge $timeout ]; then
        echo '{"error": true, "message": "Lock timeout"}'
        return 1
    fi
    echo $$ > "$LOCK_FILE"
    return 0
}

# Release lock
release_lock() {
    rm -f "$LOCK_FILE"
}

# Register an agent
register_agent() {
    local agent_id="$1"
    local track="$2"
    init_state
    acquire_lock || return 1

    local timestamp=$(date -Iseconds)
    local state=$(cat "$STATE_FILE")

    # Add/update agent
    state=$(echo "$state" | jq --arg id "$agent_id" --arg track "$track" --arg ts "$timestamp" '
        .agents[$id] = {
            "track": $track,
            "status": "active",
            "startedAt": $ts,
            "lastHeartbeat": $ts
        } |
        .lastUpdate = $ts
    ')

    echo "$state" > "$STATE_FILE"
    release_lock

    echo '{"success": true, "agentId": "'"$agent_id"'"}'
}

# Claim a task
claim_task() {
    local agent_id="$1"
    local task_id="$2"
    init_state
    acquire_lock || return 1

    local timestamp=$(date -Iseconds)
    local state=$(cat "$STATE_FILE")

    # Check if already claimed
    local current_owner=$(echo "$state" | jq -r --arg tid "$task_id" '.tasks[$tid].claimedBy // ""')
    if [ -n "$current_owner" ] && [ "$current_owner" != "$agent_id" ]; then
        release_lock
        echo '{"error": true, "message": "Task already claimed by '"$current_owner"'"}'
        return 1
    fi

    # Claim the task
    state=$(echo "$state" | jq --arg id "$agent_id" --arg tid "$task_id" --arg ts "$timestamp" '
        .tasks[$tid] = {
            "claimedBy": $id,
            "status": "in_progress",
            "claimedAt": $ts
        } |
        .lastUpdate = $ts
    ')

    echo "$state" > "$STATE_FILE"
    release_lock

    echo '{"success": true, "taskId": "'"$task_id"'", "claimedBy": "'"$agent_id"'"}'
}

# Complete a task
complete_task() {
    local agent_id="$1"
    local task_id="$2"
    init_state
    acquire_lock || return 1

    local timestamp=$(date -Iseconds)
    local state=$(cat "$STATE_FILE")

    # Mark complete
    state=$(echo "$state" | jq --arg id "$agent_id" --arg tid "$task_id" --arg ts "$timestamp" '
        .tasks[$tid].status = "completed" |
        .tasks[$tid].completedAt = $ts |
        .lastUpdate = $ts
    ')

    echo "$state" > "$STATE_FILE"
    release_lock

    # Also update TODO.md - mark task as complete
    if [ -f "$TODO_FILE" ]; then
        sed -i.bak "s/- \[ \] .*${task_id}.*/- [x] $(date +%Y-%m-%d): \0/" "$TODO_FILE" 2>/dev/null
        rm -f "${TODO_FILE}.bak"
    fi

    echo '{"success": true, "taskId": "'"$task_id"'", "status": "completed"}'
}

# Get available (unclaimed) tasks
get_available_tasks() {
    local track="$1"
    init_state

    local state=$(cat "$STATE_FILE")
    local claimed_tasks=$(echo "$state" | jq -r '.tasks | to_entries | map(select(.value.status == "in_progress")) | map(.key) | join("|")')

    if [ ! -f "$TODO_FILE" ]; then
        echo '{"error": true, "message": "TODO.md not found"}'
        return 1
    fi

    # Parse TODO.md for unclaimed tasks in the specified track
    local tasks=""
    local in_track=false

    while IFS= read -r line; do
        if [[ "$line" =~ ^###.*Track.*"$track" ]] || [[ "$line" =~ ^###.*"$track" ]]; then
            in_track=true
        elif [[ "$line" =~ ^### ]] && [ "$in_track" = true ]; then
            in_track=false
        elif [ "$in_track" = true ] && [[ "$line" =~ ^-\ \[\ \] ]]; then
            # Extract task - skip if claimed
            local task_text=$(echo "$line" | sed 's/- \[ \] //')
            if [ -z "$claimed_tasks" ] || ! echo "$task_text" | grep -qE "$claimed_tasks"; then
                tasks="$tasks\"$task_text\","
            fi
        fi
    done < "$TODO_FILE"

    # Remove trailing comma and wrap in array
    tasks=$(echo "$tasks" | sed 's/,$//')
    echo '{"tasks": ['"$tasks"']}'
}

# Get coordination status
get_status() {
    init_state
    local state=$(cat "$STATE_FILE")

    local active_agents=$(echo "$state" | jq '[.agents | to_entries | map(select(.value.status == "active"))] | length')
    local in_progress=$(echo "$state" | jq '[.tasks | to_entries | map(select(.value.status == "in_progress"))] | length')
    local completed=$(echo "$state" | jq '[.tasks | to_entries | map(select(.value.status == "completed"))] | length')

    echo "$state" | jq --arg active "$active_agents" --arg prog "$in_progress" --arg done "$completed" '{
        "activeAgents": ($active | tonumber),
        "tasksInProgress": ($prog | tonumber),
        "tasksCompleted": ($done | tonumber),
        "agents": .agents,
        "tasks": .tasks
    }'
}

# Heartbeat - update agent's last seen time
heartbeat() {
    local agent_id="$1"
    init_state
    acquire_lock || return 1

    local timestamp=$(date -Iseconds)
    local state=$(cat "$STATE_FILE")

    state=$(echo "$state" | jq --arg id "$agent_id" --arg ts "$timestamp" '
        .agents[$id].lastHeartbeat = $ts |
        .lastUpdate = $ts
    ')

    echo "$state" > "$STATE_FILE"
    release_lock
    echo '{"success": true}'
}

# Deregister agent
deregister_agent() {
    local agent_id="$1"
    init_state
    acquire_lock || return 1

    local timestamp=$(date -Iseconds)
    local state=$(cat "$STATE_FILE")

    # Mark agent as inactive, release its tasks
    state=$(echo "$state" | jq --arg id "$agent_id" --arg ts "$timestamp" '
        .agents[$id].status = "inactive" |
        .agents[$id].endedAt = $ts |
        (.tasks | to_entries | map(select(.value.claimedBy == $id and .value.status == "in_progress")) | map(.key)) as $released |
        reduce $released[] as $tid (.; .tasks[$tid].status = "available" | .tasks[$tid].claimedBy = null) |
        .lastUpdate = $ts
    ')

    echo "$state" > "$STATE_FILE"
    release_lock
    echo '{"success": true, "agentId": "'"$agent_id"'"}'
}

# Main command handler
case "$1" in
    init)
        init_state
        echo '{"success": true}'
        ;;
    register)
        register_agent "$2" "$3"
        ;;
    claim)
        claim_task "$2" "$3"
        ;;
    complete)
        complete_task "$2" "$3"
        ;;
    available)
        get_available_tasks "$2"
        ;;
    status)
        get_status
        ;;
    heartbeat)
        heartbeat "$2"
        ;;
    deregister)
        deregister_agent "$2"
        ;;
    *)
        echo '{"error": true, "message": "Unknown command. Use: init|register|claim|complete|available|status|heartbeat|deregister"}'
        exit 1
        ;;
esac
