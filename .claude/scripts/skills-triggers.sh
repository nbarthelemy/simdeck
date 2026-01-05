#!/bin/bash
# Skills Triggers Script - JSON output for Claude to format

collect_skills() {
    SKILLS_DIR=".claude/skills"

    # Find all skills
    SKILLS="[]"
    if [ -d "$SKILLS_DIR" ]; then
        SKILLS=$(find "$SKILLS_DIR" -name "SKILL.md" 2>/dev/null | while read skill_file; do
            skill_dir=$(dirname "$skill_file")
            skill_name=$(basename "$skill_dir")

            # Extract frontmatter fields
            name=$(grep "^name:" "$skill_file" 2>/dev/null | sed 's/^name: *//' | tr -d '"')
            desc=$(grep "^description:" "$skill_file" 2>/dev/null | sed 's/^description: *//' | head -c 200)

            # Use directory name if no name in frontmatter
            [ -z "$name" ] && name="$skill_name"

            # Output as JSON object
            jq -n --arg n "$name" --arg d "$desc" '{name: $n, description: $d}'
        done | jq -s '.')
    fi

    SKILL_COUNT=$(echo "$SKILLS" | jq 'length')

    cat << JSONEOF
{
  "count": $SKILL_COUNT,
  "skills": $SKILLS
}
JSONEOF
}

collect_skills
