#!/bin/bash
# Loop Manager - State management for autonomous loops
# Usage: loop-manager.sh <action> [args]

set -e

# Always resolve paths relative to repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

LOOP_DIR="$REPO_ROOT/.claude/loop"
STATE_FILE="$LOOP_DIR/state.json"
HISTORY_DIR="$LOOP_DIR/history"
CHECKPOINTS_DIR="$LOOP_DIR/checkpoints"
LOGS_DIR="$LOOP_DIR/logs"

# Ensure directories exist
init_dirs() {
    mkdir -p "$LOOP_DIR" "$HISTORY_DIR" "$CHECKPOINTS_DIR" "$LOGS_DIR"
}

# Generate loop ID
generate_id() {
    echo "loop_$(date +%Y%m%d_%H%M%S)"
}

# Get current timestamp
timestamp() {
    date -Iseconds
}

# Check if loop is active
is_active() {
    if [ -f "$STATE_FILE" ]; then
        status=$(jq -r '.status' "$STATE_FILE" 2>/dev/null || echo "none")
        if [ "$status" = "running" ] || [ "$status" = "paused" ]; then
            return 0
        fi
    fi
    return 1
}

# Get current status
get_status() {
    if [ -f "$STATE_FILE" ]; then
        jq -r '.status' "$STATE_FILE" 2>/dev/null || echo "none"
    else
        echo "none"
    fi
}

# Initialize new loop
init_loop() {
    local prompt="$1"
    local completion_type="$2"
    local completion_condition="$3"
    local max_iterations="${4:-20}"
    local max_time="${5:-2h}"
    local mode="${6:-standard}"
    local verify_cmd="${7:-}"

    init_dirs

    if is_active; then
        echo "ERROR: Loop already active" >&2
        return 1
    fi

    local loop_id=$(generate_id)
    local now=$(timestamp)

    cat > "$STATE_FILE" << EOF
{
  "id": "$loop_id",
  "status": "running",
  "prompt": $(echo "$prompt" | jq -Rs .),
  "mode": "$mode",
  "started_at": "$now",
  "iterations": {
    "current": 0,
    "max": $max_iterations
  },
  "completion": {
    "type": "$completion_type",
    "condition": $(echo "$completion_condition" | jq -Rs .),
    "verify_command": $(echo "$verify_cmd" | jq -Rs .),
    "met": false
  },
  "limits": {
    "max_time": "$max_time",
    "max_cost": null,
    "checkpoint_interval": 5
  },
  "checkpoints": [],
  "metrics": {
    "estimated_tokens": 0,
    "estimated_cost": "\$0.00",
    "elapsed_time": "0s",
    "start_time": $(date +%s)
  },
  "errors": []
}
EOF

    echo "$loop_id"
}

# Increment iteration
next_iteration() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active loop" >&2
        return 1
    fi

    local current=$(jq -r '.iterations.current' "$STATE_FILE")
    local next=$((current + 1))
    local start_time=$(jq -r '.metrics.start_time' "$STATE_FILE")
    local now=$(date +%s)
    local elapsed=$((now - start_time))
    local elapsed_human=$(printf '%dh %dm %ds' $((elapsed/3600)) $((elapsed%3600/60)) $((elapsed%60)))

    jq ".iterations.current = $next | .metrics.elapsed_time = \"$elapsed_human\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "$next"
}

# Create checkpoint
checkpoint() {
    local summary="$1"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active loop" >&2
        return 1
    fi

    local iteration=$(jq -r '.iterations.current' "$STATE_FILE")
    local now=$(timestamp)
    local checkpoint_file="$CHECKPOINTS_DIR/checkpoint_${iteration}.json"

    # Get recently modified files
    local files=$(git diff --name-only HEAD~1 2>/dev/null | head -10 | jq -R . | jq -s .)

    cat > "$checkpoint_file" << EOF
{
  "iteration": $iteration,
  "timestamp": "$now",
  "summary": $(echo "$summary" | jq -Rs .),
  "files_modified": $files
}
EOF

    # Add to state
    jq ".checkpoints += [{\"iteration\": $iteration, \"timestamp\": \"$now\", \"summary\": $(echo "$summary" | jq -Rs .)}]" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "$checkpoint_file"
}

