---
description: Debug hook configuration and execution. Lists all hooks, checks scripts, and shows recent executions.
allowed-tools: Bash
---

# /debug:hooks - Debug Hook Configuration

1. Run `bash .claude/scripts/debug-hooks.sh` to collect hook data as JSON
2. Format as a compact debug report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🪝 Hook Debug
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Configured Hooks:
  SessionStart: {count} | PostToolUse: {count} | Stop: {count}

Scripts ({total}):
  {list script names, mark ⚠️ if not executable}

Log: {exists ? "✅ Found" : "No log"} {recentErrors > 0 ? "⚠️ N errors" : ""}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If notExecutable > 0, show: "Fix: chmod +x .claude/scripts/*.sh"
