#!/bin/bash
# Block --no-verify and similar hook-bypassing flags
# Enforces that Claude must fix issues rather than bypass hooks
#
# Called by PreToolUse hook with JSON input containing tool_input.command
# Exit 0 = allow, Exit 2 = block with message

# Read JSON input from stdin
input=$(cat)

# Extract command from tool input
COMMAND=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

if [ -z "$COMMAND" ]; then
  # No command found, allow the operation
  exit 0
fi

# Check if this is a git command
if [[ "$COMMAND" =~ ^git[[:space:]] ]]; then

    # Extract just the command part before any -m "message" to avoid false positives
    # from commit messages that mention --no-verify
    CMD_BEFORE_MSG=$(echo "$COMMAND" | sed 's/ -m .*$//' | sed "s/ -m '.*$//" | sed 's/ -m ".*$//')

    # --no-verify is always blocked for any git command
    if [[ "$CMD_BEFORE_MSG" =~ [[:space:]]--no-verify([[:space:]]|$) ]]; then
        cat << 'BLOCKED_MSG'
BLOCKED: Cannot use '--no-verify' to bypass git hooks.

Fix the issues that hooks are catching instead of bypassing them.
Common fixes:
  - Run linter: npm run lint:fix / eslint --fix
  - Run formatter: npm run format / prettier --write
  - Fix type errors: npx tsc --noEmit
  - Run tests: npm test
BLOCKED_MSG
        exit 2
    fi

    # -n is --no-verify only for git commit (not git log -n 5, etc)
    if [[ "$CMD_BEFORE_MSG" =~ ^git[[:space:]]+commit ]] && [[ "$CMD_BEFORE_MSG" =~ [[:space:]]-n([[:space:]]|$) ]]; then
        cat << 'BLOCKED_MSG'
BLOCKED: Cannot use '-n' (--no-verify) to bypass git hooks.

Fix the issues that hooks are catching instead of bypassing them.
Common fixes:
  - Run linter: npm run lint:fix / eslint --fix
  - Run formatter: npm run format / prettier --write
  - Fix type errors: npx tsc --noEmit
  - Run tests: npm test
BLOCKED_MSG
        exit 2
    fi

    # Block --no-gpg-sign as well
    if [[ "$CMD_BEFORE_MSG" =~ [[:space:]]--no-gpg-sign([[:space:]]|$) ]]; then
        cat << 'BLOCKED_MSG'
BLOCKED: Cannot use '--no-gpg-sign' to bypass signing.

If GPG signing is required, configure it properly or discuss with the user.
BLOCKED_MSG
        exit 2
    fi
fi

# Allow the command
exit 0
