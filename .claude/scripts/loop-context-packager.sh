#!/bin/bash
# Loop Context Packager - Package task context for fresh subagent execution
# Usage: loop-context-packager.sh [--task-json <json>] [--plan-file <file>]

set -e

# Always resolve paths relative to repo root
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

# Parse arguments
TASK_JSON=""
PLAN_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --task-json)
            TASK_JSON="$2"
            shift 2
            ;;
        --plan-file)
            PLAN_FILE="$2"
            shift 2
            ;;
        --help)
            echo "Usage: loop-context-packager.sh [options]"
            echo ""
            echo "Options:"
            echo "  --task-json <json>  Structured task JSON from parse_structured_task"
            echo "  --plan-file <file>  Plan file to extract context from"
            echo ""
            echo "Output: JSON context package for subagent"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Get project context if available
get_project_context() {
    local context_file="$REPO_ROOT/.claude/project-context.json"
    if [ -f "$context_file" ]; then
        # Extract relevant fields only
        jq '{
            projectName: .projectName,
            detected: .detected,
            confidence: .confidence
        }' "$context_file" 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

# Get CLAUDE.md summary (first 50 lines)
get_claude_md_summary() {
    local claude_md="$REPO_ROOT/CLAUDE.md"
    if [ -f "$claude_md" ]; then
        head -50 "$claude_md" | jq -Rs .
    else
        echo '""'
    fi
}

# Get relevant file contents (max 5 files, max 100 lines each)
get_relevant_files() {
    local files="$1"
    local result="[]"

    if [ -z "$files" ]; then
        echo "[]"
        return
    fi

    # Split comma-separated files
    IFS=',' read -ra FILE_ARRAY <<< "$files"

    for file in "${FILE_ARRAY[@]}"; do
        # Trim whitespace
        file=$(echo "$file" | xargs)

        # Skip if file doesn't exist
        if [ ! -f "$REPO_ROOT/$file" ]; then
            continue
        fi

        # Get file content (max 100 lines)
        local content=$(head -100 "$REPO_ROOT/$file" | jq -Rs .)
        local line_count=$(wc -l < "$REPO_ROOT/$file" | xargs)

        # Add to result array
        result=$(echo "$result" | jq --arg f "$file" --argjson c "$content" --arg lc "$line_count" '. += [{
            "path": $f,
            "content": $c,
            "lineCount": ($lc | tonumber),
            "truncated": (($lc | tonumber) > 100)
        }]')
    done

    echo "$result"
}

# Main packaging function
package_context() {
    local task_id=""
    local task_description=""
    local task_files=""
    local task_action=""
    local task_verify=""
    local task_done=""

    # Parse task JSON if provided
    if [ -n "$TASK_JSON" ]; then
        task_id=$(echo "$TASK_JSON" | jq -r '.taskId // ""')
        task_description=$(echo "$TASK_JSON" | jq -r '.description // ""')
        task_files=$(echo "$TASK_JSON" | jq -r '.files // ""')
        task_action=$(echo "$TASK_JSON" | jq -r '.action // ""')
        task_verify=$(echo "$TASK_JSON" | jq -r '.verify // ""')
        task_done=$(echo "$TASK_JSON" | jq -r '.done // ""')
    fi

    # Get project context
    local project_context=$(get_project_context)

    # Get CLAUDE.md summary
    local claude_summary=$(get_claude_md_summary)

    # Get relevant files content
    local relevant_files=$(get_relevant_files "$task_files")

    # Get plan overview if plan file provided
    local plan_overview='""'
    if [ -n "$PLAN_FILE" ] && [ -f "$PLAN_FILE" ]; then
        # Extract overview and current phase
        plan_overview=$(head -50 "$PLAN_FILE" | jq -Rs .)
    fi

    # Output context package
    cat << JSONEOF
{
  "task": {
    "id": "$task_id",
    "description": $(echo "$task_description" | jq -Rs .),
    "files": $(echo "$task_files" | jq -Rs .),
    "action": $(echo "$task_action" | jq -Rs .),
    "verify": $(echo "$task_verify" | jq -Rs .),
    "done": $(echo "$task_done" | jq -Rs .)
  },
  "projectContext": $project_context,
  "claudeMdSummary": $claude_summary,
  "relevantFiles": $relevant_files,
  "planOverview": $plan_overview,
  "constraints": {
    "singleTask": true,
    "returnStructuredResult": true,
    "followExistingPatterns": true
  },
  "outputFormat": {
    "required": ["status", "summary", "filesModified"],
    "example": {
      "status": "success|failure|partial",
      "summary": "Brief description of what was done",
      "filesModified": ["path/to/file.ts"],
      "blockers": []
    }
  }
}
JSONEOF
}

package_context
