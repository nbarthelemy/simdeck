---
description: Create a manual backup of the .claude/ infrastructure directory.
allowed-tools: Bash(*)
---

# /backup:create [name] - Create Infrastructure Backup

Create a timestamped backup of the current `.claude/` infrastructure.

## Usage

```
/backup:create [optional-name]
```

Examples:
- `/backup:create` → `backup-20260103-143022/`
- `/backup:create pre-refactor` → `pre-refactor-20260103-143022/`

## Process

1. Create backup directory: `.claude/backups/[name]-[timestamp]/`
2. Copy all `.claude/` contents except:
   - `logs/`
   - `backups/`
   - `settings.local.json`
3. Record in backup manifest
4. Confirm with details

## Commands

```bash
# Create backup directory
BACKUP_NAME="${1:-backup}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR=".claude/backups/${BACKUP_NAME}-${TIMESTAMP}"

mkdir -p "$BACKUP_DIR"

# Copy infrastructure (excluding logs, backups, local settings)
rsync -av --exclude='logs' --exclude='backups' --exclude='settings.local.json' \
  .claude/ "$BACKUP_DIR/"

# Record manifest
echo "{
  \"name\": \"${BACKUP_NAME}\",
  \"timestamp\": \"$(date -Iseconds)\",
  \"files\": $(find "$BACKUP_DIR" -type f | wc -l)
}" > "$BACKUP_DIR/manifest.json"
```

## Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💾 Backup Created
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📁 Location: .claude/backups/[name]-[timestamp]/
📊 Files: [N] files backed up
📏 Size: [X] KB

To restore: /backup:restore [name]-[timestamp]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
