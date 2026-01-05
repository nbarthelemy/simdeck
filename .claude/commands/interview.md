---
description: Conduct an in-depth project specification interview to clarify architecture, tech stack, design decisions, and requirements. Creates .claude/SPEC.md
allowed-tools: Bash(*), Write, Edit, Read, Glob, Grep, WebSearch, WebFetch
---

# /interview - Project Specification Interview

You are conducting a comprehensive project specification interview.

## Arguments

- `/interview` - Start full interview from scratch
- `/interview resume` - Continue from existing SPEC.md
- `/interview [topic]` - Focus on specific area (e.g., `/interview auth`, `/interview infra`)

## Available Topics

- `vision` - Project goals and scope
- `architecture` - System design and patterns
- `stack` - Technology choices
- `data` - Database and data model
- `api` - API design
- `auth` - Authentication and authorization
- `infra` - Infrastructure and deployment
- `security` - Security and compliance
- `process` - Development workflow

## Interview Process

### Phase 1: Silent Context Gathering

Before asking ANY questions, read and analyze:

1. **Existing Documentation:**
   - `.claude/SPEC.md` (if exists)
   - `.claude/CLAUDE.md`
   - `README.md`
   - `.claude/project-context.json`
   - `package.json` / `requirements.txt` / other deps
   - Any `docs/` directory contents
   - `.env.example`

2. **Codebase Analysis:**
   - File structure and organization
   - Existing implementations
   - Config files
   - API routes or endpoints
   - Database schemas
   - Test structure

3. **Identify What's Already Defined:**
   - List decisions already made
   - Note technologies in use
   - Understand existing architecture

4. **Identify TRUE Gaps:**
   - What decisions are genuinely unclear?
   - What areas have no guidance?
   - What tradeoffs haven't been considered?

### Phase 2: Interactive Interview

**CRITICAL RULES:**

1. **Never ask obvious questions** - If it's in docs or code, don't ask
2. **One question at a time** - Wait for response before next
3. **Provide informed suggestions** - Every question includes recommendations
4. **Explain WHY you're asking** - Connect to architectural implications
5. **Be specific, not generic** - Tailor to this exact project
6. **Research before suggesting** - Use WebSearch for current best practices
7. **Go deep, not broad** - Exhaust one area before moving to next

**Question Format:**

```
I see you're building [X] with [detected tech].
For [specific component], I didn't find a decision on [topic].

Options I'd suggest:

**[Option A]** - [1-2 sentence description]
- Pros: [specific benefits]
- Cons: [specific drawbacks]
- Best when: [use case]

**[Option B]** - [1-2 sentence description]
- Pros: [specific benefits]
- Cons: [specific drawbacks]
- Best when: [use case]

Given [something specific about their project], I'd lean toward [recommendation] because [reason].

Which approach fits your needs?
```

### Phase 3: Write Specification

After gathering answers, write comprehensive `.claude/SPEC.md` using the template at `.claude/skills/interview-agent/spec-template.md`.

### Phase 4: Update Infrastructure

1. Update `project-context.json` with confirmed tech stack
2. Update `settings.json` with appropriate permissions
3. Notify user: "Specification complete. See .claude/SPEC.md"

## Interview Categories

Only ask about areas that are UNDEFINED:

### A. Project Vision & Scope
- What problem does this solve? For whom?
- What's the MVP vs full vision?
- What's explicitly out of scope?

### B. Technical Architecture
- Monolith vs microservices vs serverless?
- Real-time requirements?
- Background job processing?
- Caching strategy?

### C. Data & State
- Primary database and why?
- Data relationships and access patterns?
- File/media storage?
- Client-side state management?

### D. Authentication & Authorization
- Auth provider or self-hosted?
- User roles and permissions model?
- API authentication approach?

### E. API Design
- REST vs GraphQL vs tRPC vs gRPC?
- Versioning strategy?
- Rate limiting?

### F. Frontend & UX
- SSR vs SSG vs CSR vs hybrid?
- Component library or custom?
- Accessibility requirements?

### G. Infrastructure & DevOps
- Deployment target and why?
- Environment strategy?
- CI/CD requirements?
- Monitoring needs?

### H. Security & Compliance
- Data sensitivity level?
- Compliance requirements?
- Encryption requirements?

## Important Behaviors

- **Never ask redundant questions**
- **Always suggest, never just ask**
- **Go deep** - Better to thoroughly cover 5 areas than superficially touch 20
- **Be practical** - Consider timeline, team size, budget
- **Challenge assumptions** - Gently question decisions that seem problematic
- **Document uncertainty** - Note unclear items in Open Questions section
