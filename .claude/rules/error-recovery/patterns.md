# Error Patterns

> Load on-demand for unfamiliar errors

## Command Not Found

`which <tool>` → check alt names (python3/python) → suggest install

## Permission Denied

`ls -la` → check dir → check if locked

## Module Not Found

Check venv → `pip list | grep` → install dev dep

## Git Errors

`git branch` → `git status` → `git diff`

## Build Errors

Read full error → check line refs → run linter → check recent changes

## Logging

All errors → `.claude/logs/errors.log` with attempt count and resolution
