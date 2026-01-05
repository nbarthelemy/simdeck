---
description: Restore infrastructure from a previous backup.
allowed-tools: Bash, Read
---

# /backup:restore [id] - Restore From Backup

## List Mode (no ID provided)

Run `bash .claude/scripts/list-backups.sh` to get available backups as JSON.

**If no backups** (`count: 0`):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 No Backups Found
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Create a backup with /backup:create
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Format backup list as:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📦 Available Backups ({count})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. {id}
   Created: {created}
   Files: {fileCount} | Size: {size}
   Type: {type}

2. {id}
   ...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
To restore: /backup:restore <id>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Restore Mode (ID provided)

1. **Verify backup exists**
   ```bash
   BACKUP_DIR=".claude/backups/$ID"
   [ -d "$BACKUP_DIR" ] || echo "Backup not found"
   ```

2. **Show confirmation prompt**
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   🔄 Restore Backup
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ⚠️  This will overwrite current infrastructure.

   Backup: {id}
   Files: {count}

   Proceed with restore?
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```

3. **After user confirms**, create safety backup and restore:
   ```bash
   # Safety backup
   SAFETY=".claude/backups/pre-restore-$(date +%Y%m%d-%H%M%S)"
   mkdir -p "$SAFETY"
   rsync -av --exclude='logs' --exclude='backups' .claude/ "$SAFETY/"

   # Restore
   rsync -av --exclude='logs' --exclude='backups' "$BACKUP_DIR/" .claude/
   ```

4. **Report success**
   ```
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ✅ Restored from {id}
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   Safety backup: {safety_dir}
   Run /health:check to verify.
   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   ```
