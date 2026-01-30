# Permission Matrix

> Full details: `.claude/references/permissions-guide.md`

## Bash Wildcards

`Bash(npm *)` - npm + anything | `Bash(* --help)` - any cmd + --help

## Git Hook Enforcement

**NEVER bypass git hooks.** When a pre-commit hook fails:
1. Read the error message
2. Fix the underlying issue (lint, format, types, tests)
3. Stage the fixes
4. Commit again WITHOUT `--no-verify`

The `--no-verify` flag is blocked by a PreToolUse hook. Fix issues, don't bypass them.

## Tech-Specific

Auto-added during `/ce:init` based on detected stack. See `command-mappings.json`.

## Override

In `.claude/settings.local.json`:
```json
{"permissions": {"allow": ["Bash(custom *)"], "deny": ["Bash(npm publish *)"]}}
```
