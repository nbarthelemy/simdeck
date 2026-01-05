#!/bin/bash
# Session End Hook
# Runs when Claude finishes a session

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Session Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Git stats (if in a git repo)
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Count commits since session start (approximate - last hour)
    RECENT_COMMITS=$(git rev-list --count --since="1 hour ago" HEAD 2>/dev/null || echo "0")
    echo "📝 Recent commits: $RECENT_COMMITS"

    # Files with uncommitted changes
    CHANGED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CHANGED" -gt 0 ]; then
        echo "📁 Uncommitted changes: $CHANGED files"
    fi
fi

# Check for patterns that reached threshold and propose skills
if [ -f ".claude/learning/.thresholds_reached" ] && [ -s ".claude/learning/.thresholds_reached" ]; then
    if [ -x ".claude/scripts/propose-skill.sh" ]; then
        bash .claude/scripts/propose-skill.sh
    fi
fi

# Check for extension patterns and propose agents
if [ -f ".claude/learning/patterns.json" ]; then
    if [ -x ".claude/scripts/propose-agent.sh" ]; then
        bash .claude/scripts/propose-agent.sh
    fi
fi

# Check for pending proposals
PENDING_SKILLS=$(grep -c "^### " .claude/learning/pending-skills.md 2>/dev/null) || PENDING_SKILLS=0
PENDING_AGENTS=$(grep -c "^### " .claude/learning/pending-agents.md 2>/dev/null) || PENDING_AGENTS=0
PENDING_COMMANDS=$(grep -c "^### " .claude/learning/pending-commands.md 2>/dev/null) || PENDING_COMMANDS=0
PENDING_HOOKS=$(grep -c "^### " .claude/learning/pending-hooks.md 2>/dev/null) || PENDING_HOOKS=0

TOTAL_PENDING=$((PENDING_SKILLS + PENDING_AGENTS + PENDING_COMMANDS + PENDING_HOOKS))

if [ "$TOTAL_PENDING" -gt 0 ]; then
    echo ""
    echo "💡 Proposals pending review:"
    [ "$PENDING_SKILLS" -gt 0 ] && echo "   - $PENDING_SKILLS skills"
    [ "$PENDING_AGENTS" -gt 0 ] && echo "   - $PENDING_AGENTS agents"
    [ "$PENDING_COMMANDS" -gt 0 ] && echo "   - $PENDING_COMMANDS commands"
    [ "$PENDING_HOOKS" -gt 0 ] && echo "   - $PENDING_HOOKS hooks"
    echo "   Run /learn:review to see details"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Log session end
echo "[$(date -Iseconds)] Session ended" >> .claude/logs/sessions.log 2>/dev/null || true
