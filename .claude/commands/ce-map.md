---
description: Generate comprehensive codebase analysis documents in .claude/codebase/
allowed-tools: Read, Write, Glob, Grep, Bash, Task
---

# /ce:map - Codebase Mapping

Generate comprehensive analysis documents for the codebase. Spawns 6 parallel analysis agents to create documentation in `.claude/codebase/`.

**Usage:**
- `/ce:map` - Generate all 6 analysis documents
- `/ce:map status` - Check which documents exist
- `/ce:map clean` - Remove existing documents and regenerate

## Documents Generated

| Document | Agent | Purpose |
|----------|-------|---------|
| `ARCHITECTURE.md` | architecture-analyst | System design, patterns, data flow |
| `STRUCTURE.md` | structure-analyst | Directory layout, key files |
| `CONVENTIONS.md` | conventions-analyst | Code style, naming, patterns |
| `TESTING.md` | testing-analyst | Test setup, coverage, patterns |
| `INTEGRATIONS.md` | integration-analyst | External services, APIs |
| `CONCERNS.md` | concerns-analyst | Tech debt, security, improvements |

## Process

### 1. Check Status
```bash
bash .claude/scripts/map-codebase.sh status
```

If all documents exist and are recent, ask if regeneration is needed.

### 2. Initialize Directory
```bash
bash .claude/scripts/map-codebase.sh init
```

### 3. Spawn Analysis Agents

Launch 6 agents in parallel using Task tool:

```
Task(subagent_type="general-purpose", prompt="
You are the {agent-name} specialist.
Read .claude/agents/{agent-name}.md for full instructions.
Analyze this codebase and generate .claude/codebase/{DOCUMENT}.md
Follow the output format specified in the agent file.
")
```

**Agents to spawn:**
1. `architecture-analyst` → `ARCHITECTURE.md`
2. `structure-analyst` → `STRUCTURE.md`
3. `conventions-analyst` → `CONVENTIONS.md`
4. `testing-analyst` → `TESTING.md`
5. `integration-analyst` → `INTEGRATIONS.md`
6. `concerns-analyst` → `CONCERNS.md`

### 4. Verify Completion

After agents complete, verify all documents were created:

```bash
bash .claude/scripts/map-codebase.sh status
```

### 5. Output Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🗺️  Codebase Mapping Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Documents: 6/6 generated
Location: .claude/codebase/

├── ARCHITECTURE.md  ✓
├── STRUCTURE.md     ✓
├── CONVENTIONS.md   ✓
├── TESTING.md       ✓
├── INTEGRATIONS.md  ✓
└── CONCERNS.md      ✓

These documents are now available for:
- /ce:prime context loading
- Feature planning reference
- Onboarding documentation

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## When to Use

- **New project setup** - After `/ce:init` to understand the codebase
- **Onboarding** - Generate docs for new team members
- **Major refactoring** - Before planning significant changes
- **Periodic refresh** - Regenerate when codebase has changed significantly

## Integration

Documents in `.claude/codebase/` are:
- Loaded by `/ce:prime` for context
- Referenced by `/ce:feature` during planning
- Used by analysis agents for informed recommendations
