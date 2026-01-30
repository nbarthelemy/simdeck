---
description: Force a comprehensive pattern analysis of the project and recent activity. Updates observations and generates new proposals.
allowed-tools: Read, Write, Glob, Grep, Bash(git:*)
---

# /analyze-patterns - Force Pattern Analysis

Trigger a comprehensive analysis of development patterns in the current project.

## Process

### Step 1: Load Context

Read and analyze:
- `.claude/project-context.json` - Tech stack
- `.claude/SPEC.md` - Project specification
- `.claude/learning/working/observations.md` - Existing patterns

### Step 2: Analyze Git History

```bash
# Recent commits
git log --oneline -20

# Files changed recently
git diff --stat HEAD~10

# Frequently modified files
git log --pretty=format: --name-only | sort | uniq -c | sort -rn | head -20
```

### Step 3: Analyze File Patterns

Examine:
- File types and their distribution
- Directory structure patterns
- Config file conventions
- Test file locations
- Import patterns

### Step 4: Identify Gaps

Check for:
- Technologies without dedicated skills
- Repeated manual operations
- Missing automation opportunities
- Undocumented workflows

### Step 5: Generate Recommendations

For each identified pattern:
1. Determine type (skill/command/hook/agent)
2. Assess evidence strength
3. Calculate occurrence count
4. Write to appropriate pending file

### Step 6: Report

Output analysis summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Pattern Analysis Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Project Overview
- Languages: [detected]
- Frameworks: [detected]
- File count: [N]
- Recent activity: [summary]

## Patterns Identified

### New Patterns ([N])
[List of newly identified patterns]

### Updated Patterns ([N])
[Patterns with increased occurrences]

### Ready for Implementation ([N])
[Patterns at or above threshold]

## Recommendations

1. [High priority recommendation]
2. [Medium priority recommendation]
3. [Low priority recommendation]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Run /learn:review for full details
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## When to Use

- Periodically to catch missed patterns
- After significant development milestones
- When onboarding to a new project
- To refresh stale observations
