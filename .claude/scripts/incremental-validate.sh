#!/bin/bash
# Incremental Validate - Orchestrator for tiered validation
# Usage: incremental-validate.sh <tier> [options] [files...]
# Tiers: task | phase | feature
# Options: --fix (auto-fix for task tier)

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
SCRIPTS_DIR="$REPO_ROOT/.claude/scripts"

# Parse arguments
TIER="${1:-task}"
shift || true

FIX_FLAG=""
AFFECTED_FILES=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix) FIX_FLAG="--fix"; shift ;;
        --affected)
            shift
            while [[ $# -gt 0 ]] && [[ ! "$1" =~ ^-- ]]; do
                AFFECTED_FILES+=("$1")
                shift
            done
            ;;
        --help|-h)
            echo "Usage: incremental-validate.sh <tier> [options] [files...]"
            echo ""
            echo "Tiers:"
            echo "  task     Fast lint check (<5s) with auto-fix"
            echo "  phase    Type check + affected tests (<30s)"
            echo "  feature  Full validation suite"
            echo ""
            echo "Options:"
            echo "  --fix             Auto-fix lint issues (task tier only)"
            echo "  --affected <files>  Validate specific files"
            echo ""
            echo "Examples:"
            echo "  incremental-validate.sh task --fix"
            echo "  incremental-validate.sh phase src/api/user.ts"
            echo "  incremental-validate.sh feature"
            exit 0
            ;;
        *)
            # Treat as file
            AFFECTED_FILES+=("$1")
            shift
            ;;
    esac
done

# Route to tier-specific script
case "$TIER" in
    task)
        if [ -f "$SCRIPTS_DIR/validate-task.sh" ]; then
            if [ ${#AFFECTED_FILES[@]} -gt 0 ]; then
                bash "$SCRIPTS_DIR/validate-task.sh" $FIX_FLAG "${AFFECTED_FILES[@]}"
            else
                bash "$SCRIPTS_DIR/validate-task.sh" $FIX_FLAG
            fi
        else
            echo '{"error": true, "message": "validate-task.sh not found"}'
            exit 1
        fi
        ;;

    phase)
        if [ -f "$SCRIPTS_DIR/validate-phase.sh" ]; then
            if [ ${#AFFECTED_FILES[@]} -gt 0 ]; then
                bash "$SCRIPTS_DIR/validate-phase.sh" "${AFFECTED_FILES[@]}"
            else
                bash "$SCRIPTS_DIR/validate-phase.sh"
            fi
        else
            echo '{"error": true, "message": "validate-phase.sh not found"}'
            exit 1
        fi
        ;;

    feature)
        # Full validation - delegate to existing /validate or run full suite
        START_TIME=$(date +%s)
        PASSED=true

        # Run lint
        LINT_RESULT=0
        if [ -f "package.json" ] && [ -f "node_modules/.bin/eslint" ]; then
            npx eslint . --ext .ts,.tsx,.js,.jsx || LINT_RESULT=$?
        elif command -v ruff &>/dev/null; then
            ruff check . || LINT_RESULT=$?
        fi
        [ $LINT_RESULT -ne 0 ] && PASSED=false

        # Run type check
        TYPE_RESULT=0
        if [ -f "tsconfig.json" ]; then
            npx tsc --noEmit || TYPE_RESULT=$?
        elif command -v mypy &>/dev/null && [ -f "pyproject.toml" ]; then
            mypy . || TYPE_RESULT=$?
        elif [ -f "go.mod" ]; then
            go vet ./... || TYPE_RESULT=$?
        fi
        [ $TYPE_RESULT -ne 0 ] && PASSED=false

        # Run tests
        TEST_RESULT=0
        if [ -f "package.json" ]; then
            npm test 2>&1 || TEST_RESULT=$?
        elif command -v pytest &>/dev/null; then
            pytest 2>&1 || TEST_RESULT=$?
        elif [ -f "go.mod" ]; then
            go test ./... 2>&1 || TEST_RESULT=$?
        elif [ -f "Cargo.toml" ]; then
            cargo test 2>&1 || TEST_RESULT=$?
        fi
        [ $TEST_RESULT -ne 0 ] && PASSED=false

        # Run build
        BUILD_RESULT=0
        if [ "$PASSED" = true ]; then
            if [ -f "package.json" ]; then
                npm run build 2>&1 || BUILD_RESULT=$?
            elif [ -f "go.mod" ]; then
                go build ./... 2>&1 || BUILD_RESULT=$?
            elif [ -f "Cargo.toml" ]; then
                cargo build 2>&1 || BUILD_RESULT=$?
            fi
            [ $BUILD_RESULT -ne 0 ] && PASSED=false
        fi

        END_TIME=$(date +%s)
        ELAPSED=$((END_TIME - START_TIME))

        cat << JSONEOF
{
  "tier": "feature",
  "passed": $PASSED,
  "checks": {
    "lint": {"passed": $([ $LINT_RESULT -eq 0 ] && echo "true" || echo "false")},
    "types": {"passed": $([ $TYPE_RESULT -eq 0 ] && echo "true" || echo "false")},
    "tests": {"passed": $([ $TEST_RESULT -eq 0 ] && echo "true" || echo "false")},
    "build": {"passed": $([ $BUILD_RESULT -eq 0 ] && echo "true" || echo "false")}
  },
  "elapsedTime": "${ELAPSED}s"
}
JSONEOF

        exit $([ "$PASSED" = "true" ] && echo 0 || echo 1)
        ;;

    *)
        echo '{"error": true, "message": "Invalid tier. Use: task, phase, or feature"}'
        exit 1
        ;;
esac
