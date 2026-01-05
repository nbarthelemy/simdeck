---
name: loop:history
description: View history of past autonomous loops
arguments:
  - name: loop_id
    description: Specific loop ID to view details (optional)
    required: false
---

# Loop History

View history of all past loop runs.

## List All Loops

If no loop_id provided, list all past loops:

```bash
mkdir -p .claude/loop/history

if [ -z "$(ls -A .claude/loop/history 2>/dev/null)" ]; then
  echo "No loop history found."
  echo "Start a loop with: /loop \"<prompt>\" --until \"<condition>\""
  exit 0
fi
```

## Display History List

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📜 LOOP HISTORY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

ID                      Status      Iterations  Duration  Cost
─────────────────────────────────────────────────────────────
loop_20260103_154500    ✅ complete    15/20      1h 23m   $4.50
loop_20260102_091200    🛑 cancelled    8/50      45m      $2.10
loop_20260101_220000    ✅ complete    42/50      6h 15m   $18.75
loop_20251231_140000    ❌ failed       3/20      12m      $0.85

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

View details: /loop:history <loop_id>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Display Loop Details

If loop_id provided:

```bash
if [ ! -f ".claude/loop/history/${loop_id}.json" ]; then
  echo "❌ Loop not found: ${loop_id}"
  exit 1
fi
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📜 LOOP DETAILS: {loop_id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Task:
   {full prompt}

🔢 Status: {status}
   Started: {started_at}
   Ended: {ended_at}
   Duration: {total_duration}

📊 Iterations:
   Completed: {current}/{max}
   Checkpoints: {checkpoint_count}

🎯 Completion:
   Type: {type}
   Condition: {condition}
   Met: {yes/no}

💰 Metrics:
   Estimated Tokens: {tokens}
   Estimated Cost: {cost}

📁 Files Modified:
   {list of files}

📝 Checkpoints:
   ├─ Iteration 5: "API routes created"
   ├─ Iteration 10: "Tests written, 3 failing"
   ├─ Iteration 15: "All tests passing"
   └─ Final: "Complete"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Statistics Summary

At end of history list:

```
📊 Overall Statistics:
   Total loops: {count}
   Completed: {count} ({percent}%)
   Cancelled: {count}
   Failed: {count}

   Total iterations: {sum}
   Total time: {sum}
   Total est. cost: {sum}
```
