---
description: Execute an implementation plan via /loop with automatic validation
allowed-tools: Read, Write, Edit, Bash, Skill
---

# /execute - Plan Execution Orchestrator

Thin orchestrator that delegates plan execution to `/loop --plan` and runs final validation via `/validate`.

**Usage:** `/execute <plan-path>`

**Example:** `/execute .claude/plans/user-authentication.md`

## Process

### Step 1: Validate Plan Exists

```bash
[ -f "{plan_path}" ] || echo "ERROR: Plan not found"
```

If plan not found, list available plans:
```bash
ls -la .claude/plans/*.md 2>/dev/null
```

### Step 2: Update Plan Status

Read the plan file and update status from `ready` to `in_progress`:

```markdown
> Status: in_progress
```

Output `EXECUTE_STARTED` marker.

### Step 3: Delegate to Loop

Invoke `/loop` with plan mode:

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

### Step 4: Run Final Validation

After loop completes, invoke `/validate`:

```
Skill: validate
```

Run full validation suite (lint, types, tests, build).

Record validation results.

### Step 5: Update TODO.md

If validation passes, find and mark the related TODO item complete:

1. Read `.claude/TODO.md`
2. Find matching feature (by plan filename or feature name)
3. Update: `- [ ]` → `- [x]` with completion date

```markdown
- [x] {Feature name} (completed {date})
```

### Step 6: Soft Context Suggestion

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

### Step 7: Summary Report

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

### /execute:status
Show execution status of current or specified plan.

### /execute:resume <plan>
Resume execution from last incomplete task.

### /execute:list
List all plans and their execution status.

## Markers

- `EXECUTE_STARTED` - Plan execution began
- `PLAN_DELEGATED` - Handed off to /loop
- `VALIDATION_STARTED` - Running /validate
- `EXECUTE_COMPLETE` - All done successfully
- `EXECUTE_FAILED` - Completed with issues

## Error Handling

If `/loop` fails or is interrupted:
1. Plan state is preserved in `.claude/loop/plan-state.json`
2. Use `/execute:resume` to continue from last checkpoint
3. Manual intervention may be needed for blocked tasks

## Integration

```
/feature "Add auth" → Creates .claude/plans/add-auth.md
    ↓
/execute .claude/plans/add-auth.md
    ├── /loop --plan .claude/plans/add-auth.md
    │     ├── Task 1.1 → TASK_COMPLETE
    │     ├── Task 1.2 → TASK_COMPLETE
    │     └── ... → PLAN_COMPLETE
    ├── /validate
    │     └── VALIDATION_PASS
    └── Update TODO.md → EXECUTE_COMPLETE
```
