---
description: "Learning system: /learn review|implement"
allowed-tools: Bash, Read, Write
---

# /learn - Pattern Learning System

## Usage

```
/learn review              Show pending proposals
/learn implement <type> <name>  Implement a proposal
```

## Actions

### review
Run: `bash .claude/scripts/learn-review.sh`
Shows pending: skills, agents, commands, hooks
Each with occurrence count and source patterns

### implement
Args: type (skill|agent|command|hook), name
Creates the proposed item using appropriate creator skill
Updates learning files to mark as implemented
