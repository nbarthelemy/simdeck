---
description: Export Claudenv infrastructure for sharing with other projects or team members.
allowed-tools: Bash(*)
---

# /claudenv:export - Export Infrastructure

Create a sanitized, shareable export of the Claudenv infrastructure.

## Process

1. Create sanitized copy (remove sensitive data)
2. Package as tarball
3. Include README with import instructions
4. Report export location

## What's Exported

**Included:**
- `commands/` - All slash commands
- `skills/` - All skills
- `rules/` - Instruction sets
- `templates/` - Templates
- `scripts/` - Hook scripts
- `settings.json` - Permissions (sanitized)
- `version.json` - Version info

**Excluded:**
- `logs/` - Execution logs
- `backups/` - Backup history
- `settings.local.json` - Local overrides
- `project-context.json` - Project-specific
- `SPEC.md` - Project-specific
- `learning/` - Project-specific patterns

## Commands

```bash
EXPORT_NAME="claudenv-export-$(date +%Y%m%d)"
EXPORT_DIR="/tmp/$EXPORT_NAME"

# Create clean export
mkdir -p "$EXPORT_DIR"
cp -r .claude/commands "$EXPORT_DIR/"
cp -r .claude/skills "$EXPORT_DIR/"
cp -r .claude/rules "$EXPORT_DIR/"
cp -r .claude/templates "$EXPORT_DIR/"
cp -r .claude/scripts "$EXPORT_DIR/"
cp .claude/settings.json "$EXPORT_DIR/"
cp .claude/version.json "$EXPORT_DIR/"
cp .claude/CLAUDE.md "$EXPORT_DIR/"

# Create import instructions
cat > "$EXPORT_DIR/README.md" << 'EOF'
# Claudenv Infrastructure Export

## Import Instructions

1. Extract to your project's `.claude/` directory
2. Run `/claudenv` to initialize for your project
3. Customize as needed

## Contents

- commands/ - Slash commands
- skills/ - Auto-invoked skills
- rules/ - Instruction sets
- templates/ - File templates
- scripts/ - Hook scripts
- settings.json - Base permissions
- CLAUDE.md - Framework instructions

EOF

# Create tarball
tar -czf ".claude-infrastructure-export.tar.gz" -C /tmp "$EXPORT_NAME"
rm -rf "$EXPORT_DIR"
```

## Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📤 Infrastructure Export
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ Export created: .claude-infrastructure-export.tar.gz

Contents:
- [N] commands
- [N] skills
- [N] rules
- [N] templates
- [N] scripts

Size: [X] KB

To import in another project:
  tar -xzf .claude-infrastructure-export.tar.gz -C .claude/
  /claudenv

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
