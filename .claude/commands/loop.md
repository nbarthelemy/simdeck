---
name: loop
description: Start an autonomous iterative development loop
arguments:
  - name: prompt
    description: The task to iterate on
    required: true
  - name: options
    description: Loop options (--until, --max, --verify, etc.)
    required: false
---

# Autonomous Loop

Start an iterative development loop that continues until completion conditions are met.

## Parse Arguments

Extract from input:
- **Prompt**: The main task description (quoted string after /loop)
- **Options**: Any flags provided

### Available Options

| Option | Description | Example |
|--------|-------------|---------|
| `--until "<text>"` | Exit when output contains exact phrase | `--until "All tests passing"` |
| `--until-exit <code>` | Exit when verify command returns code | `--until-exit 0` |
| `--until-regex "<pattern>"` | Exit when output matches regex | `--until-regex "0 errors"` |
| `--verify "<cmd>"` | Command to run after each iteration | `--verify "npm test"` |
| `--max <n>` | Maximum iterations (default: 20) | `--max 50` |
| `--max-time <duration>` | Maximum time (default: 2h) | `--max-time 8h` |
| `--max-cost <amount>` | Maximum estimated cost | `--max-cost $10` |
| `--mode <mode>` | Loop mode: standard, tdd, refine | `--mode tdd` |
| `--checkpoint <n>` | Checkpoint every N iterations | `--checkpoint 5` |

## Pre-Loop Checks

1. **Validate Arguments**
   ```
   - Prompt must be provided
   - At least one completion condition required (--until, --until-exit, or --until-regex)
   - Safety limit must be set (--max or --max-time, defaults applied if missing)
   ```

2. **Check for Existing Loop**
   ```bash
   if [ -f ".claude/loop/state.json" ]; then
     # Check if loop is running or paused
     status=$(jq -r '.status' .claude/loop/state.json)
     if [ "$status" = "running" ] || [ "$status" = "paused" ]; then
       echo "⚠️ Loop already active. Use /loop:status, /loop:resume, or /loop:cancel"
       exit 1
     fi
   fi
   ```

3. **Initialize Loop State**
   ```bash
   mkdir -p .claude/loop/checkpoints .claude/loop/logs
   ```

## Create State File

Write to `.claude/loop/state.json`:

```json
{
  "id": "loop_YYYYMMDD_HHMMSS",
  "status": "running",
  "prompt": "<user prompt>",
  "mode": "<standard|tdd|refine>",
  "started_at": "<ISO timestamp>",
  "iterations": {
    "current": 0,
    "max": <max value or 20>
  },
  "completion": {
    "type": "<exact|exit|regex>",
    "condition": "<condition value>",
    "verify_command": "<verify command if set>",
    "met": false
  },
  "limits": {
    "max_time": "<duration or 2h>",
    "max_cost": "<cost or null>",
    "checkpoint_interval": <interval or 5>
  },
  "checkpoints": [],
  "metrics": {
    "estimated_tokens": 0,
    "estimated_cost": "$0.00",
    "elapsed_time": "0s"
  }
}
```

## Start Loop

Display startup message:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 AUTONOMOUS LOOP STARTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 Task: <prompt>
🎯 Complete when: <completion condition>
🛡️ Safety limits: max <N> iterations, <time> max time
📊 Mode: <mode>

Starting iteration 1...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Iteration Execution

For each iteration:

### 1. Update State
```json
{
  "iterations": { "current": N }
}
```

### 2. Build Iteration Prompt

```markdown
## Loop Context

**Iteration**: {current}/{max}
**Elapsed**: {elapsed_time}
**Mode**: {mode}

## Original Task

{user_prompt}

## Previous Iteration Summary

{summary from last iteration, or "First iteration" if iteration 1}

## Completion Target

When this task is complete, include this exact phrase in your response:
{completion_phrase}

Or if using verification, ensure the verification command succeeds.

## Instructions

Continue working toward the completion target. Focus on incremental progress.
Use all available tools. If you encounter blockers, document them clearly.

If the task is complete, output the completion phrase.
If you need more iterations, summarize progress and continue.
```

### 3. Execute Task
- Run the prompt with full Claude capabilities
- Capture output for condition checking

### 4. Run Verification (if --verify set)
```bash
{verify_command}
EXIT_CODE=$?
```

### 5. Check Completion Conditions

```python
# Exact match
if "--until" in options:
    if completion_phrase in output:
        complete = True

# Exit code
if "--until-exit" in options:
    if exit_code == expected_code:
        complete = True

# Regex
if "--until-regex" in options:
    if regex.match(pattern, output):
        complete = True
```

### 6. Check Safety Limits

```python
if current_iteration >= max_iterations:
    status = "max_iterations_reached"
    stop = True

if elapsed_time >= max_time:
    status = "time_limit_reached"
    stop = True

if estimated_cost >= max_cost:
    status = "cost_limit_reached"
    stop = True
```

### 7. Checkpoint (if interval reached)

Save to `.claude/loop/checkpoints/checkpoint_{iteration}.json`:
```json
{
  "iteration": N,
  "timestamp": "<ISO>",
  "summary": "<iteration summary>",
  "files_modified": ["file1.ts", "file2.ts"],
  "errors": []
}
```

### 8. Continue or Complete

If complete:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ LOOP COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Summary:
   Iterations: {total}
   Time: {elapsed}
   Est. Cost: {cost}

📁 Files Modified:
   {list of files}

🎯 Completion: {condition met}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If continuing:
```
───────────────────────────────────────────────────────────
📍 Iteration {N} complete
   Progress: {brief summary}
   Continuing to iteration {N+1}...
───────────────────────────────────────────────────────────
```

## Error Handling

If error occurs 3 times consecutively:
1. Pause loop
2. Save state
3. Notify user
4. Suggest `/loop:resume` after fixing issue

## Examples

```bash
# Basic loop
/loop "Fix all TypeScript errors" --until "Found 0 errors" --max 10

# TDD loop
/loop "Implement user login" --mode tdd --verify "npm test" --until-exit 0

# Overnight run
/loop "Build complete API" --until "API_COMPLETE" --max 50 --max-time 8h

# Refinement
/loop "Improve test coverage" --verify "npm run coverage" --until-regex "[89][0-9]%" --max 15
```
