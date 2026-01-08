#!/bin/bash
# Agents Triggers Script - JSON output for Claude to format

collect_agents() {
    AGENTS_DIR=".claude/agents"
    TRIGGERS_FILE=".claude/agents/triggers.json"

    # Check if triggers.json exists
    HAS_TRIGGERS="false"
    TRIGGERS_DATA="{}"
    if [ -f "$TRIGGERS_FILE" ]; then
        HAS_TRIGGERS="true"
        TRIGGERS_DATA=$(cat "$TRIGGERS_FILE")
    fi

    # Find all agents from .md files
    AGENTS="[]"
    if [ -d "$AGENTS_DIR" ]; then
        AGENTS=$(find "$AGENTS_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | while read agent_file; do
            agent_name=$(basename "$agent_file" .md)

            # Extract frontmatter only (between first --- and second ---)
            # Use awk for cross-platform compatibility
            frontmatter=$(awk '/^---$/{if(++c==1)next; if(c==2)exit} c==1' "$agent_file")

            # Extract name and description from frontmatter only
            name=$(echo "$frontmatter" | grep "^name:" | head -1 | sed 's/^name: *//' | tr -d '"')
            desc=$(echo "$frontmatter" | grep "^description:" | head -1 | sed 's/^description: *//' | cut -c1-200)

            # Use filename if no name in frontmatter
            [ -z "$name" ] && name="$agent_name"

            # Get triggers from triggers.json if available
            if [ "$HAS_TRIGGERS" = "true" ]; then
                triggers=$(echo "$TRIGGERS_DATA" | jq -r --arg n "$name" '.agents[$n] // empty')
                if [ -n "$triggers" ] && [ "$triggers" != "null" ]; then
                    keywords=$(echo "$triggers" | jq -r '.keywords // []')
                    phrases=$(echo "$triggers" | jq -r '.phrases // []')
                    file_patterns=$(echo "$triggers" | jq -r '.file_patterns // []')
                    jq -n --arg n "$name" --arg d "$desc" --argjson k "$keywords" --argjson p "$phrases" --argjson f "$file_patterns" \
                        '{name: $n, description: $d, keywords: $k, phrases: $p, file_patterns: $f}'
                else
                    jq -n --arg n "$name" --arg d "$desc" '{name: $n, description: $d, keywords: [], phrases: [], file_patterns: []}'
                fi
            else
                jq -n --arg n "$name" --arg d "$desc" '{name: $n, description: $d, keywords: [], phrases: [], file_patterns: []}'
            fi
        done | jq -s '.')
    fi

    AGENT_COUNT=$(echo "$AGENTS" | jq 'length')

    cat << JSONEOF
{
  "has_triggers_config": $HAS_TRIGGERS,
  "triggers_file": "$TRIGGERS_FILE",
  "count": $AGENT_COUNT,
  "agents": $AGENTS
}
JSONEOF
}

collect_agents
