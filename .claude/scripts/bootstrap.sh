#!/bin/bash
# Claudenv Bootstrap Script
# Called by /claudenv command to initialize infrastructure

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Claudenv Bootstrap"
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
mkdir -p .claude/{logs,backups,learning}

# Initialize learning files if missing
echo "📚 Initializing learning files..."

if [ ! -f ".claude/learning/observations.md" ]; then
    cat > .claude/learning/observations.md << 'EOF'
# Development Pattern Observations

> Maintained by learning-agent skill. Auto-updated after tasks.

---

## Session Log

<!-- Entries appended automatically by learning-agent -->
EOF
fi

for file in pending-skills pending-commands pending-hooks; do
    if [ ! -f ".claude/learning/${file}.md" ]; then
        touch ".claude/learning/${file}.md"
    fi
done

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x .claude/scripts/*.sh 2>/dev/null || true

# Run tech detection
echo ""
echo "🔍 Detecting tech stack..."
if [ -f ".claude/scripts/detect-stack.sh" ]; then
    bash .claude/scripts/detect-stack.sh > /tmp/claudenv-detection.json 2>/dev/null

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
