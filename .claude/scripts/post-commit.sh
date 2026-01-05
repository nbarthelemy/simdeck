#!/bin/bash
# Post-commit Hook
# Runs after git commits to log and notify

COMMIT_HASH=$(git rev-parse --short HEAD 2>/dev/null)
COMMIT_MSG=$(git log -1 --pretty=%s 2>/dev/null)

# Log the commit
echo "[$(date -Iseconds)] Commit: $COMMIT_HASH - $COMMIT_MSG" >> .claude/logs/hook-executions.log 2>/dev/null || true

# Brief notification (non-blocking)
echo "✅ Committed: $COMMIT_HASH"
