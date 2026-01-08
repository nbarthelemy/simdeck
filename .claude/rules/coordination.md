# Multi-Agent Coordination

When multiple Claude instances work on the same project in parallel terminals, they MUST coordinate via the shared state system.

## Coordination Protocol

### On Session Start

1. Generate a unique agent ID: `agent-{terminal}-{timestamp}`
2. Register with coordinator:
   ```bash
   bash .claude/scripts/todo-coordinator.sh register "$AGENT_ID" "$TRACK_NAME"
   ```
3. Check coordination status to see other active agents

### Before Starting a Task

1. Check available tasks:
   ```bash
   bash .claude/scripts/todo-coordinator.sh available "$TRACK_NAME"
   ```
2. Claim the task before working:
   ```bash
   bash .claude/scripts/todo-coordinator.sh claim "$AGENT_ID" "$TASK_ID"
   ```
3. If claim fails (already taken), pick another task

### During Work

1. Send heartbeats every few iterations:
   ```bash
   bash .claude/scripts/todo-coordinator.sh heartbeat "$AGENT_ID"
   ```
2. Check status periodically to see other agents' progress:
   ```bash
   bash .claude/scripts/todo-coordinator.sh status
   ```

### On Task Completion

1. Mark task complete:
   ```bash
   bash .claude/scripts/todo-coordinator.sh complete "$AGENT_ID" "$TASK_ID"
   ```
2. Update TODO.md (coordinator does this automatically)
3. Claim next available task

### On Session End

1. Deregister to release any incomplete tasks:
   ```bash
   bash .claude/scripts/todo-coordinator.sh deregister "$AGENT_ID"
   ```

## Shared State Files

```
.claude/loop/
├── coordination.json    # Shared state (agents, tasks, claims)
└── .coordination.lock   # Lock file for atomic updates
```

### coordination.json Structure

```json
{
  "version": 1,
  "agents": {
    "agent-term1-1704567890": {
      "track": "Track A",
      "status": "active",
      "startedAt": "2026-01-06T12:00:00Z",
      "lastHeartbeat": "2026-01-06T12:05:00Z"
    }
  },
  "tasks": {
    "implement-login-form": {
      "claimedBy": "agent-term1-1704567890",
      "status": "in_progress",
      "claimedAt": "2026-01-06T12:01:00Z"
    },
    "add-validation": {
      "claimedBy": null,
      "status": "available"
    }
  },
  "lastUpdate": "2026-01-06T12:05:00Z"
}
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

The `/loop` command should:
1. Register on start
2. Check available tasks each iteration
3. Claim before working
4. Complete after finishing
5. Deregister on exit

The `/next` command should:
1. Show coordination status
2. Highlight which tracks have active agents
3. Warn about potential conflicts
