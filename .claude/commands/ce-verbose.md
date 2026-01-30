---
description: "Verbosity control: /ce:verbose on|off|status"
allowed-tools: Bash
---

# /ce:verbose - Output Verbosity Control

Control how much Claude explains its actions. Useful for learning (verbose) or experienced users who want speed (concise).

## Usage

```
/ce:verbose on       Enable detailed explanations after actions
/ce:verbose off      Minimal output, just results
/ce:verbose status   Show current setting
```

## Actions

### on

Creates `.claude/verbose-mode` marker file.

When enabled, Claude will:
- Explain reasoning behind decisions
- Summarize what changed after tool calls
- Note trade-offs considered
- Provide educational context

### off

Removes marker file.

Claude returns to default concise mode:
- Brief confirmations
- Results without explanation
- Faster workflow

### status

Check current verbosity setting:

```bash
if [ -f .claude/verbose-mode ]; then echo "Verbose: ON"; else echo "Verbose: OFF"; fi
```

## Use Cases

**Learning:** Turn on when exploring unfamiliar code or learning new patterns
**Speed:** Turn off when doing repetitive tasks or already understand the approach
**Debugging:** Turn on to understand why Claude made specific choices
