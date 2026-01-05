---
name: loop:cancel
description: Cancel and stop the active autonomous loop
---

# Cancel Loop

Stop the current loop and archive its state.

## Check for Active Loop

```bash
if [ ! -f ".claude/loop/state.json" ]; then
  echo "❌ No active loop to cancel."
  exit 1
fi
```

## Archive Loop State

1. **Read current state**
   ```bash
   loop_id=$(jq -r '.id' .claude/loop/state.json)
   ```

2. **Update final status**
   ```json
   {
     "status": "cancelled",
     "cancelled_at": "<ISO timestamp>",
     "cancel_reason": "user_requested",
     "final_iteration": N
   }
   ```

3. **Move to history**
   ```bash
   mkdir -p .claude/loop/history
   mv .claude/loop/state.json ".claude/loop/history/${loop_id}.json"
   ```

4. **Archive logs**
   ```bash
   mv .claude/loop/logs/* ".claude/loop/history/" 2>/dev/null || true
   ```

## Display Cancellation

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🛑 LOOP CANCELLED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Task: {prompt}
📍 Stopped at iteration: {current}/{max}
⏱️  Total time: {elapsed_time}
💰 Est. Cost: {estimated_cost}

📊 Summary:
   Iterations completed: {current}
   Checkpoints saved: {count}
   Files modified: {count}

📁 State archived to: .claude/loop/history/{loop_id}.json

Start a new loop with: /loop "<prompt>" --until "<condition>"
Review history with: /loop:history
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Cleanup

```bash
# Remove active checkpoints (archived already)
rm -rf .claude/loop/checkpoints/*

# Keep history intact
# .claude/loop/history/ contains all past loops
```
