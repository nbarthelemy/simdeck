---
name: loop:pause
description: Pause the active autonomous loop
---

# Pause Loop

Pause the currently running loop, saving state for later resumption.

## Check for Active Loop

```bash
if [ ! -f ".claude/loop/state.json" ]; then
  echo "❌ No active loop to pause."
  exit 1
fi

status=$(jq -r '.status' .claude/loop/state.json)
if [ "$status" != "running" ]; then
  echo "❌ Loop is not running (current status: $status)"
  exit 1
fi
```

## Create Checkpoint

Before pausing, save current state:

1. **Save checkpoint**
   ```bash
   iteration=$(jq -r '.iterations.current' .claude/loop/state.json)
   cp .claude/loop/state.json ".claude/loop/checkpoints/pause_${iteration}.json"
   ```

2. **Update state file**
   ```json
   {
     "status": "paused",
     "paused_at": "<ISO timestamp>",
     "pause_reason": "user_requested"
   }
   ```

## Display Confirmation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏸️  LOOP PAUSED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Task: {prompt}
📍 Paused at iteration: {current}/{max}
⏱️  Elapsed: {elapsed_time}
💰 Est. Cost: {estimated_cost}

State saved. Resume with: /loop:resume
Cancel with: /loop:cancel
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
