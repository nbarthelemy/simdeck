#!/bin/bash
# Health Check Script - JSON output for Claude to format

collect_health() {
    # Settings
    SETTINGS_EXISTS=$([ -f ".claude/settings.json" ] && echo "true" || echo "false")
    SETTINGS_VALID="false"
    PERMISSIONS_OK="false"
    HOOKS_OK="false"

    if [ "$SETTINGS_EXISTS" = "true" ]; then
        jq empty .claude/settings.json 2>/dev/null && SETTINGS_VALID="true"
        jq -e '.permissions' .claude/settings.json >/dev/null 2>&1 && PERMISSIONS_OK="true"
        jq -e '.hooks' .claude/settings.json >/dev/null 2>&1 && HOOKS_OK="true"
    fi

    # Skills
    SKILL_TOTAL=$(find .claude/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
    SKILL_VALID=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
    SKILL_MISSING=$((SKILL_TOTAL - SKILL_VALID))

    # Commands
    CMD_TOTAL=$(find .claude/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    CMD_EMPTY=$(find .claude/commands -name "*.md" -empty 2>/dev/null | wc -l | tr -d ' ')

    # Scripts
    SCRIPT_TOTAL=$(find .claude/scripts -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
    SCRIPT_NOT_EXEC=$(find .claude/scripts -name "*.sh" ! -perm -u+x 2>/dev/null | wc -l | tr -d ' ')

    # Learning files
    LEARNING_FILES=(".claude/learning/observations.md" ".claude/learning/pending-skills.md" ".claude/learning/pending-agents.md" ".claude/learning/pending-commands.md" ".claude/learning/pending-hooks.md")
    LEARNING_MISSING=0
    for f in "${LEARNING_FILES[@]}"; do
        [ ! -f "$f" ] && LEARNING_MISSING=$((LEARNING_MISSING + 1))
    done

    # Project context
    CONTEXT_EXISTS=$([ -f ".claude/project-context.json" ] && echo "true" || echo "false")
    CONTEXT_VALID="false"
    [ "$CONTEXT_EXISTS" = "true" ] && jq empty .claude/project-context.json 2>/dev/null && CONTEXT_VALID="true"

    # Version
    VERSION_EXISTS=$([ -f ".claude/version.json" ] && echo "true" || echo "false")
    VERSION_VALID="false"
    VERSION=""
    if [ "$VERSION_EXISTS" = "true" ]; then
        jq empty .claude/version.json 2>/dev/null && VERSION_VALID="true"
        VERSION=$(jq -r '.infrastructureVersion // ""' .claude/version.json 2>/dev/null)
    fi

    cat << JSONEOF
{
  "settings": {
    "exists": $SETTINGS_EXISTS,
    "valid": $SETTINGS_VALID,
    "permissionsConfigured": $PERMISSIONS_OK,
    "hooksConfigured": $HOOKS_OK
  },
  "skills": {
    "total": $SKILL_TOTAL,
    "valid": $SKILL_VALID,
    "missingSKILL": $SKILL_MISSING
  },
  "commands": {
    "total": $CMD_TOTAL,
    "empty": $CMD_EMPTY
  },
  "scripts": {
    "total": $SCRIPT_TOTAL,
    "notExecutable": $SCRIPT_NOT_EXEC
  },
  "learning": {
    "filesMissing": $LEARNING_MISSING
  },
  "context": {
    "exists": $CONTEXT_EXISTS,
    "valid": $CONTEXT_VALID
  },
  "version": {
    "exists": $VERSION_EXISTS,
    "valid": $VERSION_VALID,
    "value": "$VERSION"
  }
}
JSONEOF
}

collect_health
