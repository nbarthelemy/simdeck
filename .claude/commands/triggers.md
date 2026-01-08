---
description: "Trigger management: /triggers skills|agents|regenerate"
allowed-tools: Bash
---

# /triggers - Skill/Agent Trigger Management

## Usage

```
/triggers skills       List skill triggers
/triggers agents       List agent triggers
/triggers regenerate   Rebuild trigger reference
```

## Actions

### skills
Run: `bash .claude/scripts/skills-triggers.sh`
Shows all skills with keywords and phrases from `.claude/skills/triggers.json`

### agents
Run: `bash .claude/scripts/agents-triggers.sh`
Shows all agents with keywords, phrases, and file patterns from `.claude/agents/triggers.json`

### regenerate
Run: `bash .claude/scripts/generate-trigger-reference.sh`
Rebuilds `.claude/rules/trigger-reference.md` from triggers.json files
Run after editing trigger configs
