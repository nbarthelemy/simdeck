# Feature: {Feature Name}

> Created: {YYYY-MM-DD HH:MM}
> Status: draft | ready | in_progress | completed
> Estimated Tasks: {n}

## Overview

{2-3 sentence description of what this feature does and why it's needed}

## User Stories

- As a {user type}, I want to {action} so that {benefit}
- As a {user type}, I want to {action} so that {benefit}

## Implementation Phases

### Phase 1: {Phase Name}
> {Brief description of this phase} | {n} tasks

#### Tasks

- [ ] **Task 1.1**: {Specific, actionable task description}
  - File: `path/to/file.ts`
  - Details: {What exactly to implement, including code patterns to follow}
  - References: `path/to/similar/code.ts:45-60` (example to follow)

- [ ] **Task 1.2**: {Specific, actionable task description}
  - Files: `path/a.ts`, `path/b.ts`
  - Details: {Implementation specifics}
  - Depends: Task 1.1

### Phase 2: {Phase Name}
> {Brief description} | {n} tasks

#### Tasks

- [ ] **Task 2.1**: {Task description}
  - File: `path/to/file.ts`
  - Details: {Implementation specifics}

## Testing Strategy

### Unit Tests
- [ ] `path/to/test.ts`: {Test description}
- [ ] `path/to/test.ts`: {Test description}

### Integration Tests
- [ ] `path/to/integration.test.ts`: {Test description}

### E2E Tests (if applicable)
- [ ] `e2e/feature.spec.ts`: {User flow description}

## Validation Commands

```bash
# Type check
{npm run typecheck | npx tsc --noEmit | mypy . | etc.}

# Lint
{npm run lint | ruff check . | etc.}

# Unit tests
{npm test | pytest | go test ./... | etc.}

# Build
{npm run build | cargo build | etc.}
```

## Acceptance Criteria

- [ ] {Specific, testable criterion}
- [ ] {Specific, testable criterion}
- [ ] All tests pass
- [ ] No type errors
- [ ] No lint errors
- [ ] Code follows existing patterns

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| {What was decided} | {The choice made} | {Why this choice} |

## Dependencies

### Internal
- {Module/component this depends on}

### External
- {npm package / PyPI package / etc. if any new deps needed}

## References

- `path/to/similar/feature.ts` - Similar implementation to follow
- [External Doc](url) - {What it covers}

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| {What could go wrong} | Low/Med/High | {How to prevent/handle} |

## Notes

{Any additional context, edge cases to consider, or implementation notes}
