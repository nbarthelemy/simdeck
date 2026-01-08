---
description: Bootstrap Claude Code infrastructure for current project. Detects tech stack, generates permissions, migrates CLAUDE.md, and initializes all systems.
allowed-tools: Bash, Write, Edit, Read, Glob, Grep, WebSearch, WebFetch
---

# /claudenv - Infrastructure Bootstrap

You are initializing the Claudenv infrastructure for this project.

## Bootstrap Process

Execute these steps in order. After each step, validate success before proceeding.

### Step 1: Prepare Infrastructure

Run the bootstrap preparation script:

```bash
bash .claude/scripts/bootstrap.sh
```

This creates required directories and initializes learning files.

**Validation**: Verify these exist:
- `.claude/logs/` directory
- `.claude/backups/` directory
- `.claude/learning/` directory
- `.claude/learning/observations.md`

If any are missing, create them.

### Step 2: Detect Tech Stack

Run tech detection:

```bash
bash .claude/scripts/detect-stack.sh
```

Parse the JSON output and extract:
- `packageManager` - npm, yarn, pnpm, pip, cargo, etc.
- `languages` - array of detected languages
- `frameworks` - array of detected frameworks
- `testRunner` - jest, vitest, pytest, etc.
- `database` - prisma, drizzle, mongoose, etc.
- `cloudPlatforms` - aws, gcp, heroku, vercel, etc.
- `confidence` - high, medium, or low

### Step 3: Handle Low Confidence

**IMPORTANT**: If confidence is "low":

1. Inform the user: "Detection confidence is LOW. This usually means the project is new or has minimal configuration."
2. **Automatically run `/interview`** to gather requirements
3. After interview completes, continue with remaining steps

If confidence is "medium" or "high", continue without interview.

### Step 4: Generate project-context.json

Create `.claude/project-context.json` with ALL detected information:

```json
{
  "detected": {
    "languages": ["from detection"],
    "frameworks": ["from detection"],
    "packageManager": "from detection or null",
    "testRunner": "from detection or null",
    "database": "from detection or null",
    "cloudPlatforms": ["from detection"],
    "isMonorepo": false,
    "hasCICD": false,
    "cicdPlatform": null,
    "isContainerized": false,
    "isServerless": false,
    "serverlessPlatform": null,
    "detectionConfidence": "high|medium|low"
  },
  "filePatterns": {
    "source": ["src/**/*", "app/**/*", "lib/**/*"],
    "test": ["**/*.test.*", "**/*.spec.*", "tests/**/*"],
    "config": ["*.config.*", "*.json", "*.yaml", "*.toml"]
  },
  "initializedAt": "ISO_DATE",
  "version": "1.0.0"
}
```

**Validation**: Read back the file and verify it's valid JSON.

### Step 5: Update settings.json Permissions

Based on detected tech stack, add appropriate command permissions.

Read `.claude/skills/tech-detection/command-mappings.json` and merge relevant commands into `.claude/settings.json` allow list.

For example:
- If `npm` detected → ensure npm commands are allowed
- If `prisma` detected → add prisma commands
- If `gcp` detected → add gcloud commands

**Validation**: Verify settings.json is still valid JSON after editing.

### Step 6: Migrate CLAUDE.md

Check for existing CLAUDE.md files:

```bash
find . -maxdepth 2 -name "CLAUDE.md" -o -name "claude.md" 2>/dev/null
```

If found at project root (`./CLAUDE.md`):
1. Read the ENTIRE content
2. Check if `.claude/CLAUDE.md` already has migrated content
3. If not migrated, preserve original in `.claude/CLAUDE.md` following `.claude/rules/migration.md`
4. Create pointer file at root

**Validation**: If migration occurred, verify:
- Original content is preserved in `.claude/CLAUDE.md`
- Line count of new file >= original

### Step 7: Run LSP Setup

Install language servers for detected languages:

```bash
bash .claude/scripts/lsp-setup.sh
```

**Validation**: Check `.claude/lsp-config.json` was created or updated.

### Step 8: MCP Server Setup

Check for referenced MCP servers and install if possible:

