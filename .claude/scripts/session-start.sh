#!/bin/bash
# Session Start Hook
# Runs when a new Claude session begins

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
echo "🚀 Session Started"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check for missed handoff from previous session
if [ -f ".claude/state/.needs-handoff" ]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  PREVIOUS SESSION ENDED WITHOUT HANDOFF"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Context from the previous session may be lost."
    echo "Review the session state and update if needed:"
    echo ""
    echo "   /ce:focus                # View current state"
    echo "   /ce:focus set \"task\"     # Set current focus"
    echo "   /ce:focus decision \"...\" # Record a decision"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Clear the marker so we only warn once
    rm -f ".claude/state/.needs-handoff"
fi

# Load session state if available
if [ -f ".claude/state/session-state.json" ] && command -v jq &> /dev/null; then
    STATE_FILE=".claude/state/session-state.json"

    # Get focus info
    ACTIVE_PLAN=$(jq -r '.focus.activePlan // empty' "$STATE_FILE")
    CURRENT_TASK=$(jq -r '.focus.currentTask // empty' "$STATE_FILE")
    FOCUS_LOCKED=$(jq -r '.focus.locked' "$STATE_FILE")

    # Get handoff info
    HANDOFF_NOTES=$(jq -r '.handoff.notes // empty' "$STATE_FILE")
    NEXT_STEPS=$(jq -r '.handoff.nextSteps | length' "$STATE_FILE")

    # Get blockers
    BLOCKER_COUNT=$(jq -r '.blockers | length' "$STATE_FILE")

    # Display focus if active
    if [ -n "$CURRENT_TASK" ]; then
        echo ""
        echo "🎯 Current Focus:"
        echo "   Task: $CURRENT_TASK"
        [ -n "$ACTIVE_PLAN" ] && echo "   Plan: $ACTIVE_PLAN"
        [ "$FOCUS_LOCKED" = "true" ] && echo "   Status: 🔒 Locked"
    fi

    # Display handoff notes from last session
    if [ -n "$HANDOFF_NOTES" ]; then
        echo ""
        echo "📋 From last session:"
        echo "   $HANDOFF_NOTES"
    fi

    # Display next steps if any
    if [ "$NEXT_STEPS" -gt 0 ]; then
        echo ""
        echo "📝 Next steps ($NEXT_STEPS):"
        jq -r '.handoff.nextSteps[:3][] | "   • " + .' "$STATE_FILE"
        [ "$NEXT_STEPS" -gt 3 ] && echo "   ... and $((NEXT_STEPS - 3)) more"
    fi

    # Display blockers if any
    if [ "$BLOCKER_COUNT" -gt 0 ]; then
        echo ""
        echo "🚧 Blockers ($BLOCKER_COUNT):"
        jq -r '.blockers[:3][] | "   • " + .issue + " (since " + .since + ")"' "$STATE_FILE"
    fi

    # Increment session count
    bash .claude/scripts/state-manager.sh init > /dev/null 2>&1 || true
fi

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
            echo "   Run /ce:admin update to upgrade"
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
    echo "   Run /ce:init to initialize"
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
    echo "   Run /ce:interview to create"
fi

