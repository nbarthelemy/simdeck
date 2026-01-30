#!/bin/bash
# Autopilot Manager - State management for autonomous feature completion
# Usage: autopilot-manager.sh <action> [args]
#
# Enhanced with:
#   - Git feature isolation (branch per feature)
#   - Dependency graph support (smart execution order)
#   - Incremental validation hooks

set -e

# Always resolve paths relative to repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

LOOP_DIR="$REPO_ROOT/.claude/loop"
STATE_FILE="$LOOP_DIR/autopilot-state.json"
HISTORY_DIR="$LOOP_DIR/history"
TODO_FILE="$REPO_ROOT/.claude/TODO.md"

# Integration scripts
SCRIPTS_DIR="$REPO_ROOT/.claude/scripts"
GIT_ISOLATION="$SCRIPTS_DIR/git-isolation-manager.sh"
DEP_GRAPH="$SCRIPTS_DIR/dependency-graph.sh"
VALIDATE="$SCRIPTS_DIR/incremental-validate.sh"

# Ensure directories exist
init_dirs() {
    mkdir -p "$LOOP_DIR" "$HISTORY_DIR"
}

# Generate autopilot ID
generate_id() {
    echo "autopilot_$(date +%Y%m%d_%H%M%S)"
}

# Get current timestamp
timestamp() {
    date -Iseconds
}

# Check if autopilot is active
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

# Count features in TODO.md
# Returns: "available:in_progress:completed" colon-separated format
count_features() {
    if [ ! -f "$TODO_FILE" ]; then
        echo "0:0:0"
        return
    fi

    # Count unchecked items (- [ ])
    local available=$(grep -c "^- \[ \]" "$TODO_FILE" 2>/dev/null | tr -d '\n' || echo "0")
    [ -z "$available" ] && available=0
    # Count in-progress items (- [~])
    local in_progress=$(grep -c "^- \[~\]" "$TODO_FILE" 2>/dev/null | tr -d '\n' || echo "0")
    [ -z "$in_progress" ] && in_progress=0
    # Count completed items (- [x])
    local completed=$(grep -c "^- \[x\]" "$TODO_FILE" 2>/dev/null | tr -d '\n' || echo "0")
    [ -z "$completed" ] && completed=0

    echo "$available:$in_progress:$completed"
}

# Get next uncompleted feature from TODO.md
# Uses dependency graph if available to respect dependencies
get_next_feature() {
    if [ ! -f "$TODO_FILE" ]; then
        echo "TODO_MISSING"
        return 1
    fi

    # Try dependency graph first
    if [ -f "$DEP_GRAPH" ]; then
        local next_result=$(bash "$DEP_GRAPH" next 2>/dev/null)

        # Check special statuses
        if [ "$next_result" = "ALL_COMPLETE" ]; then
            echo "ALL_COMPLETE"
            return 0
        elif [ "$next_result" = "BLOCKED" ]; then
            echo "BLOCKED_BY_DEPS"
            return 0
        elif echo "$next_result" | jq -e '.name' &>/dev/null; then
            # Got a valid feature from dependency graph
            local name=$(echo "$next_result" | jq -r '.name')
            local line=$(echo "$next_result" | jq -r '.lineNumber')
            echo "{\"lineNumber\": $line, \"feature\": $(echo "$name" | jq -Rs .), \"fromDepGraph\": true}"
            return 0
        fi
    fi

    # Fallback: simple linear search for first unchecked item
    local feature_line=$(grep -n "^- \[ \]" "$TODO_FILE" | head -1)

    if [ -z "$feature_line" ]; then
        echo "ALL_COMPLETE"
        return 0
    fi

    # Extract line number and content
    local line_num=$(echo "$feature_line" | cut -d: -f1)
    local feature_text=$(echo "$feature_line" | cut -d: -f2- | sed 's/^- \[ \] //')

    # Try to extract feature name from **Name** pattern
    local feature_name=$(echo "$feature_text" | grep -o '\*\*[^*]*\*\*' | head -1 | sed 's/\*\*//g')
    if [ -z "$feature_name" ]; then
        feature_name="$feature_text"
    fi

    echo "{\"lineNumber\": $line_num, \"feature\": $(echo "$feature_name" | jq -Rs .), \"fullText\": $(echo "$feature_text" | jq -Rs .), \"fromDepGraph\": false}"
}

