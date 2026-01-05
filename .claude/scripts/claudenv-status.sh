#!/bin/bash
# Claudenv Status Script - JSON output for Claude to format

# Collect all data into JSON
output_json() {
    # Project context
    if [ -f ".claude/project-context.json" ]; then
        LANGS=$(jq -r '.languages // [] | join(", ")' .claude/project-context.json 2>/dev/null)
        FRAMEWORKS=$(jq -r '.frameworks // [] | join(", ")' .claude/project-context.json 2>/dev/null)
        PKG_MGR=$(jq -r '.packageManager // ""' .claude/project-context.json 2>/dev/null)
        STACK_DETECTED="true"
    else
        LANGS=""
        FRAMEWORKS=""
        PKG_MGR=""
        STACK_DETECTED="false"
    fi

    # Spec
    [ -f ".claude/SPEC.md" ] && SPEC_EXISTS="true" || SPEC_EXISTS="false"

    # Counts
    SKILL_COUNT=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
    AGENT_COUNT=$(find .claude/agents -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
    CMD_COUNT=$(find .claude/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

    # Hooks
    HOOK_SESSION=$(jq -e '.hooks.SessionStart' .claude/settings.json >/dev/null 2>&1 && echo "true" || echo "false")
    HOOK_TOOL=$(jq -e '.hooks.PostToolUse' .claude/settings.json >/dev/null 2>&1 && echo "true" || echo "false")
    HOOK_STOP=$(jq -e '.hooks.Stop' .claude/settings.json >/dev/null 2>&1 && echo "true" || echo "false")

    # Learning
    OBS_COUNT=$(grep -c "^## " .claude/learning/observations.md 2>/dev/null) || OBS_COUNT=0
    PENDING_SKILLS=$(grep -c "^### " .claude/learning/pending-skills.md 2>/dev/null) || PENDING_SKILLS=0
    PENDING_AGENTS=$(grep -c "^### " .claude/learning/pending-agents.md 2>/dev/null) || PENDING_AGENTS=0
    PENDING_CMDS=$(grep -c "^### " .claude/learning/pending-commands.md 2>/dev/null) || PENDING_CMDS=0
    PENDING_HOOKS=$(grep -c "^### " .claude/learning/pending-hooks.md 2>/dev/null) || PENDING_HOOKS=0

    # Permissions
    ALLOW_COUNT=$(jq -r '.permissions.allow // [] | length' .claude/settings.json 2>/dev/null)
    DENY_COUNT=$(jq -r '.permissions.deny // [] | length' .claude/settings.json 2>/dev/null)

    # Health
    SETTINGS_VALID=$(jq empty .claude/settings.json 2>/dev/null && echo "true" || echo "false")
    SCRIPTS_EXEC=$([ $(find .claude/scripts -name "*.sh" ! -perm -u+x 2>/dev/null | wc -l | tr -d ' ') -eq 0 ] && echo "true" || echo "false")

    # Version
    VERSION=$(jq -r '.infrastructureVersion // "unknown"' .claude/version.json 2>/dev/null)

    # Output JSON
    cat << JSONEOF
{
  "version": "$VERSION",
  "stack": {
    "detected": $STACK_DETECTED,
    "languages": "$LANGS",
    "frameworks": "$FRAMEWORKS",
    "packageManager": "$PKG_MGR"
  },
  "spec": $SPEC_EXISTS,
  "counts": {
    "skills": $SKILL_COUNT,
    "agents": $AGENT_COUNT,
    "commands": $CMD_COUNT
  },
  "hooks": {
    "sessionStart": $HOOK_SESSION,
    "postToolUse": $HOOK_TOOL,
    "stop": $HOOK_STOP
  },
  "learning": {
    "observations": $OBS_COUNT,
    "pendingSkills": $PENDING_SKILLS,
    "pendingAgents": $PENDING_AGENTS,
    "pendingCommands": $PENDING_CMDS,
    "pendingHooks": $PENDING_HOOKS
  },
  "permissions": {
    "allowed": $ALLOW_COUNT,
    "denied": $DENY_COUNT
  },
  "health": {
    "settingsValid": $SETTINGS_VALID,
    "scriptsExecutable": $SCRIPTS_EXEC
  }
}
JSONEOF
}

output_json
