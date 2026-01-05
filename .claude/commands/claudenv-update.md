---
description: Update Claudenv infrastructure to latest version from GitHub.
allowed-tools: Bash, Read, Write, Edit, WebFetch, Glob
---

# /claudenv:update - Update Infrastructure

## Step 1: Check for Updates

Run `bash .claude/scripts/check-update.sh` to get version comparison as JSON.

**If error**: Show error message and stop.

**If no update** (`updateAvailable: false`):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Claudenv Up to Date (v{current})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
**STOP HERE** - do not proceed with any other steps.

**If update available** (`updateAvailable: true`):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Update Available: v{current} → v{latest}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Changes: {changelog}

This will backup and update framework files.
Your customizations (hooks, permissions, Project Facts) are preserved.

Proceed with update?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 2: Apply Update (after user confirms)

Run `bash .claude/scripts/apply-update.sh` to backup and apply the update.

**If error** (`success: false`):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Update Failed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Error: {error}
Backup: {backupDir}

Run /backup:restore to restore from backup.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If success** (`success: true`):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Updated to v{version}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Files updated: {filesUpdated}
Files removed: {filesDeprecated}
Backup: {backupDir}

Run /health:check to verify.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
