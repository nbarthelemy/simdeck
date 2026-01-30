#!/bin/bash
# Usage Tracker - Tracks session token usage estimates
# Usage: usage-tracker.sh <command> [args]
#
# Commands:
#   status       - Show current session usage
#   record       - Record usage (reads JSON from stdin)
#   history      - Show usage history
#   reset        - Reset current session

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

USAGE_DIR=".claude/state"
USAGE_FILE="$USAGE_DIR/usage.json"
HISTORY_FILE="$USAGE_DIR/usage-history.json"

mkdir -p "$USAGE_DIR"

# Initialize usage file if missing
init_usage() {
    if [ ! -f "$USAGE_FILE" ]; then
        cat > "$USAGE_FILE" << 'EOF'
{
  "session": {
    "started": null,
    "inputTokens": 0,
    "outputTokens": 0,
    "toolCalls": 0,
    "estimatedCost": 0.0
  }
}
EOF
    fi
}

# Initialize history file if missing
init_history() {
    if [ ! -f "$HISTORY_FILE" ]; then
        echo '{"sessions": []}' > "$HISTORY_FILE"
    fi
}

# Pricing (per 1M tokens)
# Claude Opus: $15 input, $75 output
# Claude Sonnet: $3 input, $15 output
# Using Sonnet pricing as default
INPUT_PRICE_PER_M=3
OUTPUT_PRICE_PER_M=15

cmd_status() {
    init_usage

    # Get session state
    if [ -f ".claude/state/session-state.json" ]; then
        SESSION_COUNT=$(jq -r '.metadata.sessionCount // 0' .claude/state/session-state.json)
    else
        SESSION_COUNT=0
    fi

    # Read usage data
    local input_tokens=$(jq -r '.session.inputTokens // 0' "$USAGE_FILE")
    local output_tokens=$(jq -r '.session.outputTokens // 0' "$USAGE_FILE")
    local tool_calls=$(jq -r '.session.toolCalls // 0' "$USAGE_FILE")
    local started=$(jq -r '.session.started // empty' "$USAGE_FILE")

    # Calculate cost estimate (Sonnet pricing)
    local input_cost=$(echo "scale=4; $input_tokens * $INPUT_PRICE_PER_M / 1000000" | bc)
    local output_cost=$(echo "scale=4; $output_tokens * $OUTPUT_PRICE_PER_M / 1000000" | bc)
    local total_cost=$(echo "scale=4; $input_cost + $output_cost" | bc)

    # Calculate total tokens
    local total_tokens=$((input_tokens + output_tokens))

    # Format started field
    local started_json="null"
    if [ -n "$started" ]; then
        started_json="\"$started\""
    fi

    # Format as JSON for Claude
    cat << EOF
{
  "error": false,
  "usage": {
    "sessionCount": $SESSION_COUNT,
    "started": $started_json,
    "inputTokens": $input_tokens,
    "outputTokens": $output_tokens,
    "totalTokens": $total_tokens,
    "toolCalls": $tool_calls,
    "estimatedCost": {
      "input": $input_cost,
      "output": $output_cost,
      "total": $total_cost
    },
    "pricing": {
      "model": "sonnet",
      "inputPer1M": $INPUT_PRICE_PER_M,
      "outputPer1M": $OUTPUT_PRICE_PER_M
    }
  }
}
EOF
}

cmd_record() {
    init_usage

    # Read input
    local data=$(cat)
    local input_tokens=$(echo "$data" | jq -r '.inputTokens // 0')
    local output_tokens=$(echo "$data" | jq -r '.outputTokens // 0')
    local tool_calls=$(echo "$data" | jq -r '.toolCalls // 1')

    local now=$(date -Iseconds)
    local tmp=$(mktemp)

    jq --argjson input "$input_tokens" \
       --argjson output "$output_tokens" \
       --argjson tools "$tool_calls" \
       --arg ts "$now" '
        .session.inputTokens += $input |
        .session.outputTokens += $output |
        .session.toolCalls += $tools |
        .session.started //= $ts
    ' "$USAGE_FILE" > "$tmp" && mv "$tmp" "$USAGE_FILE"

    echo '{"error": false, "message": "Usage recorded"}'
}

cmd_history() {
    init_history

    # Get last 10 sessions
    jq '.sessions | reverse | .[0:10]' "$HISTORY_FILE"
}

cmd_reset() {
    init_usage
    init_history

    # Archive current session to history if it has usage
    local current_input=$(jq -r '.session.inputTokens // 0' "$USAGE_FILE")
    if [ "$current_input" -gt 0 ]; then
        local now=$(date -Iseconds)
        local tmp=$(mktemp)

        # Add current session to history
        jq --slurpfile usage "$USAGE_FILE" --arg ts "$now" '
            .sessions += [{
                "date": $ts,
                "inputTokens": $usage[0].session.inputTokens,
                "outputTokens": $usage[0].session.outputTokens,
                "toolCalls": $usage[0].session.toolCalls
            }]
        ' "$HISTORY_FILE" > "$tmp" && mv "$tmp" "$HISTORY_FILE"
    fi

    # Reset current session
    cat > "$USAGE_FILE" << 'EOF'
{
  "session": {
    "started": null,
    "inputTokens": 0,
    "outputTokens": 0,
    "toolCalls": 0,
    "estimatedCost": 0.0
  }
}
EOF

    echo '{"error": false, "message": "Session usage reset"}'
}

# Main
case "${1:-status}" in
    status)
        cmd_status
        ;;
    record)
        cmd_record
        ;;
    history)
        cmd_history
        ;;
    reset)
        cmd_reset
        ;;
    *)
        echo '{"error": true, "message": "Unknown command: '"$1"'"}'
        exit 1
        ;;
esac
