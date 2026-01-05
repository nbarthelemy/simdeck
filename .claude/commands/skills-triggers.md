---
description: List all available skills with their trigger keywords and phrases.
allowed-tools: Bash
---

# /skills:triggers - Skill Discovery

1. Run `bash .claude/scripts/skills-triggers.sh` to collect skill data as JSON
2. Format as a skill list:

**If no skills** (`count: 0`):
```
🎯 No skills installed. Run /claudenv to set up infrastructure.
```

**If skills exist**:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🎯 Available Skills ({count})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{for each skill}
**{name}**
  → {description truncated to ~80 chars}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Keep descriptions concise. Skills auto-invoke based on keywords in description.
