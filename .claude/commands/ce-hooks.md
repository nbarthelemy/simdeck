---
description: "Hook management: /ce:hooks list|info|toggle"
allowed-tools: Bash
---

# /ce:hooks - Hook Management

View and manage Claude Code hooks in the current project.

## Usage

```
/ce:hooks              # List all hooks with status
/ce:hooks list         # Same as above
/ce:hooks info <name>  # Show details for a specific hook
/ce:hooks toggle <name># Enable/disable a hook
```

## Implementation

### List Hooks

Run `bash .claude/scripts/hooks-manager.sh list` to get all hooks as JSON.

**Format output as:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🪝 Hooks
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Hook                    Status    Trigger
  ────────────────────────────────────────────
  session-start.sh        ✅        SessionStart
  unified-gate.sh         ✅        PreToolUse
  post-write.sh           ✅        PostToolUse
  ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Show Hook Info

Run `bash .claude/scripts/hooks-manager.sh info <name>`.

**Format output as:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🪝 Hook: {name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Status:      {enabled ? "✅ Enabled" : "❌ Disabled"}
Trigger:     {trigger}
Description: {description}
Path:        {path}
Modified:    {modified}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Toggle Hook

Run `bash .claude/scripts/hooks-manager.sh toggle <name>`.

Confirm the result: "Hook {name} is now {enabled/disabled}."

## Hook Types

| Trigger | When It Runs |
|---------|--------------|
| `SessionStart` | New Claude session begins |
| `Stop` | Session ends |
| `PreToolUse` | Before a tool is used (can block) |
| `PostToolUse` | After a tool completes |

## Common Hooks

| Hook | Purpose |
|------|---------|
| `unified-gate.sh` | Plan, TDD, focus lock, and read-before-write enforcement |
| `post-write.sh` | Learning observer, decision reminders, quick-fix cleanup |
| `block-no-verify.sh` | Prevents bypassing git hooks |
| `track-read.sh` | Tracks file read operations |

## Notes

- Disabled hooks are marked in `.claude/scripts/.disabled/`
- Toggle doesn't delete the hook, just disables it
- Some hooks are essential (session-start/end) - use caution