# Mark complete
complete_loop() {
    local reason="${1:-condition_met}"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active loop" >&2
        return 1
    fi

    local now=$(timestamp)
    local loop_id=$(jq -r '.id' "$STATE_FILE")

    jq ".status = \"complete\" | .completed_at = \"$now\" | .completion.met = true | .completion_reason = \"$reason\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    # Archive
    mv "$STATE_FILE" "$HISTORY_DIR/${loop_id}.json"

    echo "complete"
}

# Pause loop
pause_loop() {
    local reason="${1:-user_requested}"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active loop" >&2
        return 1
    fi

    local status=$(get_status)
    if [ "$status" != "running" ]; then
        echo "ERROR: Loop not running (status: $status)" >&2
        return 1
    fi

    local now=$(timestamp)
    jq ".status = \"paused\" | .paused_at = \"$now\" | .pause_reason = \"$reason\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "paused"
}

# Resume loop
resume_loop() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active loop" >&2
        return 1
    fi

    local status=$(get_status)
    if [ "$status" != "paused" ]; then
        echo "ERROR: Loop not paused (status: $status)" >&2
        return 1
    fi

    local now=$(timestamp)
    local paused_at=$(jq -r '.paused_at' "$STATE_FILE")

    jq ".status = \"running\" | .resumed_at = \"$now\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "resumed"
}