# Initialize autopilot session
init_autopilot() {
    local max_features="${1:-null}"
    local max_time="${2:-4h}"
    local max_cost="${3:-\$50}"
    local pause_on_failure="${4:-false}"
    local skip_validation="${5:-false}"
    local isolate="${6:-true}"
    local merge_on_success="${7:-false}"
    local validate_after_task="${8:-false}"
    local validate_after_phase="${9:-false}"

    # Note: init_dirs is called AFTER git preflight to avoid stashing untracked .claude/loop/

    if is_active; then
        echo '{"error": true, "message": "Autopilot already active. Use cancel first."}'
        return 1
    fi

    if [ ! -f "$TODO_FILE" ]; then
        echo '{"error": true, "message": "TODO.md not found. Run /spec first."}'
        return 1
    fi

    local autopilot_id=$(generate_id)
    local now=$(timestamp)
    local counts=$(count_features)
    local available=$(echo "$counts" | cut -d: -f1 | tr -d '\n')
    local in_progress=$(echo "$counts" | cut -d: -f2 | tr -d '\n')
    local completed=$(echo "$counts" | cut -d: -f3 | tr -d '\n')
    # Ensure numeric values with defaults
    available=${available:-0}
    in_progress=${in_progress:-0}
    completed=${completed:-0}
    local total=$((available + in_progress + completed))

    # Git isolation preflight check (may stash untracked files including .claude/loop/)
    local git_isolation_result='{}'
    if [ "$isolate" = "true" ] && [ -f "$GIT_ISOLATION" ]; then
        git_isolation_result=$(bash "$GIT_ISOLATION" preflight --stash-uncommitted 2>&1) || {
            echo "{\"error\": true, \"message\": \"Git isolation preflight failed\", \"details\": $(echo "$git_isolation_result" | jq -Rs .)}"
            return 1
        }
    fi

    # Create directories AFTER git stash (stash may remove untracked .claude/loop/)
    init_dirs

    # Build dependency graph if script exists
    local dep_graph_result='{}'
    if [ -f "$DEP_GRAPH" ]; then
        dep_graph_result=$(bash "$DEP_GRAPH" build 2>&1) || true
    fi

    cat > "$STATE_FILE" << JSONEOF
{
  "id": "$autopilot_id",
  "status": "running",
  "startedAt": "$now",
  "features": {
    "total": $total,
    "completed": $completed,
    "failed": 0,
    "skipped": 0,
    "blocked": 0,
    "remaining": $available
  },
  "limits": {
    "maxFeatures": $max_features,
    "maxTime": "$max_time",
    "maxCost": "$max_cost"
  },
  "options": {
    "pauseOnFailure": $pause_on_failure,
    "skipValidation": $skip_validation,
    "isolate": $isolate,
    "mergeOnSuccess": $merge_on_success,
    "validateAfterTask": $validate_after_task,
    "validateAfterPhase": $validate_after_phase
  },
  "gitIsolation": $git_isolation_result,
  "currentFeature": null,
  "currentBranch": null,
  "history": [],
  "metrics": {
    "elapsedTime": "0s",
    "estimatedCost": "\$0.00",
    "tasksCompleted": 0,
    "filesModified": 0,
    "validationFailures": 0,
    "startTime": $(date +%s)
  }
}
JSONEOF

    echo "{\"id\": \"$autopilot_id\", \"totalFeatures\": $total, \"available\": $available, \"isolate\": $isolate}"
}

