#!/bin/bash
# Pre-commit Hook
# Runs before git commits to check for issues

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Pre-commit Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Count staged files
STAGED=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | wc -l | tr -d ' ')
echo "📁 Staged files: $STAGED"

WARNINGS=0
ERRORS=0

# Secret scanning
echo ""
echo "🔐 Scanning for secrets..."

STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null)
SECRETS_FOUND=0

for file in $STAGED_FILES; do
    # Skip allowed files
    case "$file" in
        *.example|*.template|*.sample|.env.example|.env.template|*.md)
            continue
            ;;
    esac

    # Skip binary files
    if file "$file" 2>/dev/null | grep -qE 'binary|image|executable'; then
        continue
    fi

    # Check for potential secrets
    if [ -f "$file" ]; then
        # API keys
        if grep -qE "(sk-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|gho_[a-zA-Z0-9]{36}|AKIA[0-9A-Z]{16})" "$file" 2>/dev/null; then
            echo "   ⚠️  Potential API key in: $file"
            SECRETS_FOUND=1
            WARNINGS=$((WARNINGS + 1))
        fi

        # Private keys
        if grep -q "-----BEGIN.*PRIVATE KEY-----" "$file" 2>/dev/null; then
            echo "   ⚠️  Private key in: $file"
            SECRETS_FOUND=1
            WARNINGS=$((WARNINGS + 1))
        fi

        # Generic secrets
        if grep -qiE "(password|secret|token)\s*[=:]\s*['\"][^'\"]{8,}['\"]" "$file" 2>/dev/null; then
            echo "   ⚠️  Potential secret in: $file"
            SECRETS_FOUND=1
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
done

if [ "$SECRETS_FOUND" -eq 0 ]; then
    echo "   ✅ No secrets detected"
fi

# Check for large files
echo ""
echo "📏 Checking file sizes..."

for file in $STAGED_FILES; do
    if [ -f "$file" ]; then
        SIZE=$(wc -c < "$file" 2>/dev/null | tr -d ' ')
        # Warn if > 1MB
        if [ "$SIZE" -gt 1048576 ]; then
            SIZE_MB=$((SIZE / 1048576))
            echo "   ⚠️  Large file (${SIZE_MB}MB): $file"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
done

# Check for debug statements
echo ""
echo "🐛 Checking for debug statements..."

DEBUG_FOUND=0
for file in $STAGED_FILES; do
    case "$file" in
        *.js|*.ts|*.jsx|*.tsx)
            if grep -qE "console\.(log|debug|warn)\(" "$file" 2>/dev/null; then
                echo "   ⚠️  console.log in: $file"
                DEBUG_FOUND=1
            fi
            ;;
        *.py)
            if grep -qE "^[^#]*\bprint\(" "$file" 2>/dev/null; then
                echo "   ⚠️  print() in: $file"
                DEBUG_FOUND=1
            fi
            ;;
    esac
done

if [ "$DEBUG_FOUND" -eq 0 ]; then
    echo "   ✅ No debug statements found"
fi

# Show pending learnings
PENDING=$(grep -c "^### " .claude/learning/working/pending-skills.md 2>/dev/null || echo "0")
if [ "$PENDING" -gt 0 ]; then
    echo ""
    echo "💡 $PENDING skill proposals pending (/learn:review)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [ "$ERRORS" -gt 0 ]; then
    echo "❌ $ERRORS errors, $WARNINGS warnings"
    echo "   Fix errors before committing"
    exit 1
elif [ "$WARNINGS" -gt 0 ]; then
    echo "⚠️  $WARNINGS warnings (commit allowed)"
else
    echo "✅ All checks passed"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Log hook execution
echo "[$(date -Iseconds)] Pre-commit check: $ERRORS errors, $WARNINGS warnings" >> .claude/logs/hook-executions.log 2>/dev/null || true

exit 0
