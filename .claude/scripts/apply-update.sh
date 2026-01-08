#!/bin/bash
# Apply Update Script - Performs backup, download, and update
# Called after user confirms update

apply_update() {
    # Create backup directory
    BACKUP_DIR=".claude/backups/pre-update-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    # Backup existing files
    cp -r .claude/settings.json .claude/version.json "$BACKUP_DIR/" 2>/dev/null
    cp -r .claude/commands .claude/skills .claude/scripts .claude/rules "$BACKUP_DIR/" 2>/dev/null || true
    [ -d .claude/agents ] && cp -r .claude/agents "$BACKUP_DIR/"
    [ -f .claude/CLAUDE.md ] && cp .claude/CLAUDE.md "$BACKUP_DIR/"
    [ -f .claude/manifest.json ] && cp .claude/manifest.json "$BACKUP_DIR/"

    # Download latest release
    TEMP_DIR="/tmp/claudenv-update-$$"
    mkdir -p "$TEMP_DIR"

    if ! curl -sL "https://github.com/nbarthelemy/claudenv/archive/refs/heads/main.tar.gz" | tar -xz -C "$TEMP_DIR" 2>/dev/null; then
        cat << JSONEOF
{
  "success": false,
  "error": "Failed to download update from GitHub",
  "backupDir": "$BACKUP_DIR"
}
JSONEOF
        return
    fi

    SOURCE_DIR="$TEMP_DIR/claudenv-main/dist"

    # Check manifest exists
    if [ ! -f "$SOURCE_DIR/manifest.json" ]; then
        cat << JSONEOF
{
  "success": false,
  "error": "Downloaded archive missing manifest.json",
  "backupDir": "$BACKUP_DIR"
}
JSONEOF
        rm -rf "$TEMP_DIR"
        return
    fi

    # Remove deprecated files (count before removal)
    DEPRECATED_COUNT=0
    for file in $(jq -r '.deprecated[]' "$SOURCE_DIR/manifest.json" 2>/dev/null); do
        [ -z "$file" ] && continue
        if [ -f ".claude/$file" ]; then
            rm -f ".claude/$file"
            DEPRECATED_COUNT=$((DEPRECATED_COUNT + 1))
        fi
    done

    # Copy framework files from manifest
    UPDATED_COUNT=0
    for file in $(jq -r '.files[]' "$SOURCE_DIR/manifest.json" 2>/dev/null); do
        [ -z "$file" ] && continue
        if [ -f "$SOURCE_DIR/$file" ]; then
            dir=$(dirname "$file")
            mkdir -p ".claude/$dir"
            cp "$SOURCE_DIR/$file" ".claude/$file"
            UPDATED_COUNT=$((UPDATED_COUNT + 1))
        fi
    done

    # Copy version and manifest
    cp "$SOURCE_DIR/version.json" .claude/version.json
    cp "$SOURCE_DIR/manifest.json" .claude/manifest.json

    # Replace relative paths with absolute paths in settings.json hooks
    PROJECT_DIR="$PWD"
    if command -v sed &> /dev/null; then
        sed -i.bak "s|bash .claude/|bash $PROJECT_DIR/.claude/|g" .claude/settings.json
        rm -f .claude/settings.json.bak
    fi

    # Make scripts executable
    chmod +x .claude/scripts/*.sh 2>/dev/null

    # Get new version
    NEW_VERSION=$(jq -r '.infrastructureVersion // "unknown"' .claude/version.json 2>/dev/null)

    # Cleanup
    rm -rf "$TEMP_DIR"

    cat << JSONEOF
{
  "success": true,
  "version": "$NEW_VERSION",
  "backupDir": "$BACKUP_DIR",
  "filesUpdated": $UPDATED_COUNT,
  "filesDeprecated": $DEPRECATED_COUNT
}
JSONEOF
}

apply_update
