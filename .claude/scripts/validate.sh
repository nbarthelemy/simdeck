#!/bin/bash
# Infrastructure Validation Script
# Used by /health:check and /claudenv commands
# Validates all required files exist and are properly configured

set -e

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏥 Running Health Checks"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PASSED=0
WARNINGS=0
ERRORS=0
FIXES_APPLIED=0

# Auto-fix mode (pass --fix to enable)
AUTO_FIX=false
if [[ "$1" == "--fix" ]]; then
    AUTO_FIX=true
    echo "🔧 Auto-fix mode enabled"
    echo ""
fi

# Function to check and report (critical - causes failure)
check() {
    local name="$1"
    local condition="$2"
    local fix_cmd="$3"

    if eval "$condition"; then
        echo "✅ $name"
        PASSED=$((PASSED + 1))
    else
        if [[ "$AUTO_FIX" == "true" ]] && [[ -n "$fix_cmd" ]]; then
            echo "🔧 $name - fixing..."
            eval "$fix_cmd" 2>/dev/null && {
                echo "   ✅ Fixed"
                PASSED=$((PASSED + 1))
                FIXES_APPLIED=$((FIXES_APPLIED + 1))
            } || {
                echo "❌ $name - fix failed"
                ERRORS=$((ERRORS + 1))
            }
        else
            echo "❌ $name"
            ERRORS=$((ERRORS + 1))
        fi
    fi
}

