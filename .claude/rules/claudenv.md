# Claudenv Framework

> Complete Claude Code infrastructure for autonomous development

## Quick Reference

### Key Commands

| Command | Description |
|---------|-------------|
| `/spec` | Full project setup: interview, tech detect, CLAUDE.md, TODO.md |
| `/prime` | Load comprehensive project context (auto-runs at session start) |
| `/feature <name>` | Plan a feature, save to `.claude/plans/` |
| `/next` | Interactive feature workflow - pick, plan, execute with confirmations |
| `/autopilot` | Fully autonomous feature completion from TODO.md |
| `/execute <plan>` | Execute plan via `/loop --plan` + `/validate` |
| `/validate` | Run stack-aware validation (lint, type-check, test, build) |
| `/rca <issue>` | Root cause analysis for bugs |
| `/claudenv` | Bootstrap infrastructure for current project |
| `/interview` | Conduct project specification interview |
| `/loop` | Start autonomous iterative development loop |
| `/loop --plan <file>` | Execute structured plan file (phases/tasks) |
| `/loop status` | Check current loop progress |
| `/loop pause` | Pause active loop |
| `/loop resume` | Resume paused loop |
| `/loop cancel` | Stop and cancel active loop |
| `/lsp` | Auto-detect and install LSP servers |
| `/lsp:status` | Check LSP server status |
| `/claudenv:status` | Show system overview |
| `/health:check` | Verify infrastructure integrity |
| `/learn:review` | Review pending automation proposals |
| `/reflect` | Consolidate learnings, update project knowledge |
| `/reflect evolve` | Analyze failures and propose system improvements |
| `/analyze-patterns` | Force pattern analysis |
| `/skills:triggers` | List skill trigger keywords and phrases |
| `/agents:triggers` | List agent trigger keywords and phrases |

### Skills (Auto-Invoked)

Skills auto-invoke based on triggers in `.claude/skills/triggers.json`. See `@rules/trigger-reference.md` for full trigger list.

### Directory Structure

```
.claude/
├── CLAUDE.md           # Project instructions + @rules/claudenv.md
├── settings.json       # Permissions & hooks
├── SPEC.md             # Project specification (generated)
├── project-context.json # Detected tech stack
├── commands/           # Slash commands
├── skills/             # Auto-invoked capabilities
│   └── triggers.json   # Skill trigger configuration
├── agents/             # Specialist subagents for orchestration
│   └── triggers.json   # Agent trigger configuration
├── orchestration/      # Orchestration config (triggers, limits)
├── rules/              # Modular instruction sets
├── scripts/            # Shell scripts for hooks
├── templates/          # Templates for generation
├── reference/          # Curated best practices docs (read by /prime)
├── plans/              # Feature implementation plans (/feature output)
├── rca/                # Root cause analysis documents (/rca output)
├── learning/           # Pattern observations
├── loop/               # Autonomous loop state & history
├── lsp-config.json     # Installed LSP servers (generated)
├── logs/               # Execution logs
└── backups/            # Auto-backups
```

---

## PIV Workflow (Prime-Implement-Validate)

A structured approach to feature development that ensures context-rich, one-pass implementation success.

### Overview

```
/spec → /prime → /feature → /execute → /validate
         │                      │
         │                      └── calls /loop --plan + /validate
         │
         └── auto-runs at session start
```

**Workflow Options:**
- **Interactive**: `/next` - Pick features, confirm each step
- **Autonomous**: `/autopilot` - Complete all features without interaction

### /spec - Project Setup

Full project initialization:

```bash
/spec
```

1. Runs `/interview` for deep questioning
2. Detects tech stack via `detect-stack.sh`
3. Refines CLAUDE.md with project rules
4. Extracts features from SPEC.md
5. Populates TODO.md with features

### /prime - Context Loading

Runs automatically at session start. Loads:
- Project structure and tech stack
- Documentation (CLAUDE.md, SPEC.md, README)
- Reference materials from `.claude/reference/`
- Current git state and recent changes
- Active work (TODO.md, existing plans)

### /feature - Feature Planning

Creates persistent implementation plans:

```bash
/feature "Add user authentication"
```

Outputs to `.claude/plans/add-user-authentication.md`:
- Overview and user stories
- Implementation phases with atomic tasks
- Testing strategy
- Validation commands
- Acceptance criteria

### /execute - Plan Execution

Thin orchestrator that delegates work:

```bash
/execute .claude/plans/add-user-authentication.md
```

