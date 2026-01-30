---
description: Load comprehensive project context for informed development
allowed-tools: Read, Glob, Grep, Bash
---

# /ce:prime - Project Context Loading

Build comprehensive understanding of the codebase before starting work. This command primes Claude with full project context.

**Auto-run:** This command runs automatically at session start (once per session).

## Process

### 1. Analyze Project Structure

```bash
# List tracked files
git ls-files 2>/dev/null | head -100

# Show directory structure (exclude noise)
tree -L 3 -I 'node_modules|__pycache__|.git|dist|build|.next|coverage|.pytest_cache|venv|.venv|target' 2>/dev/null || find . -type d -maxdepth 3 | grep -v -E 'node_modules|__pycache__|\.git|dist|build' | head -50
```

### 2. Read Core Documentation

Read these files (silently, don't output contents):

1. `.claude/CLAUDE.md` - Project instructions
2. `.claude/SPEC.md` - Project specification (if exists)
3. `.claude/project-context.json` - Detected tech stack
4. `README.md` - Project overview
5. Any `ARCHITECTURE.md`, `CONTRIBUTING.md`, or `docs/` index

### 3. Read Reference Materials

If `.claude/references/` exists, read all files in that directory. These contain curated best practices for the project's tech stack.

### 4. Identify Key Files

Based on detected tech stack, identify and skim:

**Entry Points:**
- `main.py`, `app.py`, `index.ts`, `main.ts`, `main.go`, `lib.rs`
- `src/index.*`, `src/main.*`, `src/app.*`

**Configuration:**
- `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`
- `tsconfig.json`, `vite.config.*`, `next.config.*`
- `.env.example`, `config/`

**Key Abstractions:**
- Core models/schemas
- Main routes/controllers
- Service layer entry points

### 5. Understand Current State

```bash
# Recent activity
git log --oneline -10

# Current status
git status --short

# Recent changes
git diff --stat HEAD~5 2>/dev/null || echo "Not enough history"

# Active branches
git branch -a 2>/dev/null | head -10
```

### 6. Check for Active Work

```bash
# Check TODO.md for in-progress items
[ -f .claude/TODO.md ] && grep -E '^\s*-\s*\[~\]' .claude/TODO.md

# Check for existing plans
[ -d .claude/plans ] && ls -la .claude/plans/ 2>/dev/null
```

## Output Report

After gathering context, output a brief report:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 Project Context Loaded
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Project: {name}
Purpose: {one-line description}

Tech Stack:
  {language} | {framework} | {database}

Architecture: {brief pattern description}

Key Files:
  - {entry_point} - Main entry
  - {config} - Configuration
  - {core_module} - Core logic

Current State:
  Branch: {branch}
  Recent: {last_commit_summary}
  Status: {clean/uncommitted changes}

Active Work:
  - {in_progress_item or "None"}

Reference Docs: {count} files in .claude/references/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Keep the report concise - under 25 lines. The goal is awareness, not exhaustive detail.

## Markers

Output `CONTEXT_LOADED` at the end for loop detection.

## Notes

- Don't output file contents directly - summarize key insights
- Focus on understanding patterns and conventions
- Note anything unusual or non-standard
- If SPEC.md is missing, suggest running `/interview`
- If reference docs are missing, note which could be helpful
