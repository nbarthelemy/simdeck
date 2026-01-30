#!/bin/bash
# Git Isolation Manager - Branch lifecycle management for feature isolation
# Usage: git-isolation-manager.sh <action> [args]
#
# Actions:
#   preflight [--stash-uncommitted]    Check git state before autopilot
#   create <feature-name>              Create feature branch
#   rollback <branch> <base>           Rollback failed feature
#   complete <branch> <base> [--merge|--keep|--squash]  Complete feature
#   restore_baseline [--apply-stash]   Restore original state

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
LOOP_DIR="$REPO_ROOT/.claude/loop"
STATE_FILE="$LOOP_DIR/autopilot-state.json"
FAILURES_DIR="$LOOP_DIR/failures"

# Ensure directories exist
init_dirs() {
    mkdir -p "$LOOP_DIR" "$FAILURES_DIR"
}

# Check if in git repo
is_git_repo() {
    git rev-parse --git-dir &>/dev/null
}

# Get current branch name
get_current_branch() {
    git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "HEAD"
}

# Get current commit SHA
get_current_commit() {
    git rev-parse HEAD 2>/dev/null || echo ""
}

# Check for uncommitted changes
has_uncommitted_changes() {
    [ -n "$(git status --porcelain 2>/dev/null)" ]
}

# Generate slug from feature name
slugify() {
    local name="$1"
    echo "$name" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//'
}

# Check if branch exists
branch_exists() {
    git rev-parse --verify "$1" &>/dev/null
}

# ==========================================
# PREFLIGHT - Check git state before autopilot
# ==========================================
preflight() {
    local stash_uncommitted=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --stash-uncommitted) stash_uncommitted=true; shift ;;
            *) shift ;;
        esac
    done

    init_dirs

    # Check if git repo
    if ! is_git_repo; then
        cat << 'JSONEOF'
{
  "gitReady": false,
  "error": true,
  "message": "Not a git repository"
}
JSONEOF
        return 1
    fi

    local current_branch=$(get_current_branch)
    local current_commit=$(get_current_commit)
    local stash_id=""

    # Handle uncommitted changes
    if has_uncommitted_changes; then
        if [ "$stash_uncommitted" = true ]; then
            stash_id=$(git stash push -u -m "autopilot-baseline-$(date +%Y%m%d_%H%M%S)" 2>&1 | grep -o 'stash@{[0-9]*}' || echo "")
            if [ -z "$stash_id" ]; then
                stash_id="stash@{0}"
            fi
        else
            # List uncommitted files
            local uncommitted=$(git status --porcelain | head -10 | jq -R . | jq -s .)
            cat << JSONEOF
{
  "gitReady": false,
  "error": true,
  "message": "Uncommitted changes detected. Use --stash-uncommitted or commit first.",
  "uncommittedFiles": $uncommitted
}
JSONEOF
            return 1
        fi
    fi

    # Check for detached HEAD
    local detached=false
    if [ "$current_branch" = "HEAD" ]; then
        detached=true
    fi

    cat << JSONEOF
{
  "gitReady": true,
  "baselineBranch": "$current_branch",
  "baselineCommit": "$current_commit",
  "stashId": $([ -n "$stash_id" ] && echo "\"$stash_id\"" || echo "null"),
  "detachedHead": $detached
}
JSONEOF
}

# ==========================================
# CREATE - Create feature branch
# ==========================================
create_branch() {
    local feature_name="$1"
    local base_branch="${2:-$(get_current_branch)}"

    if [ -z "$feature_name" ]; then
        echo '{"error": true, "message": "Feature name required"}'
        return 1
    fi

    init_dirs

    # Generate branch name
    local slug=$(slugify "$feature_name")
    local branch="autopilot/$slug"

    # Handle collision
    local counter=2
    while branch_exists "$branch"; do
        branch="autopilot/${slug}-${counter}"
        ((counter++))
    done

    # Record base state
    local base_commit=$(get_current_commit)

    # Create and checkout branch
    git checkout -b "$branch" >/dev/null 2>&1 || {
        echo '{"error": true, "message": "Failed to create branch"}'
        return 1
    }

    cat << JSONEOF
{
  "success": true,
  "featureBranch": "$branch",
  "baseBranch": "$base_branch",
  "baseCommit": "$base_commit",
  "featureName": $(echo "$feature_name" | jq -Rs .)
}
JSONEOF
}

