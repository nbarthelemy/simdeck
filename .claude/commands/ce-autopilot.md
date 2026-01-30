---
description: Fully autonomous feature completion until TODO.md is empty
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Skill
---

# /ce:autopilot - Autonomous Development

Fully autonomous mode that iteratively processes features from TODO.md until complete or limits are reached. No user interaction required.

## Usage

```
/autopilot                          Complete all TODO features
/autopilot --max-features 5         Limit to 5 features
/autopilot --dry-run               Show plan without executing
/autopilot --pause-on-failure      Stop on first failure
/autopilot --isolate               Git branch per feature (default)
/autopilot --no-isolate            Disable git isolation
/autopilot --validate-all          Run validation at all tiers
/autopilot status                   Show autopilot progress
/autopilot cancel                   Stop running autopilot
/autopilot graph                    Visualize feature dependencies
```

## Options

| Flag | Description | Default |
|------|-------------|---------|
| `--max-features <n>` | Maximum features to complete | unlimited |
| `--max-time <dur>` | Maximum runtime | 4h |
| `--max-cost <amt>` | Maximum estimated cost | $50 |
| `--dry-run` | Show execution plan only | false |
| `--pause-on-failure` | Stop on first failed feature | false |
| `--skip-validation` | Skip /ce:validate between features | false |
| `--isolate` | Create git branch per feature | true |
| `--no-isolate` | Disable git branch isolation | - |
| `--merge-on-success` | Auto-merge successful feature branches | false |
| `--validate-after-task` | Run lint check after each task | false |
| `--validate-after-phase` | Run type+test check after each phase | false |
| `--validate-all` | Enable all validation tiers | false |

## Feature Dependencies

Define dependencies in TODO.md using the `→ depends:` syntax:

```markdown
## P0 - Foundation
- [ ] **Database schema**: Create tables
  → [plan](.claude/plans/database-schema.md)

## P1 - Core Features
- [ ] **User auth**: JWT authentication
  → [plan](.claude/plans/user-auth.md)
  → depends: Database schema

- [ ] **API endpoints**: REST API
  → depends: Database schema, User auth
```

Features with dependencies will only execute after all dependencies are completed.
If a dependency fails, dependent features are automatically skipped with status `BLOCKED_BY_DEPS`.

## Git Feature Isolation

When `--isolate` is enabled (default), each feature:
1. Creates a new branch: `autopilot/{feature-slug}`
2. All commits happen on feature branch
3. On success: branch is kept (or merged with `--merge-on-success`)
4. On failure: branch is deleted, diff saved to `.claude/loop/failures/`

This ensures failed features leave no trace on your main branch.

## Incremental Validation

With `--validate-all`, validation runs at multiple tiers:

| Tier | When | What | Time |
|------|------|------|------|
| Task | After each task | Lint with auto-fix | <5s |
| Phase | After each phase | Type check + affected tests | <30s |
| Feature | After each feature | Full lint + types + tests + build | varies |

Enable selectively:
- `--validate-after-task`: Task tier only
- `--validate-after-phase`: Phase tier only
- `--validate-all`: All tiers

## Process

### Step 1: Initialize

Check prerequisites:
```bash
[ -f ".claude/TODO.md" ] || echo "TODO_MISSING"
```

Create autopilot state with options:
```bash
bash .claude/scripts/autopilot-manager.sh init \
    "$max_features" "$max_time" "$max_cost" \
    "$pause_on_failure" "$skip_validation" \
    "$isolate" "$merge_on_success" \
    "$validate_after_task" "$validate_after_phase"
```

