---
description: Audit permissions configuration against detected tech stack and suggest optimizations.
allowed-tools: Bash
---

# /claudenv:audit - Permission Audit

Run `bash .claude/scripts/audit.sh` to analyze permissions vs detected tech stack.

**If error**: Show error message and suggest running `/claudenv` first.

**If no project context** (`hasProjectContext: false`):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  No Project Context
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Run /claudenv to detect your tech stack first.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Format successful output as:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Permission Audit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary:
  Total permissions: {totalPermissions}
  Core (always needed): {corePermissions}
  Tech-specific: {techPermissions}

Detected Stack:
  Languages: {languages}
  Frameworks: {frameworks}
  Package Manager: {packageManager}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Matching Permissions ({count})
   {command} → {reason}
   ...

⚠️  Unused Permissions ({count})
   {command} → No {expectedFile} found
   ...
   Consider removing if not needed.

❌ Missing Permissions ({count})
   {command} → {detectedFile} found
   ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run /claudenv to regenerate permissions
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Only show sections with count > 0. Keep output compact.
