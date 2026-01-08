---
description: Fully autonomous feature completion until TODO.md is empty
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill
---

# /autopilot - Autonomous Development

Fully autonomous mode that iteratively processes features from TODO.md until complete or limits are reached. No user interaction required.

## Usage

```
/autopilot                          Complete all TODO features
/autopilot --max-features 5         Limit to 5 features
/autopilot --dry-run               Show plan without executing
/autopilot --pause-on-failure      Stop on first failure
/autopilot status                   Show autopilot progress
/autopilot cancel                   Stop running autopilot
```

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--max-features <n>` | Maximum features to complete | unlimited |
| `--max-time <dur>` | Maximum runtime | 4h |
| `--max-cost <amt>` | Maximum estimated cost | $50 |
| `--dry-run` | Show execution plan only | false |
| `--pause-on-failure` | Stop on first failed feature | false |
| `--skip-validation` | Skip /validate between features | false |

## Process

### Step 1: Initialize

Check prerequisites:
```bash
[ -f ".claude/TODO.md" ] || echo "TODO_MISSING"
```

Create autopilot state:
```bash
bash .claude/scripts/autopilot-manager.sh init
```

Output `AUTOPILOT_STARTED` marker.

### Step 2: Dry Run Mode

If `--dry-run`:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Autopilot Plan (Dry Run)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Features to process:
  1. {Feature A} - Plan: exists | Tasks: {n}
  2. {Feature B} - Plan: needs creation
  3. {Feature C} - Plan: exists | Tasks: {n}

Total features: {n}
Est. tasks: ~{m}
Est. time: {hours}h

Run without --dry-run to execute.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Exit without executing.

### Step 3: Main Loop

```
while features_remaining AND within_limits:

    # Get next feature from TODO.md
    feature = get_next_uncompleted_feature()

    if !feature:
        break  # All done

    output "AUTOPILOT_FEATURE_START: {feature}"

    # Check/create plan
    if plan_exists(feature):
        plan = load_plan(feature)
    else:
        invoke /feature to create plan

    # Mark in progress
    update TODO.md: [ ] → [~]

    # Execute via /execute
    result = invoke /execute with plan

    # Record result
    if result.success:
        output "AUTOPILOT_FEATURE_COMPLETE: {feature}"
        state.features.completed++
    else:
        output "AUTOPILOT_FEATURE_FAILED: {feature}"
        state.features.failed++

        if --pause-on-failure:
            output "AUTOPILOT_PAUSED: failure"
            break

        log_failure(feature, result.error)
        # Continue to next feature

    # Check limits
    if exceeded_limits():
        output "AUTOPILOT_LIMIT_REACHED: {limit}"
        break

    # Checkpoint
    save_state()
```

### Step 4: Generate Summary Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Autopilot Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Session: {autopilot_id}
Duration: {hours}h {minutes}m
Est. Cost: ${amount}

Features:
  ✅ Completed: {n}
  ❌ Failed: {n}
  ⏭️  Skipped: {n}
  📋 Remaining: {n}

Completed:
  1. ✅ {Feature A} ({tasks} tasks, {time})
  2. ✅ {Feature B} ({tasks} tasks, {time})
  3. ❌ {Feature C} - {error_summary}

Files Modified: {n}
Tests Added: {n}
Lines: +{added} -{removed}

Stop Reason: {all_complete | limit | failure | cancelled}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Output `AUTOPILOT_COMPLETE` marker.

### Step 5: Archive State

```bash
bash .claude/scripts/autopilot-manager.sh archive
```

Move state to `.claude/loop/history/autopilot_{id}.json`.

## State File

`.claude/loop/autopilot-state.json`:

```json
{
  "id": "autopilot_20260108_143000",
  "status": "running",
  "startedAt": "2026-01-08T14:30:00Z",
  "features": {
    "total": 10,
    "completed": 3,
    "failed": 1,
    "skipped": 0,
    "remaining": 6
  },
  "limits": {
    "maxFeatures": null,
    "maxTime": "4h",
    "maxCost": "$50"
  },
  "currentFeature": "Add email notifications",
  "history": [
    {"feature": "Add auth", "status": "complete", "duration": "45m"},
    {"feature": "Create API", "status": "complete", "duration": "30m"},
    {"feature": "Build UI", "status": "failed", "error": "Test failures"}
  ],
  "metrics": {
    "elapsedTime": "1h 15m",
    "estimatedCost": "$12.50",
    "tasksCompleted": 45,
    "filesModified": 23
  }
}
```

## Safety Guardrails

- **Time limit**: 4 hours default
- **Cost limit**: $50 default
- **No git push**: Only local commits
- **No deploy**: Never deploys to any environment
- **Checkpoint every feature**: Can resume from failure
- **Critical error stop**: Immediately stops on file system or permission errors

## Subcommands

### /autopilot status
Show current autopilot progress:
```bash
bash .claude/scripts/autopilot-manager.sh status
```

### /autopilot cancel
Stop running autopilot gracefully:
```bash
bash .claude/scripts/autopilot-manager.sh cancel
```

### /autopilot resume
Resume from last checkpoint after failure:
```bash
bash .claude/scripts/autopilot-manager.sh resume
```

### /autopilot history
Show past autopilot runs.

## Markers

- `AUTOPILOT_STARTED` - Autopilot began
- `AUTOPILOT_FEATURE_START: {name}` - Starting a feature
- `AUTOPILOT_FEATURE_COMPLETE: {name}` - Feature done
- `AUTOPILOT_FEATURE_FAILED: {name}` - Feature failed
- `AUTOPILOT_LIMIT_REACHED: {limit}` - Hit a limit
- `AUTOPILOT_PAUSED: {reason}` - Paused
- `AUTOPILOT_COMPLETE` - Finished

## Integration

```
/spec → Creates TODO.md with features
    ↓
/autopilot
    ├── For each feature in TODO.md:
    │     ├── /feature (create plan if needed)
    │     ├── /execute (runs /loop + /validate)
    │     ├── Update TODO.md
    │     └── Record result
    ├── Check limits
    └── Generate report

vs.

/next → Interactive version with confirmations
```

## Examples

```bash
# Complete all features
/autopilot

# Limit to first 3 features
/autopilot --max-features 3

# Stop on first failure for debugging
/autopilot --pause-on-failure

# See what would run
/autopilot --dry-run

# Check progress of running autopilot
/autopilot status
```

## Tips

- Use `--dry-run` first to see what will be executed
- Use `--pause-on-failure` when debugging
- Monitor with `/autopilot status` in another terminal
- Review `.claude/loop/autopilot-state.json` for detailed state
- Use `/next` for interactive control when needed
