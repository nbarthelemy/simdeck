---
description: Orchestrate full project setup with interview, tech detection, and feature extraction
allowed-tools: Bash, Read, Write, Edit, Glob, Grep, Skill, AskUserQuestion
---

# /spec - Project Specification Setup

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
3. Extract patterns to .claude/reference/
4. Help me review what to keep
```

### Step 5: Extract and Prioritize Features from SPEC.md

Parse SPEC.md sections:
- `## Goals` - High-level objectives
- `## Features` - Specific features
- `## MVP Scope` or `## In Scope` - What to build
- `## Open Questions` - Things to resolve

Identify discrete, implementable units. Each feature should be:
- Specific enough to plan
- Small enough for one `/execute` cycle
- Independent or with clear dependencies

**Assign priorities** based on:
- `P0` - Foundation/blocking (required for other features)
- `P1` - Core MVP features
- `P2` - Enhancement/nice-to-have

Use AskUserQuestion if priority is unclear:

```
I've identified {n} features. Help me prioritize:

{Feature Name}
- Seems like: P1 (core feature)
- Dependencies: none detected

Is this priority correct?
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

(To be filled by /feature command)

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
> Run `/next` to work through features interactively
> Run `/autopilot` for autonomous completion

## P0 - Foundation

- [ ] **{Feature 1}**: {description} → [plan](.claude/plans/{slug}.md)
- [ ] **{Feature 2}**: {description} → [plan](.claude/plans/{slug}.md)

## P1 - Core Features

- [ ] **{Feature 3}**: {description} → [plan](.claude/plans/{slug}.md)
- [ ] **{Feature 4}**: {description} → [plan](.claude/plans/{slug}.md)

## P2 - Enhancements

- [ ] **{Feature 5}**: {description} → [plan](.claude/plans/{slug}.md)

## Setup Tasks

- [ ] Configure development environment
- [ ] Set up testing infrastructure
- [ ] Configure CI/CD (if applicable)

## Completed

(Features move here after successful /execute)
```

**Format notes:**
- Features link to their plan files
- P0 features should be completed first (they may block others)
- Use checkboxes: `[ ]` pending, `[~]` in progress, `[x]` complete

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
  /next       - Pick a feature and start (interactive)
  /autopilot  - Complete all features autonomously
  /feature X  - Flesh out a specific plan file

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Output `SPEC_COMPLETE` marker.

## Subcommands

### /spec:status
Show current spec status without running workflow.

### /spec:features
Re-extract features from SPEC.md to TODO.md.

### /spec:refresh
Full refresh: re-run interview, detection, and extraction.

## Markers

- `SPEC_STARTED`
- `INTERVIEW_COMPLETE`
- `TECH_DETECTED`
- `FEATURES_EXTRACTED`
- `SPEC_COMPLETE`

## Integration

After `/spec` completes:
- SPEC.md is the project north star
- TODO.md contains all features to implement
- Use `/next` for interactive feature workflow
- Use `/autopilot` for autonomous completion
