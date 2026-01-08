#!/bin/bash
# Learning Observer Hook Script
# Triggered after file modifications to capture and track patterns
# Automatically detects when thresholds are reached for skill/agent creation

# Exit gracefully if not in project root
[ ! -d ".claude" ] && exit 0

LEARNING_DIR=".claude/learning"
PATTERNS_FILE="$LEARNING_DIR/patterns.json"
THRESHOLDS_FILE="$LEARNING_DIR/.thresholds_reached"

# Ensure learning directory exists
mkdir -p "$LEARNING_DIR"

# Initialize patterns file if missing or invalid
init_patterns_file() {
    if [ ! -f "$PATTERNS_FILE" ] || ! jq empty "$PATTERNS_FILE" 2>/dev/null; then
        cat > "$PATTERNS_FILE" << 'EOF'
{
  "version": 1,
  "last_updated": null,
  "file_patterns": {},
  "directory_patterns": {},
  "extension_patterns": {},
  "thresholds": {
    "skill_creation": 3,
    "agent_creation": 5
  }
}
EOF
    fi
}

init_patterns_file

# Get current timestamp
TIMESTAMP=$(date -Iseconds)
TODAY=$(date +%Y-%m-%d)

# Get context from environment or argument
CONTEXT="${CLAUDE_TOOL_NAME:-$1}"
INPUT="${CLAUDE_TOOL_INPUT:-$2}"

# Exit if no context
[ -z "$CONTEXT" ] && exit 0

# Track file edit pattern
track_file_pattern() {
    local file_path="$1"
    [ -z "$file_path" ] && return

    # Extract components
    local dir_path=$(dirname "$file_path")
    local extension="${file_path##*.}"
    local filename=$(basename "$file_path")

    # Update patterns.json using jq
    local tmp_file=$(mktemp)

    jq --arg fp "$file_path" \
       --arg dp "$dir_path" \
       --arg ext "$extension" \
       --arg ts "$TIMESTAMP" \
       --arg today "$TODAY" '
        # Update file pattern
        .file_patterns[$fp] = (
            (.file_patterns[$fp] // {"count": 0, "first_seen": $today, "last_seen": null, "dates": []}) |
            .count += 1 |
            .last_seen = $today |
            .dates = ((.dates + [$today]) | unique | .[-10:])
        ) |

        # Update directory pattern
        .directory_patterns[$dp] = (
            (.directory_patterns[$dp] // {"count": 0, "first_seen": $today, "files": []}) |
            .count += 1 |
            .files = ((.files + [$fp]) | unique | .[-20:])
        ) |

        # Update extension pattern
        .extension_patterns[$ext] = (
            (.extension_patterns[$ext] // {"count": 0, "first_seen": $today}) |
            .count += 1
        ) |

        .last_updated = $ts
    ' "$PATTERNS_FILE" > "$tmp_file" && mv "$tmp_file" "$PATTERNS_FILE"
}

# Check if any patterns have reached thresholds
check_thresholds() {
    local skill_threshold=$(jq -r '.thresholds.skill_creation // 3' "$PATTERNS_FILE")

    # Find directory patterns that have reached threshold
    local triggered=$(jq -r --argjson threshold "$skill_threshold" '
        .directory_patterns | to_entries |
        map(select(.value.count >= $threshold)) |
        map(.key) | join("\n")
    ' "$PATTERNS_FILE")

    if [ -n "$triggered" ]; then
        # Write triggered patterns to thresholds file
        echo "$triggered" | while read -r dir; do
            if [ -n "$dir" ] && ! grep -q "^$dir$" "$THRESHOLDS_FILE" 2>/dev/null; then
                echo "$dir" >> "$THRESHOLDS_FILE"
            fi
        done
    fi
}

# Main logic based on context
case "$CONTEXT" in
    Write|Edit|MultiEdit)
        # Extract file path from input (first argument or JSON)
        if [ -n "$INPUT" ]; then
            # Try to extract file_path from JSON-like input
            file_path=$(echo "$INPUT" | grep -oE '"file_path"\s*:\s*"[^"]+"' | head -1 | sed 's/.*"file_path"\s*:\s*"\([^"]*\)".*/\1/')

            # If not found, assume input is the file path
            [ -z "$file_path" ] && file_path="$INPUT"

            track_file_pattern "$file_path"
            check_thresholds
        fi
        ;;
    --check-thresholds)
        check_thresholds
        # Output any patterns that reached threshold
        if [ -f "$THRESHOLDS_FILE" ] && [ -s "$THRESHOLDS_FILE" ]; then
            echo "PATTERNS_REACHED_THRESHOLD"
            cat "$THRESHOLDS_FILE"
        fi
        ;;
    --reset)
        rm -f "$THRESHOLDS_FILE"
        echo "Thresholds reset"
        ;;
esac

exit 0
