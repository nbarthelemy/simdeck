---
description: "Usage tracking: /ce:usage [status|history|reset]"
allowed-tools: Bash
---

# /ce:usage - Token Usage Tracking

View estimated token usage and costs for the current session.

## Usage

```
/ce:usage              # Show current session usage
/ce:usage status       # Same as above
/ce:usage history      # Show past session usage
/ce:usage reset        # Reset current session counter
```

## Implementation

### Show Status

Run `bash .claude/scripts/usage-tracker.sh status` to get usage data as JSON.

**Format output as:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Session Usage
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Session: #{sessionCount}
Started: {started or "Not started"}

Tokens:
  Input:  {inputTokens:,}
  Output: {outputTokens:,}
  Total:  {totalTokens:,}

Tool Calls: {toolCalls}

Estimated Cost (Sonnet):
  Input:  ${estimatedCost.input:.4f}
  Output: ${estimatedCost.output:.4f}
  ─────────────────────────
  Total:  ${estimatedCost.total:.4f}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Show History

Run `bash .claude/scripts/usage-tracker.sh history`.

Show last 5-10 sessions with date and token counts.

### Reset Session

Run `bash .claude/scripts/usage-tracker.sh reset`.

Confirm: "Session usage counter reset."

## Notes

- Estimates use Claude Sonnet pricing ($3/1M input, $15/1M output)
- Token counts are approximate based on tool calls
- History is preserved across sessions
- Reset archives current session before clearing

## Accuracy

Usage tracking is **estimated** based on:
- Characters in tool inputs/outputs (÷4 for tokens)
- Does not include system prompt or conversation context

For accurate billing, check your Anthropic Console.
