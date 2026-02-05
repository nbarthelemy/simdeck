#!/bin/bash
# Memory Get
# Retrieve full observation by ID
# Usage: memory-get.sh <id>

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

MEMORY_DIR=".claude/memory"
DB_FILE="$MEMORY_DIR/memory.db"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    echo '{"error": true, "message": "Database not initialized"}'
    exit 1
fi

# Get observation ID
OBS_ID="${1:-}"
if [ -z "$OBS_ID" ]; then
    echo '{"error": true, "message": "No observation ID provided"}'
    exit 1
fi

# Validate ID is numeric
if ! [[ "$OBS_ID" =~ ^[0-9]+$ ]]; then
    echo '{"error": true, "message": "Invalid observation ID"}'
    exit 1
fi

# Fetch observation
RESULT=$(sqlite3 "$DB_FILE" "
    SELECT json_object(
        'id', id,
        'session_id', session_id,
        'timestamp', timestamp,
        'tool_name', tool_name,
        'tool_input', tool_input,
        'tool_output', tool_output,
        'files_involved', files_involved,
        'summary', summary,
        'keywords', keywords,
        'importance', importance,
        'compressed', compressed,
        'created_at', created_at
    )
    FROM observations
    WHERE id = $OBS_ID;
")

if [ -z "$RESULT" ]; then
    echo '{"error": true, "message": "Observation not found"}'
    exit 1
fi

# Check if there's an embedding
HAS_EMBEDDING=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM observation_embeddings WHERE observation_id = $OBS_ID;")

cat << JSONEOF
{
  "error": false,
  "observation": $RESULT,
  "hasEmbedding": $([ "$HAS_EMBEDDING" -gt 0 ] && echo "true" || echo "false")
}
JSONEOF
