---
description: Plan a feature with detailed implementation strategy saved to .claude/plans/
allowed-tools: Read, Write, Glob, Grep, Bash, WebFetch, WebSearch, AskUserQuestion
---

# /ce:feature - Feature Planning

Transform a feature request into a detailed, executable implementation plan. Plans are saved to `.claude/plans/` for persistence and can be executed with `/ce:execute`.

**Usage:**
```
/ce:feature <feature-description>
/ce:feature <feature> --output prompts    # Build prompts for external tools
/ce:feature <feature> --output design     # Design handoff spec
/ce:feature <feature> --target stitch     # Optimize prompts for Stitch
/ce:feature <feature> --target v0         # Optimize prompts for v0
/ce:feature <feature> --skip-ux           # Skip UX analysis (infrastructure features)
```

**Example:** `/ce:feature Add workflow builder with drag-drop canvas`

## Philosophy

> "Context is King" - The goal is one-pass implementation success through exhaustive upfront analysis.

A good plan enables any developer (human or AI) to implement the feature without additional research or clarification.

**UX Philosophy:** Every user-facing feature gets UX analysis BEFORE implementation planning. UX decisions made upfront prevent "game time" decisions that lead to inconsistent experiences.

## Process

### Phase 0: Interface Classification

First, determine what type of interface this feature involves:

| Interface Type | Indicators | UX Passes |
|----------------|------------|-----------|
| `visual` | UI, component, page, screen, dashboard | All 6 passes |
| `api` | Endpoint, service, REST, GraphQL | mental-model, info-arch, state-design |
| `cli` | Command, flag, terminal, shell | mental-model, affordances, state-design, flow-integrity |
| `none` | Database, config, infrastructure | Skip UX analysis |

If `--skip-ux` flag is provided, skip to Phase 2.

### Phase 0.5: UX Analysis (for user-facing features)

Run the relevant UX passes based on interface type. This is the **most important phase** - it prevents generic, inconsistent UIs.

#### Pass 1: Mental Model (all interface types)
- What does the user think this feature does?
- What prior experience do they bring?
- What misconceptions are likely?

**Required output:**
```markdown
## Pass 1: Mental Model

**Primary user intent:** [One sentence]
**Prior experience:** [What they know]
**Misconceptions to address:**
- [Misconception] → Addressed by: [UX decision]
```

#### Pass 2: Information Architecture (all interface types)
- What concepts will users encounter?
- How should they be grouped?
- What's primary vs secondary vs hidden?

**Required output:**
```markdown
## Pass 2: Information Architecture

**Concepts:**
| Concept | Description | Visibility |
|---------|-------------|------------|
| [Name] | [What it is] | Primary/Secondary/Hidden |

**Grouping rationale:** [Why organized this way]
```

#### Pass 3: Affordances (visual, cli)
- What actions are available?
- How does user discover them?
- What looks clickable/editable/actionable?

**Required output:**
```markdown
## Pass 3: Affordances

| Action | Signal | Discovery |
|--------|--------|-----------|
| [Action] | [Visual cue] | [How user finds it] |
```

#### Pass 4: Cognitive Load (visual, cli)
- Where will users hesitate?
- What decisions can we eliminate?
- What smart defaults can we provide?

**Required output:**
```markdown
## Pass 4: Cognitive Load

**Friction points:**
| Moment | Simplification |
|--------|----------------|
| [Where user hesitates] | [How we help] |

**Defaults:** [What we pre-fill and why]
```

#### Pass 5: State Design (all interface types)
- What states can the system be in?
- How is each state communicated?
- What can users do in each state?

**Required output:**
```markdown
## Pass 5: State Design

| State | User Sees | User Understands | User Can Do |
|-------|-----------|------------------|-------------|
| Empty | | | |
| Loading | | | |
| Success | | | |
| Partial | | | |
| Error | | | |
```

