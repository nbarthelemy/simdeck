---
description: "Autonomy control: /autonomy pause|resume"
allowed-tools: Bash
---

# /autonomy - Autonomy Level Control

## Usage

```
/autonomy pause    Reduce autonomy, ask before actions
/autonomy resume   Restore full autonomy
```

## Actions

### pause
Creates `.claude/autonomy-paused` marker file
Claude will ask before: file edits, commands, git operations

### resume
Removes marker file
Restores configured autonomy level from rules
