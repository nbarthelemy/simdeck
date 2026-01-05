---
description: Debug a specific skill/agent - check configuration, triggers, permissions, and recent invocations.
allowed-tools: Bash
---

# /debug:agent [name] - Debug Skill/Agent

Run `bash .claude/scripts/debug-agent.sh <name>` to analyze the skill/agent.

**If no name provided** (`error: true, message: "Usage..."`):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  Usage: /debug:agent <skill-name>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Example: /debug:agent frontend-design
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If skill not found** (`error: true`):
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
❌ Skill Not Found: {name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Searched: {searchedLocations}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Format successful output as:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Debug: {name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Type: {type}
Location: {location}
Files: {files}

Frontmatter:
  name: {name} {✅ or ❌}
  description: {description} {✅ or ❌}
  allowed-tools: {allowedTools} {✅ or ⚠️}
  model: {model or "default"}

Triggers:
  {trigger phrases from description}

Tool Permissions:
  {tool}: {status ✅/⚠️/❓}
  ...

Recent Activity:
  {log files or "No recent invocations"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Issues: {issueCount} {✅ None / ⚠️ Warnings / ❌ Errors}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

{List any issues if issueCount > 0}
```

Keep output compact. Show ✅ for valid fields, ❌ for missing required, ⚠️ for warnings.