# Cancel loop
cancel_loop() {
    local reason="${1:-user_requested}"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active loop" >&2
        return 1
    fi

    local now=$(timestamp)
    local loop_id=$(jq -r '.id' "$STATE_FILE")

    jq ".status = \"cancelled\" | .cancelled_at = \"$now\" | .cancel_reason = \"$reason\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    # Archive
    mv "$STATE_FILE" "$HISTORY_DIR/${loop_id}.json"

    # Clean up checkpoints
    rm -rf "$CHECKPOINTS_DIR"/*

    echo "cancelled"
}

# Log error
log_error() {
    local error="$1"

    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi

    local now=$(timestamp)
    jq ".errors += [{\"timestamp\": \"$now\", \"error\": $(echo "$error" | jq -Rs .)}]" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
}

# Check limits
check_limits() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "no_loop"
        return
    fi

    local current=$(jq -r '.iterations.current' "$STATE_FILE")
    local max=$(jq -r '.iterations.max' "$STATE_FILE")

    if [ "$current" -ge "$max" ]; then
        echo "max_iterations"
        return
    fi

    # Check time limit
    local start_time=$(jq -r '.metrics.start_time' "$STATE_FILE")
    local max_time=$(jq -r '.limits.max_time' "$STATE_FILE")
    local now=$(date +%s)
    local elapsed=$((now - start_time))

    # Parse max_time (e.g., "2h" -> 7200)
    local max_seconds=7200
    if [[ "$max_time" =~ ([0-9]+)h ]]; then
        max_seconds=$((${BASH_REMATCH[1]} * 3600))
    elif [[ "$max_time" =~ ([0-9]+)m ]]; then
        max_seconds=$((${BASH_REMATCH[1]} * 60))
    fi

    if [ "$elapsed" -ge "$max_seconds" ]; then
        echo "time_limit"
        return
    fi

    echo "ok"
}

# Get state as JSON
get_state() {
    if [ -f "$STATE_FILE" ]; then
        cat "$STATE_FILE"
    else
        echo "{}"
    fi
}

# List history
list_history() {
    init_dirs

    if [ -z "$(ls -A "$HISTORY_DIR" 2>/dev/null)" ]; then
        echo "[]"
        return
    fi

    local result="["
    local first=true

    for f in "$HISTORY_DIR"/*.json; do
        if [ "$first" = true ]; then
            first=false
        else
            result="$result,"
        fi
        result="$result$(cat "$f")"
    done

    result="$result]"
    echo "$result"
}

# ============================================
# Plan Mode Functions
# ============================================

PLAN_STATE_FILE="$LOOP_DIR/plan-state.json"

# Initialize plan execution
init_plan() {
    local plan_file="$1"
    local validate_after_phase="${2:-false}"

    init_dirs

    if [ ! -f "$plan_file" ]; then
        echo "ERROR: Plan file not found: $plan_file" >&2
        return 1
    fi

    local now=$(timestamp)

    # Extract phases from plan file (lines starting with "### Phase")
    local phases=$(grep -n "^### Phase" "$plan_file" | head -20)
    local phase_count=$(echo "$phases" | grep -c "Phase" || echo "0")

    # Count tasks (lines with "- [ ] **Task")
    local task_count=$(grep -c "\- \[ \] \*\*Task" "$plan_file" || echo "0")

    cat > "$PLAN_STATE_FILE" << EOF
{
  "planFile": "$plan_file",
  "status": "running",
  "startedAt": "$now",
  "validateAfterPhase": $validate_after_phase,
  "currentPhase": 1,
  "currentTask": null,
  "totalPhases": $phase_count,
  "totalTasks": $task_count,
  "tasksCompleted": [],
  "phasesCompleted": [],
  "validationResults": {}
}
EOF

    echo "$PLAN_STATE_FILE"
}

# Get next uncompleted task from plan
get_next_plan_task() {
    if [ ! -f "$PLAN_STATE_FILE" ]; then
        echo "ERROR: No plan state" >&2
        return 1
    fi

    local plan_file=$(jq -r '.planFile' "$PLAN_STATE_FILE")
    local completed=$(jq -r '.tasksCompleted | join("|")' "$PLAN_STATE_FILE")

    # Find first unchecked task
    local task_line=$(grep -n "\- \[ \] \*\*Task" "$plan_file" | head -1)

    if [ -z "$task_line" ]; then
        echo "PLAN_COMPLETE"
        return 0
    fi

    # Extract task ID and description
    local line_num=$(echo "$task_line" | cut -d: -f1)
    local task_text=$(echo "$task_line" | cut -d: -f2-)

    # Parse task ID (e.g., "Task 1.1" -> "1.1")
    local task_id=$(echo "$task_text" | grep -o "Task [0-9.]*" | sed 's/Task //')

    echo "{\"lineNumber\": $line_num, \"taskId\": \"$task_id\", \"text\": $(echo "$task_text" | jq -Rs .)}"
}

# Mark task complete in plan state and file
complete_plan_task() {
    local task_id="$1"

    if [ ! -f "$PLAN_STATE_FILE" ]; then
        echo "ERROR: No plan state" >&2
        return 1
    fi

    local plan_file=$(jq -r '.planFile' "$PLAN_STATE_FILE")
    local now=$(timestamp)

    # Add to completed list
    jq ".tasksCompleted += [\"$task_id\"] | .currentTask = \"$task_id\" | .lastUpdated = \"$now\"" "$PLAN_STATE_FILE" > "$PLAN_STATE_FILE.tmp"
    mv "$PLAN_STATE_FILE.tmp" "$PLAN_STATE_FILE"

    # Update plan file: change [ ] to [x] for this task
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s/\- \[ \] \*\*Task $task_id\*\*/- [x] **Task $task_id**/" "$plan_file"
    else
        sed -i "s/\- \[ \] \*\*Task $task_id\*\*/- [x] **Task $task_id**/" "$plan_file"
    fi

    echo "TASK_COMPLETE: $task_id"
}

# Mark phase complete
complete_plan_phase() {
    local phase_name="$1"

    if [ ! -f "$PLAN_STATE_FILE" ]; then
        echo "ERROR: No plan state" >&2
        return 1
    fi

    local now=$(timestamp)
    local current=$(jq -r '.currentPhase' "$PLAN_STATE_FILE")

    jq ".phasesCompleted += [\"$phase_name\"] | .currentPhase = $((current + 1)) | .lastUpdated = \"$now\"" "$PLAN_STATE_FILE" > "$PLAN_STATE_FILE.tmp"
    mv "$PLAN_STATE_FILE.tmp" "$PLAN_STATE_FILE"

    echo "PHASE_COMPLETE: $phase_name"
}

