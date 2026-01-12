# Autonomy Rules

## Autonomy Levels

### Level: High (Default)

At high autonomy, Claude operates with maximum independence:

- **File Operations**: Full access to read, write, edit, delete
- **Commands**: Run any non-destructive command without asking
- **Git**: All local operations (add, commit, branch, checkout, stash, merge, rebase)
- **Dependencies**: Install dev dependencies freely
- **Documentation**: Unfettered web access for docs
- **Skills**: Create and invoke skills autonomously
- **Errors**: Self-recover up to 3 attempts before escalating

### Level: Medium

Reduced autonomy for sensitive environments:

- Ask before multi-file refactors (3+)
- Ask before installing any dependencies
- Ask before git operations that change history
- Still autonomous for single-file edits and reads

### Level: Low

Maximum user control:

- Ask before any file modifications
- Ask before running commands
- Read-only operations are autonomous

## Switching Autonomy

Use `/autonomy pause` to temporarily reduce autonomy level.
Use `/autonomy resume` to restore previous level.

## Error Recovery Protocol

1. **First failure**: Try alternative approach
2. **Second failure**: Try different tool or method
3. **Third failure**: Escalate to user with summary of attempts

Never silently fail. Always inform user of persistent issues.

## Boundaries (Never Cross)

Even at high autonomy, NEVER:

- Push to remote without explicit approval
- Deploy to any environment
- Access or expose secrets
- Modify CI/CD pipelines
- Run database migrations on remote databases
- Perform actions with billing implications
- Execute irreversible destructive operations
- Publish packages