# Start working on a feature
start_feature() {
    local feature_name="$1"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active autopilot" >&2
        return 1
    fi

    local now=$(timestamp)
    local isolate=$(jq -r '.options.isolate // false' "$STATE_FILE")
    local branch_name=""

    # Create feature branch if isolation is enabled
    if [ "$isolate" = "true" ] && [ -f "$GIT_ISOLATION" ]; then
        local branch_result=$(bash "$GIT_ISOLATION" create "$feature_name" 2>&1)
        if echo "$branch_result" | jq -e '.error' &>/dev/null; then
            echo "WARNING: Failed to create feature branch: $branch_result" >&2
        else
            branch_name=$(echo "$branch_result" | jq -r '.featureBranch // empty')
        fi
    fi

    # Update dependency graph status if available
    if [ -f "$DEP_GRAPH" ]; then
        bash "$DEP_GRAPH" update "$feature_name" "in_progress" 2>/dev/null || true
    fi

    jq ".currentFeature = $(echo "$feature_name" | jq -Rs .) | .currentFeatureStarted = \"$now\" | .currentBranch = $(echo "$branch_name" | jq -Rs .)" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    if [ -n "$branch_name" ]; then
        echo "AUTOPILOT_FEATURE_START: $feature_name (branch: $branch_name)"
    else
        echo "AUTOPILOT_FEATURE_START: $feature_name"
    fi
}

# Record feature completion
record_complete() {
    local feature_name="$1"
    local tasks_done="${2:-0}"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active autopilot" >&2
        return 1
    fi

    local now=$(timestamp)
    local started=$(jq -r '.currentFeatureStarted' "$STATE_FILE")
    local current_branch=$(jq -r '.currentBranch // empty' "$STATE_FILE")
    local isolate=$(jq -r '.options.isolate // false' "$STATE_FILE")
    local merge_on_success=$(jq -r '.options.mergeOnSuccess // false' "$STATE_FILE")
    local base_branch=$(jq -r '.gitIsolation.baselineBranch // "main"' "$STATE_FILE")

    # Calculate duration
    local start_ts=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${started%+*}" "+%s" 2>/dev/null || date -d "$started" "+%s" 2>/dev/null || echo "0")
    local end_ts=$(date +%s)
    local duration_sec=$((end_ts - start_ts))
    local duration="${duration_sec}s"
    if [ $duration_sec -ge 60 ]; then
        duration="$((duration_sec / 60))m"
    fi

    # Handle branch completion if isolation is enabled
    local branch_action="none"
    if [ "$isolate" = "true" ] && [ -n "$current_branch" ] && [ -f "$GIT_ISOLATION" ]; then
        if [ "$merge_on_success" = "true" ]; then
            local complete_result=$(bash "$GIT_ISOLATION" complete "$current_branch" "$base_branch" --merge 2>&1)
            branch_action="merged"
        else
            local complete_result=$(bash "$GIT_ISOLATION" complete "$current_branch" "$base_branch" --keep 2>&1)
            branch_action="kept"
        fi
    fi

    # Update dependency graph status
    if [ -f "$DEP_GRAPH" ]; then
        bash "$DEP_GRAPH" update "$feature_name" "completed" 2>/dev/null || true
    fi

    # Update state
    jq ".features.completed += 1 | .features.remaining -= 1 | .currentFeature = null | .currentBranch = null | .metrics.tasksCompleted += $tasks_done | .history += [{\"feature\": $(echo "$feature_name" | jq -Rs .), \"status\": \"complete\", \"duration\": \"$duration\", \"branch\": $(echo "$current_branch" | jq -Rs .), \"branchAction\": \"$branch_action\", \"completedAt\": \"$now\"}]" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    if [ -n "$current_branch" ]; then
        echo "AUTOPILOT_FEATURE_COMPLETE: $feature_name (branch $branch_action)"
    else
        echo "AUTOPILOT_FEATURE_COMPLETE: $feature_name"
    fi
}

