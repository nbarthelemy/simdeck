---
description: Phase management for TODO.md - insert, remove, move, reorder tasks
allowed-tools: Read, Edit, Bash
---

# /ce:phase - Phase Management

Manage phases and tasks in TODO.md with operations to insert, remove, move, and view task status.

**Usage:**
- `/ce:phase` or `/ce:phase status` - Show task counts and progress
- `/ce:phase list` - List all tasks with their status
- `/ce:phase insert "task" --after "other task"` - Insert task after another
- `/ce:phase remove "task pattern"` - Remove a task
- `/ce:phase move "task" --to "P1"` - Move task to different section

## Actions

### Status (default)

```bash
bash .claude/scripts/phase-manager.sh status
```

**Output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Phase Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Progress: {completed}/{total} ({percentage}%)

Tasks:
  [ ] Pending:     {count}
  [~] In Progress: {count}
  [!] Blocked:     {count}
  [x] Completed:   {count}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### List

```bash
bash .claude/scripts/phase-manager.sh list
```

Show all tasks with their status and line numbers.

### Insert

Insert a new task after an existing task:

```bash
bash .claude/scripts/phase-manager.sh insert "Add caching layer" "after:Implement API"
```

**Arguments:**
- First: New task description
- Second: Task to insert after (pattern match)

### Remove

Remove a task by pattern:

```bash
bash .claude/scripts/phase-manager.sh remove "Legacy migration"
```

**Confirmation:** Before removing, confirm with user unless task is already completed.

### Move

Move a task to a different section:

```bash
bash .claude/scripts/phase-manager.sh move "Add analytics" "P2"
```

**Sections:** P0, P1, P2, Backlog, Current Focus

## Task Markers

| Marker | Status | Meaning |
|--------|--------|---------|
| `[ ]` | pending | Not started |
| `[~]` | in_progress | Currently working on |
| `[!]` | blocked | Waiting on something |
| `[x]` | completed | Done |

## Examples

```bash
# View current status
/ce:phase status

# Add a new task after authentication
/ce:phase insert "Add rate limiting" --after "authentication"

# Move a task to P2 (lower priority)
/ce:phase move "Nice to have feature" --to "P2"

# Remove a completed task
/ce:phase remove "Old migration task"

# List all tasks
/ce:phase list
```

## Related Commands

- `/ce:backlog` - Quick deferral of current task
- `/ce:blocker` - Mark task as blocked
- `/ce:next` - Pick next task to work on
