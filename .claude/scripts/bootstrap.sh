#!/bin/bash
# Claudenv Bootstrap Script
# Called by /claudenv command to initialize infrastructure

set -e

# Check for workspace setup (parent .claude with claudenv)
find_workspace_root() {
    local check_dir="$PWD"
    while [ "$check_dir" != "/" ]; do
        local parent_dir=$(dirname "$check_dir")
        if [ -f "$parent_dir/.claude/version.json" ]; then
            echo "$parent_dir/.claude"
            return 0
        fi
        check_dir="$parent_dir"
    done
    return 1
}

WORKSPACE_ROOT=$(find_workspace_root 2>/dev/null || echo "")
IS_SUBPROJECT=false
SCRIPTS_DIR=".claude/scripts"
if [ -n "$WORKSPACE_ROOT" ]; then
    IS_SUBPROJECT=true
    SCRIPTS_DIR="$WORKSPACE_ROOT/scripts"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Claudenv Bootstrap"
if [ "$IS_SUBPROJECT" = true ]; then
    echo "   (Subproject - inherits from workspace)"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Ensure we're in a project directory
if [ ! -d ".claude" ]; then
    echo "❌ .claude directory not found"
    echo "   Please copy the claudenv .claude/ directory to your project first"
    exit 1
fi

# Create directories if missing
echo ""
echo "📁 Ensuring directory structure..."
mkdir -p .claude/{logs,backups,learning,learning/working,plans,rca,references}

# Initialize learning files if missing
echo "📚 Initializing learning files..."

if [ ! -f ".claude/learning/working/observations.md" ]; then
    cat > .claude/learning/working/observations.md << 'EOF'
# Development Pattern Observations

> Maintained by learning-agent skill. Auto-updated after tasks.

---

## Session Log

<!-- Entries appended automatically by learning-agent -->
EOF
fi

for file in pending-skills pending-commands pending-hooks pending-agents; do
    if [ ! -f ".claude/learning/working/${file}.md" ]; then
        touch ".claude/learning/working/${file}.md"
    fi
done

# Make scripts executable (only for workspace root)
if [ "$IS_SUBPROJECT" = false ]; then
    echo "🔧 Making scripts executable..."
    chmod +x .claude/scripts/*.sh 2>/dev/null || true
fi

# Run tech detection
echo ""
echo "🔍 Detecting tech stack..."
if [ -f "$SCRIPTS_DIR/detect-stack.sh" ]; then
    bash "$SCRIPTS_DIR/detect-stack.sh" > /tmp/claudenv-detection.json 2>/dev/null

    # Show summary
    if command -v jq &> /dev/null; then
        CONFIDENCE=$(cat /tmp/claudenv-detection.json | jq -r '.detection.confidence' 2>/dev/null)
        echo "   Confidence: $CONFIDENCE"
    fi
fi

# Check for existing CLAUDE.md
echo ""
if [ -f "CLAUDE.md" ] && [ ! -f ".claude/CLAUDE.md.migrated" ]; then
    echo "📋 Found existing CLAUDE.md at project root"
    echo "   This will be migrated (preserving all content)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Bootstrap preparation complete"
echo ""
echo "Next steps (Claude will handle):"
echo "1. Analyze detection results"
echo "2. Generate project-context.json"
echo "3. Update settings.json with tech-specific permissions"
echo "4. Migrate CLAUDE.md if needed"
echo "5. Run health check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
