#!/bin/bash
# List Backups Script - JSON output for Claude to format
# Scans .claude/backups/ and returns metadata for each backup

list_backups() {
    BACKUP_DIR=".claude/backups"

    # Check if backups directory exists
    if [ ! -d "$BACKUP_DIR" ]; then
        cat << JSONEOF
{
  "error": false,
  "backups": [],
  "count": 0,
  "message": "No backups directory found"
}
JSONEOF
        return
    fi

    # Build JSON array of backups
    BACKUPS_JSON="[]"

    for dir in "$BACKUP_DIR"/*/; do
        [ -d "$dir" ] || continue

        DIR_NAME=$(basename "$dir")

        # Get creation date from directory name or stat
        if [[ "$DIR_NAME" =~ ([0-9]{8})-?([0-9]{6})? ]]; then
            # Extract date from name like "pre-update-20260105-143000"
            DATE_PART="${BASH_REMATCH[1]}"
            TIME_PART="${BASH_REMATCH[2]:-000000}"
            CREATED="${DATE_PART:0:4}-${DATE_PART:4:2}-${DATE_PART:6:2} ${TIME_PART:0:2}:${TIME_PART:2:2}:${TIME_PART:4:2}"
        else
            # Fall back to stat
            CREATED=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M:%S" "$dir" 2>/dev/null || stat -c "%y" "$dir" 2>/dev/null | cut -d'.' -f1)
        fi

        # Count files
        FILE_COUNT=$(find "$dir" -type f 2>/dev/null | wc -l | tr -d ' ')

        # Get size
        SIZE=$(du -sh "$dir" 2>/dev/null | cut -f1)

        # Check for manifest
        HAS_MANIFEST="false"
        [ -f "$dir/manifest.json" ] && HAS_MANIFEST="true"

        # Determine backup type from name
        TYPE="manual"
        [[ "$DIR_NAME" == pre-update-* ]] && TYPE="pre-update"
        [[ "$DIR_NAME" == pre-restore-* ]] && TYPE="pre-restore"
        [[ "$DIR_NAME" == pre-refactor-* ]] && TYPE="pre-refactor"
        [[ "$DIR_NAME" == auto-* ]] && TYPE="automatic"

        BACKUPS_JSON=$(echo "$BACKUPS_JSON" | jq \
            --arg id "$DIR_NAME" \
            --arg created "$CREATED" \
            --arg files "$FILE_COUNT" \
            --arg size "$SIZE" \
            --arg type "$TYPE" \
            --arg manifest "$HAS_MANIFEST" \
            '. + [{
                "id": $id,
                "created": $created,
                "fileCount": ($files | tonumber),
                "size": $size,
                "type": $type,
                "hasManifest": ($manifest == "true")
            }]')
    done

    # Sort by created date (newest first) and count
    BACKUPS_JSON=$(echo "$BACKUPS_JSON" | jq 'sort_by(.created) | reverse')
    COUNT=$(echo "$BACKUPS_JSON" | jq 'length')

    cat << JSONEOF
{
  "error": false,
  "backups": $BACKUPS_JSON,
  "count": $COUNT
}
JSONEOF
}

list_backups
