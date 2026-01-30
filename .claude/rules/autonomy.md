# Autonomy Rules

> Full details: `.claude/references/autonomy-guide.md`

## Levels

**High (Default):** Full file/command/git access, install dev deps, self-recover 3x

**Medium:** Ask before: multi-file refactors (3+), installing deps, history-changing git ops

**Low:** Ask before any modification; reads are autonomous

## Commands

`/autonomy pause` - reduce level | `/autonomy resume` - restore

