#!/bin/bash
# Generate trigger reference from triggers.json files
# Output: .claude/rules/trigger-reference.md

CLAUDE_DIR=".claude"
SKILLS_TRIGGERS="$CLAUDE_DIR/skills/triggers.json"
AGENTS_TRIGGERS="$CLAUDE_DIR/agents/triggers.json"
OUTPUT_FILE="$CLAUDE_DIR/rules/trigger-reference.md"

generate_reference() {
    mkdir -p "$CLAUDE_DIR/rules"

    cat << 'HEADER'
# Trigger Reference

> Auto-generated from triggers.json - DO NOT EDIT MANUALLY

Use this reference to match user requests to the appropriate skill or agent.

## Skill Triggers

When the user's request contains these keywords or phrases, invoke the corresponding skill.

HEADER

    # Generate skills section
    if [ -f "$SKILLS_TRIGGERS" ]; then
        jq -r '
            .skills | to_entries[] |
            "### \(.key)\n" +
            "**Keywords:** " + (if (.value.keywords | length) > 0 then (.value.keywords | join(", ")) else "none" end) + "\n" +
            "**Phrases:** " + (if (.value.phrases | length) > 0 then (.value.phrases | map("\"" + . + "\"") | join(", ")) else "none" end) + "\n"
        ' "$SKILLS_TRIGGERS" 2>/dev/null
    else
        echo "*No skills/triggers.json found*"
        echo ""
    fi

    cat << 'MIDDLE'

## Agent Triggers

When the user's request contains these keywords or phrases, consider delegating to the corresponding agent.

MIDDLE

    # Generate agents section
    if [ -f "$AGENTS_TRIGGERS" ]; then
        jq -r '
            .agents | to_entries[] |
            "### \(.key)\n" +
            "**Keywords:** " + (if (.value.keywords | length) > 0 then (.value.keywords | join(", ")) else "none" end) + "\n" +
            "**Phrases:** " + (if (.value.phrases | length) > 0 then (.value.phrases | map("\"" + . + "\"") | join(", ")) else "none" end) + "\n" +
            (if (.value.file_patterns | length) > 0 then "**File patterns:** " + (.value.file_patterns | join(", ")) + "\n" else "" end)
        ' "$AGENTS_TRIGGERS" 2>/dev/null
    else
        echo "*No agents/triggers.json found*"
        echo ""
    fi

    cat << 'FOOTER'

## Matching Rules

1. **Case-insensitive** - match regardless of capitalization
2. **Partial match** - trigger phrase can be part of larger request
3. **Multiple matches** - if multiple skills/agents match, prefer the most specific
4. **Skills vs Agents** - Skills run in main context; Agents run as subagents via Task tool

## Invocation

- **Skills**: Use the `Skill` tool with the skill name
- **Agents**: Use the `Task` tool with `subagent_type` matching the agent name
FOOTER
}

# Generate and save
generate_reference > "$OUTPUT_FILE"
echo "Generated: $OUTPUT_FILE"
