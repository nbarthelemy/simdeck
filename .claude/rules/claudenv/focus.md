# Session Focus & State

> Maintain context across sessions. Prevent drift. Preserve decisions.

## State File

`.claude/state/session-state.json` tracks:

| Field | Purpose |
|-------|---------|
| `focus.activePlan` | Current plan being executed |
| `focus.currentTask` | Specific task within plan |
| `focus.filesInScope` | Files allowed when locked |
| `focus.locked` | Whether focus is locked |
| `decisions[]` | Key decisions made (persist across sessions) |
| `blockers[]` | What's blocking progress |
| `handoff` | Notes for next session |

## Focus Lock

When `focus.locked = true`:
- Edits restricted to `filesInScope`
- Must complete or explicitly unlock before switching tasks
- Prevents context-switching drift

## Session Lifecycle

### Start
1. Load session-state.json
2. Display current focus, blockers, handoff notes
3. Resume from where last session ended

### During
1. Set focus when starting work: `/ce:focus set <plan>`
2. Lock to prevent drift: `/ce:focus lock`
3. Record decisions as made: `/ce:focus decision "choice"`
4. Track blockers: `/ce:focus blocker "issue"`

### End
1. Capture handoff: `/ce:focus handoff`
2. Document completed tasks, next steps, notes
3. Clear or preserve focus for next session

## Commands

| Command | Action |
|---------|--------|
| `/ce:focus` | Show current state |
| `/ce:focus set <plan>` | Set focus to plan |
| `/ce:focus lock` | Lock focus |
| `/ce:focus unlock` | Unlock focus |
| `/ce:focus clear` | Complete and clear |
| `/ce:focus decision` | Record decision |
| `/ce:focus blocker` | Record blocker |
| `/ce:focus handoff` | Capture handoff notes |

## Decisions

Decisions persist across sessions. Use for:
- Architecture choices ("Use PostgreSQL over MySQL")
- Library selections ("bcrypt for password hashing")
- Pattern preferences ("Prefer composition over inheritance")
- User preferences ("Explicit error messages")

Format:
```json
{
  "date": "2026-01-20",
  "decision": "Use bcrypt for password hashing",
  "reason": "Better library support, sufficient security"
}
```

## Blockers

Track what's stuck:
```json
{
  "issue": "Need API key for email service",
  "since": "2026-01-19",
  "owner": "user"
}
```

Clear when resolved: `/ce:focus clear-blocker <index>`

## Handoff

End-of-session capture:
- **completedTasks**: What got done
- **nextSteps**: What should happen next
- **notes**: Context, preferences, warnings

This becomes the starting point for the next session.

## Enforcement

When focus is locked, the `unified-gate.sh` hook:
1. Checks if file being edited is in `filesInScope`
2. Blocks edits outside scope with helpful message
3. Suggests: unlock, add file to scope, or complete current task

## Best Practices

1. **Set focus** at start of meaningful work
2. **Lock focus** when deep in implementation
3. **Record decisions** immediately (memory fades)
4. **Track blockers** don't rely on memory
5. **Capture handoff** before ending session
6. **Review handoff** at start of new session
