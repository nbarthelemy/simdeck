---
name: lsp
description: Auto-detect and install LSP servers for the project
arguments:
  - name: action
    description: Optional action (install, remove, update)
    required: false
---

# LSP Setup

Automatically detect project languages and install appropriate LSP servers.

## Process

### Step 1: Detect Languages

Analyze the project for languages in use:

```bash
# Run the LSP detection script
bash .claude/scripts/lsp-setup.sh detect
```

Or manually scan:

```bash
# Find all unique file extensions
find . -type f -name "*.*" \
  ! -path "./node_modules/*" \
  ! -path "./.git/*" \
  ! -path "./vendor/*" \
  ! -path "./venv/*" \
  ! -path "./.venv/*" \
  ! -path "./target/*" \
  ! -path "./build/*" \
  ! -path "./dist/*" \
  | sed 's/.*\.//' | sort | uniq -c | sort -rn
```

### Step 2: Map to LSP Servers

Read `.claude/skills/lsp-agent/lsp-mappings.json` and determine required servers.

For each detected language:
1. Look up in `extension_to_language` mapping
2. Find matching server in `servers`
3. Check if priority 1 server is available

### Step 3: Check Installation Status

```bash
# Run the LSP setup script with status check
bash .claude/scripts/lsp-setup.sh status
```

Display table of required vs installed:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 LSP Server Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Language        Server                    Status
──────────────────────────────────────────────────────────
TypeScript      typescript-language-server  ✅ Installed
Python          pyright                     ❌ Missing
Go              gopls                       ✅ Installed
Rust            rust-analyzer               ⚠️  Outdated

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 4: Install Missing Servers

For each missing server:

1. Determine best installation method based on available package managers:
   - npm/pnpm/yarn for JS tools
   - pip for Python tools
   - go install for Go tools
   - brew for macOS
   - cargo for Rust tools
   - gem for Ruby tools

2. Run installation:
   ```bash
   bash .claude/scripts/lsp-setup.sh install <server-name>
   ```

3. Verify installation:
   ```bash
   <command> --version
   ```

### Step 5: Update Configuration

Write to `.claude/lsp-config.json`:

```json
{
  "detected_languages": ["typescript", "python", "go"],
  "servers": {
    "typescript-language-server": {
      "installed": true,
      "version": "4.3.0",
      "command": "typescript-language-server",
      "args": ["--stdio"]
    },
    "pyright": {
      "installed": true,
      "version": "1.1.350",
      "command": "pyright-langserver",
      "args": ["--stdio"]
    }
  },
  "last_setup": "2026-01-03T15:00:00Z"
}
```

### Step 6: Report Results

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ LSP SETUP COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Languages detected: 5
🔧 Servers installed: 3 new, 2 existing
⏱️ Setup time: 45s

Installed:
  ✓ pyright (Python)
  ✓ rust-analyzer (Rust)
  ✓ bash-language-server (Shell)

Already available:
  ✓ typescript-language-server (TypeScript)
  ✓ gopls (Go)

LSP is now active. Use:
  - Go to definition: LSP goToDefinition
  - Find references: LSP findReferences
  - Hover for docs: LSP hover
  - List symbols: LSP documentSymbol

Check status anytime: /lsp:status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Manual Installation

To install a specific server:

```bash
/lsp install typescript-language-server
/lsp install pyright
/lsp install gopls
```

## Troubleshooting

If a server fails to install:

1. Check if required package manager is available
2. Try alternative installation method from mappings
3. Check network connectivity
4. Run with verbose output:
   ```bash
   bash .claude/scripts/lsp-setup.sh install <server> --verbose
   ```
