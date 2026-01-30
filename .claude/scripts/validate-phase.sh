#!/bin/bash
# Validate Phase - Type checking and affected tests
# Usage: validate-phase.sh [file1 file2 ...]
# Returns JSON result

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
AFFECTED_FILES=("$@")

# If no files provided, get affected files for phase scope
if [ ${#AFFECTED_FILES[@]} -eq 0 ]; then
    if [ -f "$REPO_ROOT/.claude/scripts/get-affected-files.sh" ]; then
        mapfile -t AFFECTED_FILES < <(bash "$REPO_ROOT/.claude/scripts/get-affected-files.sh" phase)
    fi
fi

# Exit early if no files
if [ ${#AFFECTED_FILES[@]} -eq 0 ]; then
    cat << 'JSONEOF'
{
  "tier": "phase",
  "passed": true,
  "checks": {
    "types": {"passed": true, "errors": 0},
    "tests": {"passed": true, "testsRun": 0, "testsPassed": 0, "testsFailed": 0}
  },
  "elapsedTime": "0s",
  "affectedFiles": [],
  "message": "No files to validate"
}
JSONEOF
    exit 0
fi

START_TIME=$(date +%s)
TYPE_ERRORS=0
TEST_ERRORS=0
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Detect project type
HAS_TYPESCRIPT=false
HAS_PYTHON=false
HAS_GO=false
HAS_RUST=false

[ -f "tsconfig.json" ] && HAS_TYPESCRIPT=true
[ -f "pyproject.toml" ] || [ -f "requirements.txt" ] && HAS_PYTHON=true
[ -f "go.mod" ] && HAS_GO=true
[ -f "Cargo.toml" ] && HAS_RUST=true

# Run type checking
run_type_check() {
    # TypeScript
    if [ "$HAS_TYPESCRIPT" = true ]; then
        npx tsc --noEmit 2>&1 || TYPE_ERRORS=$((TYPE_ERRORS + 1))
    fi

    # Python (mypy)
    if [ "$HAS_PYTHON" = true ]; then
        PY_FILES=()
        for file in "${AFFECTED_FILES[@]}"; do
            [[ "$file" == *.py ]] && [ -f "$file" ] && PY_FILES+=("$file")
        done

        if [ ${#PY_FILES[@]} -gt 0 ]; then
            if command -v mypy &>/dev/null; then
                mypy "${PY_FILES[@]}" 2>&1 || TYPE_ERRORS=$((TYPE_ERRORS + 1))
            elif command -v pyright &>/dev/null; then
                pyright "${PY_FILES[@]}" 2>&1 || TYPE_ERRORS=$((TYPE_ERRORS + 1))
            fi
        fi
    fi

    # Go
    if [ "$HAS_GO" = true ]; then
        GO_FILES=()
        for file in "${AFFECTED_FILES[@]}"; do
            [[ "$file" == *.go ]] && [ -f "$file" ] && GO_FILES+=("$file")
        done

        if [ ${#GO_FILES[@]} -gt 0 ]; then
            # Get unique packages
            PACKAGES=$(printf '%s\n' "${GO_FILES[@]}" | xargs -n1 dirname 2>/dev/null | sort -u | sed 's|^|./|')
            if [ -n "$PACKAGES" ]; then
                go vet $PACKAGES 2>&1 || TYPE_ERRORS=$((TYPE_ERRORS + 1))
            fi
        fi
    fi

    # Rust
    if [ "$HAS_RUST" = true ]; then
        cargo check 2>&1 || TYPE_ERRORS=$((TYPE_ERRORS + 1))
    fi
}

# Find related test files
find_test_files() {
    local TEST_FILES=()

    for file in "${AFFECTED_FILES[@]}"; do
        [ ! -f "$file" ] && continue

        local dir=$(dirname "$file")
        local base=$(basename "$file")
        local name="${base%.*}"
        local ext="${base##*.}"

        case "$ext" in
            ts|tsx|js|jsx)
                # Look for test files in various patterns
                local patterns=(
                    "$dir/$name.test.$ext"
                    "$dir/$name.spec.$ext"
                    "$dir/__tests__/$name.$ext"
                    "${dir/src/tests}/$name.test.$ext"
                )
                for pattern in "${patterns[@]}"; do
                    [ -f "$pattern" ] && TEST_FILES+=("$pattern")
                done
                ;;
            py)
                # Python test patterns
                local patterns=(
                    "$dir/test_$name.py"
                    "${dir/src/tests}/test_$name.py"
                    "$dir/${name}_test.py"
                )
                for pattern in "${patterns[@]}"; do
                    [ -f "$pattern" ] && TEST_FILES+=("$pattern")
                done
                ;;
            go)
                # Go test file
                local test_file="${file%.go}_test.go"
                [ -f "$test_file" ] && TEST_FILES+=("$test_file")
                ;;
        esac
    done

    # Return unique list
    printf '%s\n' "${TEST_FILES[@]}" | sort -u
}

# Run tests for affected files
run_affected_tests() {
    mapfile -t TEST_FILES < <(find_test_files)

    if [ ${#TEST_FILES[@]} -eq 0 ]; then
        return 0
    fi

    TESTS_RUN=${#TEST_FILES[@]}

    # JavaScript/TypeScript tests
    if [ "$HAS_TYPESCRIPT" = true ] || [ -f "package.json" ]; then
        JS_TESTS=()
        for tf in "${TEST_FILES[@]}"; do
            [[ "$tf" == *.ts ]] || [[ "$tf" == *.js ]] || [[ "$tf" == *.tsx ]] || [[ "$tf" == *.jsx ]] && JS_TESTS+=("$tf")
        done

        if [ ${#JS_TESTS[@]} -gt 0 ]; then
            # Try jest first, then vitest
            if [ -f "jest.config.js" ] || [ -f "jest.config.ts" ]; then
                OUTPUT=$(npx jest "${JS_TESTS[@]}" --passWithNoTests --json 2>&1) || TEST_ERRORS=$((TEST_ERRORS + 1))
                TESTS_PASSED=$(echo "$OUTPUT" | jq -r '.numPassedTests // 0' 2>/dev/null || echo "0")
                TESTS_FAILED=$(echo "$OUTPUT" | jq -r '.numFailedTests // 0' 2>/dev/null || echo "0")
            elif [ -f "vitest.config.ts" ] || [ -f "vitest.config.js" ]; then
                npx vitest run "${JS_TESTS[@]}" 2>&1 || TEST_ERRORS=$((TEST_ERRORS + 1))
            else
                npm test -- "${JS_TESTS[@]}" 2>&1 || TEST_ERRORS=$((TEST_ERRORS + 1))
            fi
        fi
    fi

    # Python tests
    if [ "$HAS_PYTHON" = true ]; then
        PY_TESTS=()
        for tf in "${TEST_FILES[@]}"; do
            [[ "$tf" == *.py ]] && PY_TESTS+=("$tf")
        done

        if [ ${#PY_TESTS[@]} -gt 0 ] && command -v pytest &>/dev/null; then
            OUTPUT=$(pytest "${PY_TESTS[@]}" -v --tb=short 2>&1) || TEST_ERRORS=$((TEST_ERRORS + 1))
            TESTS_PASSED=$(echo "$OUTPUT" | grep -c " passed" || echo "0")
            TESTS_FAILED=$(echo "$OUTPUT" | grep -c " failed" || echo "0")
        fi
    fi

    # Go tests
    if [ "$HAS_GO" = true ]; then
        GO_TESTS=()
        for tf in "${TEST_FILES[@]}"; do
            [[ "$tf" == *_test.go ]] && GO_TESTS+=("$tf")
        done

        if [ ${#GO_TESTS[@]} -gt 0 ]; then
            PACKAGES=$(printf '%s\n' "${GO_TESTS[@]}" | xargs -n1 dirname | sort -u | sed 's|^|./|')
            go test -v $PACKAGES 2>&1 || TEST_ERRORS=$((TEST_ERRORS + 1))
        fi
    fi

    # Rust tests
    if [ "$HAS_RUST" = true ]; then
        cargo test 2>&1 || TEST_ERRORS=$((TEST_ERRORS + 1))
    fi
}

# Run checks
run_type_check
run_affected_tests

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

TYPES_PASSED=$([ $TYPE_ERRORS -eq 0 ] && echo "true" || echo "false")
TESTS_OK=$([ $TEST_ERRORS -eq 0 ] && echo "true" || echo "false")
PASSED=$([ "$TYPES_PASSED" = "true" ] && [ "$TESTS_OK" = "true" ] && echo "true" || echo "false")

# Build JSON array of files
FILES_JSON=$(printf '%s\n' "${AFFECTED_FILES[@]}" | jq -R . | jq -s .)

# Output JSON result
cat << JSONEOF
{
  "tier": "phase",
  "passed": $PASSED,
  "checks": {
    "types": {
      "passed": $TYPES_PASSED,
      "errors": $TYPE_ERRORS
    },
    "tests": {
      "passed": $TESTS_OK,
      "testsRun": $TESTS_RUN,
      "testsPassed": $TESTS_PASSED,
      "testsFailed": $TESTS_FAILED
    }
  },
  "elapsedTime": "${ELAPSED}s",
  "affectedFiles": $FILES_JSON
}
JSONEOF

exit $([ "$PASSED" = "true" ] && echo 0 || echo 1)
