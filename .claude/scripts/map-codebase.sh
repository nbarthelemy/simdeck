#!/bin/bash
# Map Codebase Script - Initialize and check codebase analysis
# Usage: map-codebase.sh [init|status|clean]

set -e

# Always resolve paths relative to repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
CODEBASE_DIR="$REPO_ROOT/.claude/codebase"

# Documents to generate
DOCUMENTS=(
    "ARCHITECTURE.md"
    "STRUCTURE.md"
    "CONVENTIONS.md"
    "TESTING.md"
    "INTEGRATIONS.md"
    "CONCERNS.md"
)

# Initialize codebase directory
init_codebase_dir() {
    mkdir -p "$CODEBASE_DIR"
    echo '{"initialized": true, "timestamp": "'$(date -Iseconds)'"}'
}

# Check status of existing documents
check_status() {
    local existing=0
    local missing=0
    local docs_status="["

    for doc in "${DOCUMENTS[@]}"; do
        if [ -f "$CODEBASE_DIR/$doc" ]; then
            existing=$((existing + 1))
            local mod_time=$(stat -f "%Sm" -t "%Y-%m-%d" "$CODEBASE_DIR/$doc" 2>/dev/null || stat -c "%y" "$CODEBASE_DIR/$doc" 2>/dev/null | cut -d' ' -f1)
            docs_status+="{\"name\": \"$doc\", \"exists\": true, \"modified\": \"$mod_time\"},"
        else
            missing=$((missing + 1))
            docs_status+="{\"name\": \"$doc\", \"exists\": false},"
        fi
    done

    # Remove trailing comma and close array
    docs_status="${docs_status%,}]"

    cat << JSONEOF
{
  "directory": "$CODEBASE_DIR",
  "initialized": $([ -d "$CODEBASE_DIR" ] && echo "true" || echo "false"),
  "totalDocuments": ${#DOCUMENTS[@]},
  "existing": $existing,
  "missing": $missing,
  "complete": $([ "$missing" -eq 0 ] && echo "true" || echo "false"),
  "documents": $docs_status
}
JSONEOF
}

# Clean codebase directory
clean_codebase() {
    if [ -d "$CODEBASE_DIR" ]; then
        rm -rf "$CODEBASE_DIR"
        echo '{"cleaned": true}'
    else
        echo '{"cleaned": false, "message": "Directory does not exist"}'
    fi
}

# Main dispatcher
case "${1:-status}" in
    init)
        init_codebase_dir
        ;;
    status)
        check_status
        ;;
    clean)
        clean_codebase
        ;;
    --help|-h)
        echo "Usage: map-codebase.sh [init|status|clean]"
        echo ""
        echo "Commands:"
        echo "  init    Create .claude/codebase/ directory"
        echo "  status  Check status of analysis documents"
        echo "  clean   Remove codebase directory"
        ;;
    *)
        check_status
        ;;
esac
