---
name: loop:resume
description: Resume a paused autonomous loop
---

# Resume Loop

Resume a previously paused loop from its saved state.

## Check for Paused Loop

```bash
if [ ! -f ".claude/loop/state.json" ]; then
  echo "❌ No loop state found."
  echo "Start a new loop with: /loop \"<prompt>\" --until \"<condition>\""
  exit 1
fi

status=$(jq -r '.status' .claude/loop/state.json)
if [ "$status" != "paused" ]; then
  echo "❌ No paused loop to resume (current status: $status)"
  if [ "$status" = "running" ]; then
    echo "Loop is already running. Use /loop:status to check progress."
  fi
  exit 1
fi
```

## Restore State

1. **Update status**
   ```json
   {
     "status": "running",
     "resumed_at": "<ISO timestamp>",
     "pause_duration": "<time paused>"
   }
   ```

2. **Load last checkpoint context**
   - Read last iteration summary
   - Identify files that were being worked on
   - Restore progress tracking

## Display Resumption

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▶️  LOOP RESUMED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Task: {prompt}
📍 Resuming from iteration: {current}/{max}
⏱️  Previously elapsed: {elapsed_time}
⏸️  Paused for: {pause_duration}

🎯 Completion target: {condition}

Continuing iteration {current + 1}...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Resume Iteration

Build context from last checkpoint and continue:

```markdown
## Loop Resumed

**Resuming iteration {N+1} after pause**

### Context from Pause Point

{Last checkpoint summary}

### Files in Progress

{List of files being worked on}

### Continue Working

Pick up where you left off. The completion target is:
{completion_condition}
```
