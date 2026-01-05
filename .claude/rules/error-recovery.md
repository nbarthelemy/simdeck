# Error Recovery Guidelines

## Recovery Protocol

When an error occurs, follow this escalation path:

### Attempt 1: Alternative Approach

- Try a different command that achieves the same goal
- Use a different tool if available
- Check for typos or syntax errors

### Attempt 2: Different Method

- Research the error message
- Check documentation for the correct approach
- Try a workaround

### Attempt 3: Diagnostic Deep-Dive

- Run diagnostic commands to understand the environment
- Check versions, dependencies, configuration
- Look for related issues in logs

### Escalation (After 3 Failures)

If all attempts fail:

1. **Summarize** what you tried
2. **Explain** what you learned from each attempt
3. **Suggest** possible solutions user could try
4. **Ask** for guidance

## Common Error Patterns

### Command Not Found

1. Check if tool is installed: `which <tool>` or `type <tool>`
2. Check alternative names: `python3` vs `python`, `pip3` vs `pip`
3. Suggest installation if missing

### Permission Denied

1. Check file permissions: `ls -la <file>`
2. Check if running in correct directory
3. Check if file is locked by another process

### Module/Package Not Found

1. Check if in correct virtual environment
2. Check if package is installed: `pip list | grep <package>`
3. Try installing: `pip install <package>` (dev deps only)

### Git Errors

1. Check current branch: `git branch`
2. Check for uncommitted changes: `git status`
3. Check for conflicts: `git diff`

### Build/Compile Errors

1. Read the full error message
2. Check line numbers and file references
3. Run linter/type-checker for more context
4. Check recent changes that might have caused the issue

## Self-Healing Actions

These actions can be taken autonomously to recover:

- **Fix linting errors**: Run formatter, fix imports
- **Fix type errors**: Add type annotations, fix mismatches
- **Fix test failures**: Debug and update tests or code
- **Resolve conflicts**: Attempt automatic merge resolution
- **Install missing deps**: For dev dependencies only
- **Create missing files**: If referenced but missing
- **Fix permissions**: chmod for scripts that need to be executable

## Logging Errors

All errors should be logged to `.claude/logs/errors.log`:

```
[TIMESTAMP] ERROR in <context>
Command: <command>
Output: <output>
Attempt: <1|2|3>
Resolution: <what was tried>
Status: <resolved|escalated>
```
