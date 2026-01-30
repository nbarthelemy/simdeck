---
name: tool-search
description: Discover available tools on-demand. Triggers: what tools, find tool, available MCP, tool for, capability search.
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash(*)
---

# Tool Search Skill

Discover and describe available tools without loading them all into context.

## Purpose

Instead of loading all MCP tools and skills into base context (which burns tokens), this skill discovers them on-demand when you need a specific capability.

## When to Activate

- "What tools do I have for X?"
- "Find a tool that can Y"
- "What MCP servers are available?"
- "Is there a capability for Z?"
- "Tool for database/api/file operations"

## Discovery Process

### 1. Search Skills

```bash
# Find all available skills
find .claude/skills -name "SKILL.md" -exec grep -l "" {} \;

# Search skill descriptions for capability
grep -r "description:" .claude/skills/*/SKILL.md | grep -i "<keyword>"
```

### 2. Search MCP Servers

```bash
# Check configured MCP servers
cat ~/.claude/settings.json 2>/dev/null | grep -A5 "mcpServers" || echo "No global MCP config"

# Check project MCP config
cat .claude/settings.json 2>/dev/null | grep -A5 "mcpServers" || echo "No project MCP config"
```

### 3. Search Agents

```bash
# List available agents
ls .claude/agents/*.md 2>/dev/null

# Search agent descriptions
grep -l "<capability>" .claude/agents/*.md
```

### 4. List Built-in Tools

Always available:
- `Read` - Read files
- `Write` - Create/overwrite files
- `Edit` - Modify files
- `Glob` - Find files by pattern
- `Grep` - Search file contents
- `Bash` - Execute commands
- `WebSearch` - Search the web
- `WebFetch` - Fetch URL content
- `Task` - Spawn subagents
- `LSP` - Code intelligence (if configured)

## Output Format

When searching for a capability, return:

```markdown
## Available Tools for [Capability]

### Built-in
- **Tool Name**: Brief description

### Skills
- **skill-name**: Description (location: .claude/skills/...)

### MCP Servers
- **server-name**: Description (if configured)

### Agents
- **agent-name**: Description (for complex tasks)
```

## Progressive Disclosure Pattern

This skill implements progressive disclosure:

1. **Discovery** (this skill): Find what's available
2. **Loading**: Read full skill/agent file when needed
3. **Execution**: Use the loaded capability

Token savings: ~85% vs loading all tool schemas upfront

## Integration with Orchestrator

When orchestrator needs to find capabilities:
1. Invoke tool-search for discovery
2. Load only matched skills/agents
3. Execute with minimal context

## Example

**User**: "I need to deploy to Cloud Run"

**Search**:
```bash
grep -ri "cloud run\|gcp\|deploy" .claude/skills/*/SKILL.md .claude/agents/*.md
```

**Result**:
- Skill: `cloud-run-deploy` at `.claude/skills/.../cloud-run-deploy/SKILL.md`
- Agent: `devops-engineer` for complex deployments

**Action**: Load cloud-run-deploy skill, proceed with deployment