# Record phase validation result
record_phase_validation() {
    local phase_name="$1"
    local passed="$2"
    local output="$3"

    if [ ! -f "$PLAN_STATE_FILE" ]; then
        return 1
    fi

    jq ".validationResults[\"$phase_name\"] = {\"passed\": $passed, \"output\": $(echo "$output" | jq -Rs .)}" "$PLAN_STATE_FILE" > "$PLAN_STATE_FILE.tmp"
    mv "$PLAN_STATE_FILE.tmp" "$PLAN_STATE_FILE"
}

# Check if plan is complete
is_plan_complete() {
    if [ ! -f "$PLAN_STATE_FILE" ]; then
        echo "false"
        return
    fi

    local plan_file=$(jq -r '.planFile' "$PLAN_STATE_FILE")

    # Check if any unchecked tasks remain
    local remaining=$(grep -c "\- \[ \] \*\*Task" "$plan_file" || echo "0")

    if [ "$remaining" -eq 0 ]; then
        echo "true"
    else
        echo "false"
    fi
}

# Complete plan execution
complete_plan() {
    local reason="${1:-all_tasks_done}"

    if [ ! -f "$PLAN_STATE_FILE" ]; then
        echo "ERROR: No plan state" >&2
        return 1
    fi

    local plan_file=$(jq -r '.planFile' "$PLAN_STATE_FILE")
    local now=$(timestamp)

    # Update plan state
    jq ".status = \"complete\" | .completedAt = \"$now\" | .completionReason = \"$reason\"" "$PLAN_STATE_FILE" > "$PLAN_STATE_FILE.tmp"
    mv "$PLAN_STATE_FILE.tmp" "$PLAN_STATE_FILE"

    # Update plan file status
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/> Status: .*/> Status: completed/' "$plan_file"
    else
        sed -i 's/> Status: .*/> Status: completed/' "$plan_file"
    fi

    # Archive plan state
    local plan_id=$(basename "$plan_file" .md)
    mv "$PLAN_STATE_FILE" "$HISTORY_DIR/plan-${plan_id}-$(date +%Y%m%d_%H%M%S).json"

    echo "PLAN_COMPLETE"
}

# Get plan state
get_plan_state() {
    if [ -f "$PLAN_STATE_FILE" ]; then
        cat "$PLAN_STATE_FILE"
    else
        echo "{}"
    fi
}

# Main dispatcher
case "${1:-}" in
    init)
        shift
        init_loop "$@"
        ;;
    next)
        next_iteration
        ;;
    checkpoint)
        shift
        checkpoint "$@"
        ;;
    complete)
        shift
        complete_loop "$@"
        ;;
    pause)
        shift
        pause_loop "$@"
        ;;
    resume)
        resume_loop
        ;;
    cancel)
        shift
        cancel_loop "$@"
        ;;
    error)
        shift
        log_error "$@"
        ;;
    check)
        check_limits
        ;;
    status)
        get_status
        ;;
    state)
        get_state
        ;;
    history)
        list_history
        ;;
    active)
        is_active && echo "true" || echo "false"
        ;;
    # Plan mode actions
    init_plan)
        shift
        init_plan "$@"
        ;;
    next_task)
        get_next_plan_task
        ;;
    complete_task)
        shift
        complete_plan_task "$@"
        ;;
    complete_phase)
        shift
        complete_plan_phase "$@"
        ;;
    record_validation)
        shift
        record_phase_validation "$@"
        ;;
    plan_complete)
        is_plan_complete
        ;;
    finish_plan)
        shift
        complete_plan "$@"
        ;;
    plan_state)
        get_plan_state
        ;;
    *)
        echo "Usage: loop-manager.sh <action> [args]"
        echo ""
        echo "Loop Actions:"
        echo "  init, next, checkpoint, complete, pause, resume, cancel"
        echo "  error, check, status, state, history, active"
        echo ""
        echo "Plan Mode Actions:"
        echo "  init_plan, next_task, complete_task, complete_phase"
        echo "  record_validation, plan_complete, finish_plan, plan_state"
        exit 1
        ;;
esac
