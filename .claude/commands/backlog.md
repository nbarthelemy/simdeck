---
description: Send current or specified task to the backlog
allowed-tools: Read, Edit, Grep
---

# /backlog - Send Task to Backlog

Move the current in-progress task or a specified task to the Backlog section of TODO.md.

## Usage

```
/backlog                              Move current task ([~]) to backlog
/backlog --reason "<why>"             Current task with deferral reason
/backlog "<task-text>"                Move specific task by name
/backlog "<task-text>" --reason "..." Specific task with reason
```

## Process

### Step 1: Locate TODO.md

```bash
[ -f ".claude/TODO.md" ] && echo ".claude/TODO.md" || ([ -f "TODO.md" ] && echo "TODO.md" || echo "NOT_FOUND")
```

If not found:
```
No TODO.md found. Create one with /spec or manually.
```

### Step 2: Identify Task

**No argument provided:**

Find the in-progress task:
```bash
grep -n "^\- \[~\]" {todo_file}
```

- If none found: "No task currently in progress. Specify a task: `/backlog \"task name\"`"
- If multiple found: List them and ask which one to backlog

**Task text provided:**

Search for matching task (case-insensitive):
```bash
grep -in "{task_text}" {todo_file} | grep "^\- \["
```

- If no match: "No task matching '{text}' found. Check spelling or use `/backlog` to move current task."
- If multiple matches: Show numbered list and ask user to be more specific

### Step 3: Identify Source Section

Scan backwards from the task line to find the section header (line starting with `##`).

Common sections:
- `## Current Focus`
- `## P0 - Foundation`
- `## P1 - Core Features`
- `## P2 - Enhancements`

### Step 4: Move to Backlog

1. **Remove** the task line from its current location
2. **Reset** checkbox state: `[~]` or `[!]` → `[ ]`
3. **Preserve** any metadata (plan links, annotations)
4. **Add reason** if provided: append `(deferred: {reason})`
5. **Insert** into Backlog section

If Backlog section doesn't exist, create it:
```markdown
## Backlog

- [ ] {task}
```

### Step 5: Confirm

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Moved to Backlog
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Task: {task text}
From: {original section}
Reason: {reason or "—"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Backlog Entry Format

Without reason:
```markdown
- [ ] Implement caching layer
```

With reason:
```markdown
- [ ] Implement caching layer (deferred: needs API design first)
```

Preserved with plan link:
```markdown
- [ ] **Add authentication** → [plan](.claude/plans/add-authentication.md) (deferred: blocked by DB migration)
```

## Edge Cases

### Multiple In-Progress Tasks
If multiple `[~]` tasks exist:
```
Multiple tasks in progress:
1. [~] Add user login
2. [~] Create dashboard

Which task to backlog? (Enter number or task text)
```

### Task Not Found
```
No task matching "caching" found in TODO.md.

Did you mean one of these?
  - Implement caching layer
  - Cache invalidation logic

Or use /backlog without arguments to move the current task.
```

### Already in Backlog
```
Task is already in Backlog section. No changes made.
```

## Markers

- `BACKLOG_MOVED` - Task successfully moved
- `BACKLOG_NOT_FOUND` - No matching task
- `BACKLOG_MULTIPLE` - Multiple matches, needs clarification