# Record feature failure
record_failed() {
    local feature_name="$1"
    local error_msg="$2"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active autopilot" >&2
        return 1
    fi

    local now=$(timestamp)
    local current_branch=$(jq -r '.currentBranch // empty' "$STATE_FILE")
    local isolate=$(jq -r '.options.isolate // false' "$STATE_FILE")
    local base_branch=$(jq -r '.gitIsolation.baselineBranch // "main"' "$STATE_FILE")

    # Rollback branch if isolation is enabled
    local rollback_result=""
    local failure_diff=""
    if [ "$isolate" = "true" ] && [ -n "$current_branch" ] && [ -f "$GIT_ISOLATION" ]; then
        # Save state before rollback (git clean removes untracked files)
        local saved_state=$(cat "$STATE_FILE")
        rollback_result=$(bash "$GIT_ISOLATION" rollback "$current_branch" "$base_branch" 2>&1)
        failure_diff=$(echo "$rollback_result" | jq -r '.failureDiff // empty' 2>/dev/null)
        # Ensure directories exist after git clean
        init_dirs
        # Restore state file
        echo "$saved_state" > "$STATE_FILE"
    fi

    # Update dependency graph status
    if [ -f "$DEP_GRAPH" ]; then
        bash "$DEP_GRAPH" update "$feature_name" "failed" 2>/dev/null || true
    fi

    # Check which features are now blocked due to this failure
    local blocked_features='[]'
    if [ -f "$DEP_GRAPH" ]; then
        # Get features that depend on this one
        local graph=$(bash "$DEP_GRAPH" build 2>/dev/null)
        blocked_features=$(echo "$graph" | jq --arg name "$feature_name" '[.features[] | select(.dependencies[] == $name) | .name]' 2>/dev/null || echo '[]')
    fi

    jq ".features.failed += 1 | .features.remaining -= 1 | .currentFeature = null | .currentBranch = null | .history += [{\"feature\": $(echo "$feature_name" | jq -Rs .), \"status\": \"failed\", \"error\": $(echo "$error_msg" | jq -Rs .), \"branch\": $(echo "$current_branch" | jq -Rs .), \"failureDiff\": $(echo "$failure_diff" | jq -Rs .), \"blockedFeatures\": $blocked_features, \"failedAt\": \"$now\"}]" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    if [ -n "$current_branch" ]; then
        echo "AUTOPILOT_FEATURE_FAILED: $feature_name (branch rolled back, diff saved)"
    else
        echo "AUTOPILOT_FEATURE_FAILED: $feature_name"
    fi

    # Report blocked features
    local blocked_count=$(echo "$blocked_features" | jq 'length')
    if [ "$blocked_count" -gt 0 ]; then
        echo "AUTOPILOT_FEATURES_BLOCKED: $blocked_count features blocked by this failure"
    fi
}

# Record feature skipped
record_skipped() {
    local feature_name="$1"
    local reason="$2"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active autopilot" >&2
        return 1
    fi

    local now=$(timestamp)

    jq ".features.skipped += 1 | .features.remaining -= 1 | .currentFeature = null | .history += [{\"feature\": $(echo "$feature_name" | jq -Rs .), \"status\": \"skipped\", \"reason\": $(echo "$reason" | jq -Rs .), \"skippedAt\": \"$now\"}]" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "AUTOPILOT_FEATURE_SKIPPED: $feature_name"
}

# Check if limits exceeded
check_limits() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "no_autopilot"
        return
    fi

    # Check max features
    local completed=$(jq -r '.features.completed' "$STATE_FILE")
    local max_features=$(jq -r '.limits.maxFeatures' "$STATE_FILE")

    if [ "$max_features" != "null" ] && [ "$completed" -ge "$max_features" ]; then
        echo "max_features"
        return
    fi

    # Check time limit
    local start_time=$(jq -r '.metrics.startTime' "$STATE_FILE")
    local max_time=$(jq -r '.limits.maxTime' "$STATE_FILE")
    local now=$(date +%s)
    local elapsed=$((now - start_time))

    # Parse max_time (e.g., "4h" -> 14400)
    local max_seconds=14400
    if [[ "$max_time" =~ ([0-9]+)h ]]; then
        max_seconds=$((${BASH_REMATCH[1]} * 3600))
    elif [[ "$max_time" =~ ([0-9]+)m ]]; then
        max_seconds=$((${BASH_REMATCH[1]} * 60))
    fi

    if [ "$elapsed" -ge "$max_seconds" ]; then
        echo "time_limit"
        return
    fi

    # Check remaining features
    local remaining=$(jq -r '.features.remaining' "$STATE_FILE")
    if [ "$remaining" -le 0 ]; then
        echo "all_complete"
        return
    fi

    echo "ok"
}

