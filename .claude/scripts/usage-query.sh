#!/bin/bash
# Usage Query - Query usage history from SQLite
# Usage: usage-query.sh <command> [args]
#
# Commands:
#   status      - Current session stats
#   today       - Today's usage
#   week        - Last 7 days
#   history N   - Last N sessions
#   by-tool     - Breakdown by tool

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
    # Fall back to JSON-based tracker
    if [ -x ".claude/scripts/usage-tracker.sh" ]; then
        case "${1:-status}" in
            status) bash .claude/scripts/usage-tracker.sh status ;;
            history) bash .claude/scripts/usage-tracker.sh history ;;
            *) bash .claude/scripts/usage-tracker.sh status ;;
        esac
    fi
    exit 0
fi

# Pricing (per 1M tokens)
INPUT_PRICE=3
OUTPUT_PRICE=15

cmd_status() {
    local result=$(sqlite3 "$DB_FILE" "
        SELECT json_object(
            'inputTokens', COALESCE(SUM(input_tokens), 0),
            'outputTokens', COALESCE(SUM(output_tokens), 0),
            'totalTokens', COALESCE(SUM(input_tokens + output_tokens), 0),
            'toolCalls', COUNT(*),
            'totalCost', ROUND(COALESCE(SUM(cost_estimate), 0), 4)
        )
        FROM usage_records
        WHERE session_id = 'current' OR timestamp >= datetime('now', '-1 hour');
    ")

    cat << JSONEOF
{
  "error": false,
  "usage": $result,
  "pricing": {
    "model": "sonnet",
    "inputPer1M": $INPUT_PRICE,
    "outputPer1M": $OUTPUT_PRICE
  }
}
JSONEOF
}

cmd_today() {
    local result=$(sqlite3 "$DB_FILE" "
        SELECT json_object(
            'inputTokens', COALESCE(SUM(input_tokens), 0),
            'outputTokens', COALESCE(SUM(output_tokens), 0),
            'totalTokens', COALESCE(SUM(input_tokens + output_tokens), 0),
            'toolCalls', COUNT(*),
            'totalCost', ROUND(COALESCE(SUM(cost_estimate), 0), 4)
        )
        FROM usage_records
        WHERE date(timestamp) = date('now');
    ")

    cat << JSONEOF
{
  "error": false,
  "period": "today",
  "usage": $result
}
JSONEOF
}

cmd_week() {
    local daily=$(sqlite3 "$DB_FILE" "
        SELECT json_group_array(json_object(
            'date', date,
            'inputTokens', input_tokens,
            'outputTokens', output_tokens,
            'totalCost', total_cost
        ))
        FROM (
            SELECT
                date(timestamp) as date,
                SUM(input_tokens) as input_tokens,
                SUM(output_tokens) as output_tokens,
                ROUND(SUM(cost_estimate), 4) as total_cost
            FROM usage_records
            WHERE timestamp >= datetime('now', '-7 days')
            GROUP BY date(timestamp)
            ORDER BY date DESC
        );
    ")

    local total=$(sqlite3 "$DB_FILE" "
        SELECT json_object(
            'inputTokens', COALESCE(SUM(input_tokens), 0),
            'outputTokens', COALESCE(SUM(output_tokens), 0),
            'totalCost', ROUND(COALESCE(SUM(cost_estimate), 0), 4)
        )
        FROM usage_records
        WHERE timestamp >= datetime('now', '-7 days');
    ")

    cat << JSONEOF
{
  "error": false,
  "period": "last7days",
  "daily": $daily,
  "total": $total
}
JSONEOF
}

cmd_history() {
    local limit="${1:-10}"

    local sessions=$(sqlite3 "$DB_FILE" "
        SELECT json_group_array(json_object(
            'sessionId', session_id,
            'date', date,
            'inputTokens', input_tokens,
            'outputTokens', output_tokens,
            'toolCalls', tool_calls,
            'totalCost', total_cost
        ))
        FROM (
            SELECT
                session_id,
                date(timestamp) as date,
                SUM(input_tokens) as input_tokens,
                SUM(output_tokens) as output_tokens,
                COUNT(*) as tool_calls,
                ROUND(SUM(cost_estimate), 4) as total_cost
            FROM usage_records
            GROUP BY session_id
            ORDER BY MAX(timestamp) DESC
            LIMIT $limit
        );
    ")

    cat << JSONEOF
{
  "error": false,
  "sessions": $sessions
}
JSONEOF
}

cmd_by_tool() {
    local breakdown=$(sqlite3 "$DB_FILE" "
        SELECT json_group_array(json_object(
            'toolName', tool_name,
            'count', count,
            'inputTokens', input_tokens,
            'outputTokens', output_tokens
        ))
        FROM (
            SELECT
                COALESCE(tool_name, 'unknown') as tool_name,
                COUNT(*) as count,
                SUM(input_tokens) as input_tokens,
                SUM(output_tokens) as output_tokens
            FROM usage_records
            WHERE timestamp >= datetime('now', '-7 days')
            GROUP BY tool_name
            ORDER BY count DESC
        );
    ")

    cat << JSONEOF
{
  "error": false,
  "period": "last7days",
  "byTool": $breakdown
}
JSONEOF
}

# Main
case "${1:-status}" in
    status)
        cmd_status
        ;;
    today)
        cmd_today
        ;;
    week)
        cmd_week
        ;;
    history)
        cmd_history "${2:-10}"
        ;;
    by-tool)
        cmd_by_tool
        ;;
    *)
        echo '{"error": true, "message": "Unknown command. Use: status|today|week|history|by-tool"}'
        exit 1
        ;;
esac
