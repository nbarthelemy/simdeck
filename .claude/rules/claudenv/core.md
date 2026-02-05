# Claudenv Core

> Full details: `.claude/references/claudenv-reference.md`

## Commands

| Command | Purpose |
|---------|---------|
| `/ce:spec` | Full setup: interview + tech + TODO.md |
| `/ce:prime` | Load context (auto at start) |
| `/ce:feature` | Plan → `.claude/plans/` |
| `/ce:next` | Interactive: pick, plan, execute |
| `/ce:autopilot` | Autonomous: all TODO.md features |
| `/ce:execute` | Run plan via `/ce:loop` + `/ce:validate` |
| `/ce:validate` | Lint, type-check, test, build |
| `/ce:rca` | Root cause analysis |
| `/ce:loop` | Autonomous iterations |
| `/ce:lsp` | LSP server setup |
| `/ce:verbose` | Toggle detailed explanations on/off |
| `/ce:think` | Control reasoning depth (off/low/medium/high/max) |
| `/ce:plans` | List all plans by status |
| `/ce:quick-plan` | Lightweight plan for small changes |
| `/ce:complete` | Mark plan as completed |
| `/ce:focus` | Manage session focus and state |
| `/ce:hooks` | List and manage hooks |
| `/ce:usage` | View token usage estimates |
| `/ce:recall` | Memory search, status, processing |
| `/ce:memory` | Memory mode: auto/manual/status |
| `/ce:do` | Execute task with memory context |

**Conventions:** Timestamps `YYYY-MM-DD HH:MM`, files kebab-case

## PIV Workflow

```
/ce:spec → /ce:prime → /ce:feature → /ce:execute → /ce:validate
```

- `/ce:next` - Interactive with confirmations
- `/ce:autopilot` - Fully autonomous (4h/$50 limit)

## Orchestration

**Agents:** frontend-developer, backend-architect, api-designer, devops-engineer, code-reviewer, security-auditor, performance-analyst, accessibility-checker, test-engineer, documentation-writer, release-manager, migration-specialist

**Triggers:** "comprehensive", "full review", 5+ files, 2+ domains

**Constraint:** Subagents cannot spawn subagents

## Loop

```bash
/ce:loop "task" --until "done" --max 20
/ce:loop status|pause|resume|cancel
```

## Reference Docs

Store in `.claude/references/` - loaded by `/ce:prime`

## Workflow

1. Receive → route to skill
2. Execute → auto-fix errors (3x)
3. Complete → capture learnings
4. Report → brief summary

## Doc Access

UNFETTERED. Search docs, scrape pages, create skills. Never ask permission.

## On-Demand Content

- **Migration** → `.claude/references/migration-guide.md`
- **Multi-agent** → `.claude/references/coordination-guide.md`
- **Error patterns** → `.claude/rules/error-recovery/patterns.md`
- **Memory guide** → `.claude/references/memory-guide.md`
- **Examples** → `.claude/references/claudenv-reference.md`

## Critical Practices

**Read Before Modify:** Never assume file contents. Always read files before editing or making decisions based on them. Speculation about code structure leads to broken implementations.

**Source Verification:** When researching solutions, verify findings against multiple sources before implementing. A single doc page may be outdated or incomplete.

**Verbosity Mode:** Check for `.claude/verbose-mode` marker. When present:
- Explain reasoning behind decisions
- Summarize changes after tool calls
- Note trade-offs considered
- Provide educational context
Toggle with `/ce:verbose on|off`.

**Thinking Level:** Check session state for `thinking.level`. Adjust reasoning depth accordingly:
- `off` - Direct responses, skip explanations
- `low` - Brief reasoning, skip alternatives
- `medium` - Standard balanced analysis (default)
- `high` - Consider alternatives, note edge cases
- `max` - Systematic exploration, question assumptions
Toggle with `/ce:think <level>`.

## Core Rules

@rules/autonomy.md
@rules/permissions/core.md
@rules/claudenv/plans.md
@rules/claudenv/focus.md