# Update elapsed time
update_metrics() {
    if [ ! -f "$STATE_FILE" ]; then
        return 1
    fi

    local start_time=$(jq -r '.metrics.startTime' "$STATE_FILE")
    local now=$(date +%s)
    local elapsed=$((now - start_time))
    local elapsed_human=$(printf '%dh %dm %ds' $((elapsed/3600)) $((elapsed%3600/60)) $((elapsed%60)))

    # Get files modified count
    local files_modified=$(git diff --name-only HEAD~1 2>/dev/null | wc -l | tr -d ' ')

    jq ".metrics.elapsedTime = \"$elapsed_human\" | .metrics.filesModified = $files_modified" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"
}

# Pause autopilot
pause_autopilot() {
    local reason="${1:-user_requested}"

    if [ ! -f "$STATE_FILE" ]; then
        echo '{"error": true, "message": "No active autopilot"}'
        return 1
    fi

    local status=$(get_status)
    if [ "$status" != "running" ]; then
        echo "{\"error\": true, \"message\": \"Autopilot not running (status: $status)\"}"
        return 1
    fi

    local now=$(timestamp)
    jq ".status = \"paused\" | .pausedAt = \"$now\" | .pauseReason = \"$reason\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo '{"status": "paused"}'
}

# Resume autopilot
resume_autopilot() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"error": true, "message": "No active autopilot"}'
        return 1
    fi

    local status=$(get_status)
    if [ "$status" != "paused" ]; then
        echo "{\"error\": true, \"message\": \"Autopilot not paused (status: $status)\"}"
        return 1
    fi

    local now=$(timestamp)
    jq ".status = \"running\" | .resumedAt = \"$now\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo '{"status": "resumed"}'
}

# Cancel autopilot
cancel_autopilot() {
    local reason="${1:-user_requested}"
    local restore="${2:-true}"

    if [ ! -f "$STATE_FILE" ]; then
        echo '{"error": true, "message": "No active autopilot"}'
        return 1
    fi

    local now=$(timestamp)
    local autopilot_id=$(jq -r '.id' "$STATE_FILE")
    local isolate=$(jq -r '.options.isolate // false' "$STATE_FILE")
    local current_branch=$(jq -r '.currentBranch // empty' "$STATE_FILE")
    local base_branch=$(jq -r '.gitIsolation.baselineBranch // "main"' "$STATE_FILE")

    update_metrics

    # If on a feature branch, rollback
    if [ "$isolate" = "true" ] && [ -n "$current_branch" ] && [ -f "$GIT_ISOLATION" ]; then
        bash "$GIT_ISOLATION" rollback "$current_branch" "$base_branch" 2>/dev/null || true
    fi

    # Restore baseline if requested
    local restored=false
    if [ "$restore" = "true" ] && [ "$isolate" = "true" ] && [ -f "$GIT_ISOLATION" ]; then
        local restore_result=$(bash "$GIT_ISOLATION" restore_baseline --apply-stash 2>&1)
        if echo "$restore_result" | jq -e '.success' &>/dev/null; then
            restored=true
        fi
    fi

    jq ".status = \"cancelled\" | .cancelledAt = \"$now\" | .cancelReason = \"$reason\" | .baselineRestored = $restored" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    # Archive
    mv "$STATE_FILE" "$HISTORY_DIR/${autopilot_id}.json"

    echo "{\"status\": \"cancelled\", \"baselineRestored\": $restored}"
}

