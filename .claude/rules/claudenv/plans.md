# Plan-First Development

> Significant features require documented plans before implementation.

## When Required

**Required:** New features, multi-file refactors (3+), architectural changes
**Exempt:** Tests, config, types, docs, `.claude/*`, quick fixes

## Workflow

```
/ce:feature "desc" → draft → ready → /ce:execute → in_progress → completed
```

## Lifecycle

| Status | Edits Allowed |
|--------|---------------|
| `draft` | No |
| `ready` | Files in plan |
| `in_progress` | All related |
| `completed` | N/A |
| `blocked` | No |

## Quick-Fix Bypass

```bash
touch .claude/quick-fix    # One edit, auto-deleted
touch .claude/plans-disabled  # Disable enforcement
```

## Commands

| Command | Purpose |
|---------|---------|
| `/ce:feature <desc>` | Create plan |
| `/ce:execute <plan>` | Start executing |
| `/ce:plans` | List all |