If `--isolate`, also runs git preflight to stash uncommitted changes.

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

    # Get next feature (respects dependencies)
    feature = get_next_feature()  # Uses dependency graph

    if feature == "ALL_COMPLETE":
        break  # All done

    if feature == "BLOCKED_BY_DEPS":
        output "AUTOPILOT_BLOCKED: All remaining features have unmet dependencies"
        break

    output "AUTOPILOT_FEATURE_START: {feature}"

    # Create feature branch if --isolate
    if isolate:
        branch = create_feature_branch(feature)
        output "AUTOPILOT_BRANCH: {branch}"

    # Check/create plan
    if plan_exists(feature):
        plan = load_plan(feature)
    else:
        invoke /ce:feature to create plan

    # Mark in progress
    update TODO.md: [ ] → [~]
    update_dependency_graph(feature, "in_progress")

    # Execute via /ce:execute (includes task/phase validation if enabled)
    result = invoke /ce:execute with plan

    # Record result
    if result.success:
        output "AUTOPILOT_FEATURE_COMPLETE: {feature}"
        state.features.completed++
        update_dependency_graph(feature, "completed")

        if isolate AND merge_on_success:
            merge_feature_branch(branch)
        else if isolate:
            keep_branch_for_review(branch)
    else:
        output "AUTOPILOT_FEATURE_FAILED: {feature}"
        state.features.failed++
        update_dependency_graph(feature, "failed")

        if isolate:
            rollback_feature_branch(branch)  # Saves diff to failures/

        # Mark dependent features as blocked
        for dep in get_dependent_features(feature):
            mark_blocked(dep)

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
    "blocked": 2,
    "remaining": 4
  },
  "limits": {
    "maxFeatures": null,
    "maxTime": "4h",
    "maxCost": "$50"
  },
  "options": {
    "pauseOnFailure": false,
    "skipValidation": false,
    "isolate": true,
    "mergeOnSuccess": false,
    "validateAfterTask": true,
    "validateAfterPhase": true
  },
  "gitIsolation": {
    "gitReady": true,
    "baselineBranch": "main",
    "baselineCommit": "abc1234",
    "stashId": "stash@{0}"
  },
  "currentFeature": "Add email notifications",
  "currentBranch": "autopilot/add-email-notifications",
  "history": [
    {"feature": "Add auth", "status": "complete", "duration": "45m", "branch": "autopilot/add-auth", "branchAction": "merged"},
    {"feature": "Create API", "status": "complete", "duration": "30m", "branch": "autopilot/create-api", "branchAction": "kept"},
    {"feature": "Build UI", "status": "failed", "error": "Test failures", "branch": "autopilot/build-ui", "failureDiff": ".claude/loop/failures/build-ui-20260108.diff"}
  ],
  "metrics": {
    "elapsedTime": "1h 15m",
    "estimatedCost": "$12.50",
    "tasksCompleted": 45,
    "filesModified": 23,
    "validationFailures": 2
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

### /ce:autopilot status
Show current autopilot progress:
```bash
bash .claude/scripts/autopilot-manager.sh status
```

### /ce:autopilot cancel
Stop running autopilot gracefully, restore baseline if isolated:
```bash
bash .claude/scripts/autopilot-manager.sh cancel
```

### /ce:autopilot resume
Resume from last checkpoint after failure:
```bash
bash .claude/scripts/autopilot-manager.sh resume
```

### /ce:autopilot history
Show past autopilot runs.

### /ce:autopilot graph
Visualize feature dependency graph:
```bash
bash .claude/scripts/autopilot-manager.sh graph
```

Output:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Feature Dependency Graph
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[x] Database schema
[ ] User auth
    → depends: Database schema
[ ] API endpoints
    → depends: Database schema, User auth

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Summary: 1 completed, 0 in progress, 2 pending
Next: User auth
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### /ce:autopilot restore
Restore git state to pre-autopilot baseline:
```bash
bash .claude/scripts/autopilot-manager.sh restore_baseline
```

## Markers

- `AUTOPILOT_STARTED` - Autopilot began
- `AUTOPILOT_FEATURE_START: {name}` - Starting a feature
- `AUTOPILOT_BRANCH: {branch}` - Feature branch created
- `AUTOPILOT_FEATURE_COMPLETE: {name}` - Feature done
- `AUTOPILOT_FEATURE_FAILED: {name}` - Feature failed
- `AUTOPILOT_FEATURES_BLOCKED: {n}` - Features blocked by failure
- `AUTOPILOT_BLOCKED` - All remaining features blocked by deps
- `AUTOPILOT_LIMIT_REACHED: {limit}` - Hit a limit
- `AUTOPILOT_PAUSED: {reason}` - Paused
- `AUTOPILOT_COMPLETE` - Finished
- `TASK_VALIDATION_STARTED` - Task validation begun
- `TASK_VALIDATION_PASSED` - Task validation passed
- `TASK_VALIDATION_FAILED` - Task validation failed
- `PHASE_VALIDATION_STARTED` - Phase validation begun
- `PHASE_VALIDATION_PASSED` - Phase validation passed
- `PHASE_VALIDATION_FAILED` - Phase validation failed

## Integration

```
/spec → Creates TODO.md with features
    ↓
/autopilot
    ├── For each feature in TODO.md:
    │     ├── /ce:feature (create plan if needed)
    │     ├── /ce:execute (runs /ce:loop + /ce:validate)
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
- Monitor with `/ce:autopilot status` in another terminal
- Review `.claude/loop/autopilot-state.json` for detailed state
- Use `/ce:next` for interactive control when needed
