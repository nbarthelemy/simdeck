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
    local context_mode="${8:-fresh}"  # fresh (default) or same
    local commit_mode="${9:-none}"    # none, task, or phase

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
  "contextMode": "$context_mode",
  "commitMode": "$commit_mode",
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
  "subagentResults": [],
  "commits": [],
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

# Record subagent result (for fresh context mode)
record_subagent_result() {
    local iteration="$1"
    local task_id="$2"
    local status="$3"
    local summary="$4"
    local files_modified="$5"
    local duration="$6"

    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi

    local now=$(timestamp)

    # Parse files_modified as JSON array or create one
    local files_json="[]"
    if [ -n "$files_modified" ]; then
        files_json=$(echo "$files_modified" | tr ',' '\n' | jq -R . | jq -s .)
    fi

    jq ".subagentResults += [{
        \"iteration\": $iteration,
        \"taskId\": $(echo "$task_id" | jq -Rs .),
        \"status\": \"$status\",
        \"summary\": $(echo "$summary" | jq -Rs .),
        \"filesModified\": $files_json,
        \"duration\": \"$duration\",
        \"timestamp\": \"$now\"
    }]" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
}

# Get context mode
get_context_mode() {
    if [ -f "$STATE_FILE" ]; then
        jq -r '.contextMode // "fresh"' "$STATE_FILE"
    else
        echo "fresh"
    fi
}

# Estimate context tokens used
# Heuristic based on iterations, files modified, and errors
estimate_context_tokens() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "0"
        return
    fi

    # Base context (rules, skills, project context)
    local base_tokens=5000

    # Per-iteration accumulation (rough estimate)
    local iterations=$(jq -r '.iterations.current // 0' "$STATE_FILE")
    local tokens_per_iteration=2500

    # Files modified accumulation
    local subagent_count=$(jq -r '.subagentResults | length // 0' "$STATE_FILE")
    local tokens_per_subagent=1000

    # Errors add context
    local error_count=$(jq -r '.errors | length // 0' "$STATE_FILE")
    local tokens_per_error=500

    local total=$((base_tokens + (iterations * tokens_per_iteration) + (subagent_count * tokens_per_subagent) + (error_count * tokens_per_error)))

    echo "$total"
}

# Get context budget status
get_context_budget() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"estimatedTokens": 0, "maxTokens": 200000, "percentage": 0, "status": "none"}'
        return
    fi

    local estimated=$(estimate_context_tokens)
    local max_tokens=200000
    local threshold=80  # 80% is quality degradation threshold

    local percentage=$((estimated * 100 / max_tokens))

    local status="healthy"
    if [ "$percentage" -ge 90 ]; then
        status="critical"
    elif [ "$percentage" -ge "$threshold" ]; then
        status="warning"
    fi

    cat << JSONEOF
{
  "estimatedTokens": $estimated,
  "maxTokens": $max_tokens,
  "percentage": $percentage,
  "threshold": $threshold,
  "status": "$status"
}
JSONEOF
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
    local validate_after_task="${3:-false}"

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
  "validateAfterTask": $validate_after_task,
  "currentPhase": 1,
  "currentPhaseStartedAt": "$now",
  "currentTask": null,
  "totalPhases": $phase_count,
  "totalTasks": $task_count,
  "tasksCompleted": [],
  "phasesCompleted": [],
  "validationResults": {},
  "validationFailures": 0
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

    # Check if task validation is enabled
    local validate_tasks=$(jq -r '.validateAfterTask // false' "$PLAN_STATE_FILE")
    if [ "$validate_tasks" = "true" ]; then
        echo "TASK_VALIDATION_STARTED"

        # Run task-level validation with auto-fix
        local validation_script="$REPO_ROOT/.claude/scripts/incremental-validate.sh"
        if [ -f "$validation_script" ]; then
            local validation_result
            if validation_result=$(bash "$validation_script" task --fix 2>&1); then
                echo "TASK_VALIDATION_PASSED"
            else
                echo "TASK_VALIDATION_FAILED"
                echo "$validation_result"
                # Increment failure counter
                jq '.validationFailures += 1' "$PLAN_STATE_FILE" > "$PLAN_STATE_FILE.tmp"
                mv "$PLAN_STATE_FILE.tmp" "$PLAN_STATE_FILE"
                return 1
            fi
        fi
    fi

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

    # Check if phase validation is enabled
    local validate_phases=$(jq -r '.validateAfterPhase // false' "$PLAN_STATE_FILE")
    if [ "$validate_phases" = "true" ]; then
        echo "PHASE_VALIDATION_STARTED"

        # Run phase-level validation (types + tests)
        local validation_script="$REPO_ROOT/.claude/scripts/incremental-validate.sh"
        if [ -f "$validation_script" ]; then
            local validation_result
            if validation_result=$(bash "$validation_script" phase 2>&1); then
                echo "PHASE_VALIDATION_PASSED"
                # Record success
                record_phase_validation "$phase_name" "true" "$validation_result"
            else
                echo "PHASE_VALIDATION_FAILED"
                echo "$validation_result"
                # Record failure
                record_phase_validation "$phase_name" "false" "$validation_result"
                # Increment failure counter
                jq '.validationFailures += 1' "$PLAN_STATE_FILE" > "$PLAN_STATE_FILE.tmp"
                mv "$PLAN_STATE_FILE.tmp" "$PLAN_STATE_FILE"
                return 1
            fi
        fi
    fi

    # Update phase start time for next phase
    jq ".phasesCompleted += [\"$phase_name\"] | .currentPhase = $((current + 1)) | .currentPhaseStartedAt = \"$now\" | .lastUpdated = \"$now\"" "$PLAN_STATE_FILE" > "$PLAN_STATE_FILE.tmp"
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