# ==========================================
# ROLLBACK - Rollback failed feature
# ==========================================
rollback_branch() {
    local feature_branch="$1"
    local base_branch="$2"

    if [ -z "$feature_branch" ] || [ -z "$base_branch" ]; then
        echo '{"error": true, "message": "Feature branch and base branch required"}'
        return 1
    fi

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local branch_name=$(basename "$feature_branch")

    # Capture failure artifacts to temp before git clean (which deletes untracked files)
    local temp_diff=$(mktemp)
    local temp_log=$(mktemp)

    # Save diff (all changes on feature branch)
    git diff "$base_branch"..."$feature_branch" > "$temp_diff" 2>/dev/null || true

    # Save commit log
    git log --oneline "$base_branch".."$feature_branch" > "$temp_log" 2>/dev/null || true

    # Include uncommitted changes in diff
    if has_uncommitted_changes; then
        echo "" >> "$temp_diff"
        echo "# Uncommitted changes:" >> "$temp_diff"
        git diff >> "$temp_diff" 2>/dev/null || true
        git diff --cached >> "$temp_diff" 2>/dev/null || true
    fi

    # Discard uncommitted changes
    git reset --hard HEAD >/dev/null 2>&1 || true
    git clean -fd >/dev/null 2>&1 || true

    # Ensure directories exist after git clean
    init_dirs

    # Move failure artifacts from temp to final location
    local diff_file="$FAILURES_DIR/${branch_name}-${timestamp}.diff"
    local log_file="$FAILURES_DIR/${branch_name}-${timestamp}-commits.log"
    mv "$temp_diff" "$diff_file" 2>/dev/null || true
    mv "$temp_log" "$log_file" 2>/dev/null || true

    # Switch to base branch
    git checkout "$base_branch" >/dev/null 2>&1 || {
        echo '{"error": true, "message": "Failed to switch to base branch"}'
        return 1
    }

    # Delete feature branch
    git branch -D "$feature_branch" >/dev/null 2>&1 || true

    cat << JSONEOF
{
  "success": true,
  "rolledBack": true,
  "deletedBranch": "$feature_branch",
  "baseBranch": "$base_branch",
  "failureDiff": "$diff_file",
  "failureLog": "$log_file"
}
JSONEOF
}

# ==========================================
# COMPLETE - Complete successful feature
# ==========================================
complete_branch() {
    local feature_branch="$1"
    local base_branch="$2"
    local action="${3:---keep}"

    if [ -z "$feature_branch" ] || [ -z "$base_branch" ]; then
        echo '{"error": true, "message": "Feature branch and base branch required"}'
        return 1
    fi

    local current=$(get_current_branch)

    case "$action" in
        --merge)
            # Merge feature into base
            git checkout "$base_branch" >/dev/null 2>&1 || {
                echo '{"error": true, "message": "Failed to switch to base branch"}'
                return 1
            }

            if git merge --no-ff "$feature_branch" -m "Merge feature: $(basename "$feature_branch" | sed 's/autopilot\///')"; then
                git branch -D "$feature_branch" >/dev/null 2>&1 || true

                cat << JSONEOF
{
  "success": true,
  "action": "merged",
  "featureBranch": "$feature_branch",
  "baseBranch": "$base_branch",
  "branchDeleted": true
}
JSONEOF
            else
                # Merge conflict
                git merge --abort 2>/dev/null || true
                git checkout "$current" 2>/dev/null || true

                cat << JSONEOF
{
  "success": false,
  "error": true,
  "message": "Merge conflict detected. Branch preserved for manual resolution.",
  "featureBranch": "$feature_branch",
  "baseBranch": "$base_branch"
}
JSONEOF
                return 1
            fi
            ;;

        --squash)
            # Squash merge
            git checkout "$base_branch" >/dev/null 2>&1 || {
                echo '{"error": true, "message": "Failed to switch to base branch"}'
                return 1
            }

            if git merge --squash "$feature_branch" && git commit -m "feat: $(basename "$feature_branch" | sed 's/autopilot\///' | sed 's/-/ /g')"; then
                git branch -D "$feature_branch" >/dev/null 2>&1 || true

                cat << JSONEOF
{
  "success": true,
  "action": "squashed",
  "featureBranch": "$feature_branch",
  "baseBranch": "$base_branch",
  "branchDeleted": true
}
JSONEOF
            else
                git reset --hard HEAD 2>/dev/null || true
                git checkout "$current" 2>/dev/null || true

                cat << JSONEOF
{
  "success": false,
  "error": true,
  "message": "Squash merge failed. Branch preserved.",
  "featureBranch": "$feature_branch"
}
JSONEOF
                return 1
            fi
            ;;

        --keep|*)
            # Just switch back to base, keep branch for review
            git checkout "$base_branch" >/dev/null 2>&1 || {
                echo '{"error": true, "message": "Failed to switch to base branch"}'
                return 1
            }

            cat << JSONEOF
{
  "success": true,
  "action": "kept",
  "featureBranch": "$feature_branch",
  "baseBranch": "$base_branch",
  "branchDeleted": false,
  "message": "Branch kept for review. Merge manually when ready."
}
JSONEOF
            ;;
    esac
}

