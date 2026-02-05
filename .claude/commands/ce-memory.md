---
description: Memory mode control - toggle automatic vs manual memory surfacing
allowed-tools: Bash
---

# /ce:memory - Memory Mode Control

Control how memory surfaces during sessions.

## Usage

```
/ce:memory           # Show current mode
/ce:memory status    # Show current mode and stats
/ce:memory auto      # Enable automatic memory surfacing (default)
/ce:memory manual    # Disable automatic, require /ce:do for context
```

## Actions

### Status (default)

Run `bash .claude/scripts/memory-status.sh` to check mode and stats.

Check for `.claude/.memory-manual` flag:
- **Flag absent** (default): Automatic mode
- **Flag present**: Manual mode

**Display as:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 Memory Mode: {auto|manual}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Database: {database.size}
Observations: {counts.observations}
Pending: {pending.observations}

{if auto}
Memory context is automatically injected at session start
and surfaced when relevant during work.
{/if}

{if manual}
Use /ce:do <task> to get memory context for tasks.
Example: /ce:do fix the auth bug
{/if}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Auto

Enable automatic memory surfacing:

```bash
rm -f .claude/.memory-manual
```

**Output:**
```
Memory mode: automatic

Memory context will be:
- Injected at session start
- Surfaced when working with files that have history
- Used for error pattern matching

To disable: /ce:memory manual
```

### Manual

Disable automatic memory surfacing:

```bash
touch .claude/.memory-manual
```

**Output:**
```
Memory mode: manual

Memory surfacing is disabled. Use /ce:do to get context:
  /ce:do <task description>

Example:
  /ce:do fix the authentication bug
  /ce:do implement user settings page

To re-enable automatic mode: /ce:memory auto
```

## Automatic vs Manual

| Mode | Session Start | File Operations | Explicit Query |
|------|---------------|-----------------|----------------|
| Auto | Injects context | Surfaces history | Works |
| Manual | No injection | No surfacing | Use /ce:do |

**When to use manual mode:**
- Working on very focused tasks where extra context is distracting
- Debugging memory issues
- Conserving context window for large operations

**When to use auto mode (default):**
- Normal development work
- Benefiting from cross-session context
- Learning from past patterns