```bash
bash .claude/scripts/mcp-setup.sh
```

This will:
- Scan settings.json for `mcp__*` permission patterns
- Install missing MCP servers that can be installed via CLI
- Warn about extension-based MCPs (VS Code, Chrome) that require manual install

**Note**: Extension-based MCPs (ide, claude-in-chrome) cannot be auto-installed.
Inform user if they need to install VS Code extension or Chrome extension.

### Step 9: Create Specialist Agents

Based on detected tech stack, create specialist subagents for orchestration:

1. Check which technologies were detected in Step 2
2. For each technology that benefits from specialized expertise:
   - Check if agent already exists in `.claude/agents/`
   - If not exists, invoke `agent-creator` skill to create it
3. Report created agents

**Tech-to-Agent Mapping:**
| Detected | Agent Created |
|----------|--------------|
| React | `react-specialist` |
| Vue | `vue-specialist` |
| Next.js | `nextjs-specialist` |
| Django | `django-specialist` |
| AWS | `aws-architect` |
| GCP | `gcp-architect` |
| Prisma | `prisma-specialist` |

See `.claude/skills/agent-creator/references/tech-agent-mappings.md` for full mapping.

**Note**: Only create agents for technologies that need deep specialist knowledge.
Generic agents (code-reviewer, security-auditor, etc.) are already included.

### Step 10: Generate Trigger Reference

Generate the trigger reference file that Claude uses to match user requests to skills/agents:

```bash
bash .claude/scripts/generate-trigger-reference.sh
```

**Validation**: Verify `.claude/rules/trigger-reference.md` exists and contains skill/agent trigger mappings.

### Step 11: Final Validation

Run comprehensive validation to ensure everything was created:

```bash
bash .claude/scripts/validate.sh
```

**Required - ALL must pass:**
- ✅ `.claude/settings.json` exists and is valid JSON
- ✅ `.claude/CLAUDE.md` exists
- ✅ `.claude/version.json` exists
- ✅ `.claude/project-context.json` exists and is valid JSON
- ✅ All skills have `SKILL.md` with valid frontmatter
- ✅ All scripts in `.claude/scripts/` are executable

**Required directories:**
- ✅ `.claude/commands/`
- ✅ `.claude/skills/`
- ✅ `.claude/agents/`
- ✅ `.claude/orchestration/`
- ✅ `.claude/scripts/`
- ✅ `.claude/learning/`
- ✅ `.claude/logs/`
- ✅ `.claude/backups/`

**Learning files:**
- ✅ `.claude/learning/observations.md`
- ✅ `.claude/learning/pending-skills.md`
- ✅ `.claude/learning/pending-agents.md`
- ✅ `.claude/learning/pending-commands.md`
- ✅ `.claude/learning/pending-hooks.md`

**Trigger reference:**
- ✅ `.claude/rules/trigger-reference.md` exists

**If ANY validation fails:**
1. Create missing files/directories
2. Fix permissions (`chmod +x` for scripts)
3. Re-run validation until all pass

### Step 12: Report Results

Output a summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Claudenv Initialized
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 Detected Stack:
   Languages: [list]
   Frameworks: [list]
   Package Manager: [name]
   Database/ORM: [name]
   Cloud Platforms: [list]
   Confidence: [HIGH/MEDIUM/LOW]

🔧 Configured:
   ✅ project-context.json created
   ✅ settings.json updated
   ✅ CLAUDE.md [migrated/preserved/created]
   ✅ Learning system initialized
   ✅ LSP servers: [count] installed
   ✅ Agents: [count] created for detected tech

🤖 Available Agents:
   [List of agents in .claude/agents/]

✅ Validation: [X] passed, [Y] warnings, [Z] errors

📚 Available Commands:
   /interview    - Clarify requirements
   /loop         - Autonomous development
   /lsp:status   - Check language servers
   /health:check - Verify integrity

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Error Handling

If any step fails:
1. Log error to `.claude/logs/errors.log` with timestamp
2. Attempt to fix automatically (up to 3 retries)
3. If still failing, report specific error and suggested fix to user

Never report success if validation has errors. Always fix issues first.
