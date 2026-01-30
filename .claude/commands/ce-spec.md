---
description: Orchestrate full project setup with interview, tech detection, and feature extraction
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Skill, AskUserQuestion
---

# /ce:spec - Project Specification Setup

Orchestrates complete project initialization: deep interview, tech detection, CLAUDE.md refinement, and feature extraction to TODO.md.

## Usage

```
/spec                    Full specification workflow
/spec --skip-interview   Skip interview if SPEC.md exists
/spec --refresh          Re-run on existing project
```

## Process

### Step 1: Check Prerequisites

```bash
# Check for existing artifacts
[ -f ".claude/SPEC.md" ] && echo "SPEC_EXISTS"
[ -f ".claude/project-context.json" ] && echo "CONTEXT_EXISTS"
[ -f ".claude/TODO.md" ] && echo "TODO_EXISTS"
```

Output `SPEC_STARTED` marker.

### Step 2: Run Interview

Unless `--skip-interview` AND SPEC.md exists, invoke the interview skill:

```
Skill: interview
```

This creates `.claude/SPEC.md` with complete project specification through deep questioning.

Output `INTERVIEW_COMPLETE` marker.

### Step 3: Run Tech Detection

```bash
bash .claude/scripts/detect-stack.sh > .claude/project-context.json
```

Parse results and display detected stack:
- Languages
- Frameworks
- Package manager
- Cloud platforms

Output `TECH_DETECTED` marker.

### Step 4: Refine CLAUDE.md

Read `.claude/CLAUDE.md` and ensure it contains ONLY:
- Core project facts
- Essential conventions
- Reference to `@rules/claudenv.md`

If bloated (>100 lines of non-framework content), use AskUserQuestion:

```
CLAUDE.md appears to have significant content ({n} lines).
Should I:
1. Keep as-is (it's all essential)
2. Extract architecture details to SPEC.md
3. Extract patterns to .claude/references/
4. Help me review what to keep
```

### Step 5: Extract and Classify Features from SPEC.md

Parse SPEC.md sections:
- `## Goals` - High-level objectives
- `## Features` - Specific features
- `## MVP Scope` or `## In Scope` - What to build
- `## Experience Design` - UX decisions that inform features
- `## Open Questions` - Things to resolve

Identify discrete, implementable units. Each feature should be:
- Specific enough to plan
- Small enough for one `/ce:execute` cycle
- Independent or with clear dependencies

**Assign priorities** based on:
- `P0` - Foundation/blocking (required for other features)
- `P1` - Core MVP features
- `P2` - Enhancement/nice-to-have

**Classify interface type** for each feature:
- `visual` - User interface components
- `api` - Backend endpoints/services
- `cli` - Command-line interface
- `none` - Infrastructure, config, non-user-facing

**Determine relevant UX passes** based on interface type:

| Interface Type | UX Passes Required |
|----------------|-------------------|
| `visual` | all 6 passes (mental-model, info-arch, affordances, cognitive-load, state-design, flow-integrity) |
| `api` | mental-model, info-arch, state-design |
| `cli` | mental-model, affordances, state-design, flow-integrity |
| `none` | skip UX analysis |

**Set output target** (default: claude):
- `claude` - Direct implementation via /ce:execute
- `stitch` - Build prompts optimized for Google Stitch
- `v0` - Build prompts optimized for v0
- `polymet` - Build prompts for Polymet
- `figma` - Design handoff for Figma

**Infer dependencies** by analyzing:
- Explicit mentions: "requires X", "after Y is complete", "depends on Z"
- Implicit ordering: Data models before APIs, Auth before protected features
- Priority relationships: P1 features implicitly depend on P0 features (foundation)

Common dependency patterns:
| Feature Type | Typically Depends On |
|--------------|---------------------|
| API endpoints | Database schema, Auth |
| Frontend pages | API endpoints, Auth |
| Integrations | Core features they extend |
| Tests | Features they test |

Use AskUserQuestion if classification is unclear:

```
I've identified {n} features. Help me classify:

{Feature Name}
- Priority: P1 (core feature)
- Interface: visual
- UX Passes: all
- Output Target: claude (default)
- Dependencies: {Database schema, User auth}

Is this classification correct?
```

### Step 6: Create Feature Plan Files

For each extracted feature:

