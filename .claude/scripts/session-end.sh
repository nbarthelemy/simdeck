#!/bin/bash
# Session End Hook
# Runs when Claude finishes a session

# Find project root by looking for .claude directory
find_project_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.claude" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

# Change to project root or exit gracefully
PROJECT_ROOT=$(find_project_root)
if [ -z "$PROJECT_ROOT" ]; then
    exit 0
fi
cd "$PROJECT_ROOT" || exit 0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Session Summary"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check session state and enforce handoff
NEEDS_HANDOFF=false
HANDOFF_REASONS=""

if [ -f ".claude/state/session-state.json" ] && command -v jq &> /dev/null; then
    STATE_FILE=".claude/state/session-state.json"

    # Get current state
    CURRENT_TASK=$(jq -r '.focus.currentTask // empty' "$STATE_FILE")
    HANDOFF_NOTES=$(jq -r '.handoff.notes // empty' "$STATE_FILE")
    NEXT_STEPS_COUNT=$(jq -r '.handoff.nextSteps | length' "$STATE_FILE")
    DECISION_COUNT=$(jq -r '.decisions | length' "$STATE_FILE")
    BLOCKER_COUNT=$(jq -r '.blockers | length' "$STATE_FILE")

    # Determine if handoff is needed
    if [ -n "$CURRENT_TASK" ]; then
        NEEDS_HANDOFF=true
        HANDOFF_REASONS="${HANDOFF_REASONS}   • Active focus: $CURRENT_TASK\n"
    fi

    if [ "$BLOCKER_COUNT" -gt 0 ]; then
        NEEDS_HANDOFF=true
        HANDOFF_REASONS="${HANDOFF_REASONS}   • $BLOCKER_COUNT active blockers\n"
    fi

    # Show decisions made this session
    if [ "$DECISION_COUNT" -gt 0 ]; then
        echo ""
        echo "📝 Decisions recorded: $DECISION_COUNT"
    fi
fi

# Git stats (if in a git repo)
if git rev-parse --git-dir > /dev/null 2>&1; then
    # Count commits since session start (approximate - last hour)
    RECENT_COMMITS=$(git rev-list --count --since="1 hour ago" HEAD 2>/dev/null || echo "0")

    # Files with uncommitted changes
    CHANGED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
    if [ "$CHANGED" -gt 0 ]; then
        NEEDS_HANDOFF=true
        HANDOFF_REASONS="${HANDOFF_REASONS}   • $CHANGED uncommitted files\n"
        echo ""
        echo "📁 Uncommitted changes: $CHANGED files"
    fi

    [ "$RECENT_COMMITS" -gt 0 ] && echo "📝 Recent commits: $RECENT_COMMITS"
fi

# Show handoff status
if [ "$NEEDS_HANDOFF" = true ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if [ -z "$HANDOFF_NOTES" ] && [ "$NEXT_STEPS_COUNT" -eq 0 ]; then
        echo "⚠️  HANDOFF REQUIRED"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Work in progress detected:"
        echo -e "$HANDOFF_REASONS"
        echo ""
        echo "Please run before ending session:"
        echo "   /ce:focus handoff \"summary of progress\""
        echo ""
        echo "Or acknowledge incomplete state:"
        echo "   /ce:focus clear"
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Create marker for next session to detect missing handoff
        mkdir -p ".claude/state"
        echo "{\"reason\": \"no handoff notes\", \"timestamp\": \"$(date -Iseconds)\"}" > ".claude/state/.needs-handoff"
    else
        echo "✅ Handoff captured"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        if [ -n "$HANDOFF_NOTES" ]; then
            echo "Notes: $HANDOFF_NOTES"
        fi
        if [ "$NEXT_STEPS_COUNT" -gt 0 ]; then
            echo "Next steps: $NEXT_STEPS_COUNT pending"
        fi
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        # Remove marker if it exists
        rm -f ".claude/state/.needs-handoff"
    fi
fi

# Update session timestamp
if [ -f "$STATE_FILE" ]; then
    NOW=$(date -Iseconds)
    TMP=$(mktemp)
    jq --arg ts "$NOW" '.handoff.lastSession = $ts | .metadata.sessionCount += 1' "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"
fi

# Check for patterns that reached threshold and propose skills
if [ -f ".claude/learning/.thresholds_reached" ] && [ -s ".claude/learning/.thresholds_reached" ]; then
    if [ -x ".claude/scripts/propose-skill.sh" ]; then
        bash .claude/scripts/propose-skill.sh
    fi
fi

# Check for extension patterns and propose agents
if [ -f ".claude/learning/working/patterns.json" ]; then
    if [ -x ".claude/scripts/propose-agent.sh" ]; then
        bash .claude/scripts/propose-agent.sh
    fi
fi

# Check for pending proposals
PENDING_SKILLS=$(grep -c "^### " .claude/learning/working/pending-skills.md 2>/dev/null) || PENDING_SKILLS=0
PENDING_AGENTS=$(grep -c "^### " .claude/learning/working/pending-agents.md 2>/dev/null) || PENDING_AGENTS=0
PENDING_COMMANDS=$(grep -c "^### " .claude/learning/working/pending-commands.md 2>/dev/null) || PENDING_COMMANDS=0
PENDING_HOOKS=$(grep -c "^### " .claude/learning/working/pending-hooks.md 2>/dev/null) || PENDING_HOOKS=0

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

# Sync task state back to TODO.md via task-bridge
if [ -x ".claude/scripts/task-bridge.sh" ]; then
    bash .claude/scripts/task-bridge.sh summary > /dev/null 2>&1 || true
fi

# Generate daily log entry
if [ -x ".claude/scripts/daily-log.sh" ]; then
    bash .claude/scripts/daily-log.sh > /dev/null 2>&1 || true
fi

# Log session end
echo "[$(date -Iseconds)] Session ended" >> .claude/logs/sessions.log 2>/dev/null || true
