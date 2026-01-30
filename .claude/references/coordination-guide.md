# Multi-Agent Coordination

When multiple Claude instances work on the same project in parallel terminals, they MUST coordinate via the shared state system.

## Coordination Protocol

Uses Claude Code's native task system (TaskCreate, TaskUpdate, TaskList) for coordination.
TODO.md sync is handled by `task-bridge.sh`.

### On Session Start

1. Import tasks from TODO.md:
   ```bash
   bash .claude/scripts/task-bridge.sh import
   ```
2. Create native tasks using TaskCreate for each pending item
3. Use `addBlockedBy` to set up dependencies between tasks

### Before Starting a Task

1. Use TaskList to see available (pending, unblocked) tasks
2. Use TaskUpdate to set status to `in_progress`

### On Task Completion

1. Use TaskUpdate to mark task as `completed`
2. TaskList to pick next available task

### On Session End

1. Export task state back to TODO.md:
   ```bash
   bash .claude/scripts/task-bridge.sh export
   ```

## Conflict Prevention

1. **File-level**: Don't modify files another agent is working on
2. **Task-level**: Only work on claimed tasks
3. **Branch-level**: Use separate branches if making commits

## Communication via TODO.md

Agents communicate progress by updating TODO.md:
- `[x]` - Task completed
- `[~]` - Task in progress (claimed)
- `[ ]` - Task available
- `[!]` - Task blocked

Add notes under tasks for context:
```markdown
- [~] P1: Implement login form
  > Claimed by agent-term1 at 12:01
  > Working on: form validation
```

## Loop Integration

The `/ce:loop` command should:
1. Register on start
2. Check available tasks each iteration
3. Claim before working
4. Complete after finishing
5. Deregister on exit

The `/ce:next` command should:
1. Show coordination status
2. Highlight which tracks have active agents
3. Warn about potential conflicts
