---
name: loop:status
description: Show current autonomous loop status
allowed-tools: Bash
---

# /loop:status - Loop Status

1. Run `bash .claude/scripts/loop-status.sh` to collect loop state as JSON
2. Format based on whether a loop is active:

**If no active loop** (`active: false`):
```
🔄 No active loop. Start with: /loop "<task>" --until "<condition>"
```

**If loop is active** (`active: true`):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Loop: {status emoji} {status}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 {prompt (truncated if long)}

Progress: [{bar}] {current}/{max} ({percentage}%)
Elapsed: {minutes}m | Limit: {maxTime}
Condition: {type} "{target}" - {met ? "✅ Met" : "pending"}
Files: {filesModified} modified

Commands: /loop:pause | /loop:resume | /loop:cancel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Status emojis: running=🟢, paused=⏸️, complete=✅, failed=❌
