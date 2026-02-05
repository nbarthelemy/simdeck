# Session Focus

> Maintain context across sessions. Prevent drift.

## State File

`.claude/state/session-state.json` tracks: `focus.activePlan`, `focus.currentTask`, `focus.filesInScope`, `focus.locked`, `decisions[]`, `blockers[]`, `handoff`

## Focus Lock

When `locked = true`: Edits restricted to `filesInScope`. Must unlock before switching.

## Commands

| Command | Action |
|---------|--------|
| `/ce:focus` | Show state |
| `/ce:focus set <plan>` | Set focus |
| `/ce:focus lock/unlock` | Toggle lock |
| `/ce:focus clear` | Complete |
| `/ce:focus decision` | Record decision |
| `/ce:focus blocker` | Record blocker |
| `/ce:focus handoff` | Capture notes |

## Decisions

Persist across sessions: architecture choices, library selections, user preferences.

## Session Lifecycle

**Start:** Load state, display focus/blockers/handoff, resume
**During:** Set focus, lock when deep, record decisions
**End:** Capture handoff, clear or preserve
