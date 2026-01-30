# UX Analysis Guide

> The 6-Pass Framework for User Experience Design

This guide documents the UX analysis framework used throughout the claudenv pipeline. Every user-facing feature should complete relevant UX passes BEFORE implementation.

## Why UX Analysis Matters

When you skip UX planning:
- AI makes "game time" decisions that lead to inconsistent UIs
- Features feel generic and forgettable
- Users get confused by mixed mental models
- States aren't handled consistently
- Errors and edge cases are afterthoughts

When you do UX analysis first:
- Every visual decision has a reason
- Interfaces feel cohesive and intentional
- Users' mental models are respected
- All states are designed upfront
- Errors become first-class citizens

## The 6 Passes

### Pass 1: Mental Model

**Question:** What does the user think is happening?

Every user approaches your interface with preconceptions based on:
- Similar tools they've used
- Domain knowledge they have
- Expectations from your marketing/docs

**Ask:**
- What does the user believe this system does?
- What prior experience do they bring?
- What wrong mental models are likely?
- How do we reinforce the correct model?

**Output:**
```markdown
## Pass 1: Mental Model

**Primary user intent:** [One sentence from user's perspective]

**Prior experience:** [What similar tools/concepts they know]

**Likely misconceptions:**
- [Misconception 1] → Addressed by: [UX decision]
- [Misconception 2] → Addressed by: [UX decision]

**Model reinforcement:** [How we consistently reinforce the correct model]
```

### Pass 2: Information Architecture

**Question:** What exists, and how is it organized?

Map every concept the user will encounter, then decide:
- How to group related concepts
- What's always visible vs on-demand
- What's hidden until needed

**Ask:**
- What concepts will users encounter?
- How should they be grouped?
- What's primary (always visible)?
- What's secondary (visible on interaction)?
- What's hidden (progressive disclosure)?

**Output:**
```markdown
## Pass 2: Information Architecture

**All concepts:**
| Concept | Description | Visibility |
|---------|-------------|------------|
| [Name] | [What it is] | Primary/Secondary/Hidden |

**Grouping:**
```
[Group 1]
├── Concept A (primary)
├── Concept B (primary)
└── Concept C (secondary)

[Group 2]
├── Concept D (primary)
└── Concept E (hidden until needed)
```

**Rationale:** [Why organized this way]
```

### Pass 3: Affordances

**Question:** What's obvious without explanation?

Users should know what they can do without reading docs. Map every action and how it's signaled.

**Ask:**
- What is clickable?
- What looks editable?
- What looks like output (read-only)?
- What looks final vs in-progress?
- How does user discover actions?

**Output:**
```markdown
## Pass 3: Affordances

| Action | Visual Signal | Discovery |
|--------|---------------|-----------|
| [Action] | [What makes it obvious] | [How user finds it] |

**Affordance rules:**
- If user sees X, they should assume Y
- [Additional rules...]
```

### Pass 4: Cognitive Load

**Question:** Where will the user hesitate?

Find every moment of friction and simplify it.

**Ask:**
- Where do users make decisions?
- Where are they uncertain what to do?
- Where are they waiting on the system?
- What decisions can we eliminate?
- What smart defaults can we provide?

**Output:**
```markdown
## Pass 4: Cognitive Load

**Friction points:**
| Moment | Type | Simplification |
|--------|------|----------------|
| [Where] | Choice/Uncertainty/Waiting | [How to reduce] |

**Defaults introduced:**
- [Field/option]: defaults to [value] because [reason]

**Progressive disclosure:**
- [What's hidden initially] → Revealed when [trigger]
```

### Pass 5: State Design

**Question:** How does the system talk back?

Every element has states. Design them all explicitly.

**Standard states:**
- **Empty** - No data yet
- **Loading** - Fetching/processing
- **Success** - Operation completed
- **Partial** - Incomplete data
- **Error** - Something went wrong

**Ask for each state:**
- What does the user see?
- What do they understand?
- What can they do next?

**Output:**
```markdown
## Pass 5: State Design

### [Element/Screen]

| State | What User Sees | What User Understands | What User Can Do |
|-------|----------------|----------------------|------------------|
| Empty | [Description] | [Understanding] | [Available actions] |
| Loading | [Description] | [Understanding] | [Available actions] |
| Success | [Description] | [Understanding] | [Available actions] |
| Partial | [Description] | [Understanding] | [Available actions] |
| Error | [Description] | [Understanding] | [Available actions] |
```

### Pass 6: Flow Integrity

**Question:** Does this feel inevitable?

Test the complete flow for failure points.

**Ask:**
- Where could users get lost?
- Where would a first-time user fail?
- What must be visible vs can be implied?
- What guardrails are needed?
- What nudges help users succeed?

**Output:**
```markdown
## Pass 6: Flow Integrity

**Flow risks:**
| Risk | Where | Mitigation |
|------|-------|------------|
| [Risk] | [Location] | [Guardrail/Nudge] |

**Visibility decisions:**
- Must be visible: [List]
- Can be implied: [List]

**First-time user experience:**
- [How we help new users succeed]

**Recovery paths:**
- [How users recover from mistakes]
```

## Which Passes Apply?

| Interface Type | Required Passes |
|----------------|-----------------|
| Visual UI | All 6 passes |
| API | Pass 1, 2, 5 (mental-model, info-arch, state-design) |
| CLI | Pass 1, 3, 5, 6 (mental-model, affordances, state-design, flow-integrity) |
| None (infra) | Skip UX analysis |

## Integration Points

### During /ce:interview

Experience Design questions are asked in Phase 2, producing the Experience Design section of SPEC.md.

### During /ce:spec

Features are classified with interface type and relevant UX passes:
```
→ interface: visual
→ ux: all
```

### During /ce:feature

UX passes are completed in Phase 0.5, embedded in the feature plan:
```markdown
## UX Analysis

### Pass 1: Mental Model
...
```

### During frontend-design

The skill checks for existing UX analysis and uses it to inform visual decisions.

## Common Mistakes

| Mistake | Why It Happens | Fix |
|---------|----------------|-----|
| Skipping to visuals | "I know what I want" | Passes are fast; do them anyway |
| Merging passes | "I'll cover this while doing that" | Separate passes force separate thinking |
| Implicit affordances | "Buttons are obviously clickable" | Map EVERY action explicitly |
| Scattered state design | "I'll add states per component" | One holistic state table catches gaps |
| Generic UX | "Users will figure it out" | First-time users fail first |

## Output Targets

UX analysis feeds different outputs:

| Target | Format |
|--------|--------|
| Claude Code | Embedded in feature plan, informs implementation |
| External tools (Stitch, v0) | Converted to build-order prompts |
| Design handoff | Formatted for designers/Figma |

## Further Reading

- `/ce:interview --demo` - Interview focused on UX for demos
- `/ce:feature --output prompts` - Generate build prompts from UX analysis
- `frontend-design` skill - Visual implementation using UX analysis
