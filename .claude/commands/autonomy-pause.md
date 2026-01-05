---
description: Temporarily pause autonomous actions. Claude will ask before taking actions.
allowed-tools: Write, Read
---

# /autonomy:pause [duration] - Pause Autonomous Actions

Temporarily reduce autonomy level so Claude asks before taking actions.

## Usage

```
/autonomy:pause [duration]
```

Duration formats:
- `30m` - 30 minutes
- `2h` - 2 hours
- `1d` - 1 day
- (omit) - indefinite until `/autonomy:resume`

## Process

1. Read current autonomy level from settings
2. Create `.claude/.autonomy-paused` marker file
3. Set autonomy to "ask-all" mode
4. Confirm with user

## Marker File

Create `.claude/.autonomy-paused`:

```json
{
  "pausedAt": "[ISO_DATE]",
  "previousLevel": "high",
  "resumeAt": "[ISO_DATE or null]",
  "reason": "user-requested"
}
```

## Behavior When Paused

- Ask before file modifications
- Ask before running commands
- Ask before installing dependencies
- Still allow read-only operations

## Output

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⏸️  Autonomy Paused
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Previous level: high
Current level: ask-all
Duration: [duration or "indefinite"]
Resume at: [time or "manual"]

I will now ask before:
- Modifying files
- Running commands
- Installing dependencies

To resume: /autonomy:resume

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