1. Calls `/loop --plan <file>` to execute tasks
2. Runs `/validate` after completion
3. Updates TODO.md on success

### /next - Interactive Workflow

Work through features one at a time with confirmation:

```bash
/next
```

1. Shows available features from TODO.md
2. Creates plan if needed via `/feature`
3. Confirms before each execution
4. Asks "Continue to next?" after completion

### /autopilot - Fully Autonomous

Complete all features without interaction:

```bash
/autopilot                    # Complete all features
/autopilot --max-features 3   # Limit to 3 features
/autopilot --dry-run         # Show plan only
/autopilot --pause-on-failure # Stop on first failure
```

Safety limits: 4h max time, $50 max cost, no git push, no deploy.

### /validate - Stack-Aware Validation

Runs appropriate checks for detected tech stack:

```bash
/validate           # Full validation
/validate --fix     # Auto-fix lint issues
/validate --quick   # Skip slow checks
```

Automatically runs: lint, type-check, test, build

### /rca - Root Cause Analysis

For bug investigation before fixing:

```bash
/rca #123                          # GitHub issue
/rca "Login fails after reset"     # Description
```

Creates `.claude/rca/{slug}.md` with:
- Issue summary and reproduction steps
- Root cause identification
- Impact assessment
- Proposed fix strategy
- Testing plan

---

## Reference Documentation

Store curated best practices in `.claude/reference/`. These are read during `/prime` to provide stack-specific guidance.

### Purpose

Reference docs help Claude:
- Follow framework-specific patterns
- Avoid common pitfalls
- Use idiomatic code
- Understand project conventions

### Suggested Files

| Stack | Suggested Reference Docs |
|-------|-------------------------|
| **React** | `react-best-practices.md`, `state-management.md` |
| **FastAPI** | `fastapi-best-practices.md`, `pydantic-patterns.md` |
| **Next.js** | `nextjs-best-practices.md`, `routing-patterns.md` |
| **Go** | `go-conventions.md`, `error-handling.md` |
| **Testing** | `testing-strategy.md`, `e2e-patterns.md` |

### Creating Reference Docs

Each doc should include:
1. Key principles
2. Common patterns with examples
3. Anti-patterns to avoid
4. Project-specific conventions

See `.claude/reference/README.md` for templates.

---

## Subagent Orchestration

Claude automatically spawns specialist subagents for complex parallel tasks.

### Built-in Agents

| Category | Agents |
|----------|--------|
| **Code** | `frontend-developer`, `backend-architect`, `api-designer`, `devops-engineer` |
| **Analysis** | `code-reviewer`, `security-auditor`, `performance-analyst`, `accessibility-checker` |
| **Process** | `test-engineer`, `documentation-writer`, `release-manager`, `migration-specialist` |

### Agent Triggers

Agents are routed based on triggers in `.claude/agents/triggers.json`. See `@rules/trigger-reference.md` for full trigger list.

### Orchestration Triggers

The orchestrator spawns agents when:
- **Keywords detected:** "comprehensive", "full review", "across codebase", "refactor all"
- **Complexity threshold:** 5+ files, 2+ domains, 4+ steps
- **Explicit request:** User asks for parallel execution

### Tech-Specific Agents

During `/claudenv`, specialist agents are created for detected technologies:
- React → `react-specialist`
- Django → `django-specialist`
- AWS → `aws-architect`
- Shopify → `shopify-specialist`
- And 50+ more mappings

### Key Constraint

**Subagents cannot spawn other subagents** (flat hierarchy).

The orchestrator is a SKILL (runs in main context) so it CAN spawn subagents via the Task tool.

---

## Skill Architecture (Claude Code 2.1+)

Claudenv leverages advanced skill features from Claude Code 2.1:

### Forked Context (`context: fork`)

Heavy-analysis skills run in isolated forked contexts to prevent main context pollution:

```yaml
---
name: orchestrator
context: fork
allowed-tools:
  - Read
  - Task
---
```

**Skills using forked context:**
- `orchestrator` - Complex multi-agent coordination
- `pattern-observer` - Background pattern analysis
- `tech-detection` - Project stack analysis
- `meta-skill` - Technology research and skill creation
- `agent-creator` - Specialist agent generation

### Agent Delegation (`agent` field)

Skills can specify which agent type should execute them:

```yaml
---
name: frontend-design
agent: frontend-developer
---
```

### YAML-Style Tool Lists

Cleaner frontmatter using YAML lists instead of comma-separated strings:

