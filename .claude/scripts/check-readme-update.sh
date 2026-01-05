#!/bin/bash
# Check if README should be updated before commit
# Runs as PreToolUse hook for git commit

# Get staged files
STAGED=$(git diff --cached --name-only 2>/dev/null)

# Check if .claude/ files are staged (excluding logs and backups)
CLAUDE_FILES=$(echo "$STAGED" | grep -E "^\.claude/" | grep -vE "(logs|backups|\.gitkeep)" || true)

# Check if README is staged
README_STAGED=$(echo "$STAGED" | grep -E "^README\.md$" || true)

# If .claude/ files changed but README wasn't updated, remind
if [ -n "$CLAUDE_FILES" ] && [ -z "$README_STAGED" ]; then
    # Check what type of files changed
    COMMANDS_CHANGED=$(echo "$CLAUDE_FILES" | grep -c "commands/" 2>/dev/null || echo "0")
    SKILLS_CHANGED=$(echo "$CLAUDE_FILES" | grep -c "skills/" 2>/dev/null || echo "0")
    VERSION_CHANGED=$(echo "$CLAUDE_FILES" | grep -c "version.json" 2>/dev/null || echo "0")

    # Ensure we have integers
    COMMANDS_CHANGED=${COMMANDS_CHANGED//[^0-9]/}
    SKILLS_CHANGED=${SKILLS_CHANGED//[^0-9]/}
    VERSION_CHANGED=${VERSION_CHANGED//[^0-9]/}
    : ${COMMANDS_CHANGED:=0}
    : ${SKILLS_CHANGED:=0}
    : ${VERSION_CHANGED:=0}

    if [ "$COMMANDS_CHANGED" -gt 0 ] || [ "$SKILLS_CHANGED" -gt 0 ] || [ "$VERSION_CHANGED" -gt 0 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📝 README Update Reminder"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "The following infrastructure files are staged:"
        echo "$CLAUDE_FILES" | sed 's/^/   /'
        echo ""
        echo "Consider updating README.md if these changes affect:"
        [ "$COMMANDS_CHANGED" -gt 0 ] && echo "   • Commands table"
        [ "$SKILLS_CHANGED" -gt 0 ] && echo "   • Skills documentation"
        [ "$VERSION_CHANGED" -gt 0 ] && echo "   • Version/Changelog"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    fi
fi

exit 0
