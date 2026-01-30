---
description: Mark a task as blocked in TODO.md with a reason
allowed-tools: Read, Edit, Glob
---

# /ce:blocker - Mark Task as Blocked

Mark the current or specified task as blocked in TODO.md.

**Usage:**
- `/ce:blocker "reason"` - Block current in-progress task
- `/ce:blocker "task name" "reason"` - Block specific task by name

## Process

1. **Find TODO.md**
   - Check `.claude/TODO.md` first
   - Fall back to `TODO.md` in project root

2. **Find Target Task**
   - If no task name provided: Find task marked with `[~]` (in progress)
   - If task name provided: Search for matching task

3. **Mark as Blocked**
   - Change checkbox from `[ ]` or `[~]` to `[!]`
   - Append blocker reason: `(blocked: {reason})`

4. **Output**
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🚫 Task Blocked
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Task: {task name}
   Reason: {reason}

   To unblock: Edit TODO.md and change [!] to [ ]
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

## Task Markers

| Marker | Meaning |
|--------|---------|
| `[ ]` | Pending |
| `[~]` | In progress |
| `[!]` | Blocked |
| `[x]` | Completed |

## Examples

```bash
# Block current task
/ce:blocker "Waiting on API keys from DevOps"

# Block specific task
/ce:blocker "Add authentication" "Need OAuth credentials"
```

## Subcommands

### /ce:blocker list
List all blocked tasks in TODO.md

### /ce:blocker clear "task name"
Remove blocker status from a task (change `[!]` back to `[ ]`)
