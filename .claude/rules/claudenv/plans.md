# Plan-First Development

> Significant features require documented plans before implementation.

## The Principle

Plans ensure thoughtful architecture before code. Like TDD for design, plan-first development catches structural issues early.

## When Plans Are Required

**Required for:**
- New features (visual, API, CLI)
- Multi-file refactors (3+ files)
- Architectural changes
- Complex bug fixes requiring design decisions

**Exempt (auto-allowed):**
- Test files: `*.test.*`, `*.spec.*`, `test_*`
- Config: `*.config.*`, `*.json`, `*.yaml`, `*.yml`
- Types: `*.d.ts`, `types.ts`, `constants.ts`
- Docs: `*.md`
- Framework: `.claude/*`, `scripts/*`, `config/*`
- Quick fixes (one-off changes)

## Workflow

```
/ce:feature → Plan Created → /ce:execute → Implementation
     ↓              ↓              ↓              ↓
  Analyze      .claude/plans/   Start plan    Edits allowed
```

### 1. Create a Plan

```bash
/ce:feature "Add user authentication with OAuth"
```

Creates `.claude/plans/user-authentication-oauth.md` with status `draft`.

### 2. Review and Mark Ready

After reviewing the plan, update status to `ready`:
```markdown
> Status: ready
```

### 3. Execute the Plan

```bash
/ce:execute .claude/plans/user-authentication-oauth.md
```

Sets status to `in_progress`. All related edits are now allowed.

### 4. Complete

When done, status becomes `completed` and TODO.md syncs.

## Plan Lifecycle

```
draft → ready → in_progress → completed
                     ↓
                  blocked (with reason)
```

| Status | Description | Edits Allowed |
|--------|-------------|---------------|
| `draft` | Initial planning | No |
| `ready` | Reviewed, approved | Files listed in plan |
| `in_progress` | Actively implementing | All related files |
| `completed` | Done | N/A |
| `blocked` | Waiting on something | No |

## Quick-Fix Bypass

For one-off changes that don't need a plan:

```bash
touch .claude/quick-fix
```

This marker allows ONE edit and is automatically deleted after.

## Disable Enforcement

To disable plan enforcement for a project:

```bash
touch .claude/plans-disabled
```

Or in `.claude/settings.local.json`:
```json
{ "plans": { "enabled": false } }
```

## TODO.md Integration

Plans automatically sync with TODO.md:

| Plan Status | TODO.md Marker |
|-------------|----------------|
| `draft` | `[ ]` |
| `ready` | `[ ]` |
| `in_progress` | `[~]` |
| `completed` | `[x]` |
| `blocked` | `[!]` |

## Commands

| Command | Purpose |
|---------|---------|
| `/ce:feature <desc>` | Create a new plan |
| `/ce:execute <plan>` | Start executing a plan |
| `/ce:plans` | List all plans by status |

## Error Message

When blocked, you'll see:

```
PLAN ENFORCEMENT: Create a plan first!

  Editing: src/features/auth/login.ts

  Options:
    1. Create a plan: /ce:feature "Feature description"
    2. Execute existing plan: /ce:execute .claude/plans/<name>.md
    3. Quick fix: touch .claude/quick-fix (auto-deleted)
    4. Disable: touch .claude/plans-disabled

  Existing plans:
    - user-auth (ready)
    - api-endpoints (in_progress)
```

## Benefits

- **Thoughtful Design**: Forces architectural thinking before coding
- **Context Preservation**: Plans document decisions for future reference
- **Visibility**: `/ce:plans` shows project progress at a glance
- **Traceability**: Links between plans, TODOs, and commits
