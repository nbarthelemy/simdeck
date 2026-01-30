---
description: "LSP management: /ce:lsp [install|status]"
allowed-tools: Bash
---

# /ce:lsp - Language Server Management

## Usage

```
/lsp              Auto-detect and install LSP servers
/lsp status       Show installed servers
/lsp install <lang>  Install specific server
```

## Actions

### Install (default)
Run: `bash .claude/scripts/lsp-setup.sh`
Detects languages in project, installs missing servers
Updates `.claude/lsp-config.json`

### Status
Run: `bash .claude/scripts/lsp-status.sh`
Shows installed vs available servers per language

### Install specific
Run: `bash .claude/scripts/lsp-setup.sh install <lang>`
Languages: typescript, python, go, rust, ruby, php, java, etc.

## LSP Operations

Once installed, use the LSP tool:
- `goToDefinition` - Jump to symbol definition
- `findReferences` - Find all usages
- `hover` - Get docs/type info
- `documentSymbol` - List file symbols
