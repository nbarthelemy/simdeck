---
description: "Autonomous loop: /loop <task>, /loop status|pause|resume|cancel|history"
allowed-tools: Bash, Read, Write, Edit
---

# /loop - Autonomous Development Loop

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
| `--track "<name>"` | Track name for coordination |
| `--agent-id "<id>"` | Agent ID (auto-generated if not provided) |
| `--plan "<file>"` | Execute structured plan file (phases/tasks) |
| `--validate-after-phase` | Run /validate after each phase (with --plan) |

## Actions

### Start Loop
1. Parse task and options from args
2. Require completion condition (--until or --until-exit)
3. **Coordination setup** (if --track provided):
   - Generate agent ID: `agent-{hostname}-{timestamp}`
   - Register: `bash .claude/scripts/todo-coordinator.sh register "$AGENT_ID" "$TRACK"`
   - Check for active agents on same track (warn if conflict)
4. Create `.claude/loop/state.json` with status "running"
5. Begin iteration cycle:
   - **If coordinated**: Check available tasks, claim next unclaimed
   - Execute task
   - Verify completion
   - **If coordinated**: Mark task complete, claim next
   - Check exit condition → repeat or exit
6. **On completion**:
   - Deregister: `bash .claude/scripts/todo-coordinator.sh deregister "$AGENT_ID"`
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

```bash
bash .claude/scripts/todo-coordinator.sh status
```

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

Plans must follow this structure (created by `/feature`):

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
   - If `--validate-after-phase`: Run `/validate --quick`

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

### Plan Mode Markers

- `PLAN_STARTED` - Plan execution began
- `TASK_COMPLETE: {task_id}` - Individual task done
- `PHASE_COMPLETE: {phase_name}` - All tasks in phase done
- `PHASE_VALIDATION_PASSED` / `PHASE_VALIDATION_FAILED` - After phase validation
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

The `/execute` command is a thin wrapper that calls `/loop --plan`:

```
/execute .claude/plans/feature.md
  └── /loop --plan .claude/plans/feature.md --until "PLAN_COMPLETE"
      └── /validate (after loop completes)
```
