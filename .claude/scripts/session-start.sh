#!/bin/bash
# Session Start Hook
# Runs when a new Claude session begins

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Session Started"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for claudenv updates (non-blocking, 2s timeout)
if [ -f ".claude/version.json" ]; then
    LOCAL_VERSION=$(cat .claude/version.json | jq -r '.infrastructureVersion' 2>/dev/null)

    # Fetch remote version with cache buster, with timeout
    REMOTE_VERSION=$(curl -sL --max-time 2 \
        "https://raw.githubusercontent.com/nbarthelemy/claudenv/main/dist/version.json?cb=$(date +%s)" 2>/dev/null \
        | jq -r '.infrastructureVersion' 2>/dev/null)

    if [ -n "$REMOTE_VERSION" ] && [ "$REMOTE_VERSION" != "null" ] && [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
        # Simple version comparison (works for semver like 2.3.0)
        if [ "$(printf '%s\n' "$REMOTE_VERSION" "$LOCAL_VERSION" | sort -V | tail -1)" = "$REMOTE_VERSION" ] && \
           [ "$REMOTE_VERSION" != "$LOCAL_VERSION" ]; then
            echo ""
            echo "📦 Update available: v$LOCAL_VERSION → v$REMOTE_VERSION"
            echo "   Run /claudenv:update to upgrade"
        fi
    fi
fi

# Load project context if available
if [ -f ".claude/project-context.json" ]; then
    echo ""
    echo "📦 Tech Stack:"

    # Extract key info using jq if available, fallback to grep
    if command -v jq &> /dev/null; then
        LANGS=$(cat .claude/project-context.json | jq -r '.detected.languages | join(", ")' 2>/dev/null)
        FRAMEWORKS=$(cat .claude/project-context.json | jq -r '.detected.frameworks | join(", ")' 2>/dev/null)
        PKG_MGR=$(cat .claude/project-context.json | jq -r '.detected.packageManager // "unknown"' 2>/dev/null)
        CLOUDS=$(cat .claude/project-context.json | jq -r '.detected.cloudPlatforms | join(", ")' 2>/dev/null)

        [ -n "$LANGS" ] && [ "$LANGS" != "null" ] && echo "   Languages: $LANGS"
        [ -n "$FRAMEWORKS" ] && [ "$FRAMEWORKS" != "null" ] && echo "   Frameworks: $FRAMEWORKS"
        [ -n "$PKG_MGR" ] && [ "$PKG_MGR" != "null" ] && echo "   Package Manager: $PKG_MGR"
        [ -n "$CLOUDS" ] && [ "$CLOUDS" != "null" ] && [ "$CLOUDS" != "" ] && echo "   Cloud: $CLOUDS"
    else
        # Fallback to simple grep
        grep -E '"(languages|frameworks|packageManager)"' .claude/project-context.json 2>/dev/null | head -3
    fi
else
    echo ""
    echo "⚠️  No project context found"
    echo "   Run /claudenv to initialize"
fi

# Check for SPEC.md
echo ""
if [ -f ".claude/SPEC.md" ]; then
    echo "📋 Specification: Found"
    # Show last modified date
    if [[ "$OSTYPE" == "darwin"* ]]; then
        MODIFIED=$(stat -f "%Sm" -t "%Y-%m-%d" .claude/SPEC.md 2>/dev/null)
    else
        MODIFIED=$(stat -c "%y" .claude/SPEC.md 2>/dev/null | cut -d' ' -f1)
    fi
    [ -n "$MODIFIED" ] && echo "   Last updated: $MODIFIED"
else
    echo "📋 Specification: Not found"
    echo "   Run /interview to create"
fi

# Count infrastructure components
echo ""
SKILLS=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
COMMANDS=$(find .claude/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

echo "🤖 Skills: $SKILLS | 📝 Commands: $COMMANDS"

# Check for pending learnings
PENDING_SKILLS=$(grep -c "^### " .claude/learning/pending-skills.md 2>/dev/null | tr -d ' \n' || echo "0")

if [ "$PENDING_SKILLS" -gt 0 ]; then
    echo "💡 $PENDING_SKILLS pending proposals (/learn:review)"
fi

# Check for paused autonomy
if [ -f ".claude/.autonomy-paused" ]; then
    echo ""
    echo "⏸️  Autonomy is PAUSED - run /autonomy:resume to restore"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Log session start
echo "[$(date -Iseconds)] Session started" >> .claude/logs/sessions.log 2>/dev/null || true
