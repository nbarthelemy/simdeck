#!/bin/bash
# Permission Audit Script - JSON output for Claude to format
# Compares detected tech stack with configured permissions

audit_permissions() {
    # Check required files
    if [ ! -f ".claude/settings.json" ]; then
        cat << JSONEOF
{
  "error": true,
  "message": "settings.json not found. Run /claudenv first."
}
JSONEOF
        return
    fi

    # Get current permissions
    PERMISSIONS=$(jq -r '.permissions.allow // []' .claude/settings.json 2>/dev/null)
    TOTAL_PERMS=$(echo "$PERMISSIONS" | jq 'length')

    # Check if project-context.json exists
    HAS_CONTEXT="false"
    LANGUAGES="[]"
    FRAMEWORKS="[]"
    PKG_MANAGER="unknown"

    if [ -f ".claude/project-context.json" ]; then
        HAS_CONTEXT="true"
        LANGUAGES=$(jq '.languages // []' .claude/project-context.json 2>/dev/null)
        FRAMEWORKS=$(jq '.frameworks // []' .claude/project-context.json 2>/dev/null)
        PKG_MANAGER=$(jq -r '.packageManager // "unknown"' .claude/project-context.json 2>/dev/null)
    fi

    # Define tech-to-permission mappings (inline for simplicity)
    # Format: tech_indicator:permission_pattern:file_check
    declare -a TECH_MAPPINGS=(
        "python:python:*.py"
        "python:pip:requirements.txt"
        "python:pytest:pytest.ini"
        "node:npm:package.json"
        "node:npx:package.json"
        "node:node:package.json"
        "go:go:go.mod"
        "rust:cargo:Cargo.toml"
        "ruby:bundle:Gemfile"
        "ruby:gem:Gemfile"
        "php:composer:composer.json"
        "java:mvn:pom.xml"
        "java:gradle:build.gradle"
        "docker:docker:Dockerfile"
        "terraform:terraform:*.tf"
    )

    # Build arrays for unused, matching, missing
    UNUSED_JSON="[]"
    MATCHING_JSON="[]"
    MISSING_JSON="[]"

    # Check each tech mapping
    for mapping in "${TECH_MAPPINGS[@]}"; do
        IFS=':' read -r tech cmd file_pattern <<< "$mapping"

        # Check if permission exists
        HAS_PERM=$(echo "$PERMISSIONS" | jq --arg cmd "Bash($cmd:*)" 'any(. == $cmd)')

        # Check if tech is present (simple file check)
        TECH_PRESENT="false"
        if [[ "$file_pattern" == *"*"* ]]; then
            # Glob pattern
            if find . -maxdepth 3 -name "${file_pattern#\*}" 2>/dev/null | head -1 | grep -q .; then
                TECH_PRESENT="true"
            fi
        else
            # Exact file
            if [ -f "$file_pattern" ]; then
                TECH_PRESENT="true"
            fi
        fi

        # Categorize
        if [ "$HAS_PERM" = "true" ] && [ "$TECH_PRESENT" = "true" ]; then
            MATCHING_JSON=$(echo "$MATCHING_JSON" | jq --arg cmd "$cmd" --arg file "$file_pattern" '. + [{"command": $cmd, "reason": $file}]')
        elif [ "$HAS_PERM" = "true" ] && [ "$TECH_PRESENT" = "false" ]; then
            UNUSED_JSON=$(echo "$UNUSED_JSON" | jq --arg cmd "$cmd" --arg file "$file_pattern" '. + [{"command": $cmd, "expectedFile": $file}]')
        elif [ "$HAS_PERM" = "false" ] && [ "$TECH_PRESENT" = "true" ]; then
            MISSING_JSON=$(echo "$MISSING_JSON" | jq --arg cmd "$cmd" --arg file "$file_pattern" '. + [{"command": $cmd, "detectedFile": $file}]')
        fi
    done

    # Count core permissions (always needed - rough estimate)
    CORE_COUNT=$(echo "$PERMISSIONS" | jq '[.[] | select(test("git|cat|ls|find|grep|head|tail|echo|mkdir|cp|mv|rm|chmod|jq|curl"))] | length')
    TECH_COUNT=$((TOTAL_PERMS - CORE_COUNT))

    cat << JSONEOF
{
  "error": false,
  "hasProjectContext": $HAS_CONTEXT,
  "summary": {
    "totalPermissions": $TOTAL_PERMS,
    "corePermissions": $CORE_COUNT,
    "techPermissions": $TECH_COUNT
  },
  "detectedStack": {
    "languages": $LANGUAGES,
    "frameworks": $FRAMEWORKS,
    "packageManager": "$PKG_MANAGER"
  },
  "unused": $UNUSED_JSON,
  "matching": $MATCHING_JSON,
  "missing": $MISSING_JSON
}
JSONEOF
}

audit_permissions
