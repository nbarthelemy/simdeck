---
description: Implement a pending proposal from the learning system. Creates skills, hooks, commands, or agents based on observed patterns.
allowed-tools: Read, Write, Edit, Bash(*), Glob
---

# /learn:implement - Implement Learning Proposal

Implement a pending proposal from the learning system.

## Usage

```
/learn:implement [type] [name]
```

**Types:**
- `skill` - Create a new skill (technology skills invoke meta-agent)
- `agent` - Create a new specialist subagent (invokes agent-creator skill)
- `command` - Create a new command
- `hook` - Create/update hook configuration

## Process

### For Skills

1. Read proposal from `.claude/learning/pending-skills.md`
2. Check skill type:
   - **Automation skills** (type: automation): Auto-create
   - **Technology skills** (type: technology): Requires user confirmation, invoke meta-agent
3. Create skill directory: `.claude/skills/[name]/`
4. Create `SKILL.md` with:
   - Appropriate triggers from observed patterns
   - Tools based on what was used
   - Instructions based on observed behavior
5. Update status in pending file
6. Notify: "✅ Created skill: [name]"

### For Agents

1. Read proposal from `.claude/learning/pending-agents.md`
2. Check agent source:
   - **From tech detection**: Create immediately
   - **From usage patterns**: Requires user confirmation (2+ occurrences)
3. **Invoke `agent-creator` skill** with:
   - Agent name
   - Detected technology or usage context
   - Category (code, analysis, process, domain)
4. Agent-creator will:
   - Research domain via web search
   - Generate agent file at `.claude/agents/[name].md`
   - Use template from `.claude/templates/agent.md.template`
5. Update status in pending file
6. Notify: "✅ Created agent: [name]"

**Note:** Agents are specialist subagents spawned by the orchestrator for parallel task execution. They cannot spawn other agents (flat hierarchy).

### For Commands

1. Read proposal from `.claude/learning/pending-commands.md`
2. Create command file: `.claude/commands/[name].md`
3. Include:
   - Description from observed usage
   - Steps based on observed sequences
   - Appropriate tool permissions
4. Update status in pending file
5. Notify: "✅ Created command: /[name]"

### For Hooks

1. Read proposal from `.claude/learning/pending-hooks.md`
2. Update `.claude/settings.json` hooks section
3. Update status in pending file
4. Notify: "✅ Created hook: [name]"

## Examples

### Skill Example

```
User: /learn:implement skill prisma-operations

Claude: Reading proposal for prisma-operations...

Creating skill at .claude/skills/prisma-operations/SKILL.md

Skill created with:
- Triggers: prisma, schema, migration, database
- Tools: Bash(prisma:*), Read, Write, Edit
- Based on 3 observed occurrences

✅ Created skill: prisma-operations

The skill will now auto-invoke when you work with Prisma.
```

### Agent Example

```
User: /learn:implement agent nextjs-specialist

Claude: Reading proposal for nextjs-specialist...

Invoking agent-creator skill...

Researching Next.js best practices and patterns...
- Server components vs client components
- App Router patterns
- Data fetching strategies
- ISR and caching

Creating agent at .claude/agents/nextjs-specialist.md

Agent created with:
- Category: domain
- Triggers: next.js, server components, app router, ISR
- Tools: Read, Write, Edit, Glob, Grep, WebFetch
- Based on detected technology: Next.js

✅ Created agent: nextjs-specialist

The agent can now be spawned by the orchestrator for Next.js tasks.
```

## Validation

Before implementing, verify:
- [ ] Proposal exists in pending file
- [ ] Pattern has sufficient evidence
- [ ] No duplicate skill/command exists
- [ ] Tools requested are appropriate