1. Convert feature name to slug: `"Add user authentication"` → `add-user-authentication`
2. Create plan file at `.claude/plans/{slug}.md` with skeleton:

```markdown
# Feature: {Name}

> Status: draft
> Priority: {P0|P1|P2}
> Created: {YYYY-MM-DD HH:MM}

## Overview

{Brief description from SPEC.md}

## Implementation Phases

(To be filled by /ce:feature command)

## Validation Commands

```bash
# To be filled based on tech stack
```
```

3. Return the plan file path

### Step 7: Populate TODO.md

Create/update `.claude/TODO.md`:

```markdown
# Development TODO

> Generated from SPEC.md on {YYYY-MM-DD HH:MM}
> Run `/ce:next` to work through features interactively
> Run `/ce:autopilot` for autonomous completion

## P0 - Foundation

- [ ] **Database schema**: Set up data models
  → [plan](.claude/plans/database-schema.md)
  → interface: none

- [ ] **User auth**: JWT authentication
  → [plan](.claude/plans/user-auth.md)
  → interface: api
  → ux: mental-model, info-arch, state-design
  → depends: Database schema

## P1 - Core Features

- [ ] **API endpoints**: REST API for core entities
  → [plan](.claude/plans/api-endpoints.md)
  → interface: api
  → ux: mental-model, info-arch, state-design
  → depends: Database schema, User auth

- [ ] **Workflow builder**: Drag-drop canvas with nodes
  → [plan](.claude/plans/workflow-builder.md)
  → interface: visual
  → ux: all
  → target: claude
  → depends: API endpoints, User auth

## P2 - Enhancements

- [ ] **Email notifications**: Send alerts to users
  → [plan](.claude/plans/email-notifications.md)
  → interface: none
  → depends: User auth

## Setup Tasks

- [ ] Configure development environment
- [ ] Set up testing infrastructure
- [ ] Configure CI/CD (if applicable)

## Completed

(Features move here after successful /ce:execute)
```

**Format notes:**
- Features link to their plan files with `→ [plan](path)`
- Interface type declared with `→ interface: visual | api | cli | none`
- UX passes declared with `→ ux: all` or `→ ux: mental-model, state-design, ...`
- Output target declared with `→ target: claude | stitch | v0 | polymet | figma`
- Dependencies declared with `→ depends: Feature A, Feature B`
- P0 features are implicitly dependencies of P1 features
- Use checkboxes: `[ ]` pending, `[~]` in progress, `[x]` complete, `[!]` blocked

**Dependency rules:**
- Features only execute when ALL dependencies are completed
- Failed dependencies block dependent features
- Dependency graph is parsed by `dependency-graph.sh`
- Use `/ce:autopilot graph` to visualize dependencies

Output `FEATURES_EXTRACTED` marker.

### Step 8: Summary Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Project Specification Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SPEC.md: {created | updated} ({n} sections)
Tech Stack: {languages} | {frameworks} | {pkg_manager}
CLAUDE.md: {refined | unchanged}

Features Extracted: {n} (P0: {x}, P1: {y}, P2: {z})

  P0 Foundation:
    • {Feature 1} → .claude/plans/{slug}.md
    • {Feature 2} → .claude/plans/{slug}.md

  P1 Core:
    • {Feature 3} → .claude/plans/{slug}.md
    • {Feature 4} → .claude/plans/{slug}.md

  P2 Enhancements:
    • {Feature 5} → .claude/plans/{slug}.md

Plan Files: {n} created in .claude/plans/
TODO.md: Populated with prioritized features

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next Steps:
  /ce:next       - Pick a feature and start (interactive)
  /ce:autopilot  - Complete all features autonomously
  /ce:feature X  - Flesh out a specific plan file

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Output `SPEC_COMPLETE` marker.

## Subcommands

### /ce:spec:status
Show current spec status without running workflow.

### /ce:spec:features
Re-extract features from SPEC.md to TODO.md.

### /ce:spec:refresh
Full refresh: re-run interview, detection, and extraction.

## Markers

- `SPEC_STARTED`
- `INTERVIEW_COMPLETE`
- `TECH_DETECTED`
- `FEATURES_EXTRACTED`
- `SPEC_COMPLETE`

## Integration

After `/ce:spec` completes:
- SPEC.md is the project north star
- TODO.md contains all features to implement
- Use `/ce:next` for interactive feature workflow
- Use `/ce:autopilot` for autonomous completion
