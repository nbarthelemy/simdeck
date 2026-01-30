# Test-Driven Development

> TDD is enforced in this project. Write failing tests before implementation.

## The TDD Cycle

```
CLARIFY → RED → GREEN → REFACTOR
    │      │      │         │
    │      │      │         └── Improve code quality (tests still pass)
    │      │      └── Write minimal code to make test pass
    │      └── Write a failing test first
    └── Interview user until requirements are crystal clear
```

## Mandatory Workflow

**Before writing ANY test or implementation code:**

0. **CLARIFY first** - Interview the user until you have complete clarity:
   - What are ALL the inputs? (types, formats, ranges)
   - What are ALL the outputs? (exact values, formats)
   - What are ALL the edge cases? (boundaries, empty, null)
   - What are ALL the error conditions? (invalid input, failures)
   - What are the acceptance criteria?

   **If you cannot list every test case with confidence, ask more questions.**

1. **Write the test first** - Describe expected behavior in test form
2. **Run the test** - Verify it fails (red)
3. **Write minimal implementation** - Just enough to pass
4. **Run the test** - Verify it passes (green)
5. **Refactor** - Clean up while tests stay green

## Interview Before Testing

When a user requests a feature, **do not start coding**. First ask:

```
I need clarity before writing tests:

1. [Question about inputs]
2. [Question about outputs]
3. [Question about edge cases]
4. [Question about errors]
...
```

Keep asking until you can enumerate ALL test cases.

## File Mapping

| Implementation | Test File |
|----------------|-----------|
| `src/**/*.ts` | `src/**/*.test.ts` OR `tests/**/*.test.ts` |
| `src/**/*.tsx` | `src/**/*.test.tsx` OR `tests/**/*.test.tsx` |
| `app/**/*.ts` | `app/**/*.test.ts` OR `__tests__/**/*.test.ts` |
| `lib/**/*.ts` | `lib/**/*.test.ts` OR `tests/**/*.test.ts` |
| `*.py` | `test_*.py` OR `*_test.py` |
| `*.go` | `*_test.go` |

## Enforcement (Enabled by Default)

A PreToolUse hook blocks writes to implementation files unless:
- A corresponding test file already exists, OR
- You are currently writing a test file

**To add new functionality:**
```
1. Create/edit test file first (e.g., user-service.test.ts)
2. Write failing test
3. Now you can edit implementation (e.g., user-service.ts)
```

## Disable TDD (Use Sparingly)

To disable TDD enforcement for a project:

```bash
touch .claude/tdd-disabled
```

Or in `.claude/settings.local.json`:
```json
{ "tdd": { "enabled": false } }
```

## Auto-Exempt Files

The hook automatically allows non-testable files:
- `*.config.*`, `*.d.ts`, `types.ts`, `constants.ts`
- Files in: `config/`, `types/`, `public/`, `assets/`

## Benefits

- **Confidence**: Tests prove code works
- **Design**: Writing tests first improves API design
- **Documentation**: Tests document expected behavior
- **Refactoring**: Safe to change code with test coverage
