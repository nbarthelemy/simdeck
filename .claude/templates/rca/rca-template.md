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

{What should happen under normal circumstances}

### Actual Behavior

{What actually happens - be specific}

### Reproduction Steps

1. {Step 1}
2. {Step 2}
3. {Step 3}
4. Observe: {The bug symptom}

### Error Details

```
{Error message, stack trace, or console output if available}
```

## Investigation

### Files Analyzed

- `path/to/file.ts:45-80` - {What was found in this section}
- `path/to/related.ts:12-30` - {What was found}
- `path/to/test.ts` - {Why existing tests didn't catch this}

### Git History

```bash
# Relevant commits
{commit_hash} {date} {author} - {message}
```

- **Likely introduced:** {date} by {author} in commit {hash}
- **Related changes:** {description of related commits}

### Related Issues

- #{related_id} - {How it's connected}

## Root Cause

**Category:** Logic Error | Edge Case | Race Condition | Missing Validation | State Bug | Type Error | External Dependency | Configuration

**Explanation:**

{Detailed technical explanation of why the bug occurs. Include:
- What condition triggers the bug
- Why the current code fails
- What the original intent was (if discernible)
}

**Code Location:**

`path/to/file.ts:67`
```typescript
// The problematic code with comments explaining the issue
{code snippet}
```

## Impact Assessment

- **Affected Users:** {All users | Users doing X | Edge case}
- **Affected Features:** {List of features impacted}
- **Frequency:** {Always | Sometimes | Rarely}
- **Workaround Available:** {Yes - describe | No}
- **Data Impact:** {None | Potential corruption - describe}

## Proposed Fix

### Primary Approach

**File:** `path/to/file.ts`
**Lines:** {line range}

**Description:** {What to change and why}

```typescript
// Proposed code change
{fixed code}
```

### Alternative Approaches

1. **{Alternative 1 name}**
   - Description: {What this would do}
   - Trade-off: {Pro/con}
   - Why not: {Reason if not chosen}

2. **{Alternative 2 name}**
   - Description: {What this would do}
   - Trade-off: {Pro/con}

### Why This Approach

{Rationale for the chosen fix approach}

## Testing Plan

### New Tests Required

- [ ] `path/to/test.ts`: Test {specific scenario that triggers the bug}
- [ ] `path/to/test.ts`: Test {edge case}
- [ ] `path/to/test.ts`: Test {regression prevention}

### Existing Tests to Update

- [ ] `path/to/existing.test.ts` - {What needs to change}

### Manual Testing

1. {Manual test step 1}
2. {Manual test step 2}
3. Verify: {Expected outcome}

### Validation Commands

```bash
# Run affected tests
{test command}

# Type check
{type check command}

# Full test suite
{full test command}
```

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| {Risk 1} | Low/Med/High | Low/Med/High | {How to mitigate} |
| {Risk 2} | Low/Med/High | Low/Med/High | {How to mitigate} |

## Checklist

- [ ] Root cause identified and documented
- [ ] Fix approach decided and documented
- [ ] Alternative approaches considered
- [ ] Impact assessment complete
- [ ] Test plan created
- [ ] Risks identified
- [ ] Ready for implementation

## Implementation

{To be filled after fix is implemented}

### Changes Made

- `path/to/file.ts` - {Description of change}

### Tests Added

- `path/to/test.ts` - {Test description}

### Verified By

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing complete
- [ ] Code reviewed

## Post-Mortem (Optional)

### What Went Well

- {Positive aspect of the investigation/fix}

### What Could Be Improved

- {Process improvement suggestion}

### Action Items

- [ ] {Follow-up action to prevent similar bugs}
