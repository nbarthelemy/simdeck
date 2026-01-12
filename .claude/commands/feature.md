---
description: Plan a feature with detailed implementation strategy saved to .claude/plans/
allowed-tools: Read, Write, Glob, Grep, Bash, WebFetch, WebSearch, AskUserQuestion
---

# /feature - Feature Planning

Transform a feature request into a detailed, executable implementation plan. Plans are saved to `.claude/plans/` for persistence and can be executed with `/execute`.

**Usage:** `/feature <feature-description>`

**Example:** `/feature Add user authentication with OAuth`

## Philosophy

> "Context is King" - The goal is one-pass implementation success through exhaustive upfront analysis.

A good plan enables any developer (human or AI) to implement the feature without additional research or clarification.

## Process

### Phase 1: Feature Understanding

Analyze the feature request to understand:

1. **Core Problem** - What user need does this solve?
2. **Feature Type** - New capability, enhancement, refactor, or bug fix?
3. **Complexity Assessment** - Simple (1-2 files), Medium (3-5 files), Complex (6+ files)
4. **Affected Systems** - Which parts of the codebase are involved?

If the request is ambiguous, use AskUserQuestion to clarify:
- Scope boundaries
- Edge cases to handle
- Priority of sub-features
- Acceptance criteria

### Phase 2: Codebase Intelligence

Gather deep context about the implementation target:

```bash
# Find related code
rg -l "{relevant_terms}" --type-add 'code:*.{ts,tsx,js,jsx,py,go,rs,rb}' -t code

# Identify patterns
rg "function|class|interface|type|def " {likely_files} | head -30

# Check existing tests
find . -name "*.test.*" -o -name "*.spec.*" -o -name "test_*" | head -20
```

Document:
- **Existing Patterns** - How similar features are implemented
- **Dependencies** - Libraries, services, APIs involved
- **Integration Points** - Where new code connects to existing
- **Testing Patterns** - How tests are structured
- **File Conventions** - Naming, location, structure

### Phase 3: External Research (if needed)

If the feature involves unfamiliar technology:

1. Search for official documentation
2. Find best practices and common patterns
3. Identify potential pitfalls
4. Compile reference links with specific section anchors

### Phase 4: Strategic Design

Think deeply about implementation:

1. **Architectural Fit** - How does this align with existing patterns?
2. **Critical Dependencies** - What must exist before implementation?
3. **Edge Cases** - What could go wrong?
4. **Extensibility** - How might this need to change in future?
5. **Trade-offs** - What alternatives were considered and why?

### Phase 5: Plan Generation

Create the plan document at `.claude/plans/{kebab-case-name}.md`:

```markdown
# Feature: {Feature Name}

> Created: {YYYY-MM-DD HH:MM}
> Status: draft | ready | in_progress | completed
> Estimated Tasks: {n}

## Overview

{2-3 sentence description of what this feature does and why}

## User Stories

- As a {user}, I want to {action} so that {benefit}
- ...

## Implementation Phases

### Phase 1: {Name}
> {Brief description} | {n} tasks

#### Tasks

- [ ] **Task 1.1**: {Specific action}
  - File: `path/to/file.ts`
  - Details: {What exactly to do, including code patterns to follow}
  - References: `path/to/similar/code.ts:45-60`

- [ ] **Task 1.2**: {Specific action}
  - Files: `path/a.ts`, `path/b.ts`
  - Details: {Implementation specifics}
  - Depends: Task 1.1

### Phase 2: {Name}
...

## Testing Strategy

### Unit Tests
- [ ] Test: {description} in `path/to/test.ts`
- [ ] Test: {description}

### Integration Tests
- [ ] Test: {description}

## Validation Commands

```bash
# Type check
{type_check_command}

# Lint
{lint_command}

# Tests
{test_command}

# Build
{build_command}
```

## Acceptance Criteria

- [ ] {Criterion 1}
- [ ] {Criterion 2}
- [ ] All tests pass
- [ ] No type errors
- [ ] Code follows existing patterns

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| {decision} | {choice} | {why} |

## References

- {Doc/file reference with specific locations}

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| {risk} | {mitigation} |
```

## Quality Criteria

Before marking the plan as ready, verify:

1. **Context Complete** - All patterns, dependencies, gotchas documented
2. **Implementation Ready** - Another developer can execute without asking questions
3. **Pattern Consistent** - Tasks follow existing conventions with specific file:line references
4. **Information Dense** - No generic references; all content is actionable

## Output

After creating the plan:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Feature Plan Created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Feature: {name}
Location: .claude/plans/{filename}.md

Phases: {n}
Tasks: {total_tasks}
Files: {files_affected}

Validation: {commands_available}

Ready to implement? Run:
  /execute .claude/plans/{filename}.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Subcommands

### /feature:list
List all plans in `.claude/plans/`

### /feature:status
Show status of all plans (draft, ready, in_progress, completed)

### /feature:delete <name>
Remove a plan file

## Tips

- Break complex features into multiple phases
- Each task should be atomic (completable in one step)
- Include specific line numbers when referencing patterns
- Document "why" not just "what"
- If a task is complex, break it into sub-tasks
