---
description: "Autonomous loop: /ce:loop <task>, /ce:loop status|pause|resume|cancel|history"
allowed-tools: Bash, Read, Write, Edit
---

# /ce:loop - Autonomous Development Loop

**IMPORTANT:** If the user provides `--track` flag or mentions coordination/parallel/multiple terminals:
```bash
Read .claude/rules/coordination.md
```

This file contains multi-agent coordination protocol for working in parallel.

## Usage

```
/loop "<task>" [options]    Start loop
/loop status                Show progress
/loop pause                 Pause loop
/loop resume                Resume loop
/loop cancel                Stop loop
/loop history [id]          View past loops
```

## Options

| Flag | Description |
|------|-------------|
| `--until "<text>"` | Exit when output contains phrase |
| `--until-exit <N>` | Exit when verify returns code |
| `--verify "<cmd>"` | Run after each iteration |
| `--max <N>` | Max iterations (default: 20) |
| `--max-time <dur>` | Max time (default: 2h) |
| `--same-context` | Run in same context (default: fresh subagent per iteration) |
| `--track "<name>"` | Track name for coordination |
| `--agent-id "<id>"` | Agent ID (auto-generated if not provided) |
| `--plan "<file>"` | Execute structured plan file (phases/tasks) |
| `--validate-after-task` | Run fast lint check after each task (with --plan) |
| `--validate-after-phase` | Run types+tests after each phase (with --plan) |
| `--validate-all` | Enable all validation tiers (with --plan) |
| `--commit-per-task` | Auto-commit after each task completion |
| `--commit-per-phase` | Auto-commit after each phase completion |

## Actions

### Start Loop
1. Parse task and options from args
2. Require completion condition (--until or --until-exit)
3. **Context mode** (default: fresh):
   - Fresh: Main context becomes coordinator, spawns subagent per iteration
   - Same: Run all iterations in current context (opt-in with `--same-context`)
4. **Coordination setup** (if --track provided):
   - Generate agent ID: `agent-{hostname}-{timestamp}`
   - Register: Use native TaskCreate to register tasks for tracking
   - Check for active agents on same track (warn if conflict)
5. Create `.claude/loop/state.json` with status "running"
6. Begin iteration cycle:
   - **If fresh context (default)**:
     - Package task context: `bash .claude/scripts/loop-context-packager.sh`
     - Spawn subagent with Task tool
     - Collect structured result
     - Record: `bash .claude/scripts/loop-manager.sh record_subagent`
   - **If same context**:
     - Execute task directly in current context
   - **If coordinated**: Check available tasks, claim next unclaimed
   - Verify completion (run --verify command if set)
   - **If --commit-per-task**: Create atomic commit
   - Check exit condition → repeat or exit
7. **On completion**:
   - Deregister: Use TaskUpdate to mark tasks completed
   - Display summary and archive to history

### Status
Run: `bash .claude/scripts/loop-status.sh`
Show: iteration progress, elapsed time, completion condition

### Pause
Update state.json: `"status": "paused"`
Save checkpoint for resumption

### Resume
Verify state is "paused", update to "running"
Continue from last checkpoint

### Cancel
Archive state to `.claude/loop/history/{id}.json`
Clean up active loop files

### History
List all loops in `.claude/loop/history/`
With ID: show detailed loop info

## State File

`.claude/loop/state.json`:
```json
{"id":"loop_YYYYMMDD_HHMMSS","status":"running","prompt":"...","iterations":{"current":0,"max":20},"completion":{"type":"exact","condition":"...","met":false}}
```

## Example

```
/loop "Fix all TypeScript errors" --until "Found 0 errors" --max 10
/loop status
/loop pause
/loop resume
```

## Multi-Agent Coordination

When using `--track`, loops coordinate with other agents via shared state.

### Coordinated Example

```bash
# Terminal 1
/loop "Complete frontend tasks" --track "Track A" --until "TRACK_A_COMPLETE" --max 15

# Terminal 2
/loop "Complete API tasks" --track "Track B" --until "TRACK_B_COMPLETE" --max 15
```

### Coordination Protocol

1. **Register** on start - announce presence to other agents
2. **Claim** tasks before working - prevents conflicts
3. **Complete** tasks when done - updates shared TODO.md
4. **Heartbeat** periodically - allows stale agent detection
5. **Deregister** on exit - releases unclaimed tasks

### Check Coordination Status

Use native TaskList to check coordination status.

