#!/bin/bash
# Get Affected Files - Determine files modified in current scope
# Usage: get-affected-files.sh <scope>
# Scopes: task | phase | feature | commit

set -e

SCOPE="${1:-task}"
REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
PLAN_STATE_FILE="$REPO_ROOT/.claude/loop/plan-state.json"

# Check if in git repo
is_git_repo() {
    git rev-parse --git-dir &>/dev/null
}

# Get unique, sorted list of files
get_unique_files() {
    sort -u | grep -v '^$' || true
}

# Get files for task scope (uncommitted changes)
get_task_files() {
    {
        # Unstaged changes
        git diff --name-only 2>/dev/null || true
        # Staged changes
        git diff --cached --name-only 2>/dev/null || true
    } | get_unique_files
}

# Get files for phase scope (all changes in current phase)
get_phase_files() {
    # Try to get phase start time from state
    if [ -f "$PLAN_STATE_FILE" ]; then
        local phase_start=$(jq -r '.currentPhaseStartedAt // empty' "$PLAN_STATE_FILE" 2>/dev/null)
        if [ -n "$phase_start" ]; then
            # Get files from commits since phase start + uncommitted
            {
                # Parse ISO timestamp for git log
                git log --since="$phase_start" --name-only --pretty=format: 2>/dev/null || true
                # Plus uncommitted changes
                get_task_files
            } | get_unique_files
            return
        fi
    fi

    # Fallback: uncommitted changes only
    get_task_files
}

# Get files for feature scope (all changes on feature branch)
get_feature_files() {
    # Determine base branch
    local main_branch
    main_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")

    # Check if we're on a feature branch
    local current_branch
    current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD")

    if [[ "$current_branch" == autopilot/* ]]; then
        # On feature branch - get all changes from branch point
        {
            git diff --name-only "$main_branch"...HEAD 2>/dev/null || true
            get_task_files
        } | get_unique_files
    else
        # Not on feature branch - use uncommitted changes
        get_task_files
    fi
}

# Get files for commit scope (files from last commit)
get_commit_files() {
    git diff HEAD~1 --name-only 2>/dev/null | get_unique_files
}

# Main
if ! is_git_repo; then
    echo "ERROR: Not a git repository" >&2
    exit 1
fi

case "$SCOPE" in
    task)
        get_task_files
        ;;
    phase)
        get_phase_files
        ;;
    feature)
        get_feature_files
        ;;
    commit)
        get_commit_files
        ;;
    *)
        echo "Usage: get-affected-files.sh <task|phase|feature|commit>" >&2
        exit 1
        ;;
esac
