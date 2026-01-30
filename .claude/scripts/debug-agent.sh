#!/bin/bash
# Debug Agent/Skill Script - JSON output for Claude to format
# Validates skill configuration and checks for issues

debug_agent() {
    SKILL_NAME="$1"

    if [ -z "$SKILL_NAME" ]; then
        cat << JSONEOF
{
  "error": true,
  "message": "Usage: debug-agent.sh <skill-name>"
}
JSONEOF
        return
    fi

    # Check skill location (skills or agents directory)
    SKILL_DIR=""
    SKILL_TYPE=""

    if [ -d ".claude/skills/claudenv/$SKILL_NAME" ]; then
        SKILL_DIR=".claude/skills/claudenv/$SKILL_NAME"
        SKILL_TYPE="skill"
    elif [ -d ".claude/skills/workspace/$SKILL_NAME" ]; then
        SKILL_DIR=".claude/skills/workspace/$SKILL_NAME"
        SKILL_TYPE="skill"
    elif [ -d ".claude/agents/$SKILL_NAME" ]; then
        SKILL_DIR=".claude/agents/$SKILL_NAME"
        SKILL_TYPE="agent"
    fi

    if [ -z "$SKILL_DIR" ]; then
        cat << JSONEOF
{
  "error": true,
  "message": "Skill or agent '$SKILL_NAME' not found",
  "searchedLocations": [".claude/skills/claudenv/$SKILL_NAME", ".claude/skills/workspace/$SKILL_NAME", ".claude/agents/$SKILL_NAME"]
}
JSONEOF
        return
    fi

    # Check for SKILL.md
    SKILL_FILE="$SKILL_DIR/SKILL.md"
    HAS_SKILL_MD="false"
    [ -f "$SKILL_FILE" ] && HAS_SKILL_MD="true"

    # For agents, also check for .md file directly
    if [ "$HAS_SKILL_MD" = "false" ] && [ -f "$SKILL_DIR.md" ]; then
        SKILL_FILE="$SKILL_DIR.md"
        HAS_SKILL_MD="true"
        SKILL_DIR=$(dirname "$SKILL_FILE")
    fi

    # If still not found, check if it's a direct agent file
    if [ "$HAS_SKILL_MD" = "false" ] && [ -f ".claude/agents/$SKILL_NAME.md" ]; then
        SKILL_FILE=".claude/agents/$SKILL_NAME.md"
        SKILL_DIR=".claude/agents"
        HAS_SKILL_MD="true"
        SKILL_TYPE="agent"
    fi

    if [ "$HAS_SKILL_MD" = "false" ]; then
        cat << JSONEOF
{
  "error": true,
  "message": "No SKILL.md or agent file found in $SKILL_DIR",
  "location": "$SKILL_DIR",
  "type": "$SKILL_TYPE"
}
JSONEOF
        return
    fi

    # List files in skill directory
    FILES_JSON="[]"
    if [ -d "$SKILL_DIR" ]; then
        while IFS= read -r file; do
            [ -n "$file" ] && FILES_JSON=$(echo "$FILES_JSON" | jq --arg f "$(basename "$file")" '. + [$f]')
        done < <(find "$SKILL_DIR" -type f -name "*" 2>/dev/null)
    else
        FILES_JSON='["'$(basename "$SKILL_FILE")'"]'
    fi

    # Parse frontmatter from SKILL.md
    FRONTMATTER=$(sed -n '/^---$/,/^---$/p' "$SKILL_FILE" | sed '1d;$d')

    # Extract fields
    NAME=$(echo "$FRONTMATTER" | grep -E "^name:" | sed 's/name:[[:space:]]*//')
    DESCRIPTION=$(echo "$FRONTMATTER" | grep -E "^description:" | sed 's/description:[[:space:]]*//')
    ALLOWED_TOOLS=$(echo "$FRONTMATTER" | grep -E "^allowed-tools:" | sed 's/allowed-tools:[[:space:]]*//')
    MODEL=$(echo "$FRONTMATTER" | grep -E "^model:" | sed 's/model:[[:space:]]*//')

    # Validate frontmatter
    ISSUES_JSON="[]"

    [ -z "$NAME" ] && ISSUES_JSON=$(echo "$ISSUES_JSON" | jq '. + [{"type": "error", "message": "Missing name in frontmatter"}]')
    [ -z "$DESCRIPTION" ] && ISSUES_JSON=$(echo "$ISSUES_JSON" | jq '. + [{"type": "error", "message": "Missing description in frontmatter"}]')
    [ -z "$ALLOWED_TOOLS" ] && ISSUES_JSON=$(echo "$ISSUES_JSON" | jq '. + [{"type": "warning", "message": "No allowed-tools specified"}]')

    # Check description length (for auto-invoke)
    DESC_LEN=${#DESCRIPTION}
    if [ "$DESC_LEN" -gt 1024 ]; then
        ISSUES_JSON=$(echo "$ISSUES_JSON" | jq --arg len "$DESC_LEN" '. + [{"type": "warning", "message": "Description exceeds 1024 chars (\($len)), may affect auto-invoke"}]')
    fi

    # Extract trigger keywords from description (simple approach)
    TRIGGERS_JSON="[]"
    # Common trigger words
    for word in "when" "use" "for" "if" "detect" "create" "build" "setup" "install" "configure"; do
        if echo "$DESCRIPTION" | grep -qi "$word"; then
            # Extract phrase around the word
            PHRASE=$(echo "$DESCRIPTION" | grep -oi "[^,.(]*$word[^,.)]*" | head -1 | tr -d '\n')
            [ -n "$PHRASE" ] && TRIGGERS_JSON=$(echo "$TRIGGERS_JSON" | jq --arg t "$PHRASE" '. + [$t]')
        fi
    done

    # Check recent invocations in logs
    INVOCATIONS_JSON="[]"
    if [ -d ".claude/logs" ]; then
        # Look for skill mentions in logs
        while IFS= read -r line; do
            [ -n "$line" ] && INVOCATIONS_JSON=$(echo "$INVOCATIONS_JSON" | jq --arg l "$line" '. + [$l]')
        done < <(grep -l "$SKILL_NAME" .claude/logs/*.log 2>/dev/null | head -5 | xargs -I {} basename {} 2>/dev/null)
    fi

    # Check tool permissions
    TOOLS_STATUS_JSON="[]"
    if [ -n "$ALLOWED_TOOLS" ] && [ -f ".claude/settings.json" ]; then
        IFS=',' read -ra TOOLS <<< "$ALLOWED_TOOLS"
        ALLOWED_PERMS=$(jq -r '.permissions.allow // []' .claude/settings.json 2>/dev/null)

        for tool in "${TOOLS[@]}"; do
            tool=$(echo "$tool" | tr -d ' ')
            # Simple check - see if tool pattern exists in permissions
            IS_ALLOWED="unknown"
            if echo "$ALLOWED_PERMS" | grep -qi "$tool"; then
                IS_ALLOWED="allowed"
            elif echo "$tool" | grep -qE "^(Read|Write|Edit|Glob|Grep|Task|WebFetch|WebSearch)$"; then
                IS_ALLOWED="allowed"  # Built-in tools
            fi
            TOOLS_STATUS_JSON=$(echo "$TOOLS_STATUS_JSON" | jq --arg t "$tool" --arg s "$IS_ALLOWED" '. + [{"tool": $t, "status": $s}]')
        done
    fi

    ISSUE_COUNT=$(echo "$ISSUES_JSON" | jq 'length')

    cat << JSONEOF
{
  "error": false,
  "name": "$SKILL_NAME",
  "type": "$SKILL_TYPE",
  "location": "$SKILL_DIR",
  "files": $FILES_JSON,
  "frontmatter": {
    "name": $([ -n "$NAME" ] && echo "\"$NAME\"" || echo "null"),
    "description": $([ -n "$DESCRIPTION" ] && echo "\"$DESCRIPTION\"" || echo "null"),
    "allowedTools": $([ -n "$ALLOWED_TOOLS" ] && echo "\"$ALLOWED_TOOLS\"" || echo "null"),
    "model": $([ -n "$MODEL" ] && echo "\"$MODEL\"" || echo "null")
  },
  "triggers": $TRIGGERS_JSON,
  "toolsStatus": $TOOLS_STATUS_JSON,
  "recentLogs": $INVOCATIONS_JSON,
  "issues": $ISSUES_JSON,
  "issueCount": $ISSUE_COUNT
}
JSONEOF
}

debug_agent "$1"
