---
description: Import Claudenv infrastructure from another project or export file.
allowed-tools: Bash(*), Read, Write
---

# /claudenv:import [path] - Import Infrastructure

Import infrastructure from an export file or another project.

## Usage

```
/claudenv:import [path-to-export.tar.gz]
/claudenv:import [path-to-.claude-directory]
```

## Process

1. Validate import source
2. Create backup of current infrastructure
3. Show diff/changes
4. Confirm merge strategy with user
5. Import with selected strategy
6. Re-run tech stack detection
7. Update settings for current project
8. Report results

## Merge Strategies

### Replace (Default for fresh projects)
- Completely replace current `.claude/`
- Use when: Starting fresh or updating from template

### Merge (Default for existing projects)
- Keep project-specific files
- Update shared infrastructure
- Use when: Updating framework version

### Selective
- Choose which components to import
- Use when: Picking specific features

## Commands

```bash
IMPORT_SOURCE="$1"

# Backup current
BACKUP_DIR=".claude/backups/pre-import-$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r .claude/* "$BACKUP_DIR/" 2>/dev/null

# Extract if tarball
if [[ "$IMPORT_SOURCE" == *.tar.gz ]]; then
  tar -xzf "$IMPORT_SOURCE" -C .claude/
elif [ -d "$IMPORT_SOURCE" ]; then
  cp -r "$IMPORT_SOURCE"/* .claude/
fi
```

## Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📥 Infrastructure Import
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Source: [path]
Backup: [backup location]

## Changes Detected

New files:
+ commands/new-command.md
+ skills/new-skill/SKILL.md

Modified files:
~ settings.json
~ CLAUDE.md

Unchanged:
= [N] files

## Strategy

Choose merge strategy:
1. Replace - Full replacement
2. Merge - Update shared, keep project-specific
3. Selective - Choose components

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### After Import

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Import Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Imported:
- [N] commands
- [N] skills
- [N] rules

Updated settings for current project's tech stack.

Run /health:check to verify integrity.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