# ==========================================
# RESTORE_BASELINE - Restore original state
# ==========================================
restore_baseline() {
    local apply_stash=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --apply-stash) apply_stash=true; shift ;;
            *) shift ;;
        esac
    done

    # Read baseline from state file
    if [ ! -f "$STATE_FILE" ]; then
        echo '{"error": true, "message": "No autopilot state file found"}'
        return 1
    fi

    local baseline_branch=$(jq -r '.gitIsolation.baselineBranch // empty' "$STATE_FILE" 2>/dev/null)
    local stash_id=$(jq -r '.gitIsolation.stashId // empty' "$STATE_FILE" 2>/dev/null)

    if [ -z "$baseline_branch" ]; then
        echo '{"error": true, "message": "No baseline branch in state"}'
        return 1
    fi

    # Switch to baseline branch
    git checkout "$baseline_branch" >/dev/null 2>&1 || {
        echo '{"error": true, "message": "Failed to restore baseline branch"}'
        return 1
    }

    # Apply stash if requested and exists
    local stash_applied=false
    if [ "$apply_stash" = true ] && [ -n "$stash_id" ] && [ "$stash_id" != "null" ]; then
        if git stash pop "$stash_id" 2>/dev/null; then
            stash_applied=true
        else
            # Stash might have been already applied or doesn't exist
            stash_applied=false
        fi
    fi

    cat << JSONEOF
{
  "success": true,
  "baselineBranch": "$baseline_branch",
  "stashApplied": $stash_applied
}
JSONEOF
}

# ==========================================
# STATUS - Get current isolation status
# ==========================================
get_status() {
    local current_branch=$(get_current_branch)
    local on_feature_branch=false

    if [[ "$current_branch" == autopilot/* ]]; then
        on_feature_branch=true
    fi

    # Count autopilot branches
    local branch_count=$(git branch | grep -c "autopilot/" 2>/dev/null || echo "0")

    cat << JSONEOF
{
  "currentBranch": "$current_branch",
  "onFeatureBranch": $on_feature_branch,
  "autopilotBranches": $branch_count,
  "uncommittedChanges": $(has_uncommitted_changes && echo "true" || echo "false")
}
JSONEOF
}

# ==========================================
# LIST - List all autopilot branches
# ==========================================
list_branches() {
    local branches=$(git branch | grep "autopilot/" | sed 's/^[* ]*//' | jq -R . | jq -s .)
    cat << JSONEOF
{
  "branches": $branches
}
JSONEOF
}

# ==========================================
# CLEANUP - Remove all autopilot branches
# ==========================================
cleanup_branches() {
    local force="${1:-false}"
    local base_branch=$(get_current_branch)

    # Don't cleanup if on an autopilot branch
    if [[ "$base_branch" == autopilot/* ]]; then
        echo '{"error": true, "message": "Cannot cleanup while on autopilot branch"}'
        return 1
    fi

    local deleted=()
    local failed=()

    for branch in $(git branch | grep "autopilot/" | sed 's/^[* ]*//'); do
        if [ "$force" = "--force" ]; then
            if git branch -D "$branch" 2>/dev/null; then
                deleted+=("$branch")
            else
                failed+=("$branch")
            fi
        else
            if git branch -d "$branch" 2>/dev/null; then
                deleted+=("$branch")
            else
                failed+=("$branch")
            fi
        fi
    done

    cat << JSONEOF
{
  "deleted": $(printf '%s\n' "${deleted[@]}" | jq -R . | jq -s .),
  "failed": $(printf '%s\n' "${failed[@]}" | jq -R . | jq -s .),
  "message": "Use --force to delete unmerged branches"
}
JSONEOF
}

# Main dispatcher
case "${1:-}" in
    preflight)
        shift
        preflight "$@"
        ;;
    create)
        shift
        create_branch "$@"
        ;;
    rollback)
        shift
        rollback_branch "$@"
        ;;
    complete)
        shift
        complete_branch "$@"
        ;;
    restore_baseline)
        shift
        restore_baseline "$@"
        ;;
    status)
        get_status
        ;;
    list)
        list_branches
        ;;
    cleanup)
        shift
        cleanup_branches "$@"
        ;;
    *)
        echo "Usage: git-isolation-manager.sh <action> [args]"
        echo ""
        echo "Actions:"
        echo "  preflight [--stash-uncommitted]    Check git state before autopilot"
        echo "  create <feature-name>              Create feature branch"
        echo "  rollback <branch> <base>           Rollback failed feature"
        echo "  complete <branch> <base> [opt]     Complete feature (--merge|--keep|--squash)"
        echo "  restore_baseline [--apply-stash]   Restore original state"
        echo "  status                             Get current isolation status"
        echo "  list                               List autopilot branches"
        echo "  cleanup [--force]                  Remove autopilot branches"
        exit 1
        ;;
esac
