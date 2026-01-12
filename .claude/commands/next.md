---
description: Interactive feature workflow - pick feature, create plan, execute with confirmation
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Skill
---

# /next - Interactive Feature Workflow

Interactively work through features from TODO.md. Picks a feature, creates a plan if needed, and executes with user confirmation at each step.

## Usage

```
/next                    Pick next feature and start
/next --list            Show available features
/next status            Show current progress
/next complete <item>   Manually mark item complete
```

## Process

### Step 1: Check Prerequisites

```bash
[ -f ".claude/TODO.md" ] || echo "TODO_MISSING"
[ -f ".claude/SPEC.md" ] || echo "SPEC_MISSING"
```

If TODO.md missing:
```
No TODO.md found. Run /spec first to create project specification
and populate the feature list.
```

Output `NEXT_STARTED` marker.

### Step 2: Parse TODO.md

Read and identify uncompleted features:

```bash
# Find unchecked items in Features section
grep -n "^- \[ \]" .claude/TODO.md
```

Categories:
- `- [ ]` = Available
- `- [~]` = In progress (skip)
- `- [x]` = Completed (skip)
- `- [!]` = Blocked (show but warn)

### Step 3: Present Feature Selection

Use AskUserQuestion to let user choose:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Available Features
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Add user authentication
2. Create API endpoints
3. Build dashboard UI
4. Add email notifications

Which feature would you like to work on?
```

Options:
- Feature 1 (first in list - recommended)
- Feature 2
- Feature 3
- Feature 4
- Show more / Other

Output `FEATURE_SELECTED: {name}` marker.

### Step 4: Check for Existing Plan

Convert feature name to kebab-case and check for plan:

```bash
SLUG=$(echo "{feature}" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-')
[ -f ".claude/plans/${SLUG}.md" ] && echo "PLAN_EXISTS"
```

### Step 5: Create Plan (if needed)

If no plan exists, invoke `/feature`:

```
Creating detailed implementation plan...

Skill: feature
Args: "{selected_feature_description}"
```

Wait for plan creation. Then present:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Plan Created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {name}
Plan: .claude/plans/{slug}.md

Phases: {n}
Tasks: {m}

Would you like to:
```

Use AskUserQuestion:
- Review the plan first
- Proceed to execution
- Skip this feature

Output `PLAN_CREATED` marker if new plan was made.

### Step 6: Mark In Progress

Update TODO.md to show feature is being worked on:

```markdown
- [~] {Feature name} (started {YYYY-MM-DD HH:MM})
```

### Step 7: Confirm Execution

Use AskUserQuestion:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Ready to Execute
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {name}
Plan: .claude/plans/{slug}.md

This will:
  • Execute {n} tasks across {m} phases
  • Run validation after completion
  • Update TODO.md on success

Proceed with execution?
```

Options:
- Yes, start execution
- Show plan details first
- Skip this feature
- Cancel

### Step 8: Execute Plan

Invoke `/execute`:

```
Skill: execute
Args: ".claude/plans/{slug}.md"
```

Wait for execution to complete.

Output `EXECUTION_STARTED` marker.

### Step 9: Post-Execution

After `/execute` completes:

If successful:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Feature Complete: {name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

TODO.md: Updated ✓
Plan: Marked complete ✓

Remaining features: {n}
```

Output `FEATURE_COMPLETE` marker.

Use AskUserQuestion:

```
Continue to next feature?
```

Options:
- Yes, show me the next feature
- No, I'm done for now

If user says Yes, loop back to Step 2.

If failed:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️ Feature Needs Attention: {name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Some issues need to be resolved.
See validation output above.

Options:
  • Fix issues and run /validate
  • Resume with /execute:resume
  • Skip and move to next feature
```

### Step 10: Session End

When user chooses to stop:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Session Summary
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Features completed: {n}
Features remaining: {m}

To continue later:
  /next         - Resume interactive workflow
  /autopilot    - Complete remaining autonomously

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Output `NEXT_STOPPED` marker.

## Subcommands

### /next --list
Show all features from TODO.md without starting workflow.

### /next status
Show progress summary:
- Features completed
- Features in progress
- Features remaining
- Current plan status

### /next complete <item>
Manually mark a TODO item as complete with timestamp.

### /next skip <item>
Skip a feature (mark with reason).

## Markers

- `NEXT_STARTED` - Workflow began
- `FEATURE_SELECTED: {name}` - User chose a feature
- `PLAN_CREATED` - New plan was generated
- `EXECUTION_STARTED` - Started /execute
- `FEATURE_COMPLETE` - Feature done successfully
- `FEATURE_FAILED` - Feature had issues
- `NEXT_STOPPED` - User ended session

## Integration

```
/spec → Creates TODO.md with features
    ↓
/next (interactive loop)
    ├── Select feature from TODO.md
    ├── /feature (create plan if needed)
    ├── Confirm with user
    ├── /execute (runs /loop + /validate)
    ├── Update TODO.md
    └── Ask: Continue? → loop or stop

/autopilot → Autonomous version (no confirmations)
```

## Tips

- Run `/spec` first to populate TODO.md
- Features are not pre-prioritized - you choose the order
- Plans are reusable - if execution fails, fix and run again
- Use `/autopilot` for hands-off completion of remaining features