# Count infrastructure components
echo ""
SKILLS=$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
COMMANDS=$(find .claude/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')

echo "🤖 Skills: $SKILLS | 📝 Commands: $COMMANDS"

# Check for plans and RCAs
PLANS=$(find .claude/plans -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
RCAS=$(find .claude/rca -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$PLANS" -gt 0 ] || [ "$RCAS" -gt 0 ]; then
    echo "📋 Plans: $PLANS | 🔍 RCAs: $RCAS"
fi

# Check for reference docs
REFS=$(find .claude/references -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
if [ "$REFS" -gt 0 ]; then
    echo "📚 Reference docs: $REFS"
fi

# Check for pending learnings
PENDING_SKILLS=$(grep -c "^### " .claude/learning/working/pending-skills.md 2>/dev/null | tr -d ' \n' || echo "0")

if [ "$PENDING_SKILLS" -gt 0 ]; then
    echo "💡 $PENDING_SKILLS pending proposals (/learn:review)"
fi

# Memory system status and automatic injection
MEMORY_MODE="auto"
if [ -f ".claude/.memory-manual" ]; then
    MEMORY_MODE="manual"
fi

if [ -f ".claude/memory/memory.db" ]; then
    MEMORY_STATUS=$(bash .claude/scripts/memory-status.sh 2>/dev/null)
    if command -v jq &> /dev/null && [ -n "$MEMORY_STATUS" ]; then
        MEM_OBS=$(echo "$MEMORY_STATUS" | jq -r '.counts.observations // 0')
        MEM_PENDING=$(echo "$MEMORY_STATUS" | jq -r '.pending.observations // 0')
        MEM_HIGH=$(echo "$MEMORY_STATUS" | jq -r '.importance.high // 0')
        MEM_VEC=$(echo "$MEMORY_STATUS" | jq -r '.vec.available // false')
        MEM_EMBED_PENDING=$(echo "$MEMORY_STATUS" | jq -r '.pending.embeddings // 0')

        if [ "$MEM_OBS" -gt 0 ] || [ "$MEM_PENDING" -gt 0 ]; then
            echo "🧠 Memory: $MEM_OBS observations ($MEM_HIGH high importance)"
            if [ "$MEM_PENDING" -gt 0 ]; then
                echo "   ⏳ $MEM_PENDING pending - will process this session"
            fi
            if [ "$MEMORY_MODE" = "manual" ]; then
                echo "   📴 Mode: manual (/ce:do for context)"
            fi
        fi

        # Generate missing embeddings in background if sqlite-vec available
        if [ "$MEM_VEC" = "true" ] && [ "$MEM_EMBED_PENDING" -gt 0 ]; then
            if [ -f ".claude/scripts/memory-embed.js" ]; then
                echo "   🔄 Generating $MEM_EMBED_PENDING embeddings in background..."
                (node .claude/scripts/memory-embed.js batch > /dev/null 2>&1 &)
            fi
        fi

        # Automatic memory context injection (when in auto mode and has observations)
        if [ "$MEMORY_MODE" = "auto" ] && [ "$MEM_OBS" -gt 0 ]; then
            MEMORY_CONTEXT=$(bash .claude/scripts/memory-inject.sh 2>/dev/null)
            if [ -n "$MEMORY_CONTEXT" ] && command -v jq &> /dev/null; then
                HAS_MEMORY=$(echo "$MEMORY_CONTEXT" | jq -r '.hasMemory // false')
                if [ "$HAS_MEMORY" = "true" ]; then
                    # Extract high importance observations for display
                    HIGH_OBS=$(echo "$MEMORY_CONTEXT" | jq -r '.context.highImportance // []')
                    HIGH_COUNT=$(echo "$HIGH_OBS" | jq 'length')

                    if [ "$HIGH_COUNT" -gt 0 ] 2>/dev/null && [ "$HIGH_COUNT" != "null" ]; then
                        echo ""
                        echo "📚 Recent Context (high importance):"
                        echo "$HIGH_OBS" | jq -r '.[:3][] | "   • " + .summary[:80] + (if (.summary | length) > 80 then "..." else "" end)' 2>/dev/null
                        if [ "$HIGH_COUNT" -gt 3 ]; then
                            echo "   ... and $((HIGH_COUNT - 3)) more"
                        fi
                    fi
                fi
            fi
        fi
    fi
fi

# Check for paused autonomy
if [ -f ".claude/.autonomy-paused" ]; then
    echo ""
    echo "⏸️  Autonomy is PAUSED - run /autonomy:resume to restore"
fi

# Display thinking level if not default
if [ -f ".claude/state/session-state.json" ] && command -v jq &> /dev/null; then
    THINKING_LEVEL=$(jq -r '.thinking.level // "medium"' .claude/state/session-state.json 2>/dev/null)
    if [ "$THINKING_LEVEL" != "medium" ]; then
        echo "🧠 Thinking: $THINKING_LEVEL"
    fi
fi

# Check TODO.md status via task-bridge
if [ -x ".claude/scripts/task-bridge.sh" ]; then
  TODO_JSON=$(bash .claude/scripts/task-bridge.sh summary 2>/dev/null)
  HAS_TODO=$(echo "$TODO_JSON" | jq -r '.hasTodo' 2>/dev/null)
  if [ "$HAS_TODO" = "true" ]; then
    TODO_PENDING=$(echo "$TODO_JSON" | jq -r '.pending' 2>/dev/null)
    TODO_PROGRESS=$(echo "$TODO_JSON" | jq -r '.progress' 2>/dev/null)
    TODO_TOTAL=$(echo "$TODO_JSON" | jq -r '.total' 2>/dev/null)
    if [ "$TODO_PENDING" -gt 0 ] 2>/dev/null; then
      echo ""
      echo "📋 TODO: $TODO_PENDING pending of $TODO_TOTAL tasks ($TODO_PROGRESS% done)"
    fi
  fi
fi

# Suggest /prime if not recently run
echo ""
echo "💡 Tip: /prime to load full project context"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Log session start
echo "[$(date -Iseconds)] Session started" >> .claude/logs/sessions.log 2>/dev/null || true
