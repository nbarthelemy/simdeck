#!/bin/bash
# Memory System Status
# Returns JSON status of the memory system
# Usage: memory-status.sh

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
PENDING_FILE="$MEMORY_DIR/.pending-observations.jsonl"
VEC_PATH_FILE="$MEMORY_DIR/.vec_path"
SQLITE3_PATH_FILE="$MEMORY_DIR/.sqlite3_path"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    cat << 'JSONEOF'
{
  "error": false,
  "initialized": false,
  "message": "Memory database not initialized. Run memory-init.sh"
}
JSONEOF
    exit 0
fi

# Use stored sqlite3 path or detect
if [ -f "$SQLITE3_PATH_FILE" ]; then
    SQLITE3=$(cat "$SQLITE3_PATH_FILE")
else
    # Prefer Homebrew sqlite3 which supports .load
    if [ -x "/opt/homebrew/opt/sqlite/bin/sqlite3" ]; then
        SQLITE3="/opt/homebrew/opt/sqlite/bin/sqlite3"
    elif [ -x "/usr/local/opt/sqlite/bin/sqlite3" ]; then
        SQLITE3="/usr/local/opt/sqlite/bin/sqlite3"
    else
        SQLITE3="sqlite3"
    fi
fi

# Get database stats
DB_SIZE=$(du -h "$DB_FILE" 2>/dev/null | cut -f1 || echo "0")

# Count records
OBSERVATION_COUNT=$($SQLITE3 "$DB_FILE" "SELECT COUNT(*) FROM observations;" 2>/dev/null || echo "0")
SESSION_COUNT=$($SQLITE3 "$DB_FILE" "SELECT COUNT(*) FROM sessions;" 2>/dev/null || echo "0")
USAGE_COUNT=$($SQLITE3 "$DB_FILE" "SELECT COUNT(*) FROM usage_records;" 2>/dev/null || echo "0")
LOOP_COUNT=$($SQLITE3 "$DB_FILE" "SELECT COUNT(*) FROM loop_runs;" 2>/dev/null || echo "0")
EMBEDDING_COUNT=$($SQLITE3 "$DB_FILE" "SELECT COUNT(*) FROM observation_embeddings;" 2>/dev/null || echo "0")

# Count by importance
HIGH_IMPORTANCE=$($SQLITE3 "$DB_FILE" "SELECT COUNT(*) FROM observations WHERE importance = 3;" 2>/dev/null || echo "0")
MEDIUM_IMPORTANCE=$($SQLITE3 "$DB_FILE" "SELECT COUNT(*) FROM observations WHERE importance = 2;" 2>/dev/null || echo "0")
LOW_IMPORTANCE=$($SQLITE3 "$DB_FILE" "SELECT COUNT(*) FROM observations WHERE importance = 1;" 2>/dev/null || echo "0")

# Count compressed
COMPRESSED_COUNT=$($SQLITE3 "$DB_FILE" "SELECT COUNT(*) FROM observations WHERE compressed = 1;" 2>/dev/null || echo "0")

# Get schema version
SCHEMA_VERSION=$($SQLITE3 "$DB_FILE" "SELECT MAX(version) FROM schema_version;" 2>/dev/null || echo "0")

# Count pending observations
PENDING_COUNT=0
if [ -f "$PENDING_FILE" ]; then
    PENDING_COUNT=$(wc -l < "$PENDING_FILE" | tr -d ' ')
fi

# Check sqlite-vec status
VEC_AVAILABLE="false"
VEC_PATH=""
if [ -f "$VEC_PATH_FILE" ]; then
    VEC_PATH=$(cat "$VEC_PATH_FILE")
    if [ -n "$VEC_PATH" ] && [ -f "$VEC_PATH" ]; then
        # Verify extension can actually load
        if $SQLITE3 :memory: ".load $VEC_PATH" "SELECT vec_version();" >/dev/null 2>&1; then
            VEC_AVAILABLE="true"
        fi
    fi
fi

# Check embeddings status
EMBEDDINGS_PENDING=$((OBSERVATION_COUNT - EMBEDDING_COUNT))
if [ "$EMBEDDINGS_PENDING" -lt 0 ]; then
    EMBEDDINGS_PENDING=0
fi

# Get last observation timestamp
LAST_OBSERVATION=$($SQLITE3 "$DB_FILE" "SELECT MAX(timestamp) FROM observations;" 2>/dev/null || echo "null")
if [ "$LAST_OBSERVATION" = "" ]; then
    LAST_OBSERVATION="null"
else
    LAST_OBSERVATION="\"$LAST_OBSERVATION\""
fi

# Get recent sessions (sqlite3 -json may not be available on all platforms)
RECENT_SESSIONS=$($SQLITE3 "$DB_FILE" "SELECT json_group_array(json_object('id', id, 'started_at', started_at, 'observation_count', observation_count)) FROM (SELECT id, started_at, observation_count FROM sessions ORDER BY started_at DESC LIMIT 5);" 2>/dev/null || echo "[]")
# Handle empty result
if [ "$RECENT_SESSIONS" = "[null]" ] || [ -z "$RECENT_SESSIONS" ]; then
    RECENT_SESSIONS="[]"
fi

# Output status as JSON
cat << JSONEOF
{
  "error": false,
  "initialized": true,
  "database": {
    "path": "$DB_FILE",
    "size": "$DB_SIZE",
    "schemaVersion": $SCHEMA_VERSION
  },
  "counts": {
    "observations": $OBSERVATION_COUNT,
    "sessions": $SESSION_COUNT,
    "usageRecords": $USAGE_COUNT,
    "loopRuns": $LOOP_COUNT,
    "embeddings": $EMBEDDING_COUNT
  },
  "importance": {
    "high": $HIGH_IMPORTANCE,
    "medium": $MEDIUM_IMPORTANCE,
    "low": $LOW_IMPORTANCE
  },
  "compressed": $COMPRESSED_COUNT,
  "pending": {
    "observations": $PENDING_COUNT,
    "embeddings": $EMBEDDINGS_PENDING
  },
  "vec": {
    "available": $VEC_AVAILABLE,
    "path": "$VEC_PATH"
  },
  "lastObservation": $LAST_OBSERVATION,
  "recentSessions": $RECENT_SESSIONS
}
JSONEOF
