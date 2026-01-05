#!/bin/bash
# Debug Hooks Script - JSON output for Claude to format

collect_hooks() {
    SETTINGS_FILE=".claude/settings.json"

    # Check settings exists
    SETTINGS_EXISTS=$([ -f "$SETTINGS_FILE" ] && echo "true" || echo "false")

    # Get hooks config
    HOOKS_JSON="{}"
    if [ "$SETTINGS_EXISTS" = "true" ]; then
        HOOKS_JSON=$(jq '.hooks // {}' "$SETTINGS_FILE" 2>/dev/null)
    fi

    # Count hook types
    SESSION_START=$(jq -r '.SessionStart | if . then (if type == "array" then length else 1 end) else 0 end' <<< "$HOOKS_JSON" 2>/dev/null) || SESSION_START=0
    POST_TOOL=$(jq -r '.PostToolUse | if . then (if type == "array" then length else 1 end) else 0 end' <<< "$HOOKS_JSON" 2>/dev/null) || POST_TOOL=0
    STOP=$(jq -r '.Stop | if . then (if type == "array" then length else 1 end) else 0 end' <<< "$HOOKS_JSON" 2>/dev/null) || STOP=0

    # Check scripts
    SCRIPT_TOTAL=$(find .claude/scripts -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')
    SCRIPT_EXEC=$(find .claude/scripts -name "*.sh" -perm -u+x 2>/dev/null | wc -l | tr -d ' ')
    SCRIPT_NOT_EXEC=$((SCRIPT_TOTAL - SCRIPT_EXEC))

    # Get script names
    SCRIPTS=$(find .claude/scripts -name "*.sh" 2>/dev/null | xargs -I {} basename {} | jq -R -s -c 'split("\n") | map(select(length > 0))')
    [ -z "$SCRIPTS" ] && SCRIPTS="[]"

    # Check log
    LOG_EXISTS=$([ -f ".claude/logs/hook-executions.log" ] && echo "true" || echo "false")
    RECENT_ERRORS=0
    if [ "$LOG_EXISTS" = "true" ]; then
        RECENT_ERRORS=$(grep -c "ERROR\|FAIL" .claude/logs/hook-executions.log 2>/dev/null) || RECENT_ERRORS=0
    fi

    cat << JSONEOF
{
  "settingsExists": $SETTINGS_EXISTS,
  "hooks": {
    "sessionStart": $SESSION_START,
    "postToolUse": $POST_TOOL,
    "stop": $STOP
  },
  "scripts": {
    "total": $SCRIPT_TOTAL,
    "executable": $SCRIPT_EXEC,
    "notExecutable": $SCRIPT_NOT_EXEC,
    "names": $SCRIPTS
  },
  "log": {
    "exists": $LOG_EXISTS,
    "recentErrors": $RECENT_ERRORS
  }
}
JSONEOF
}

collect_hooks
