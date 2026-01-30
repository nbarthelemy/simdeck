---
description: Conduct project specification interview to clarify requirements, architecture, and user experience
allowed-tools: Read, Write, Edit, AskUserQuestion, Skill, WebSearch, WebFetch
---

# /ce:interview - Project Specification Interview

Conducts a structured interview to create a complete project specification. The interview covers product requirements, user experience design, and technical architecture.

## Usage

```
/ce:interview                 Full interview (PRD + UX + Technical)
/ce:interview --quick         Quick interview (PRD + UX essentials only)
/ce:interview --demo          Demo-focused (PRD + UX + build prompts for prototyping)
/ce:interview --continue      Continue incomplete interview
```

## Interview Phases

### Phase 1: Product Requirements (PRD)
- Problem statement and target users
- Success criteria and non-goals
- Core use cases and happy paths

### Phase 2: Experience Design (UX)
- Mental model alignment
- Information architecture
- State design (empty, loading, error, success)
- Affordances and cognitive load (for visual/CLI)
- Flow integrity

### Phase 3: Technical Architecture (full mode only)
- System architecture and data model
- Auth, API, and infrastructure
- Security and compliance

## Modes

| Mode | Questions | Output | Use When |
|------|-----------|--------|----------|
| **Full** | 15-25 | Complete SPEC.md | Production projects |
| **Quick** | 5-8 | Lightweight SPEC.md | Prototypes, exploration |
| **Demo** | 8-12 | SPEC.md + build prompts | External design tools |

## Output

**Primary:** `.claude/SPEC.md` with:
- Product Requirements section
- Experience Design section
- Technical Architecture section (full mode)

**Secondary:**
- `.claude/project-context.json` - Tech stack details
- `.claude/plans/prototype-prompts.md` - Build prompts (demo mode only)

## Examples

### Starting a New Project
```
/ce:interview
```
Full interview for a production project.

### Quick Prototype
```
/ce:interview --quick
```
Get a lightweight spec to start building fast.

### Preparing for External Design Tool
```
/ce:interview --demo
```
Creates SPEC.md plus build-order prompts for Stitch, v0, Polymet, etc.

## Integration

After `/ce:interview` completes:
- Run `/ce:spec` to detect tech stack and populate TODO.md
- Or run `/ce:feature` directly if adding to existing project
- For demos, use the generated prompts with your preferred design tool

## See Also

- `/ce:spec` - Full project setup including feature extraction
- `/ce:feature` - Plan a specific feature with UX analysis
