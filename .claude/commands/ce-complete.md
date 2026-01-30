---
description: Mark a plan as completed and sync TODO.md
allowed-tools: Bash, Read, Edit
---

# /ce:complete - Complete a Plan

Mark a plan as completed and update TODO.md status.

**Usage:**
```
/ce:complete                    # Complete the active in_progress plan
/ce:complete <plan-name>        # Complete a specific plan
```

## Process

### Step 1: Find Plan

If no plan name provided:
```bash
# Find active plan
for f in .claude/plans/*.md; do
  grep -l "^> Status: in_progress" "$f" 2>/dev/null
done
```

If plan name provided, resolve to `.claude/plans/{name}.md`.

### Step 2: Run Validation

Before completing, run validation:
```bash
bash .claude/scripts/validate.sh --quick
```

If validation fails, ask:
```
Validation found issues. Complete anyway?
1. Yes, mark complete
2. No, fix issues first
```

### Step 3: Update Plan Status

Change status in the plan file:
```markdown
> Status: completed
> Completed: {YYYY-MM-DD HH:MM}
```

### Step 4: Sync TODO.md

Run plan-sync to update TODO.md:
```bash
bash .claude/scripts/plan-sync.sh complete {plan-name}
```

### Step 5: Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Plan Completed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Plan: {name}
Duration: {time since created}
Files changed: {n}

TODO.md updated: [x] {feature name}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Quick Plans

Quick plans (created by `/ce:quick-plan`) have `Type: quick-plan` in their header. These are automatically cleaned up after 7 days if completed.

## Blocked Plans

If you need to mark a plan as blocked instead:
```bash
bash .claude/scripts/plan-sync.sh block {plan-name} "Reason for blocking"
```