```yaml
allowed-tools:
  - Read
  - Write
  - Bash(npm *)
  - Bash(npx *)
```

### Skill Hooks

Skills can define their own hooks that run during skill execution:

```yaml
hooks:
  Stop:
    - command: bash .claude/scripts/cleanup.sh
```

### One-Time Hooks (`once: true`)

Session startup hooks run only once per session:

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "",
      "once": true,
      "hooks": [{"type": "command", "command": "bash .claude/scripts/session-start.sh"}]
    }]
  }
}
```

### Agent Disabling

Disable specific agents via permissions:

```json
{
  "permissions": {
    "deny": ["Task(security-auditor)"]
  }
}
```

---

## Automatic Correction Capture

When users correct Claude about project details, facts are automatically captured and stored.

### Detection

Claude watches for correction patterns:
- "no, we use X not Y"
- "actually it's X"
- "remember that..."
- "don't forget..."
- "in this project, we..."

### Storage

Corrections are saved to `## Project Facts` section in CLAUDE.md:

```markdown
## Project Facts

### Tooling
- Uses pnpm, not npm (corrected 2026-01-05)

### Structure
- Tests are in __tests__/ folders (corrected 2026-01-05)

### Conventions
- Always use const, never let (corrected 2026-01-05)
```

### Behavior

- **Auto-capture**: No threshold - corrections are immediately saved
- **Notify**: Brief message "📝 Noted: [fact]"
- **Categorize**: Facts sorted into Tooling/Structure/Conventions/Architecture
- **Consolidate**: Use `/reflect facts` to merge duplicates

### Categories

| Category | Examples |
|----------|----------|
| Tooling | Package managers, build tools, test runners |
| Structure | File locations, directory conventions |
| Conventions | Coding standards, naming patterns |
| Architecture | Design patterns, system decisions |

---

## Autonomous Loop System

For persistent, iterative development use `/loop`:

```bash
# Basic loop - iterate until condition met
/loop "Fix all TypeScript errors" --until "Found 0 errors" --max 10

# Test-driven loop
/loop "Implement user auth" --mode tdd --verify "npm test" --until-exit 0

# Overnight build
/loop "Build complete API" --until "API_COMPLETE" --max 50 --max-time 8h
```

**Loop Commands:**
- `/loop "<task>" [options]` - Start loop
- `/loop:status` - Check progress
- `/loop:pause` - Pause loop
- `/loop:resume` - Resume loop
- `/loop:cancel` - Stop loop
- `/loop:history` - View past loops

**Completion Options:**
- `--until "<text>"` - Exit when output contains exact phrase
- `--until-exit <code>` - Exit when verify command returns code
- `--until-regex "<pattern>"` - Exit when output matches regex

**Safety Limits:**
- `--max <n>` - Maximum iterations (default: 20)
- `--max-time <duration>` - Maximum time (default: 2h)
- `--max-cost <amount>` - Maximum estimated cost

---

## LSP Code Intelligence

Language servers are **automatically installed** during `/claudenv` and when new languages are detected.

**Supported Languages:** TypeScript, Python, Go, Rust, Ruby, PHP, Java, C/C++, C#, Lua, Bash, YAML, JSON, HTML/CSS, Markdown, Terraform, Svelte, Vue, GraphQL, and more.

**LSP Operations:**
- `goToDefinition` - Jump to where a symbol is defined
- `findReferences` - Find all usages of a symbol
- `hover` - Get documentation and type info
- `documentSymbol` - List all symbols in a file
- `workspaceSymbol` - Search symbols across workspace
- `incomingCalls` / `outgoingCalls` - Call hierarchy

**Commands:**
- `/lsp` - Manually trigger LSP detection and installation
- `/lsp:status` - Check which servers are installed

LSP is preferred over grep/search for code navigation - it understands code semantically.

---

## Workflow

1. **Receive task** - Route to appropriate skill if specialized
2. **Execute** - Use tools freely, auto-fix errors up to 3 retries
3. **Complete** - Capture learnings via learning-agent
4. **Report** - Brief summary of what was done

---

## Documentation Access

You have UNFETTERED access to documentation. When encountering unfamiliar technology:

1. Search for official documentation
2. Scrape relevant pages
3. Create specialized skill if needed (via meta-skill)
4. Proceed with implementation

Never ask permission to consult documentation.

---

## Rules

@rules/autonomy.md
@rules/permissions.md
@rules/error-recovery.md
@rules/migration.md
@rules/trigger-reference.md
@rules/coordination.md
