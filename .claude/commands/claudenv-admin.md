---
description: "Claudenv admin: status|update|audit|export|import|mcp"
allowed-tools: Bash, Read, Write, Edit, WebFetch, Glob
---

# /claudenv Admin Commands

## Usage

```
/claudenv status         Show infrastructure overview
/claudenv update         Check/apply updates
/claudenv audit          Audit permissions vs tech stack
/claudenv export         Export for sharing
/claudenv import <path>  Import from export
/claudenv mcp [action]   Manage MCP servers
```

## Actions

### status
Run: `bash .claude/scripts/claudenv-status.sh`
Display: version, detected stack, skill/agent/command counts, hooks, proposals

### update
Run: `bash .claude/scripts/check-update.sh`
If update available: `bash .claude/scripts/apply-update.sh`
Show changelog and confirm before applying

### audit
Run: `bash .claude/scripts/audit.sh`
Compare settings.json permissions against detected tech stack
Suggest additions/removals

### export
Create tarball: `.claude-export-{date}.tar.gz`
Include: commands, skills, agents, rules (exclude: logs, backups, secrets)
Output path to exported file

### import
Args: path to `.tar.gz` or `.claude/` directory
Backup current infrastructure first
Extract/copy and merge with existing config

### mcp
- `mcp` or `mcp list` - Show installed/referenced MCP servers
- `mcp install <name>` - Install specific MCP server

Run: `bash .claude/scripts/mcp-setup.sh [action] [name]`
