---
description: "Control reasoning depth: /ce:think off|low|medium|high|max"
allowed-tools: Bash, Read
---

# /ce:think - Thinking Level Control

Adjust Claude's reasoning depth for the current session. Higher levels mean more thorough analysis but longer responses.

## Usage

```
/ce:think             # Show current level
/ce:think <level>     # Set level (off, low, medium, high, max)
/ce:think reset       # Return to default (medium)
```

## Levels

| Level | Description | Use For |
|-------|-------------|---------|
| `off` | Direct responses, minimal reasoning | Quick factual answers |
| `low` | Brief reasoning for simple tasks | Routine changes |
| `medium` | Balanced analysis (default) | General development |
| `high` | Thorough analysis, consider alternatives | Complex features |
| `max` | Deep deliberation, extensive exploration | Architecture decisions |

## Implementation

### Show Current Level

Run `bash .claude/scripts/state-manager.sh get thinking` to get current state.

**If error or no thinking state**, default is `medium`.

**Format output as:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 Thinking Level
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current: {level}

Levels: off → low → medium → high → max
                      ▲
              (current position)

Usage: /ce:think high

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Set Level

When user runs `/ce:think <level>`:

1. Validate level is one of: off, low, medium, high, max
2. Call state-manager:
```bash
echo '{"level": "<level>"}' | bash .claude/scripts/state-manager.sh set-thinking
```
3. Confirm with brief message: "Thinking level set to: {level}"

### Reset

Same as `/ce:think medium`.

## Behavior Guidelines

Based on thinking level, adjust your approach:

**off**: Skip explanations. Just do the task.

**low**: Brief reasoning (1-2 sentences). Skip alternatives.

**medium**: Explain key decisions. Note obvious trade-offs. Standard Claude behavior.

**high**:
- Consider 2-3 alternative approaches
- Explain pros/cons of chosen approach
- Note edge cases
- Suggest potential improvements

**max**:
- Systematic exploration of problem space
- Research relevant patterns/best practices
- Consider long-term implications
- Question assumptions
- Provide comprehensive trade-off analysis
