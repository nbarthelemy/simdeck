---
description: Display full Claudenv infrastructure status overview including detected stack, skills, commands, hooks, and pending proposals.
allowed-tools: Bash
---

# /claudenv:status - System Overview

1. Run `bash .claude/scripts/claudenv-status.sh` to collect status data as JSON
2. Format the JSON output as a nicely formatted status display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏗️  Claudenv Status (v{version})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Stack: {languages, frameworks} or "Not detected"
📋 Spec: {exists or "Missing"}

🤖 Skills: {count} | 🕵️ Agents: {count} | 📝 Commands: {count}

🪝 Hooks: SessionStart {✅/❌} | PostToolUse {✅/❌} | Stop {✅/❌}

📚 Learning: {observations} observations, {total pending} pending

✅ Health: Settings {✅/❌} | Scripts {✅/❌}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Keep the output compact (under 15 lines) so it displays inline without collapsing.
