#!/bin/bash
# Generate trigger reference JSON from triggers.json files
# Output: .claude/rules/triggers/reference.json

CLAUDE_DIR=".claude"
SKILLS_TRIGGERS="$CLAUDE_DIR/skills/triggers.json"
AGENTS_TRIGGERS="$CLAUDE_DIR/agents/triggers.json"
OUTPUT_JSON="$CLAUDE_DIR/rules/triggers/reference.json"

generate_reference_json() {
    mkdir -p "$CLAUDE_DIR/rules/triggers"

    # Merge skills and agents triggers into single JSON
    jq -s '{
        version: "1.0.0",
        generated: "Auto-generated - DO NOT EDIT MANUALLY",
        skills: (.[0].skills // {}),
        agents: (.[1].agents // {}),
        matchingRules: {
            caseSensitive: false,
            partialMatch: true,
            preferSpecific: true,
            skillsRunInMain: true,
            agentsRunAsSubagents: true
        }
    }' "$SKILLS_TRIGGERS" "$AGENTS_TRIGGERS" 2>/dev/null || echo '{"error": "Failed to generate JSON"}'
}

# Generate and save JSON
generate_reference_json > "$OUTPUT_JSON"
echo "Generated: $OUTPUT_JSON"
