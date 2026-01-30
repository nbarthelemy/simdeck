---
description: Verify Claudenv infrastructure integrity. Validates settings, skills, hooks, and learning files.
allowed-tools: Bash
---

# /health:check - Verify Infrastructure Integrity

1. Run `bash .claude/scripts/health-check.sh` to collect health data as JSON
2. Format as a compact health report, counting passes/warnings/errors:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🏥 Health Check
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Settings:    {✅ valid / ❌ invalid/missing}
Permissions: {✅ configured / ⚠️ not configured}
Hooks:       {✅ configured / ⚠️ not configured}
Skills:      {✅ N valid / ⚠️ N missing SKILL.md}
Commands:    {✅ N valid / ⚠️ N empty}
Scripts:     {✅ all executable / ⚠️ N not executable}
Learning:    {✅ all present / ⚠️ N missing}
Context:     {✅ valid / ⚠️ missing}
Version:     {✅ vX.X.X / ⚠️ missing}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Result: {N} ✅ | {N} ⚠️ | {N} ❌
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Use ✅ for pass, ⚠️ for warning, ❌ for error. Keep compact.
