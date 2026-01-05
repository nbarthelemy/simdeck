#!/bin/bash
# Propose Skill Script
# Writes skill proposals to pending-skills.md when patterns reach threshold
# Called by session-end.sh when thresholds are detected

LEARNING_DIR=".claude/learning"
PENDING_FILE="$LEARNING_DIR/pending-skills.md"
PATTERNS_FILE="$LEARNING_DIR/patterns.json"
THRESHOLDS_FILE="$LEARNING_DIR/.thresholds_reached"
PROPOSED_FILE="$LEARNING_DIR/.skills_proposed"

# Ensure directories exist
mkdir -p "$LEARNING_DIR"
touch "$PROPOSED_FILE"

# Initialize pending file if missing
if [ ! -f "$PENDING_FILE" ]; then
    cat > "$PENDING_FILE" << 'EOF'
# Pending Skill Proposals

Skills suggested based on observed development patterns. Review and implement with `/learn:implement`.

EOF
fi

# Convert directory path to skill name
dir_to_skill_name() {
    local dir="$1"
    local base=$(basename "$dir")
    local parent=$(basename "$(dirname "$dir")")

    if [ "$parent" = "." ] || [ "$parent" = "src" ]; then
        echo "${base}-operations"
    else
        echo "${base}-${parent}"
    fi
}

# Create a skill proposal
propose_skill() {
    local dir_path="$1"
    local skill_name=$(dir_to_skill_name "$dir_path")
    local proposal_id="${skill_name}-$(date +%Y%m%d)"

    # Check if already proposed
    if grep -q "^$proposal_id$" "$PROPOSED_FILE" 2>/dev/null; then
        return 0
    fi

    # Check if skill already exists
    if [ -d ".claude/skills/$skill_name" ]; then
        echo "$proposal_id" >> "$PROPOSED_FILE"
        return 0
    fi

    # Get pattern data
    local files=$(jq -r --arg dir "$dir_path" '.directory_patterns[$dir].files | join(", ")' "$PATTERNS_FILE" 2>/dev/null)
    local count=$(jq -r --arg dir "$dir_path" '.directory_patterns[$dir].count' "$PATTERNS_FILE" 2>/dev/null)
    local first_seen=$(jq -r --arg dir "$dir_path" '.directory_patterns[$dir].first_seen' "$PATTERNS_FILE" 2>/dev/null)

    # Determine file type
    local file_ext="code"
    if echo "$files" | grep -q "\.ts"; then
        file_ext="TypeScript"
    elif echo "$files" | grep -q "\.py"; then
        file_ext="Python"
    elif echo "$files" | grep -q "\.go"; then
        file_ext="Go"
    elif echo "$files" | grep -q "\.js"; then
        file_ext="JavaScript"
    fi

    local dir_basename=$(basename "$dir_path")

    # Append proposal to pending file
    cat >> "$PENDING_FILE" << PROPOSALEOF

### $skill_name

**Type:** Skill
**Directory:** \`$dir_path\`
**Pattern:** $count edits since $first_seen
**Language:** $file_ext

**Files commonly edited together:**
$(echo "$files" | tr ',' '\n' | sed 's/^ */- /')

**Suggested triggers:** $dir_basename, $(basename "$(dirname "$dir_path")")

**To implement:** Run \`/learn:implement $skill_name\`

---
PROPOSALEOF

    # Mark as proposed
    echo "$proposal_id" >> "$PROPOSED_FILE"

    echo "💡 Proposed skill: $skill_name (from $dir_path)"
}

# Main: process all triggered patterns
if [ -f "$THRESHOLDS_FILE" ] && [ -s "$THRESHOLDS_FILE" ]; then
    NEW_PROPOSALS=0

    while IFS= read -r dir_path; do
        if [ -n "$dir_path" ]; then
            proposal_id="$(dir_to_skill_name "$dir_path")-$(date +%Y%m%d)"
            if ! grep -q "^$proposal_id$" "$PROPOSED_FILE" 2>/dev/null; then
                propose_skill "$dir_path"
                NEW_PROPOSALS=$((NEW_PROPOSALS + 1))
            fi
        fi
    done < "$THRESHOLDS_FILE"

    if [ "$NEW_PROPOSALS" -gt 0 ]; then
        echo ""
        echo "   Run /learn:review to see proposals"
    fi

    # Clear processed thresholds
    > "$THRESHOLDS_FILE"
fi
