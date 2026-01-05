#!/bin/bash
# Check Update Script - JSON output for Claude to format
# Compares local version with remote and fetches changelog if update available

check_update() {
    # Get current version
    CURRENT="unknown"
    if [ -f ".claude/version.json" ]; then
        CURRENT=$(jq -r '.infrastructureVersion // "unknown"' .claude/version.json 2>/dev/null)
    fi

    # Get latest version from GitHub
    # Note: raw.githubusercontent.com doesn't support query params, so no cache buster
    REMOTE_JSON=$(curl -sL "https://raw.githubusercontent.com/nbarthelemy/claudenv/main/dist/version.json" 2>/dev/null)

    if [ -z "$REMOTE_JSON" ]; then
        cat << JSONEOF
{
  "error": true,
  "message": "Could not fetch remote version",
  "current": "$CURRENT",
  "latest": null,
  "updateAvailable": false
}
JSONEOF
        return
    fi

    LATEST=$(echo "$REMOTE_JSON" | jq -r '.infrastructureVersion // "unknown"' 2>/dev/null)

    if [ "$LATEST" = "unknown" ] || [ -z "$LATEST" ]; then
        cat << JSONEOF
{
  "error": true,
  "message": "Could not parse remote version",
  "current": "$CURRENT",
  "latest": null,
  "updateAvailable": false
}
JSONEOF
        return
    fi

    # Compare versions
    if [ "$CURRENT" = "$LATEST" ]; then
        cat << JSONEOF
{
  "error": false,
  "current": "$CURRENT",
  "latest": "$LATEST",
  "updateAvailable": false
}
JSONEOF
    else
        # Get changelog for latest version
        CHANGELOG=$(echo "$REMOTE_JSON" | jq -r --arg v "$LATEST" '.changelog[$v] // "No changelog available"' 2>/dev/null)

        cat << JSONEOF
{
  "error": false,
  "current": "$CURRENT",
  "latest": "$LATEST",
  "updateAvailable": true,
  "changelog": $(echo "$CHANGELOG" | jq -R -s '.')
}
JSONEOF
    fi
}

check_update