# Function for warnings (non-critical)
warn() {
    local name="$1"
    local condition="$2"
    local fix_cmd="$3"

    if eval "$condition"; then
        echo "✅ $name"
        PASSED=$((PASSED + 1))
    else
        if [[ "$AUTO_FIX" == "true" ]] && [[ -n "$fix_cmd" ]]; then
            echo "🔧 $name - fixing..."
            eval "$fix_cmd" 2>/dev/null && {
                echo "   ✅ Fixed"
                PASSED=$((PASSED + 1))
                FIXES_APPLIED=$((FIXES_APPLIED + 1))
            } || {
                echo "⚠️  $name - fix failed"
                WARNINGS=$((WARNINGS + 1))
            }
        else
            echo "⚠️  $name"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

echo ""
echo "## Core Files"

check "settings.json exists" \
    "[ -f '.claude/settings.json' ]"

check "settings.json is valid JSON" \
    "python3 -m json.tool .claude/settings.json > /dev/null 2>&1 || jq . .claude/settings.json > /dev/null 2>&1"

check "CLAUDE.md exists" \
    "[ -f '.claude/CLAUDE.md' ]"

check "version.json exists" \
    "[ -f '.claude/version.json' ]"

echo ""
echo "## Required Directories"

check "commands/ exists" \
    "[ -d '.claude/commands' ]" \
    "mkdir -p .claude/commands"

check "skills/ exists" \
    "[ -d '.claude/skills' ]" \
    "mkdir -p .claude/skills"

check "scripts/ exists" \
    "[ -d '.claude/scripts' ]" \
    "mkdir -p .claude/scripts"

check "learning/ exists" \
    "[ -d '.claude/learning' ]" \
    "mkdir -p .claude/learning"

check "logs/ exists" \
    "[ -d '.claude/logs' ]" \
    "mkdir -p .claude/logs"

check "backups/ exists" \
    "[ -d '.claude/backups' ]" \
    "mkdir -p .claude/backups"

echo ""
echo "## Skills"

SKILL_COUNT=$(find -L .claude/skills/claudenv .claude/skills/workspace -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
echo "   Found: $SKILL_COUNT skills"

for namespace in claudenv workspace; do
    if [ -d ".claude/skills/$namespace" ]; then
        for skill_dir in .claude/skills/$namespace/*/; do
            if [ -d "$skill_dir" ]; then
                skill_name=$(basename "$skill_dir")
                if [ -f "${skill_dir}SKILL.md" ]; then
                    # Check frontmatter
                    if head -1 "${skill_dir}SKILL.md" | grep -q "^---"; then
                        echo "   ✅ $namespace:$skill_name"
                        PASSED=$((PASSED + 1))
                    else
                        echo "   ⚠️  $namespace:$skill_name - missing frontmatter"
                        WARNINGS=$((WARNINGS + 1))
                    fi
                else
                    echo "   ❌ $namespace:$skill_name - missing SKILL.md"
                    ERRORS=$((ERRORS + 1))
                fi
            fi
        done
    fi
done

echo ""
echo "## Commands"

CMD_COUNT=$(find -L .claude/commands -name "*.md" 2>/dev/null | wc -l | tr -d ' ')
echo "   Found: $CMD_COUNT commands"
check "Commands directory not empty" "[ $CMD_COUNT -gt 0 ]"

echo ""
echo "## Scripts"

for script in .claude/scripts/*.sh; do
    if [ -f "$script" ]; then
        script_name=$(basename "$script")
        if [ -x "$script" ]; then
            echo "   ✅ $script_name (executable)"
            PASSED=$((PASSED + 1))
        else
            if [[ "$AUTO_FIX" == "true" ]]; then
                chmod +x "$script" && {
                    echo "   🔧 $script_name - made executable"
                    PASSED=$((PASSED + 1))
                    FIXES_APPLIED=$((FIXES_APPLIED + 1))
                } || {
                    echo "   ⚠️  $script_name (not executable)"
                    WARNINGS=$((WARNINGS + 1))
                }
            else
                echo "   ⚠️  $script_name (not executable)"
                WARNINGS=$((WARNINGS + 1))
            fi
        fi
    fi
done

echo ""
echo "## Learning Files"

warn "observations.md exists" \
    "[ -f '.claude/learning/working/observations.md' ]" \
    "echo '# Development Pattern Observations\n\n> Maintained by learning-agent skill.\n\n---\n\n## Session Log\n' > .claude/learning/working/observations.md"

warn "pending-skills.md exists" \
    "[ -f '.claude/learning/working/pending-skills.md' ]" \
    "touch .claude/learning/working/pending-skills.md"

warn "pending-commands.md exists" \
    "[ -f '.claude/learning/working/pending-commands.md' ]" \
    "touch .claude/learning/working/pending-commands.md"

warn "pending-hooks.md exists" \
    "[ -f '.claude/learning/working/pending-hooks.md' ]" \
    "touch .claude/learning/working/pending-hooks.md"

echo ""
echo "## Project Context"

warn "project-context.json exists" \
    "[ -f '.claude/project-context.json' ]"

if [ -f ".claude/project-context.json" ]; then
    warn "project-context.json is valid JSON" \
        "python3 -m json.tool .claude/project-context.json > /dev/null 2>&1 || jq . .claude/project-context.json > /dev/null 2>&1"
fi

warn "SPEC.md exists" \
    "[ -f '.claude/SPEC.md' ]"

echo ""
echo "## LSP Configuration"

warn "lsp-config.json exists" \
    "[ -f '.claude/lsp-config.json' ]"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Summary: $PASSED passed, $WARNINGS warnings, $ERRORS errors"
if [[ $FIXES_APPLIED -gt 0 ]]; then
    echo "         $FIXES_APPLIED issues auto-fixed"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Suggest fixes if not in auto-fix mode
if [[ "$AUTO_FIX" != "true" ]] && ([ $WARNINGS -gt 0 ] || [ $ERRORS -gt 0 ]); then
    echo ""
    echo "💡 Run with --fix to auto-repair issues:"
    echo "   bash .claude/scripts/validate.sh --fix"
    echo ""
    echo "Manual fixes:"

    # Check for non-executable scripts
    for script in .claude/scripts/*.sh; do
        if [ -f "$script" ] && [ ! -x "$script" ]; then
            echo "  chmod +x $script"
        fi
    done

    # Check for missing project context
    if [ ! -f ".claude/project-context.json" ]; then
        echo "  Run /claudenv to initialize project context"
    fi

    # Check for missing SPEC
    if [ ! -f ".claude/SPEC.md" ]; then
        echo "  Run /interview to create project specification"
    fi

    # Check for missing LSP config
    if [ ! -f ".claude/lsp-config.json" ]; then
        echo "  Run /lsp to setup language servers"
    fi
fi

# Exit with error if critical issues
if [ $ERRORS -gt 0 ]; then
    exit 1
fi

exit 0
