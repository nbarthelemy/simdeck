#!/bin/bash
# Learn Review Script - JSON output for Claude to format

LEARNING_DIR=".claude/learning"

collect_learnings() {
    # Count pending items
    PENDING_SKILLS=$(grep -c "^### " "$LEARNING_DIR/pending-skills.md" 2>/dev/null) || PENDING_SKILLS=0
    PENDING_AGENTS=$(grep -c "^### " "$LEARNING_DIR/pending-agents.md" 2>/dev/null) || PENDING_AGENTS=0
    PENDING_COMMANDS=$(grep -c "^### " "$LEARNING_DIR/pending-commands.md" 2>/dev/null) || PENDING_COMMANDS=0
    PENDING_HOOKS=$(grep -c "^### " "$LEARNING_DIR/pending-hooks.md" 2>/dev/null) || PENDING_HOOKS=0

    # Get skill names
    SKILL_NAMES=$(grep "^### " "$LEARNING_DIR/pending-skills.md" 2>/dev/null | sed 's/^### //' | jq -R -s -c 'split("\n") | map(select(length > 0))')
    [ -z "$SKILL_NAMES" ] && SKILL_NAMES="[]"

    # Get agent names
    AGENT_NAMES=$(grep "^### " "$LEARNING_DIR/pending-agents.md" 2>/dev/null | sed 's/^### //' | jq -R -s -c 'split("\n") | map(select(length > 0))')
    [ -z "$AGENT_NAMES" ] && AGENT_NAMES="[]"

    # Get command names
    CMD_NAMES=$(grep "^### " "$LEARNING_DIR/pending-commands.md" 2>/dev/null | sed 's/^### //' | jq -R -s -c 'split("\n") | map(select(length > 0))')
    [ -z "$CMD_NAMES" ] && CMD_NAMES="[]"

    # Get hook names
    HOOK_NAMES=$(grep "^### " "$LEARNING_DIR/pending-hooks.md" 2>/dev/null | sed 's/^### //' | jq -R -s -c 'split("\n") | map(select(length > 0))')
    [ -z "$HOOK_NAMES" ] && HOOK_NAMES="[]"

    # Pattern tracking
    DIR_PATTERNS=0
    EXT_PATTERNS=0
    if [ -f "$LEARNING_DIR/patterns.json" ]; then
        DIR_PATTERNS=$(jq '.directory_patterns | length' "$LEARNING_DIR/patterns.json" 2>/dev/null) || DIR_PATTERNS=0
        EXT_PATTERNS=$(jq '.extension_patterns | length' "$LEARNING_DIR/patterns.json" 2>/dev/null) || EXT_PATTERNS=0
    fi

    TOTAL=$((PENDING_SKILLS + PENDING_AGENTS + PENDING_COMMANDS + PENDING_HOOKS))

    cat << JSONEOF
{
  "total": $TOTAL,
  "skills": {
    "count": $PENDING_SKILLS,
    "names": $SKILL_NAMES
  },
  "agents": {
    "count": $PENDING_AGENTS,
    "names": $AGENT_NAMES
  },
  "commands": {
    "count": $PENDING_COMMANDS,
    "names": $CMD_NAMES
  },
  "hooks": {
    "count": $PENDING_HOOKS,
    "names": $HOOK_NAMES
  },
  "patterns": {
    "directories": $DIR_PATTERNS,
    "extensions": $EXT_PATTERNS
  }
}
JSONEOF
}

collect_learnings
