---
description: "Backup management: /backup create|restore|list"
allowed-tools: Bash
---

# /backup - Infrastructure Backup

## Usage

```
/backup create     Create backup of .claude/
/backup restore    Restore from backup
/backup list       Show available backups
```

## Actions

### create
Run: `bash .claude/scripts/backup-create.sh`
Output: `.claude/backups/backup-{timestamp}.tar.gz`

### restore
Lists backups, prompts for selection
Run: `bash .claude/scripts/backup-restore.sh <backup-file>`

### list
Lists files in `.claude/backups/` with dates and sizes
