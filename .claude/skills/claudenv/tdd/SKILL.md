---
name: tdd
description: Test-Driven Development workflow guide. Enforces red-green-refactor cycle for reliable code.
triggers:
  - tdd
  - test driven
  - write tests first
  - red green refactor
tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash(npm test *, pnpm test *, yarn test *, pytest *, go test *, vitest *, jest *)
context: same
---

# TDD Skill

Guide test-driven development with strict red-green-refactor workflow.

## Activation

This skill activates when:
- User mentions "TDD", "test driven", "write tests first"
- User wants to add functionality with tests
- `/tdd` command is invoked

## Commands

| Command | Action |
|---------|--------|
| `/ce:tdd` | Show TDD status |
| `/ce:tdd disable` | Disable TDD enforcement for this project |
| `/ce:tdd enable` | Re-enable TDD enforcement |
| `/ce:tdd <feature>` | Start TDD workflow for a feature |

**Note:** TDD is enabled by default. Use `disable` only when necessary.

## Workflow

### Phase 0: CLARIFY (Interview Until Clear)

Before writing ANY test, you MUST have complete clarity. If unclear on ANY of the following, **stop and interview the user**:

**Required Clarity:**
- What is the expected input? (types, formats, ranges, edge cases)
- What is the expected output? (exact format, structure, values)
- What are the error conditions? (invalid input, edge cases, failures)
- What are the business rules? (validation, constraints, logic)
- What are the acceptance criteria? (how do we know it's correct?)

**Interview Pattern:**
```
I need more clarity before I can write comprehensive tests.

1. [Specific question about inputs]
2. [Specific question about outputs]
3. [Specific question about edge cases]
4. [Specific question about error handling]
...
```

**Keep asking until you can write tests that cover:**
- Happy path (normal successful case)
- Edge cases (boundaries, empty, null, max values)
- Error cases (invalid input, failures, exceptions)
- Business rules (all validation and logic)

**Rule: If you cannot articulate ALL test cases with confidence, you don't have enough clarity. Ask more questions.**

### Phase 1: RED (Write Failing Test)

1. **Confirm clarity** - Can you list all test cases? If not, return to Phase 0.
2. **Create test file** - Name it `*.test.ts` or `*.spec.ts`
3. **Write the test**:
   ```typescript
   describe('UserService', () => {
     it('should create a user with valid email', async () => {
       const user = await userService.create({ email: 'test@example.com' });
       expect(user.id).toBeDefined();
       expect(user.email).toBe('test@example.com');
     });
   });
   ```
4. **Run the test** - Verify it FAILS (red)
5. **Confirm failure reason** - Should fail because code doesn't exist yet

### Phase 2: GREEN (Make Test Pass)

1. **Write minimal implementation** - Just enough to pass
2. **No premature optimization** - Simple, obvious code
3. **Run the test** - Verify it PASSES (green)
4. **Commit** - "feat: add user creation (TDD green)"

### Phase 3: REFACTOR (Improve Code)

1. **Look for improvements** - DRY, naming, structure
2. **Make small changes** - One refactor at a time
3. **Run tests after each change** - Must stay green
4. **Commit** - "refactor: extract validation logic"

## TDD Checklist

Before marking a feature complete:

- [ ] Test file exists and is comprehensive
- [ ] Tests cover happy path
- [ ] Tests cover edge cases
- [ ] Tests cover error conditions
- [ ] All tests pass
- [ ] No console.logs or debug code
- [ ] Code is refactored and clean

## TDD is Enabled by Default

The PreToolUse hook automatically enforces TDD in all claudenv projects.

## Disable TDD (Use Sparingly)

For projects where TDD doesn't apply:

```bash
touch .claude/tdd-disabled
```

Or in `.claude/settings.local.json`:

```json
{
  "tdd": {
    "enabled": false
  }
}
```

## Re-enable TDD

```bash
rm .claude/tdd-disabled
```

## Test File Patterns

| Implementation | Test Location |
|----------------|---------------|
| `src/services/user.ts` | `src/services/user.test.ts` |
| `src/services/user.ts` | `tests/services/user.test.ts` |
| `lib/utils.ts` | `lib/utils.test.ts` |
| `app/api/route.ts` | `app/api/route.test.ts` |

## Example Session

```
User: Add a function to validate email addresses

Claude: Starting TDD workflow for email validation.

## Phase 0: CLARIFY

I need more clarity before I can write comprehensive tests.

1. Should we validate the email format only, or also check if the domain exists?
2. What should happen with emails containing plus signs (user+tag@example.com)?
3. Should we support international domains (user@例え.jp)?
4. What's the maximum length we should accept?
5. Should we trim whitespace, or reject emails with leading/trailing spaces?
6. What should the return type be - boolean, or an object with error details?

User: Just format validation, support plus signs, ASCII domains only,
max 254 chars, trim whitespace, return boolean.

Claude: Perfect, now I have clarity. Here are the test cases I'll cover:

**Happy path:**
- Standard email (user@example.com) → true
- Email with plus (user+tag@example.com) → true
- Email with dots in local part (first.last@example.com) → true

**Edge cases:**
- Exactly 254 characters → true
- 255 characters → false
- Leading/trailing whitespace → trimmed, then validated

**Error cases:**
- Empty string → false
- No @ symbol → false
- No domain → false
- No local part → false
- Multiple @ symbols → false
- International domain → false

## Phase 1: RED

Creating test file with comprehensive coverage...

[Creates src/utils/validate-email.test.ts]

```typescript
import { validateEmail } from './validate-email';

describe('validateEmail', () => {
  // Happy path
  it('returns true for standard email', () => {
    expect(validateEmail('user@example.com')).toBe(true);
  });

  it('returns true for email with plus sign', () => {
    expect(validateEmail('user+tag@example.com')).toBe(true);
  });

  it('returns true for email with dots in local part', () => {
    expect(validateEmail('first.last@example.com')).toBe(true);
  });

  // Edge cases
  it('returns true for email at max length (254)', () => {
    const email = 'a'.repeat(243) + '@example.com'; // 254 total
    expect(validateEmail(email)).toBe(true);
  });

  it('returns false for email over max length', () => {
    const email = 'a'.repeat(244) + '@example.com'; // 255 total
    expect(validateEmail(email)).toBe(false);
  });

  it('trims whitespace before validating', () => {
    expect(validateEmail('  user@example.com  ')).toBe(true);
  });

  // Error cases
  it('returns false for empty string', () => {
    expect(validateEmail('')).toBe(false);
  });

  it('returns false for email without @', () => {
    expect(validateEmail('userexample.com')).toBe(false);
  });

  it('returns false for email without domain', () => {
    expect(validateEmail('user@')).toBe(false);
  });

  it('returns false for email without local part', () => {
    expect(validateEmail('@example.com')).toBe(false);
  });

  it('returns false for email with multiple @', () => {
    expect(validateEmail('user@@example.com')).toBe(false);
  });
});
```

Running tests... ❌ FAILED (expected - module doesn't exist yet)

## Phase 2: GREEN

Now implementing the function...

[Creates src/utils/validate-email.ts]

```typescript
const MAX_EMAIL_LENGTH = 254;
const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[a-zA-Z]+$/;

export function validateEmail(email: string): boolean {
  const trimmed = email.trim();
  if (!trimmed || trimmed.length > MAX_EMAIL_LENGTH) return false;
  return EMAIL_REGEX.test(trimmed);
}
```

Running tests... ✅ PASSED

## Phase 3: REFACTOR

Code is clean and readable. No refactoring needed.

✅ TDD cycle complete for validateEmail
```

## Integration with test-engineer Agent

For complex testing scenarios, delegate to test-engineer:

- Coverage analysis
- Test suite optimization
- Flaky test debugging
- E2E test setup

## Anti-Patterns

**Don't:**
- Write implementation first, tests after
- Write tests that test implementation details
- Skip the RED phase (test should fail first)
- Write tests that always pass
- Mock the system under test

**Do:**
- Test behavior, not implementation
- Keep tests independent
- Use descriptive test names
- Test edge cases and errors
- Run tests frequently
