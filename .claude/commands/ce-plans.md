---
description: List all plans by status
allowed-tools: Bash
---

# /ce:plans - List Plans

Run `bash .claude/scripts/plans-list.sh` to collect plan data as JSON.

**If error** (`error: true`): Show error message.

**Format output as:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Plans
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔴 Draft ({count})
  • {name}
  • {name}

🟡 Ready ({count})
  • {name}

🟢 In Progress ({count})
  • {name} ← active

⏸️ Blocked ({count})
  • {name}: {reason}

✅ Completed ({count})
  • {name}
  • {name}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Rules:**
- Only show sections that have plans (skip empty sections)
- Mark in_progress plans with `← active`
- Show "(0 plans)" message if no plans exist at all
- Keep output compact

**If no plans exist:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Plans
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

No plans found.

Create one with:
  /ce:feature "Your feature description"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
