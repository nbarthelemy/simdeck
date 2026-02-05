#!/bin/bash
# Memory Search
# Hybrid FTS5 + sqlite-vss search for observations
# Usage: memory-search.sh <query> [options]
#
# Options:
#   --keyword     FTS5 only (fast, exact)
#   --semantic    sqlite-vss only (fuzzy, meaning)
#   --hybrid      Both, merged results (default)
#   --limit N     Max results (default 10)
#   --full        Return full content, not just summaries

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
VEC_PATH_FILE="$MEMORY_DIR/.vec_path"
SQLITE3_PATH_FILE="$MEMORY_DIR/.sqlite3_path"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    echo '{"error": true, "message": "Database not initialized"}'
    exit 1
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

# Parse arguments
QUERY=""
MODE="hybrid"
LIMIT=10
FULL=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --keyword)
            MODE="keyword"
            shift
            ;;
        --semantic)
            MODE="semantic"
            shift
            ;;
        --hybrid)
            MODE="hybrid"
            shift
            ;;
        --limit)
            LIMIT="$2"
            shift 2
            ;;
        --full)
            FULL=true
            shift
            ;;
        *)
            QUERY="$QUERY $1"
            shift
            ;;
    esac
done

QUERY=$(echo "$QUERY" | sed 's/^ *//' | sed 's/ *$//')

if [ -z "$QUERY" ]; then
    echo '{"error": true, "message": "No search query provided"}'
    exit 1
fi

# Check sqlite-vec availability
VEC_AVAILABLE=false
VEC_PATH=""
if [ -f "$VEC_PATH_FILE" ]; then
    VEC_PATH=$(cat "$VEC_PATH_FILE")
    if [ -n "$VEC_PATH" ] && [ -f "$VEC_PATH" ]; then
        # Verify extension can load
        if $SQLITE3 :memory: ".load $VEC_PATH" "SELECT vec_version();" >/dev/null 2>&1; then
            VEC_AVAILABLE=true
        fi
    fi
fi

# Escape query for SQLite
escape_sql() {
    echo "$1" | sed "s/'/''/g"
}

QUERY_ESCAPED=$(escape_sql "$QUERY")

# FTS5 search
search_fts5() {
    local select_fields="o.id, o.summary, o.tool_name, o.timestamp, o.importance, o.files_involved"
    if [ "$FULL" = true ]; then
        select_fields="o.id, o.summary, o.tool_name, o.tool_input, o.tool_output, o.timestamp, o.importance, o.files_involved"
    fi

    local query="
        SELECT $select_fields,
               bm25(observations_fts) as rank
        FROM observations o
        JOIN observations_fts fts ON o.id = fts.rowid
        WHERE observations_fts MATCH '$QUERY_ESCAPED'
        ORDER BY rank
        LIMIT $LIMIT
    "

    $SQLITE3 "$DB_FILE" "SELECT json_group_array(json_object(
        'id', id,
        'summary', summary,
        'tool_name', tool_name,
        'timestamp', timestamp,
        'importance', importance,
        'files_involved', files_involved,
        'rank', rank,
        'source', 'fts5'
    )) FROM ($query);"
}

# Semantic search (requires sqlite-vec)
search_semantic() {
    if [ "$VEC_AVAILABLE" = false ]; then
        echo "[]"
        return
    fi

    # Generate embedding for query using memory-embed.js
    local embed_script="$PROJECT_ROOT/.claude/scripts/memory-embed.js"
    if [ ! -f "$embed_script" ]; then
        echo "[]"
        return
    fi

    local embedding_result
    embedding_result=$(node "$embed_script" embed "$QUERY" 2>/dev/null)
    if [ $? -ne 0 ]; then
        echo "[]"
        return
    fi

    local embedding=$(echo "$embedding_result" | jq -r '.embedding | @json' 2>/dev/null)
    if [ -z "$embedding" ] || [ "$embedding" = "null" ]; then
        echo "[]"
        return
    fi

    local select_fields="o.id, o.summary, o.tool_name, o.timestamp, o.importance, o.files_involved"
    if [ "$FULL" = true ]; then
        select_fields="o.id, o.summary, o.tool_name, o.tool_input, o.tool_output, o.timestamp, o.importance, o.files_involved"
    fi

    # Query vec0 for nearest neighbors using KNN syntax
    local query="
        SELECT $select_fields,
               vec.distance as rank
        FROM vec_observations vec
        JOIN observation_embeddings oe ON vec.rowid = oe.vss_rowid
        JOIN observations o ON oe.observation_id = o.id
        WHERE vec.embedding MATCH '$embedding'
        AND k = $LIMIT
        ORDER BY vec.distance
    "

    $SQLITE3 "$DB_FILE" ".load $VEC_PATH" "SELECT json_group_array(json_object(
        'id', id,
        'summary', summary,
        'tool_name', tool_name,
        'timestamp', timestamp,
        'importance', importance,
        'files_involved', files_involved,
        'rank', rank,
        'source', 'vec'
    )) FROM ($query);" 2>/dev/null || echo "[]"
}

# Perform search based on mode
case "$MODE" in
    keyword)
        FTS_RESULTS=$(search_fts5)
        cat << JSONEOF
{
  "error": false,
  "query": "$QUERY_ESCAPED",
  "mode": "keyword",
  "results": $FTS_RESULTS
}
JSONEOF
        ;;

    semantic)
        if [ "$VEC_AVAILABLE" = false ]; then
            echo '{"error": true, "message": "Semantic search requires sqlite-vec"}'
            exit 1
        fi
        VEC_RESULTS=$(search_semantic)
        cat << JSONEOF
{
  "error": false,
  "query": "$QUERY_ESCAPED",
  "mode": "semantic",
  "results": $VEC_RESULTS
}
JSONEOF
        ;;

    hybrid)
        FTS_RESULTS=$(search_fts5)

        # If sqlite-vec is available, also do semantic search
        if [ "$VEC_AVAILABLE" = true ]; then
            VEC_RESULTS=$(search_semantic)

            # Merge results (FTS first, then vec for items not in FTS)
            # This is a simple merge - a more sophisticated approach would
            # combine scores and re-rank
            if command -v jq &> /dev/null; then
                MERGED=$(jq -s '
                    (.[0] // []) + (.[1] // [])
                    | group_by(.id)
                    | map(.[0])
                    | sort_by(.rank)
                    | .[:'"$LIMIT"']
                ' <<< "$FTS_RESULTS $VEC_RESULTS")
            else
                MERGED="$FTS_RESULTS"
            fi

            cat << JSONEOF
{
  "error": false,
  "query": "$QUERY_ESCAPED",
  "mode": "hybrid",
  "vecAvailable": true,
  "results": $MERGED
}
JSONEOF
        else
            # sqlite-vec not available, return FTS only
            cat << JSONEOF
{
  "error": false,
  "query": "$QUERY_ESCAPED",
  "mode": "hybrid",
  "vecAvailable": false,
  "results": $FTS_RESULTS
}
JSONEOF
        fi
        ;;
esac