# Complete autopilot session
complete_autopilot() {
    local reason="${1:-all_complete}"

    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No active autopilot" >&2
        return 1
    fi

    local now=$(timestamp)
    local autopilot_id=$(jq -r '.id' "$STATE_FILE")

    update_metrics

    jq ".status = \"complete\" | .completedAt = \"$now\" | .completionReason = \"$reason\"" "$STATE_FILE" > "$STATE_FILE.tmp"
    mv "$STATE_FILE.tmp" "$STATE_FILE"

    echo "AUTOPILOT_COMPLETE"
}

# Archive completed autopilot
archive_autopilot() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "ERROR: No state to archive" >&2
        return 1
    fi

    local autopilot_id=$(jq -r '.id' "$STATE_FILE")

    mv "$STATE_FILE" "$HISTORY_DIR/${autopilot_id}.json"

    echo "archived"
}

# Get full state as JSON
get_state() {
    if [ -f "$STATE_FILE" ]; then
        update_metrics 2>/dev/null
        cat "$STATE_FILE"
    else
        echo '{"error": true, "message": "No active autopilot"}'
    fi
}

# Get status info for display
status_info() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"active": false}'
        return
    fi

    update_metrics 2>/dev/null

    jq '{
        active: true,
        id: .id,
        status: .status,
        currentFeature: .currentFeature,
        completed: .features.completed,
        failed: .features.failed,
        remaining: .features.remaining,
        elapsedTime: .metrics.elapsedTime,
        limits: .limits
    }' "$STATE_FILE"
}

# Generate summary report
generate_report() {
    if [ ! -f "$STATE_FILE" ]; then
        local latest=$(ls -t "$HISTORY_DIR"/autopilot_*.json 2>/dev/null | head -1)
        if [ -z "$latest" ]; then
            echo '{"error": true, "message": "No autopilot history found"}'
            return 1
        fi
        cat "$latest"
    else
        update_metrics 2>/dev/null
        cat "$STATE_FILE"
    fi
}

# List history
list_history() {
    init_dirs

    if [ -z "$(ls -A "$HISTORY_DIR"/autopilot_*.json 2>/dev/null)" ]; then
        echo "[]"
        return
    fi

    local result="["
    local first=true

    for f in "$HISTORY_DIR"/autopilot_*.json; do
        if [ "$first" = true ]; then
            first=false
        else
            result="$result,"
        fi
        result="$result$(jq '{id: .id, status: .status, completedAt: .completedAt, features: .features}' "$f")"
    done

    result="$result]"
    echo "$result"
}

# ============================================
# Git Isolation & Dependency Graph Helpers
# ============================================

# Get all ready features (for parallel execution)
get_ready_features() {
    local max_count="${1:-5}"

    if [ ! -f "$DEP_GRAPH" ]; then
        # Fallback: just return first N unchecked features
        grep -n "^- \[ \]" "$TODO_FILE" 2>/dev/null | head -"$max_count" | while read -r line; do
            local line_num=$(echo "$line" | cut -d: -f1)
            local text=$(echo "$line" | cut -d: -f2- | sed 's/^- \[ \] //')
            echo "{\"lineNumber\": $line_num, \"feature\": $(echo "$text" | jq -Rs .)}"
        done
        return
    fi

    bash "$DEP_GRAPH" ready "$max_count"
}

# Visualize dependency graph
visualize_graph() {
    if [ -f "$DEP_GRAPH" ]; then
        bash "$DEP_GRAPH" visualize
    else
        echo "Dependency graph not available"
    fi
}

# Get dependency chain for a feature
get_dependency_chain() {
    local feature_name="$1"

    if [ -f "$DEP_GRAPH" ]; then
        bash "$DEP_GRAPH" chain "$feature_name"
    else
        echo '{"error": true, "message": "Dependency graph not available"}'
    fi
}

# Check if feature is blocked
is_feature_blocked() {
    local feature_name="$1"

    if [ -f "$DEP_GRAPH" ]; then
        bash "$DEP_GRAPH" blocked "$feature_name"
    else
        echo "false"
    fi
}

