#!/bin/bash
# Skills Triggers Script - JSON output for Claude to format

collect_skills() {
    SKILLS_DIR=".claude/skills"
    TRIGGERS_FILE=".claude/skills/triggers.json"

    # Check if triggers.json exists
    HAS_TRIGGERS="false"
    TRIGGERS_DATA="{}"
    if [ -f "$TRIGGERS_FILE" ]; then
        HAS_TRIGGERS="true"
        TRIGGERS_DATA=$(cat "$TRIGGERS_FILE")
    fi

    # Find all skills from SKILL.md files
    SKILLS="[]"
    if [ -d "$SKILLS_DIR" ]; then
        SKILLS=$(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | while read skill_file; do
            skill_dir=$(dirname "$skill_file")
            skill_name=$(basename "$skill_dir")

            # Extract frontmatter only (between first --- and second ---)
            # Use awk for cross-platform compatibility
            frontmatter=$(awk '/^---$/{if(++c==1)next; if(c==2)exit} c==1' "$skill_file")

            # Extract name and description from frontmatter only
            name=$(echo "$frontmatter" | grep "^name:" | head -1 | sed 's/^name: *//' | tr -d '"')
            desc=$(echo "$frontmatter" | grep "^description:" | head -1 | sed 's/^description: *//' | cut -c1-200)

            # Use directory name if no name in frontmatter
            [ -z "$name" ] && name="$skill_name"

            # Get triggers from triggers.json if available
            if [ "$HAS_TRIGGERS" = "true" ]; then
                triggers=$(echo "$TRIGGERS_DATA" | jq -r --arg n "$name" '.skills[$n] // empty')
                if [ -n "$triggers" ] && [ "$triggers" != "null" ]; then
                    keywords=$(echo "$triggers" | jq -r '.keywords // []')
                    phrases=$(echo "$triggers" | jq -r '.phrases // []')
                    jq -n --arg n "$name" --arg d "$desc" --argjson k "$keywords" --argjson p "$phrases" \
                        '{name: $n, description: $d, keywords: $k, phrases: $p}'
                else
                    jq -n --arg n "$name" --arg d "$desc" '{name: $n, description: $d, keywords: [], phrases: []}'
                fi
            else
                jq -n --arg n "$name" --arg d "$desc" '{name: $n, description: $d, keywords: [], phrases: []}'
            fi
        done | jq -s '.')
    fi

    SKILL_COUNT=$(echo "$SKILLS" | jq 'length')

    cat << JSONEOF
{
  "has_triggers_config": $HAS_TRIGGERS,
  "triggers_file": "$TRIGGERS_FILE",
  "count": $SKILL_COUNT,
  "skills": $SKILLS
}
JSONEOF
}

collect_skills