#### Pass 6: Flow Integrity (visual, cli)
- Where could users get lost?
- Where could first-time users fail?
- What guardrails are needed?

**Required output:**
```markdown
## Pass 6: Flow Integrity

| Risk | Location | Mitigation |
|------|----------|------------|
| [What could go wrong] | [Where] | [How we prevent it] |
```

**CRITICAL:** Do NOT proceed to implementation phases until all relevant UX passes are complete.

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
> Interface: visual | api | cli | none
> Output Target: claude | stitch | v0 | polymet | figma
> Estimated Tasks: {n}

## Overview

{2-3 sentence description of what this feature does and why}

## User Stories

- As a {user}, I want to {action} so that {benefit}
- ...

## UX Analysis

> This section captures UX decisions from Phase 0.5. These decisions MUST inform implementation.

### Pass 1: Mental Model
{Output from UX analysis}

### Pass 2: Information Architecture
{Output from UX analysis}

### Pass 3: Affordances
{Output from UX analysis - if applicable}

### Pass 4: Cognitive Load
{Output from UX analysis - if applicable}

### Pass 5: State Design
{Output from UX analysis}

### Pass 6: Flow Integrity
{Output from UX analysis - if applicable}

## Implementation Phases

### Phase 1: {Name}
> {Brief description} | {n} tasks

#### Tasks

- [ ] **Task 1.1**: {Brief description}
  - files: `path/to/file.ts`
  - action: {What exactly to do, including code patterns to follow}
  - verify: `{command to verify completion, e.g., npm test -- ComponentName}`
  - done: {Completion criteria - what indicates this task is finished}
  - references: `path/to/similar/code.ts:45-60`

- [ ] **Task 1.2**: {Brief description}
  - files: `path/a.ts`, `path/b.ts`
  - action: {Implementation specifics}
  - verify: `{verification command}`
  - done: {Completion criteria}
  - depends: Task 1.1

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
Interface: {visual | api | cli | none}
UX Passes: {completed passes}

Phases: {n}
Tasks: {total_tasks}
Files: {files_affected}

Validation: {commands_available}

Ready to implement? Run:
  /ce:execute .claude/plans/{filename}.md

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Output Formats

### --output claude (default)

Standard implementation plan with UX analysis embedded. Ready for `/ce:execute`.

### --output prompts

Generates self-contained build-order prompts for external design AI tools. Creates:
- `.claude/plans/{name}.md` - Standard plan
- `.claude/plans/{name}-prompts.md` - Build prompts

**Build prompt structure:**
1. Foundation (design tokens, base styles)
2. Layout Shell (navigation, structure)
3. Core Components (primary UI elements)
4. Interactions (user actions, feedback)
5. States & Feedback (empty, loading, error, success)
6. Polish (animations, responsive, edge cases)

Each prompt is **self-contained** - doesn't reference other prompts.

### --output design

Design handoff document for human designers or Figma. Includes UX analysis formatted for design review.

## Target Tool Profiles

When using `--output prompts`, the `--target` flag optimizes prompts for specific tools:

| Target | Style | Best Practices |
|--------|-------|----------------|
| `stitch` | Very vague OR very specific | Mid-detail fails; go extremes |
| `v0` | Component-focused | Single components work best |
| `polymet` | Functional prototypes | Good for interactions |
| `bolt` | Full-page context | Handles larger prompts |
| `figma` | Design tokens + specs | For designer handoff |

**Example:**
```
/ce:feature "Add workflow builder" --output prompts --target stitch
```

Produces prompts optimized for Google Stitch's characteristics.

## Subcommands

### /ce:feature:list
List all plans in `.claude/plans/`

### /ce:feature:status
Show status of all plans (draft, ready, in_progress, completed)

### /ce:feature:delete <name>
Remove a plan file

## Tips

- Break complex features into multiple phases
- Each task should be atomic (completable in one step)
- Include specific line numbers when referencing patterns
- Document "why" not just "what"
- If a task is complex, break it into sub-tasks