# Parse structured task format
# Input: Task block from plan file (multiline string)
# Output: JSON with extracted fields
parse_structured_task() {
    local task_block="$1"

    # Extract task ID and description from first line
    # Format: - [ ] **Task 1.1**: Brief description
    local first_line=$(echo "$task_block" | head -1)
    local task_id=$(echo "$first_line" | grep -oE "Task [0-9]+\.[0-9]+" | head -1)
    local description=$(echo "$first_line" | sed 's/.*\*\*Task [0-9.]*\*\*: *//' | sed 's/ *$//')

    # Extract fields (handle both single and multi-file formats)
    local files=$(echo "$task_block" | grep -E "^\s*- files?:" | sed 's/.*files\?: *//' | sed 's/`//g' | tr -d '\n')
    local action=$(echo "$task_block" | grep -E "^\s*- action:" | sed 's/.*action: *//')
    local verify=$(echo "$task_block" | grep -E "^\s*- verify:" | sed 's/.*verify: *//' | sed 's/`//g')
    local done_criteria=$(echo "$task_block" | grep -E "^\s*- done:" | sed 's/.*done: *//')
    local references=$(echo "$task_block" | grep -E "^\s*- references?:" | sed 's/.*references\?: *//' | sed 's/`//g')
    local depends=$(echo "$task_block" | grep -E "^\s*- depends?:" | sed 's/.*depends\?: *//')

    # Output as JSON
    cat << JSONEOF
{
  "taskId": "$task_id",
  "description": $(echo "$description" | jq -Rs .),
  "files": $(echo "$files" | jq -Rs .),
  "action": $(echo "$action" | jq -Rs .),
  "verify": $(echo "$verify" | jq -Rs .),
  "done": $(echo "$done_criteria" | jq -Rs .),
  "references": $(echo "$references" | jq -Rs .),
  "depends": $(echo "$depends" | jq -Rs .)
}
JSONEOF
}

# Get next task with structured fields
get_next_structured_task() {
    if [ ! -f "$PLAN_STATE_FILE" ]; then
        echo "{}"
        return 1
    fi

    local plan_file=$(jq -r '.planFile' "$PLAN_STATE_FILE")

    if [ ! -f "$plan_file" ]; then
        echo "{}"
        return 1
    fi

    # Find first unchecked task and extract its block
    local task_line_num=$(grep -n "\- \[ \] \*\*Task" "$plan_file" | head -1 | cut -d: -f1)

    if [ -z "$task_line_num" ]; then
        echo "{}"
        return 0
    fi

    # Extract task block (from task line until next task or section)
    local task_block=$(sed -n "${task_line_num},/^- \[.\] \*\*Task\|^###/p" "$plan_file" | head -n -1)

    # If task_block is empty (last task), get to end of Tasks section
    if [ -z "$task_block" ] || [ "$(echo "$task_block" | wc -l)" -eq 1 ]; then
        task_block=$(sed -n "${task_line_num},/^##/p" "$plan_file" | head -n -1)
    fi

    parse_structured_task "$task_block"
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
    record_subagent)
        shift
        record_subagent_result "$@"
        ;;
    context_mode)
        get_context_mode
        ;;
    context_budget)
        get_context_budget
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
    parse_task)
        shift
        parse_structured_task "$@"
        ;;
    next_structured_task)
        get_next_structured_task
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
        echo "  parse_task, next_structured_task"
        exit 1
        ;;
esac
