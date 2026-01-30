#!/bin/bash
# Validate Task - Fast lint check on affected files with auto-fix
# Usage: validate-task.sh [--fix] [file1 file2 ...]
# Returns JSON result

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
FIX_MODE=false
AFFECTED_FILES=()

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --fix) FIX_MODE=true; shift ;;
        *) AFFECTED_FILES+=("$1"); shift ;;
    esac
done

# If no files provided, get affected files for task scope
if [ ${#AFFECTED_FILES[@]} -eq 0 ]; then
    if [ -f "$REPO_ROOT/.claude/scripts/get-affected-files.sh" ]; then
        mapfile -t AFFECTED_FILES < <(bash "$REPO_ROOT/.claude/scripts/get-affected-files.sh" task)
    fi
fi

# Exit early if no files
if [ ${#AFFECTED_FILES[@]} -eq 0 ]; then
    cat << 'JSONEOF'
{
  "tier": "task",
  "passed": true,
  "checks": {
    "lint": {"passed": true, "filesChecked": 0, "errors": 0, "autoFixed": 0}
  },
  "elapsedTime": "0s",
  "affectedFiles": [],
  "message": "No files to validate"
}
JSONEOF
    exit 0
fi

START_TIME=$(date +%s)
ERRORS=0
AUTO_FIXED=0
LINT_OUTPUT=""

# Filter files by extension
TS_FILES=()
JS_FILES=()
PY_FILES=()
GO_FILES=()
RS_FILES=()

for file in "${AFFECTED_FILES[@]}"; do
    # Skip if file doesn't exist
    [ ! -f "$file" ] && continue

    case "$file" in
        *.ts|*.tsx) TS_FILES+=("$file") ;;
        *.js|*.jsx) JS_FILES+=("$file") ;;
        *.py) PY_FILES+=("$file") ;;
        *.go) GO_FILES+=("$file") ;;
        *.rs) RS_FILES+=("$file") ;;
    esac
done

# TypeScript/JavaScript linting
if [ ${#TS_FILES[@]} -gt 0 ] || [ ${#JS_FILES[@]} -gt 0 ]; then
    ALL_JS_FILES=("${TS_FILES[@]}" "${JS_FILES[@]}")

    if [ -f "node_modules/.bin/eslint" ]; then
        if [ "$FIX_MODE" = true ]; then
            OUTPUT=$(npx eslint "${ALL_JS_FILES[@]}" --fix 2>&1) || ERRORS=$((ERRORS + 1))
            # Count fixed issues
            AUTO_FIXED=$(echo "$OUTPUT" | grep -c "fixed" || echo "0")
        else
            OUTPUT=$(npx eslint "${ALL_JS_FILES[@]}" 2>&1) || ERRORS=$((ERRORS + 1))
        fi
        LINT_OUTPUT+="$OUTPUT"
    elif [ -f "biome.json" ] && command -v biome &>/dev/null; then
        if [ "$FIX_MODE" = true ]; then
            OUTPUT=$(npx biome check --apply "${ALL_JS_FILES[@]}" 2>&1) || ERRORS=$((ERRORS + 1))
        else
            OUTPUT=$(npx biome check "${ALL_JS_FILES[@]}" 2>&1) || ERRORS=$((ERRORS + 1))
        fi
        LINT_OUTPUT+="$OUTPUT"
    fi
fi

# Python linting
if [ ${#PY_FILES[@]} -gt 0 ]; then
    if command -v ruff &>/dev/null; then
        if [ "$FIX_MODE" = true ]; then
            OUTPUT=$(ruff check "${PY_FILES[@]}" --fix 2>&1) || ERRORS=$((ERRORS + 1))
            AUTO_FIXED=$((AUTO_FIXED + $(echo "$OUTPUT" | grep -c "Fixed" || echo "0")))
        else
            OUTPUT=$(ruff check "${PY_FILES[@]}" 2>&1) || ERRORS=$((ERRORS + 1))
        fi
        LINT_OUTPUT+="$OUTPUT"
    fi

    if [ "$FIX_MODE" = true ] && command -v black &>/dev/null; then
        OUTPUT=$(black "${PY_FILES[@]}" 2>&1) || true
        AUTO_FIXED=$((AUTO_FIXED + $(echo "$OUTPUT" | grep -c "reformatted" || echo "0")))
    fi
fi

# Go linting
if [ ${#GO_FILES[@]} -gt 0 ]; then
    if [ "$FIX_MODE" = true ]; then
        gofmt -w "${GO_FILES[@]}" 2>&1 || true
        AUTO_FIXED=$((AUTO_FIXED + ${#GO_FILES[@]}))
    else
        OUTPUT=$(gofmt -l "${GO_FILES[@]}" 2>&1) || true
        if [ -n "$OUTPUT" ]; then
            ERRORS=$((ERRORS + 1))
            LINT_OUTPUT+="Go files need formatting: $OUTPUT"
        fi
    fi
fi

# Rust linting
if [ ${#RS_FILES[@]} -gt 0 ]; then
    if command -v cargo &>/dev/null; then
        if [ "$FIX_MODE" = true ]; then
            cargo fmt 2>&1 || true
        else
            OUTPUT=$(cargo fmt --check 2>&1) || ERRORS=$((ERRORS + 1))
            LINT_OUTPUT+="$OUTPUT"
        fi
    fi
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
PASSED=$([ $ERRORS -eq 0 ] && echo "true" || echo "false")

# Build JSON array of files
FILES_JSON=$(printf '%s\n' "${AFFECTED_FILES[@]}" | jq -R . | jq -s .)

# Output JSON result
cat << JSONEOF
{
  "tier": "task",
  "passed": $PASSED,
  "checks": {
    "lint": {
      "passed": $PASSED,
      "filesChecked": ${#AFFECTED_FILES[@]},
      "errors": $ERRORS,
      "autoFixed": $AUTO_FIXED
    }
  },
  "elapsedTime": "${ELAPSED}s",
  "affectedFiles": $FILES_JSON
}
JSONEOF

exit $([ "$PASSED" = "true" ] && echo 0 || echo 1)
