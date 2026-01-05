---
description: Resume autonomous actions after a pause.
allowed-tools: Read, Bash(rm:*)
---

# /autonomy:resume - Resume Autonomous Actions

Restore previous autonomy level after a pause.

## Process

1. Check for `.claude/.autonomy-paused` marker
2. Read previous autonomy level
3. Remove marker file
4. Restore autonomy level
5. Confirm with user

## Commands

```bash
# Check for pause marker
if [ -f ".claude/.autonomy-paused" ]; then
  PREVIOUS=$(cat .claude/.autonomy-paused | jq -r '.previousLevel')
  rm .claude/.autonomy-paused
  echo "Restored to: $PREVIOUS"
else
  echo "Autonomy was not paused"
fi
```

## Output

### If Paused

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
▶️  Autonomy Resumed
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Previous level: ask-all
Restored level: high
Was paused for: [duration]

I will now operate with full autonomy:
- File modifications without asking
- Running commands autonomously
- Installing dev dependencies freely

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### If Not Paused

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
ℹ️  Autonomy Status
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Autonomy was not paused.
Current level: high

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
