---
description: Display all pending observations and proposals from the learning system. Shows skills, hooks, commands, and agents that can be implemented.
allowed-tools: Bash
---

# /learn:review - Review Pending Learnings

1. Run `bash .claude/scripts/learn-review.sh` to collect learning data as JSON
2. Format based on whether there are pending items:

**If no pending items** (`total: 0`):
```
📊 No pending proposals. Tracking {directories} directories, {extensions} extensions.
```

**If there are pending items**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Learning Review ({total} pending)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 Skills ({count}): {names joined by ", "}
🕵️ Agents ({count}): {names joined by ", "}
📝 Commands ({count}): {names joined by ", "}
🪝 Hooks ({count}): {names joined by ", "}

Patterns: {directories} dirs, {extensions} extensions tracked

To implement: /learn:implement <name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Only show categories that have items (count > 0).
