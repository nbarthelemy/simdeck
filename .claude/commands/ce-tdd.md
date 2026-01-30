---
name: /ce:tdd
description: Test-Driven Development workflow
invokes: ce:tdd
---

# /ce:tdd

Test-Driven Development workflow enforcement and guidance.

## Usage

```bash
/ce:tdd                    # Show TDD status
/ce:tdd disable            # Disable TDD enforcement
/ce:tdd enable             # Re-enable TDD enforcement
/ce:tdd <feature>          # Start TDD workflow for feature
```

## Examples

```bash
/ce:tdd                             # Check if TDD is active
/ce:tdd "user authentication"       # Start TDD for auth feature
/ce:tdd disable                     # Turn off enforcement (creates marker)
```

## What It Does

- **status** (default): Shows if TDD is enabled and test coverage
- **disable**: Creates `.claude/tdd-disabled` marker, bypassing PreToolUse hook
- **enable**: Removes disable marker, re-activating enforcement
- **<feature>**: Guides you through red-green-refactor cycle

**Note:** TDD is enabled by default in all claudenv projects.

## TDD Workflow

1. **RED**: Write a failing test first
2. **GREEN**: Write minimal code to pass
3. **REFACTOR**: Clean up while tests stay green
