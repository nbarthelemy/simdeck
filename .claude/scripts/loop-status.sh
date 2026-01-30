#!/bin/bash
# Loop Status Script - JSON output for Claude to format

# Always resolve paths relative to repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
STATE_FILE="$REPO_ROOT/.claude/loop/state.json"
PLAN_STATE_FILE="$REPO_ROOT/.claude/loop/plan-state.json"

collect_loop_status() {
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"active": false}'
        return
    fi

    # Read all state values
    PROMPT=$(jq -r '.prompt // ""' "$STATE_FILE" 2>/dev/null)
    STATUS=$(jq -r '.status // "unknown"' "$STATE_FILE" 2>/dev/null)
    CURRENT=$(jq -r '.iterations.current // .current_iteration // 0' "$STATE_FILE" 2>/dev/null)
    MAX=$(jq -r '.iterations.max // .max_iterations // 20' "$STATE_FILE" 2>/dev/null)
    START_TIME=$(jq -r '.started_at // .start_time // ""' "$STATE_FILE" 2>/dev/null)
    CONDITION_TYPE=$(jq -r '.completion.type // .condition.type // ""' "$STATE_FILE" 2>/dev/null)
    CONDITION_TARGET=$(jq -r '.completion.condition // .condition.target // ""' "$STATE_FILE" 2>/dev/null)
    CONDITION_MET=$(jq -r '.completion.met // .condition_met // false' "$STATE_FILE" 2>/dev/null)
    MAX_TIME=$(jq -r '.limits.max_time // .max_time // "2h"' "$STATE_FILE" 2>/dev/null)
    MODE=$(jq -r '.mode // "standard"' "$STATE_FILE" 2>/dev/null)
    CONTEXT_MODE=$(jq -r '.contextMode // "fresh"' "$STATE_FILE" 2>/dev/null)

    # Calculate elapsed
    ELAPSED_MINS=0
    if [ -n "$START_TIME" ] && [ "$START_TIME" != "null" ]; then
        START_EPOCH=$(date -j -f "%Y-%m-%dT%H:%M:%S" "${START_TIME%%.*}" "+%s" 2>/dev/null || echo "0")
        if [ "$START_EPOCH" -gt 0 ]; then
            NOW_EPOCH=$(date "+%s")
            ELAPSED_MINS=$(( (NOW_EPOCH - START_EPOCH) / 60 ))
        fi
    fi

    # Calculate percentage
    PCT=0
    [ "$MAX" -gt 0 ] && PCT=$((CURRENT * 100 / MAX))

    # Get context budget
    CONTEXT_BUDGET=$(bash "$REPO_ROOT/.claude/scripts/loop-manager.sh" context_budget 2>/dev/null || echo '{}')

    # Get plan context if in plan mode
    CURRENT_PHASE=""
    CURRENT_TASK=""
    NEXT_TASK=""
    TOTAL_PHASES=0
    TOTAL_TASKS=0
    TASKS_COMPLETED=0

    if [ "$MODE" = "plan" ] && [ -f "$PLAN_STATE_FILE" ]; then
        CURRENT_PHASE=$(jq -r '.currentPhase // ""' "$PLAN_STATE_FILE" 2>/dev/null)
        CURRENT_TASK=$(jq -r '.currentTask // ""' "$PLAN_STATE_FILE" 2>/dev/null)
        TOTAL_PHASES=$(jq -r '.totalPhases // 0' "$PLAN_STATE_FILE" 2>/dev/null)
        TOTAL_TASKS=$(jq -r '.totalTasks // 0' "$PLAN_STATE_FILE" 2>/dev/null)
        TASKS_COMPLETED=$(jq -r '.tasksCompleted | length // 0' "$PLAN_STATE_FILE" 2>/dev/null)

        # Get next task from plan file
        PLAN_FILE=$(jq -r '.planFile // ""' "$PLAN_STATE_FILE" 2>/dev/null)
        if [ -f "$PLAN_FILE" ]; then
            NEXT_TASK=$(grep -m1 "\- \[ \] \*\*Task" "$PLAN_FILE" 2>/dev/null | sed 's/.*\*\*Task \([0-9.]*\)\*\*.*/Task \1/' || echo "")
        fi
    fi

    cat << JSONEOF
{
  "active": true,
  "prompt": $(echo "$PROMPT" | jq -Rs .),
  "status": "$STATUS",
  "mode": "$MODE",
  "contextMode": "$CONTEXT_MODE",
  "iterations": {
    "current": $CURRENT,
    "max": $MAX,
    "percentage": $PCT
  },
  "elapsedMinutes": $ELAPSED_MINS,
  "maxTime": "$MAX_TIME",
  "condition": {
    "type": "$CONDITION_TYPE",
    "target": $(echo "$CONDITION_TARGET" | jq -Rs .),
    "met": $CONDITION_MET
  },
  "context": {
    "currentPhase": "$CURRENT_PHASE",
    "currentTask": "$CURRENT_TASK",
    "nextTask": "$NEXT_TASK",
    "totalPhases": $TOTAL_PHASES,
    "totalTasks": $TOTAL_TASKS,
    "tasksCompleted": $TASKS_COMPLETED
  },
  "contextBudget": $CONTEXT_BUDGET
}
JSONEOF
}

collect_loop_status
