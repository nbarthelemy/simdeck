---
name: lsp:status
description: Show installed and available LSP servers
allowed-tools: Bash
---

# /lsp:status - LSP Server Status

1. Run `bash .claude/scripts/lsp-status.sh` to collect LSP data as JSON
2. Format as status display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔧 LSP Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Languages detected:
  {language}: {count} files {server installed ? "✅" : "❌"}

Servers:
  typescript-language-server: {✅ installed / ❌ missing}
  pyright: {✅ installed / ❌ missing}
  gopls: {✅ installed / ❌ missing}
  rust-analyzer: {✅ installed / ❌ missing}

Config: {configExists ? "✅ Found" : "⚠️ Not configured"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Only show languages with count > 0. Run `/lsp` to install missing servers.
