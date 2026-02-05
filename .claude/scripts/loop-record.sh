#!/bin/bash
# Loop Record - Record loop execution to SQLite
# Usage: loop-record.sh <action> [args]
#
# Actions:
#   start <task> [max_iterations] [until_condition]  - Start new loop
#   iteration <loop_id> <action_taken> [result]      - Record iteration
#   complete <loop_id> [reason]                      - Mark complete
#   fail <loop_id> <error>                           - Mark failed
#   get <loop_id>                                    - Get loop state

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

DB_FILE=".claude/memory/memory.db"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    echo '{"error": true, "message": "Database not initialized"}'
    exit 1
fi

escape_sql() {
    echo "$1" | sed "s/'/''/g"
}

NOW=$(date -Iseconds)

cmd_start() {
    local task="$1"
    local max_iterations="${2:-20}"
    local until_condition="${3:-}"

    if [ -z "$task" ]; then
        echo '{"error": true, "message": "Task required"}'
        exit 1
    fi

    local task_escaped=$(escape_sql "$task")
    local until_escaped=$(escape_sql "$until_condition")

    sqlite3 "$DB_FILE" << EOF
INSERT INTO loop_runs (task, status, started_at, max_iterations, until_condition, created_at)
VALUES ('$task_escaped', 'running', '$NOW', $max_iterations, '$until_escaped', '$NOW');
EOF

    local loop_id=$(sqlite3 "$DB_FILE" "SELECT last_insert_rowid();")

    cat << JSONEOF
{
  "error": false,
  "loopId": $loop_id,
  "status": "running",
  "task": "$task_escaped"
}
JSONEOF
}

cmd_iteration() {
    local loop_id="$1"
    local action_taken="$2"
    local result="${3:-}"
    local tokens="${4:-0}"

    if [ -z "$loop_id" ] || [ -z "$action_taken" ]; then
        echo '{"error": true, "message": "loop_id and action_taken required"}'
        exit 1
    fi

    local action_escaped=$(escape_sql "$action_taken")
    local result_escaped=$(escape_sql "$result")

    # Get current iteration number
    local iter_num=$(sqlite3 "$DB_FILE" "SELECT iterations FROM loop_runs WHERE id = $loop_id;")
    iter_num=$((iter_num + 1))

    # Insert iteration
    sqlite3 "$DB_FILE" << EOF
INSERT INTO loop_iterations (loop_id, iteration_number, started_at, action_taken, result, tokens_used)
VALUES ($loop_id, $iter_num, '$NOW', '$action_escaped', '$result_escaped', $tokens);

UPDATE loop_runs SET iterations = $iter_num WHERE id = $loop_id;
EOF

    cat << JSONEOF
{
  "error": false,
  "loopId": $loop_id,
  "iteration": $iter_num
}
JSONEOF
}

cmd_complete() {
    local loop_id="$1"
    local reason="${2:-condition_met}"

    if [ -z "$loop_id" ]; then
        echo '{"error": true, "message": "loop_id required"}'
        exit 1
    fi

    sqlite3 "$DB_FILE" << EOF
UPDATE loop_runs
SET status = 'completed', ended_at = '$NOW'
WHERE id = $loop_id;
EOF

    echo '{"error": false, "message": "Loop completed"}'
}

cmd_fail() {
    local loop_id="$1"
    local error="$2"

    if [ -z "$loop_id" ]; then
        echo '{"error": true, "message": "loop_id required"}'
        exit 1
    fi

    local error_escaped=$(escape_sql "$error")

    sqlite3 "$DB_FILE" << EOF
UPDATE loop_runs
SET status = 'failed', ended_at = '$NOW', error_message = '$error_escaped'
WHERE id = $loop_id;
EOF

    echo '{"error": false, "message": "Loop marked as failed"}'
}

cmd_get() {
    local loop_id="$1"

    if [ -z "$loop_id" ]; then
        echo '{"error": true, "message": "loop_id required"}'
        exit 1
    fi

    local loop=$(sqlite3 "$DB_FILE" "
        SELECT json_object(
            'id', id,
            'task', task,
            'status', status,
            'startedAt', started_at,
            'endedAt', ended_at,
            'iterations', iterations,
            'maxIterations', max_iterations,
            'untilCondition', until_condition,
            'errorMessage', error_message
        )
        FROM loop_runs
        WHERE id = $loop_id;
    ")

    local iterations=$(sqlite3 "$DB_FILE" "
        SELECT json_group_array(json_object(
            'number', iteration_number,
            'startedAt', started_at,
            'action', action_taken,
            'result', result,
            'tokens', tokens_used
        ))
        FROM loop_iterations
        WHERE loop_id = $loop_id
        ORDER BY iteration_number;
    ")

    cat << JSONEOF
{
  "error": false,
  "loop": $loop,
  "iterations": $iterations
}
JSONEOF
}

# Main
case "${1:-}" in
    start)
        shift
        cmd_start "$@"
        ;;
    iteration)
        shift
        cmd_iteration "$@"
        ;;
    complete)
        shift
        cmd_complete "$@"
        ;;
    fail)
        shift
        cmd_fail "$@"
        ;;
    get)
        shift
        cmd_get "$@"
        ;;
    *)
        echo '{"error": true, "message": "Unknown action. Use: start|iteration|complete|fail|get"}'
        exit 1
        ;;
esac
