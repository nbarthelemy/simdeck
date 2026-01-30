---
description: Create a lightweight plan for small changes (30-60 min tasks)
allowed-tools: Read, Write, Glob, Grep
---

# /ce:quick-plan - Lightweight Planning

Create a minimal plan for small changes that don't warrant full `/ce:feature` treatment. The plan is created with `Status: in_progress` so you can immediately start coding.

**Usage:**
```
/ce:quick-plan "Add validation to user form"
/ce:quick-plan "Fix edge case in payment calculation"
```

## When to Use

| Scope | Command |
|-------|---------|
| 30-60 min task | `/ce:quick-plan` ✓ |
| Multi-hour feature | `/ce:feature` |
| Typo/one-liner | `touch .claude/quick-fix` |

## Process

### Step 1: Analyze Request

Parse the description to identify:
- Primary file(s) likely to be modified
- Whether tests exist for those files
- Quick complexity assessment

### Step 2: Create Minimal Plan

Create `.claude/plans/{slug}.md`:

```markdown
# Quick: {Description}

> Status: in_progress
> Type: quick-plan
> Created: {YYYY-MM-DD HH:MM}

## Summary

{One sentence description}

## Files

- files: `{likely_file_1}`
- files: `{likely_file_2}` (if applicable)

## Tasks

- [ ] {Main task}
- [ ] Update tests (if applicable)
- [ ] Verify with validation commands

## Done When

- [ ] Change implemented
- [ ] Tests pass
- [ ] No type errors
```

### Step 3: Confirm and Proceed

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ Quick Plan Created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{Description}

Plan: .claude/plans/{slug}.md
Status: in_progress (ready to code)

Files identified:
  • {file_1}
  • {file_2}

You can now edit these files directly.

When done: /ce:complete {slug}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Key Differences from /ce:feature

| Aspect | /ce:quick-plan | /ce:feature |
|--------|----------------|-------------|
| Status | `in_progress` immediately | `draft` → `ready` → `in_progress` |
| UX analysis | Skip | Full 6-pass analysis |
| Implementation detail | Minimal | Comprehensive |
| Time estimate | 30-60 min | Hours to days |
| File discovery | Best guess | Deep codebase analysis |

## Auto-Complete

Quick plans should be completed promptly. If a quick plan stays `in_progress` for more than one session, consider:
1. Converting to a full `/ce:feature` plan
2. Breaking into smaller pieces
3. Completing and moving on

## Slug Generation

Convert description to kebab-case slug:
- "Add validation to user form" → `add-validation-to-user-form`
- "Fix edge case in payment" → `fix-edge-case-in-payment`
- Truncate to 50 chars max
