---
description: Execute an implementation plan via /ce:loop with automatic validation
allowed-tools: Read, Write, Edit, Bash, Skill
---

# /ce:execute - Plan Execution Orchestrator

Thin orchestrator that delegates plan execution to `/ce:loop --plan` and runs final validation via `/ce:validate`.

**Usage:** `/ce:execute <plan-path>`

**Example:** `/ce:execute .claude/plans/user-authentication.md`

## Process

### Step 1: Validate Plan Exists

```bash
[ -f "{plan_path}" ] || echo "ERROR: Plan not found"
```

If plan not found, list available plans:
```bash
ls -la .claude/plans/*.md 2>/dev/null
```

### Step 2: Create Native Tasks

Parse the plan's phases and tasks, then create native Claude Code tasks for tracking:

1. Run `bash .claude/scripts/task-bridge.sh import` to check current TODO.md state
2. For each task in the plan, use TaskCreate with:
   - `subject`: The task description from the plan
   - `description`: Files to modify, verification criteria
   - `activeForm`: Present-continuous form of the task
3. Set up dependencies using `addBlockedBy` for tasks that depend on earlier phases
4. Use TaskUpdate to mark tasks as `in_progress` when starting and `completed` when done

This provides real-time task tracking visible via TaskList during execution.

### Step 3: Auto-Focus from Plan (unchanged)

Extract files from the plan's "Files to Create/Modify" table and set focus:

```bash
# Extract file paths from plan
files=$(grep -E '^\|.*\|.*\|' "{plan_path}" | grep -v '^| File' | grep -v '^|---' | awk -F'|' '{print $2}' | tr -d ' \`' | grep -v '^$')

# Set focus with plan files
bash .claude/scripts/state-manager.sh set-focus "{plan_name}" "${files[@]}"

# Lock focus during execution
bash .claude/scripts/state-manager.sh lock-focus
```

This ensures edits stay within the plan's scope during execution.

### Step 3: Update Plan Status

Read the plan file and update status from `ready` to `in_progress`:

```markdown
> Status: in_progress
```

Output `EXECUTE_STARTED` marker.

### Step 4: Delegate to Loop

Invoke `/ce:loop` with plan mode:

```
Skill: loop
Args: --plan "{plan_path}" --until "PLAN_COMPLETE" --max 50
```

This handles:
- Parsing plan structure (phases, tasks)
- Executing tasks in order
- Updating checkboxes in plan file
- Outputting `TASK_COMPLETE`, `PHASE_COMPLETE` markers

Wait for `PLAN_COMPLETE` marker.

### Step 5: Run Final Validation

After loop completes, invoke `/ce:validate`:

```
Skill: validate
```

Run full validation suite (lint, types, tests, build).

Record validation results.

### Step 6: Unlock Focus and Update TODO.md

Release the focus lock after execution:

```bash
bash .claude/scripts/state-manager.sh unlock-focus
```

Update TODO.md:

If validation passes, find and mark the related TODO item complete:

1. Read `.claude/TODO.md`
2. Find matching feature (by plan filename or feature name)
3. Update: `- [ ]` → `- [x]` with completion date

```markdown
- [x] {Feature name} (completed {YYYY-MM-DD HH:MM})
```

### Step 7: Soft Context Suggestion

If significant work was done (5+ files modified or 10+ tasks completed):

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 Context Suggestion
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This session involved significant changes.
Consider starting a fresh session for optimal
context on the next feature.

Files modified: {n}
Tasks completed: {m}

To continue fresh: Exit and run /prime
Or continue in this session.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Note**: This is a SUGGESTION only, not enforced.

### Step 8: Summary Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Execution Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Plan: {plan_name}
Status: COMPLETED

Phases: {completed}/{total}
Tasks: {completed}/{total}

Files Modified:
  - path/to/file1.ts
  - path/to/file2.ts

Validation:
  ✅ Lint: passed
  ✅ Types: passed
  ✅ Tests: passed ({n} new)
  ✅ Build: passed

TODO.md: Updated ✓

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Or if validation failed:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Execution Complete with Issues
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Plan: {plan_name}
Status: NEEDS ATTENTION

Tasks: {completed}/{total}

Validation:
  ✅ Lint: passed
  ❌ Tests: 2 failed
  ⏭️ Build: skipped

Issues to resolve:
  - test_auth.py::test_login_redirect
  - test_auth.py::test_token_refresh

Fix issues and run: /validate

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Output `EXECUTE_COMPLETE` or `EXECUTE_FAILED` marker.

## Subcommands

### /ce:execute:status
Show execution status of current or specified plan.

### /ce:execute:resume <plan>
Resume execution from last incomplete task.

### /ce:execute:list
List all plans and their execution status.

## Markers

- `EXECUTE_STARTED` - Plan execution began
- `PLAN_DELEGATED` - Handed off to /loop
- `VALIDATION_STARTED` - Running /validate
- `EXECUTE_COMPLETE` - All done successfully
- `EXECUTE_FAILED` - Completed with issues

## Error Handling

If `/ce:loop` fails or is interrupted:
1. Plan state is preserved in `.claude/loop/plan-state.json`
2. Use `/ce:execute:resume` to continue from last checkpoint
3. Manual intervention may be needed for blocked tasks

## Integration

```
/feature "Add auth" → Creates .claude/plans/add-auth.md
    ↓
/execute .claude/plans/add-auth.md
    ├── /ce:loop --plan .claude/plans/add-auth.md
    │     ├── Task 1.1 → TASK_COMPLETE
    │     ├── Task 1.2 → TASK_COMPLETE
    │     └── ... → PLAN_COMPLETE
    ├── /validate
    │     └── VALIDATION_PASS
    └── Update TODO.md → EXECUTE_COMPLETE
```
