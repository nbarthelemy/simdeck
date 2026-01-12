---
description: Root Cause Analysis for bugs - investigate, document, and plan fix
allowed-tools: Read, Write, Glob, Grep, Bash, WebFetch
---

# /rca - Root Cause Analysis

Investigate a bug or issue thoroughly before implementing a fix. Creates a documented analysis that feeds into the fix implementation.

**Usage:** `/rca <issue-id-or-description>`

**Examples:**
- `/rca #123` - Analyze GitHub issue #123
- `/rca "Login fails after password reset"` - Analyze described bug

## Process

### Phase 1: Issue Collection

**If GitHub issue ID provided:**
```bash
# Fetch issue details
gh issue view {issue_id} --json title,body,labels,comments,assignees

# Get linked PRs
gh issue view {issue_id} --json closedByPullRequestsReferences
```

**If description provided:**
- Parse the bug description
- Identify symptoms, expected vs actual behavior
- Note any error messages or stack traces

### Phase 2: Codebase Investigation

Search for relevant code:

```bash
# Find files related to the bug area
rg -l "{keywords}" --type-add 'code:*.{ts,tsx,js,jsx,py,go,rs,rb}' -t code

# Find error messages in code
rg "{error_message}" .

# Find related function/class definitions
rg "function {name}|class {name}|def {name}" .
```

Read and analyze:
1. Suspected source files
2. Related test files (why didn't tests catch this?)
3. Recent changes to affected files

```bash
# Recent changes to suspected files
git log --oneline -10 -- {file_path}

# Diff of recent changes
git diff HEAD~10 -- {file_path}

# Who changed this code
git blame {file_path}
```

### Phase 3: Root Cause Identification

Analyze to determine:

1. **What** is failing (specific function, component, flow)
2. **Why** it's failing (logic error, edge case, race condition, etc.)
3. **When** it started (if determinable from git history)
4. **Where** the fix should go (may be different from symptom location)

Common root cause categories:
- Logic error (incorrect conditional, off-by-one)
- Missing error handling
- Race condition / timing issue
- State management bug
- External dependency change
- Configuration issue
- Data validation gap
- Type mismatch

### Phase 4: Impact Assessment

Determine:
- How many users/features are affected?
- Is there a workaround?
- What's the severity? (Critical/High/Medium/Low)
- Are there related bugs that share the root cause?

### Phase 5: Fix Strategy

Design the fix:
1. **Primary fix location** - Where code changes are needed
2. **Alternative approaches** - Other ways to fix, with trade-offs
3. **Risk assessment** - What could go wrong with the fix?
4. **Regression prevention** - Tests to add

### Phase 6: Document Analysis

Create RCA document at `.claude/rca/{issue-id-or-slug}.md`:

```markdown
# RCA: {Issue Title}

> Created: {YYYY-MM-DD HH:MM}
> Issue: #{id} or {description}
> Severity: Critical | High | Medium | Low
> Status: investigating | root_cause_found | fix_planned | resolved

## Issue Summary

**Title:** {title}
**Reporter:** {who} on {when}
**Labels:** {labels}

### Expected Behavior
{what should happen}

### Actual Behavior
{what actually happens}

### Reproduction Steps
1. {step}
2. {step}
3. Observe: {symptom}

### Error Details
```
{error message, stack trace if available}
```

## Investigation

### Files Analyzed
- `path/to/file.ts:45-80` - {what was found}
- `path/to/test.ts` - {why test didn't catch}

### Git History
- {commit_hash} - {relevant change description}
- Introduced: {date} by {author} in {commit}

### Related Issues
- #{related_id} - {connection}

## Root Cause

**Category:** {Logic Error | Edge Case | Race Condition | etc.}

**Explanation:**
{Detailed explanation of why the bug occurs}

**Code Location:**
`path/to/file.ts:67`
```typescript
// The problematic code
```

## Impact Assessment

- **Affected Users:** {scope}
- **Affected Features:** {list}
- **Workaround:** {if any}
- **Data Impact:** {any data corruption?}

## Proposed Fix

### Primary Approach
**File:** `path/to/file.ts`
**Change:** {description}
```typescript
// Proposed code change
```

### Alternative Approaches
1. {Alternative 1} - Trade-off: {trade-off}
2. {Alternative 2} - Trade-off: {trade-off}

### Why This Approach
{Rationale for chosen approach}

## Testing Plan

### New Tests Required
- [ ] Test: {test_description} in `path/to/test.ts`
- [ ] Test: {edge_case_test}

### Existing Tests to Update
- [ ] `path/to/existing.test.ts` - {what to change}

### Validation Commands
```bash
{test_commands}
```

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| {risk} | Low/Med/High | {mitigation} |

## Checklist

- [ ] Root cause identified
- [ ] Fix approach decided
- [ ] Tests planned
- [ ] Ready for implementation
```

## Output

After completing analysis:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Root Cause Analysis Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Issue: {title}
Severity: {severity}

Root Cause: {brief description}
Category: {category}

Location: path/to/file.ts:67

Fix Approach: {brief}
Files to Change: {n}
Tests to Add: {n}

Document: .claude/rca/{slug}.md

Next Steps:
  /feature "Fix: {issue_title}"  # Create implementation plan
  # or
  /execute .claude/rca/{slug}.md  # If RCA includes fix plan

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Subcommands

### /rca:list
List all RCA documents.

### /rca:status
Show status of open RCAs.

### /rca:resolve <slug>
Mark an RCA as resolved.

## Markers

- `RCA_STARTED`
- `ROOT_CAUSE_FOUND`
- `FIX_PLANNED`
- `RCA_COMPLETE`

## Tips

- Don't jump to fixing - understand first
- Check git blame for context on why code was written that way
- Look for similar patterns that might have the same bug
- Consider whether this is a symptom of a larger issue
- Document assumptions and verify them
