#!/bin/bash
# Usage Record - Record usage data to SQLite
# Usage: usage-record.sh [session_id] (reads JSON from stdin)
#
# Input JSON: {"inputTokens": N, "outputTokens": N, "toolName": "...", "command": "..."}

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
        bash .claude/scripts/usage-tracker.sh record
    fi
    exit 0
fi

SESSION_ID="${1:-current}"
NOW=$(date -Iseconds)

# Read input JSON
INPUT=$(cat)

if ! command -v jq &> /dev/null; then
    echo '{"error": true, "message": "jq required"}'
    exit 1
fi

INPUT_TOKENS=$(echo "$INPUT" | jq -r '.inputTokens // 0')
OUTPUT_TOKENS=$(echo "$INPUT" | jq -r '.outputTokens // 0')
TOOL_NAME=$(echo "$INPUT" | jq -r '.toolName // empty' | sed "s/'/''/g")
COMMAND=$(echo "$INPUT" | jq -r '.command // empty' | sed "s/'/''/g")

# Calculate cost estimate (Sonnet pricing: $3/$15 per 1M)
COST=$(echo "scale=6; ($INPUT_TOKENS * 3 + $OUTPUT_TOKENS * 15) / 1000000" | bc)

# Insert into database
sqlite3 "$DB_FILE" << EOF
INSERT INTO usage_records (session_id, timestamp, input_tokens, output_tokens, tool_name, command, cost_estimate, created_at)
VALUES ('$SESSION_ID', '$NOW', $INPUT_TOKENS, $OUTPUT_TOKENS, '$TOOL_NAME', '$COMMAND', $COST, '$NOW');
EOF

echo '{"error": false, "message": "Usage recorded"}'
