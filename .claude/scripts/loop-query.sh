#!/bin/bash
# Loop Query - Query loop history from SQLite
# Usage: loop-query.sh <command> [args]
#
# Commands:
#   active      - Get currently running loop
#   recent N    - Last N loops
#   failed      - Failed loops
#   stats       - Loop statistics

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

cmd_active() {
    local active=$(sqlite3 "$DB_FILE" "
        SELECT json_object(
            'id', id,
            'task', task,
            'status', status,
            'startedAt', started_at,
            'iterations', iterations,
            'maxIterations', max_iterations
        )
        FROM loop_runs
        WHERE status = 'running'
        ORDER BY started_at DESC
        LIMIT 1;
    ")

    if [ -z "$active" ] || [ "$active" = "null" ]; then
        echo '{"error": false, "active": null}'
    else
        cat << JSONEOF
{
  "error": false,
  "active": $active
}
JSONEOF
    fi
}

cmd_recent() {
    local limit="${1:-10}"

    local loops=$(sqlite3 "$DB_FILE" "
        SELECT json_group_array(json_object(
            'id', id,
            'task', task,
            'status', status,
            'startedAt', started_at,
            'endedAt', ended_at,
            'iterations', iterations
        ))
        FROM (
            SELECT id, task, status, started_at, ended_at, iterations
            FROM loop_runs
            ORDER BY started_at DESC
            LIMIT $limit
        );
    ")

    cat << JSONEOF
{
  "error": false,
  "loops": $loops
}
JSONEOF
}

cmd_failed() {
    local loops=$(sqlite3 "$DB_FILE" "
        SELECT json_group_array(json_object(
            'id', id,
            'task', task,
            'startedAt', started_at,
            'iterations', iterations,
            'error', error_message
        ))
        FROM (
            SELECT id, task, started_at, iterations, error_message
            FROM loop_runs
            WHERE status = 'failed'
            ORDER BY started_at DESC
            LIMIT 20
        );
    ")

    cat << JSONEOF
{
  "error": false,
  "failed": $loops
}
JSONEOF
}

cmd_stats() {
    local stats=$(sqlite3 "$DB_FILE" "
        SELECT json_object(
            'total', COUNT(*),
            'completed', SUM(CASE WHEN status = 'completed' THEN 1 ELSE 0 END),
            'failed', SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END),
            'running', SUM(CASE WHEN status = 'running' THEN 1 ELSE 0 END),
            'avgIterations', ROUND(AVG(iterations), 1),
            'maxIterations', MAX(iterations),
            'totalIterations', SUM(iterations)
        )
        FROM loop_runs;
    ")

    cat << JSONEOF
{
  "error": false,
  "stats": $stats
}
JSONEOF
}

# Main
case "${1:-active}" in
    active)
        cmd_active
        ;;
    recent)
        cmd_recent "${2:-10}"
        ;;
    failed)
        cmd_failed
        ;;
    stats)
        cmd_stats
        ;;
    *)
        echo '{"error": true, "message": "Unknown command. Use: active|recent|failed|stats"}'
        exit 1
        ;;
esac
