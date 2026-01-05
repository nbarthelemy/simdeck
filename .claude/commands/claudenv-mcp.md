---
description: Manage MCP servers - detect, install, and configure referenced MCP servers.
allowed-tools: Bash, Read, Write, Edit
---

# /claudenv:mcp - MCP Server Management

Detect and install MCP servers referenced in your project's settings.

## Usage

```bash
/claudenv:mcp              # Auto-detect and install missing MCPs
/claudenv:mcp list         # List installed and referenced MCPs
/claudenv:mcp install <name>  # Install a specific MCP server
```

## Process

### Step 1: Detect Referenced MCPs

Scan `.claude/settings.json` for MCP permission patterns:
- `mcp__filesystem__*` → filesystem server
- `mcp__github__*` → GitHub server
- `mcp__ide__*` → VS Code extension (not installable)
- `mcp__claude-in-chrome__*` → Chrome extension (not installable)

### Step 2: Check Installation Status

```bash
claude mcp list
```

### Step 3: Install Missing MCPs

Run the MCP setup script:

```bash
bash .claude/scripts/mcp-setup.sh
```

## Available MCP Servers

### Installable via CLI

| Server | Description | Install Command |
|--------|-------------|-----------------|
| `filesystem` | File system access | `claude mcp add filesystem -s user -- npx -y @anthropic/mcp-filesystem ~` |
| `github` | GitHub API access | `claude mcp add github -s user -- npx -y @anthropic/mcp-github` |
| `postgres` | PostgreSQL access | `claude mcp add postgres -s user -- npx -y @anthropic/mcp-postgres` |
| `sqlite` | SQLite access | `claude mcp add sqlite -s user -- npx -y @anthropic/mcp-sqlite` |
| `puppeteer` | Browser automation | `claude mcp add puppeteer -s user -- npx -y @anthropic/mcp-puppeteer` |
| `memory` | Persistent memory | `claude mcp add memory -s user -- npx -y @anthropic/mcp-memory` |
| `fetch` | HTTP requests | `claude mcp add fetch -s user -- npx -y @anthropic/mcp-fetch` |
| `slack` | Slack integration | `claude mcp add slack -s user -- npx -y @anthropic/mcp-slack` |

### Extension-Based (Manual Install)

| Server | Source | Install |
|--------|--------|---------|
| `ide` | VS Code | Install "Claude Code" extension |
| `claude-in-chrome` | Chrome | Install from https://claude.ai/chrome |

## Adding MCP Permissions

When adding a new MCP server, also add permissions to `.claude/settings.json`:

```json
{
  "permissions": {
    "allow": [
      "mcp__filesystem__*",
      "mcp__github__*"
    ]
  }
}
```

## Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔌 MCP Server Setup
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Found MCP references: filesystem, github, ide

✓ filesystem already installed
✓ github installed
⚠ mcp__ide__* is provided by VS Code extension

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Installed: 1 | Already present: 1 | Extension-based: 1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
