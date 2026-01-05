# Claudenv Framework

> Complete Claude Code infrastructure for autonomous development

## Autonomy Level: High

You have broad autonomy within this project. Act decisively, don't ask for permission on routine tasks.

### Do Without Asking (Full Autonomy)

- Read any file in the project
- Edit/create/delete files in `.claude/` directory
- Edit/create files in source directories to complete tasks
- Run read-only commands (ls, cat, grep, find, git status, git log, etc.)
- Run diagnostics and linters
- Consult external documentation (UNFETTERED access)
- Invoke tools including mcp__ide__getDiagnostics
- Search the web for documentation or solutions
- Delegate to specialist skills
- Create new skills, hooks, and commands
- Run tests
- Install dev dependencies
- Format and lint code
- Git operations: add, commit, branch, checkout, stash
- Run build commands
- Scrape documentation sites
- Create backups before major changes

### Notify After (Inform User)

- Creating new skills (brief notification after creation)
- Modifying project configuration files
- Installing production dependencies
- Significant refactors spanning 5+ files
- Deleting source files (not in .claude/)
- Modifying environment files
- Migrating/merging existing CLAUDE.md files
- Auto-creating skills, hooks, commands at threshold

### Ask First (Requires Approval)

- Pushing to remote repositories
- Deploying to any environment
- Operations involving secrets, API keys, credentials
- Modifying CI/CD pipelines
- Database migrations on non-local databases
- Actions with billing implications
- Irreversible destructive operations outside the project
- Publishing packages

### Error Recovery (Autonomous)

- If a command fails, try alternative approaches
- If a file edit breaks something, fix it
- If tests fail after changes, debug and resolve
- If dependencies conflict, resolve them
- Only escalate to user after 3 failed attempts at resolution

---

## Quick Reference

### Key Commands

| Command | Description |
|---------|-------------|
| `/claudenv` | Bootstrap infrastructure for current project |
| `/interview` | Conduct project specification interview |
| `/loop` | Start autonomous iterative development loop |
| `/loop:status` | Check current loop progress |
| `/loop:pause` | Pause active loop |
| `/loop:resume` | Resume paused loop |
| `/loop:cancel` | Stop and cancel active loop |
| `/lsp` | Auto-detect and install LSP servers |
| `/lsp:status` | Check LSP server status |
| `/claudenv:status` | Show system overview |
| `/health:check` | Verify infrastructure integrity |
| `/learn:review` | Review pending automation proposals |
| `/reflect` | Consolidate learnings, update project knowledge |
| `/analyze-patterns` | Force pattern analysis |

### Skills (Auto-Invoked)

| Skill | Triggers On |
|-------|-------------|
| `tech-detection` | Project analysis, stack detection |
| `project-interview` | Specification interviews, requirements gathering |
| `pattern-observer` | Pattern observation, learning consolidation, automation suggestions |
| `meta-skill` | Creating new skills for unfamiliar tech |
| `skill-creator` | Scaffolding and validating skill directories |
| `frontend-design` | UI, UX, CSS, styling, Tailwind, layout, animation, visual design |
| `autonomous-loop` | Autonomous iterative loops, persistent development |
| `lsp-setup` | Auto-detects and installs language servers |
| `orchestrator` | Complex tasks, parallel execution, "comprehensive", "full review" |
| `agent-creator` | Creates specialist subagents for detected technologies |

### Directory Structure

```
.claude/
├── CLAUDE.md           # Project instructions + @rules/claudenv.md
├── settings.json       # Permissions & hooks
├── SPEC.md             # Project specification (generated)
├── project-context.json # Detected tech stack
├── commands/           # Slash commands
├── skills/             # Auto-invoked capabilities
├── agents/             # Specialist subagents for orchestration
├── orchestration/      # Orchestration config (triggers, limits)
├── rules/              # Modular instruction sets
├── scripts/            # Shell scripts for hooks
├── templates/          # Templates for generation
├── learning/           # Pattern observations
├── loop/               # Autonomous loop state & history
├── lsp-config.json     # Installed LSP servers (generated)
├── logs/               # Execution logs
└── backups/            # Auto-backups
```

---

## Subagent Orchestration

Claude automatically spawns specialist subagents for complex parallel tasks.

### Built-in Agents

| Category | Agents |
|----------|--------|
| **Code** | `frontend-developer`, `backend-architect`, `api-designer`, `devops-engineer` |
| **Analysis** | `code-reviewer`, `security-auditor`, `performance-analyst`, `accessibility-checker` |
| **Process** | `test-engineer`, `documentation-writer`, `release-manager`, `migration-specialist` |

### Trigger Conditions

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
