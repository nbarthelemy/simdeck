#!/bin/bash
# Memory Compression
# Age-based compression of observations to manage database size
# Usage: memory-compress.sh [--dry-run]
#
# Compression rules:
# - < 24h: Keep all, full detail
# - 1-7d: Keep importance >= 2, full detail
# - 7-30d: Keep importance >= 2, compress (summary only)
# - > 30d: Keep importance = 3 only, summary only

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
DRY_RUN="${1:-}"

# Check if database exists
if [ ! -f "$DB_FILE" ]; then
    echo '{"error": true, "message": "Database not initialized"}'
    exit 1
fi

# Counters
DELETED_LOW_OLD=0
DELETED_MEDIUM_OLD=0
COMPRESSED=0

# Delete low-importance observations older than 7 days
if [ "$DRY_RUN" = "--dry-run" ]; then
    DELETED_LOW_OLD=$(sqlite3 "$DB_FILE" "
        SELECT COUNT(*) FROM observations
        WHERE importance = 1
        AND timestamp < datetime('now', '-7 days');
    ")
    echo "Would delete $DELETED_LOW_OLD low-importance observations (>7 days old)"
else
    DELETED_LOW_OLD=$(sqlite3 "$DB_FILE" "
        SELECT COUNT(*) FROM observations
        WHERE importance = 1
        AND timestamp < datetime('now', '-7 days');
    ")
    sqlite3 "$DB_FILE" "
        DELETE FROM observations
        WHERE importance = 1
        AND timestamp < datetime('now', '-7 days');
    "
fi

# Delete medium-importance observations older than 30 days
if [ "$DRY_RUN" = "--dry-run" ]; then
    DELETED_MEDIUM_OLD=$(sqlite3 "$DB_FILE" "
        SELECT COUNT(*) FROM observations
        WHERE importance = 2
        AND timestamp < datetime('now', '-30 days');
    ")
    echo "Would delete $DELETED_MEDIUM_OLD medium-importance observations (>30 days old)"
else
    DELETED_MEDIUM_OLD=$(sqlite3 "$DB_FILE" "
        SELECT COUNT(*) FROM observations
        WHERE importance = 2
        AND timestamp < datetime('now', '-30 days');
    ")
    sqlite3 "$DB_FILE" "
        DELETE FROM observations
        WHERE importance = 2
        AND timestamp < datetime('now', '-30 days');
    "
fi

# Compress observations older than 7 days (clear tool_input and tool_output)
if [ "$DRY_RUN" = "--dry-run" ]; then
    COMPRESSED=$(sqlite3 "$DB_FILE" "
        SELECT COUNT(*) FROM observations
        WHERE compressed = 0
        AND timestamp < datetime('now', '-7 days')
        AND importance >= 2;
    ")
    echo "Would compress $COMPRESSED observations (>7 days old, importance >= 2)"
else
    COMPRESSED=$(sqlite3 "$DB_FILE" "
        SELECT COUNT(*) FROM observations
        WHERE compressed = 0
        AND timestamp < datetime('now', '-7 days')
        AND importance >= 2;
    ")
    sqlite3 "$DB_FILE" "
        UPDATE observations
        SET tool_input = NULL, tool_output = NULL, compressed = 1
        WHERE compressed = 0
        AND timestamp < datetime('now', '-7 days')
        AND importance >= 2;
    "
fi

# Clean up orphaned embeddings
ORPHANED_EMBEDDINGS=0
if [ "$DRY_RUN" != "--dry-run" ]; then
    ORPHANED_EMBEDDINGS=$(sqlite3 "$DB_FILE" "
        SELECT COUNT(*) FROM observation_embeddings oe
        WHERE NOT EXISTS (SELECT 1 FROM observations o WHERE o.id = oe.observation_id);
    ")
    sqlite3 "$DB_FILE" "
        DELETE FROM observation_embeddings
        WHERE observation_id NOT IN (SELECT id FROM observations);
    "
fi

# Vacuum database to reclaim space
if [ "$DRY_RUN" != "--dry-run" ]; then
    sqlite3 "$DB_FILE" "VACUUM;"
fi

# Get final stats
TOTAL_REMAINING=$(sqlite3 "$DB_FILE" "SELECT COUNT(*) FROM observations;")
DB_SIZE=$(du -h "$DB_FILE" 2>/dev/null | cut -f1 || echo "unknown")

cat << JSONEOF
{
  "error": false,
  "dryRun": $([ "$DRY_RUN" = "--dry-run" ] && echo "true" || echo "false"),
  "deleted": {
    "lowImportanceOld": $DELETED_LOW_OLD,
    "mediumImportanceOld": $DELETED_MEDIUM_OLD,
    "orphanedEmbeddings": $ORPHANED_EMBEDDINGS
  },
  "compressed": $COMPRESSED,
  "remaining": $TOTAL_REMAINING,
  "databaseSize": "$DB_SIZE"
}
JSONEOF
