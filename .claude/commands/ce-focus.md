---
description: "Manage session focus - set, lock, clear current work context"
allowed-tools: Bash, Read, Glob
---

# /ce:focus - Session Focus Management

Manage the current session focus to maintain state and prevent context drift.

## Usage

```
/ce:focus                    # Show current focus status
/ce:focus status             # Same as above
/ce:focus set <plan>         # Set focus to a plan (auto-extracts files)
/ce:focus lock               # Lock focus (prevent switching)
/ce:focus unlock             # Unlock focus
/ce:focus clear              # Clear focus (marks current task complete)
/ce:focus decision "<text>"  # Record a key decision
/ce:focus blocker "<text>"   # Record a blocker
/ce:focus handoff            # Capture handoff notes for next session
```

## Implementation

### Status (default)

Run `bash .claude/scripts/state-manager.sh status` to get current state.

**Format output as:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Session Focus
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Focus: {currentTask or "None"}
Plan:  {activePlan or "None"}
Lock:  {locked ? "🔒 Locked" : "🔓 Unlocked"}
Files: {filesInScope count} in scope

📝 Decisions ({count}):
  • {decision} - {date}
  ...

🚧 Blockers ({count}):
  • {issue} (since {since}, owner: {owner})
  ...

📋 Handoff:
  Last session: {lastSession or "Never"}
  Completed: {completedTasks count} tasks
  Next steps: {nextSteps count} items
  Notes: {notes or "None"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Set Focus

When user runs `/ce:focus set <plan-path>`:

1. Read the plan file to extract:
   - Task from plan title/overview
   - Files from `files:` fields in tasks

2. Call state-manager.sh:
```bash
echo '{"activePlan": "<plan-path>", "currentTask": "<task>", "filesInScope": ["file1", "file2"]}' | bash .claude/scripts/state-manager.sh set-focus
```

3. Confirm: "Focus set to: {task}"

### Lock/Unlock

```bash
bash .claude/scripts/state-manager.sh lock-focus
bash .claude/scripts/state-manager.sh unlock-focus
```

When locked, edits outside `filesInScope` will be blocked by the focus-enforce hook.

### Clear Focus

```bash
bash .claude/scripts/state-manager.sh clear-focus
```

This moves the current task to `completedTasks` and clears focus.

### Record Decision

When user runs `/ce:focus decision "Use bcrypt for hashing"`:

```bash
echo '{"decision": "Use bcrypt for hashing", "reason": "User preference"}' | bash .claude/scripts/state-manager.sh add-decision
```

Ask the user for the reason if not obvious.

### Record Blocker

When user runs `/ce:focus blocker "Need API key"`:

```bash
echo '{"issue": "Need API key", "owner": "user"}' | bash .claude/scripts/state-manager.sh add-blocker
```

### Capture Handoff

When user runs `/ce:focus handoff`:

1. Show current state summary
2. Ask user to confirm/edit:
   - Completed tasks (auto-populated)
   - Next steps
   - Notes for next session

3. Save:
```bash
echo '{"completedTasks": [...], "nextSteps": [...], "notes": "..."}' | bash .claude/scripts/state-manager.sh set-handoff
```

## Benefits

- **Prevents drift**: Lock focus to stay on task
- **Preserves context**: Decisions persist across sessions
- **Smooth handoff**: Next session knows where to start
- **Tracks blockers**: Don't forget what's stuck
