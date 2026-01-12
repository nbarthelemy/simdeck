---
description: "Release: version bump, commit, push"
allowed-tools: Read, Write, Edit, Bash
---

# /shipit - Release a New Version

Bump version, commit all changes, and push to remote.

## Usage

```
/shipit "Description of changes"
```

## Process

### 1. Pre-flight Checks

Run these checks first:
```bash
git status
git diff --stat
```

If no changes to commit, stop and inform user.

### 2. Determine Version Bump

Read current version from `dist/version.json` (field: `infrastructureVersion`).

Parse the version (e.g., `2.6.1` → major=2, minor=6, patch=1).

Bump the patch version by 1 (e.g., `2.6.1` → `2.6.2`).

### 3. Update version.json

Edit `dist/version.json`:
- Update `infrastructureVersion` to new version
- Update `lastUpdated` to today's date (format: `YYYY-MM-DDTHH:MM:SSZ`)
- Add new entry to `changelog` object with the user's description

### 4. Update manifest.json

Edit `dist/manifest.json`:
- Update `version` to match new version

### 5. Update README.md Changelog

Add new version entry at the top of the Changelog section:

```markdown
### vX.Y.Z
- **Changed:** {user's description}
```

### 6. Commit

```bash
git add -A
git commit -m "{description} (vX.Y.Z)

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>"
```

### 7. Push

```bash
git push origin main
```

### 8. Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 Shipped v{version}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{description}

Files changed: {n}
Commit: {short-hash}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
