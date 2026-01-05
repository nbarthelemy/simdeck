# Pending Agent Proposals

> Agents are proposed when repeated specialist patterns are detected or when tech detection identifies technologies needing specialized expertise.
>
> Run `/learn:implement agent [name]` to create a proposed agent.

**Last Reviewed:** Never
**Pending Count:** 0

---

## From Tech Detection

> Agents proposed during `/claudenv` based on detected technologies.
> These are created automatically - no action needed.

<!--
Entry format:

### {agent-name}

**Status:** proposed | created | skipped
**Technology:** {detected technology}
**Created At:** YYYY-MM-DD
**Rationale:** Why this agent would be useful

-->

---

## From Usage Patterns

> Agents proposed when the same domain expertise is needed 2+ times.

<!--
Entry format:

### {agent-name}

**Status:** proposed | approved | implemented
**Occurrences:** N
**First Seen:** YYYY-MM-DD
**Last Seen:** YYYY-MM-DD
**Evidence:**
- Task 1 that needed this specialist
- Task 2 that needed this specialist

**Suggested Agent:**
- **Triggers:** keyword1, keyword2
- **Scope:** What it would handle
- **Category:** code | analysis | process | domain

**Create:** `/learn:implement agent {name}`

-->

---

## Agent Lifecycle

1. **Proposed** - Detected via tech-detection or pattern-observer
2. **Approved** - User confirmed via `/learn:review`
3. **Created** - Agent file generated via `agent-creator`
4. **Active** - Agent available for orchestration

---

## Notes

- Agents from tech detection are created immediately during `/claudenv`
- Agents from usage patterns require 2 occurrences before proposal
- Use `/learn:implement agent [name]` to create a proposed agent
- Use `/agents` (built-in) to view all available agents
