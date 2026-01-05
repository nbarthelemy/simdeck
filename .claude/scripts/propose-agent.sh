#!/bin/bash
# Propose Agent Script
# Writes agent proposals to pending-agents.md when patterns reach threshold
# Called by session-end.sh when thresholds are detected

LEARNING_DIR=".claude/learning"
PENDING_FILE="$LEARNING_DIR/pending-agents.md"
PATTERNS_FILE="$LEARNING_DIR/patterns.json"
PROPOSED_FILE="$LEARNING_DIR/.agents_proposed"

# Ensure directories exist
mkdir -p "$LEARNING_DIR"
touch "$PROPOSED_FILE"

# Initialize pending file if missing
if [ ! -f "$PENDING_FILE" ]; then
    cat > "$PENDING_FILE" << 'EOF'
# Pending Agent Proposals

Specialist agents suggested based on observed development patterns. Review and implement with `/learn:implement`.

EOF
fi

# Map file extensions to agent types
# Returns: agent_name|technology|description
ext_to_agent() {
    local ext="$1"
    case "$ext" in
        py)     echo "python-specialist|Python|Python development including Django, FastAPI, Flask patterns" ;;
        rs)     echo "rust-specialist|Rust|Rust development with ownership, lifetimes, and async patterns" ;;
        go)     echo "go-specialist|Go|Go development including concurrency, interfaces, and idioms" ;;
        rb)     echo "ruby-specialist|Ruby|Ruby development including Rails patterns and conventions" ;;
        php)    echo "php-specialist|PHP|PHP development including Laravel, Symfony patterns" ;;
        java)   echo "java-specialist|Java|Java development including Spring patterns" ;;
        kt)     echo "kotlin-specialist|Kotlin|Kotlin development for JVM and Android" ;;
        swift)  echo "swift-specialist|Swift|Swift development for iOS/macOS" ;;
        cs)     echo "csharp-specialist|C#|C# development including .NET patterns" ;;
        ex|exs) echo "elixir-specialist|Elixir|Elixir development including Phoenix and OTP" ;;
        clj)    echo "clojure-specialist|Clojure|Clojure development and functional patterns" ;;
        scala)  echo "scala-specialist|Scala|Scala development including Akka and Play" ;;
        lua)    echo "lua-specialist|Lua|Lua scripting and game development" ;;
        zig)    echo "zig-specialist|Zig|Zig systems programming" ;;
        nim)    echo "nim-specialist|Nim|Nim development and metaprogramming" ;;
        *)      echo "" ;;
    esac
}

# Create an agent proposal
propose_agent() {
    local ext="$1"
    local mapping=$(ext_to_agent "$ext")

    [ -z "$mapping" ] && return 0

    local agent_name=$(echo "$mapping" | cut -d'|' -f1)
    local technology=$(echo "$mapping" | cut -d'|' -f2)
    local description=$(echo "$mapping" | cut -d'|' -f3)
    local proposal_id="${agent_name}-$(date +%Y%m%d)"

    # Check if already proposed
    if grep -q "^$proposal_id$" "$PROPOSED_FILE" 2>/dev/null; then
        return 0
    fi

    # Check if agent already exists
    if [ -f ".claude/agents/$agent_name.md" ]; then
        echo "$proposal_id" >> "$PROPOSED_FILE"
        return 0
    fi

    # Get pattern data
    local count=$(jq -r --arg ext "$ext" '.extension_patterns[$ext].count // 0' "$PATTERNS_FILE" 2>/dev/null)
    local first_seen=$(jq -r --arg ext "$ext" '.extension_patterns[$ext].first_seen // "unknown"' "$PATTERNS_FILE" 2>/dev/null)

    # Append proposal to pending file
    cat >> "$PENDING_FILE" << PROPOSALEOF

### $agent_name

**Type:** Agent
**Technology:** $technology
**Pattern:** $count edits to .$ext files since $first_seen
**Description:** $description

**Capabilities when created:**
- Expert-level $technology guidance
- Idiomatic code patterns
- Performance optimization
- Debugging assistance
- Architecture decisions

**To implement:** Run \`/learn:implement $agent_name\`

---
PROPOSALEOF

    # Mark as proposed
    echo "$proposal_id" >> "$PROPOSED_FILE"

    echo "💡 Proposed agent: $agent_name ($technology)"
}

# Check which extensions have reached threshold
check_extension_thresholds() {
    local agent_threshold=$(jq -r '.thresholds.agent_creation // 5' "$PATTERNS_FILE" 2>/dev/null)

    # Find extensions that reached threshold
    jq -r --argjson threshold "$agent_threshold" '
        .extension_patterns | to_entries |
        map(select(.value.count >= $threshold)) |
        map(.key) | .[]
    ' "$PATTERNS_FILE" 2>/dev/null
}

# Main execution
if [ -f "$PATTERNS_FILE" ]; then
    triggered=$(check_extension_thresholds)

    if [ -n "$triggered" ]; then
        NEW_PROPOSALS=0

        echo "$triggered" | while read -r ext; do
            if [ -n "$ext" ]; then
                mapping=$(ext_to_agent "$ext")
                if [ -n "$mapping" ]; then
                    agent_name=$(echo "$mapping" | cut -d'|' -f1)
                    proposal_id="${agent_name}-$(date +%Y%m%d)"
                    if ! grep -q "^$proposal_id$" "$PROPOSED_FILE" 2>/dev/null; then
                        propose_agent "$ext"
                    fi
                fi
            fi
        done

        # Check if any new proposals were added
        if grep -q "^### " "$PENDING_FILE" 2>/dev/null; then
            echo ""
            echo "   Run /learn:review to see proposals"
        fi
    fi
fi
