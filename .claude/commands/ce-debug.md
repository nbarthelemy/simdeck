---
description: "Debug tools: /debug hooks|agent <name>"
allowed-tools: Bash
---

# /debug - Debug Infrastructure

## Usage

```
/debug hooks           List hooks and recent executions
/debug agent <name>    Check agent config and triggers
```

## Actions

### hooks
Run: `bash .claude/scripts/debug-hooks.sh`
Shows: configured hooks, scripts, recent executions, errors

### agent <name>
Run: `bash .claude/scripts/debug-agent.sh <name>`
Shows: agent file location, frontmatter, triggers, recent invocations