# Restore baseline (used on cancel)
restore_baseline() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"error": true, "message": "No active autopilot"}'
        return 1
    fi

    local isolate=$(jq -r '.options.isolate // false' "$STATE_FILE")

    if [ "$isolate" = "true" ] && [ -f "$GIT_ISOLATION" ]; then
        bash "$GIT_ISOLATION" restore_baseline --apply-stash
    else
        echo '{"restored": false, "reason": "Isolation not enabled"}'
    fi
}

# Run feature validation
run_feature_validation() {
    local feature_name="$1"

    if [ ! -f "$VALIDATE" ]; then
        echo '{"error": true, "message": "Validation script not found"}'
        return 1
    fi

    echo "VALIDATION_STARTED: $feature_name"
    local result=$(bash "$VALIDATE" feature 2>&1)
    local exit_code=$?

    if [ $exit_code -eq 0 ]; then
        echo "VALIDATION_PASSED: $feature_name"
        echo "$result"
        return 0
    else
        echo "VALIDATION_FAILED: $feature_name"
        echo "$result"
        return 1
    fi
}

# Main dispatcher
case "${1:-}" in
    init)
        shift
        init_autopilot "$@"
        ;;
    next_feature)
        get_next_feature
        ;;
    ready_features)
        shift
        get_ready_features "$@"
        ;;
    start_feature)
        shift
        start_feature "$@"
        ;;
    complete)
        shift
        record_complete "$@"
        ;;
    failed)
        shift
        record_failed "$@"
        ;;
    skipped)
        shift
        record_skipped "$@"
        ;;
    check)
        check_limits
        ;;
    pause)
        shift
        pause_autopilot "$@"
        ;;
    resume)
        resume_autopilot
        ;;
    cancel)
        shift
        cancel_autopilot "$@"
        ;;
    finish)
        shift
        complete_autopilot "$@"
        ;;
    archive)
        archive_autopilot
        ;;
    status)
        status_info
        ;;
    state)
        get_state
        ;;
    report)
        generate_report
        ;;
    history)
        list_history
        ;;
    active)
        is_active && echo "true" || echo "false"
        ;;
    # Git Isolation actions
    restore_baseline)
        restore_baseline
        ;;
    # Dependency Graph actions
    graph)
        visualize_graph
        ;;
    chain)
        shift
        get_dependency_chain "$@"
        ;;
    blocked)
        shift
        is_feature_blocked "$@"
        ;;
    # Validation actions
    validate)
        shift
        run_feature_validation "$@"
        ;;
    *)
        echo "Usage: autopilot-manager.sh <action> [args]"
        echo ""
        echo "Core Actions:"
        echo "  init [opts...]                   Initialize autopilot"
        echo "    opts: max_features max_time max_cost pause_on_failure skip_validation"
        echo "          isolate merge_on_success validate_after_task validate_after_phase"
        echo "  next_feature                     Get next feature (respects dependencies)"
        echo "  ready_features [max]             Get all ready features (for parallel)"
        echo "  start_feature <name>             Mark feature as started"
        echo "  complete <name> [tasks]          Record feature completion"
        echo "  failed <name> <error>            Record feature failure"
        echo "  skipped <name> <reason>          Record feature skipped"
        echo "  check                            Check limits"
        echo "  pause [reason]                   Pause autopilot"
        echo "  resume                           Resume autopilot"
        echo "  cancel [reason] [restore]        Cancel autopilot"
        echo "  finish [reason]                  Complete autopilot"
        echo ""
        echo "Status Actions:"
        echo "  status                           Get status summary"
        echo "  state                            Get full state JSON"
        echo "  report                           Generate summary report"
        echo "  history                          List past autopilots"
        echo "  active                           Check if autopilot active"
        echo "  archive                          Archive to history"
        echo ""
        echo "Git Isolation Actions:"
        echo "  restore_baseline                 Restore git to pre-autopilot state"
        echo ""
        echo "Dependency Graph Actions:"
        echo "  graph                            Visualize dependency graph"
        echo "  chain <feature>                  Get dependency chain"
        echo "  blocked <feature>                Check if feature is blocked"
        echo ""
        echo "Validation Actions:"
        echo "  validate <feature>               Run full feature validation"
        exit 1
        ;;
esac