Output:
```json
{
  "activeAgents": 2,
  "tasksInProgress": 3,
  "tasksCompleted": 5,
  "agents": {...},
  "tasks": {...}
}
```

### Shared State

All coordination data is stored in `.claude/loop/coordination.json` and can be safely read by any terminal to understand the current state.

---

## Plan Mode

When `--plan <file>` is provided, loop operates in structured plan mode, iterating through phases and tasks defined in the plan file.

### Usage

```bash
/loop --plan .claude/plans/feature.md --until "PLAN_COMPLETE" --max 50
/loop --plan .claude/plans/feature.md --validate-after-phase
```

### Plan File Structure

Plans must follow this structure (created by `/ce:feature`):

```markdown
# Feature: {Name}

> Status: ready | in_progress | completed

## Implementation Phases

### Phase 1: {Name}

#### Tasks

- [ ] **Task 1.1**: {Description}
  - File: `path/to/file.ts`
  - Details: {Implementation specifics}

- [ ] **Task 1.2**: {Description}
  - Depends: Task 1.1

### Phase 2: {Name}
...

## Validation Commands
```bash
npm run typecheck
npm test
```
```

### Plan Execution Process

1. **Initialize Plan State**
   ```bash
   bash .claude/scripts/loop-manager.sh init_plan "{plan_file}"
   ```
   Creates `.claude/loop/plan-state.json`

2. **For Each Phase:**
   - For each task in phase:
     1. Check dependencies (Depends: field)
     2. Read task details (File, Details, References)
     3. Execute task implementation
     4. Update plan file: `- [ ]` → `- [x]`
     5. Output: `TASK_COMPLETE: {task_id}`
   - After all tasks: Output `PHASE_COMPLETE: {phase_name}`
   - If `--validate-after-phase`: Run `/ce:validate --quick`

3. **On Plan Completion**
   - Update plan status to `completed`
   - Output: `PLAN_COMPLETE`

### Plan State File

`.claude/loop/plan-state.json`:
```json
{
  "planFile": ".claude/plans/feature.md",
  "status": "running",
  "currentPhase": 1,
  "currentTask": "1.2",
  "phases": [
    {"name": "Phase 1", "status": "in_progress", "tasks": ["1.1", "1.2"]}
  ],
  "tasksCompleted": ["1.1"],
  "phasesCompleted": [],
  "validationResults": {
    "Phase 1": {"passed": true, "output": "..."}
  }
}
```

### Incremental Validation

When validation flags are enabled, the loop runs tiered validation to catch errors early:

| Tier | Flag | When | What | Time |
|------|------|------|------|------|
| Task | `--validate-after-task` | After each task | Lint with auto-fix | <5s |
| Phase | `--validate-after-phase` | After each phase | Type check + affected tests | <30s |
| All | `--validate-all` | Both tiers | Lint + types + tests | varies |

Validation runs:
```bash
bash .claude/scripts/incremental-validate.sh task --fix   # Task tier
bash .claude/scripts/incremental-validate.sh phase        # Phase tier
```

If validation fails, the task/phase is NOT marked complete, and error details are reported.

### Plan Mode Markers

- `PLAN_STARTED` - Plan execution began
- `TASK_COMPLETE: {task_id}` - Individual task done
- `TASK_VALIDATION_STARTED` - Task validation begun
- `TASK_VALIDATION_PASSED` - Task passed lint check
- `TASK_VALIDATION_FAILED` - Task failed lint check
- `PHASE_COMPLETE: {phase_name}` - All tasks in phase done
- `PHASE_VALIDATION_STARTED` - Phase validation begun
- `PHASE_VALIDATION_PASSED` - Phase passed type check + tests
- `PHASE_VALIDATION_FAILED` - Phase failed validation
- `PLAN_COMPLETE` - All phases done
- `PLAN_BLOCKED: {reason}` - Cannot proceed

### Example

```bash
# Create a plan
/feature "Add user authentication"

# Execute the plan
/loop --plan .claude/plans/add-user-authentication.md --until "PLAN_COMPLETE" --max 30

# With phase validation
/loop --plan .claude/plans/add-user-authentication.md --validate-after-phase --until "PLAN_COMPLETE"
```

### Integration with /execute

The `/ce:execute` command is a thin wrapper that calls `/ce:loop --plan`:

```
/execute .claude/plans/feature.md
  └── /ce:loop --plan .claude/plans/feature.md --until "PLAN_COMPLETE"
      └── /ce:validate (after loop completes)
```
