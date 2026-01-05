# Output Patterns

## Template Pattern

For consistent output format:

**Strict (API responses, data formats):**
```markdown
## Report Structure

ALWAYS use this exact template:

# [Title]

## Executive Summary
[One paragraph overview]

## Key Findings
- Finding 1
- Finding 2

## Recommendations
1. Action item
2. Action item
```

**Flexible (when adaptation useful):**
```markdown
## Report Structure

Sensible default format, adapt as needed:

# [Title]
## Summary
## Findings
## Recommendations
```

## Examples Pattern

Show input/output pairs:

```markdown
## Commit Messages

**Example 1:**
Input: Added user authentication
Output:
```
feat(auth): implement JWT authentication

Add login endpoint and token middleware
```

**Example 2:**
Input: Fixed date display bug
Output:
```
fix(reports): correct date timezone handling
```
```

Examples communicate style better than descriptions.
