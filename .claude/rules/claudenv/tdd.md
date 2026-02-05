# Test-Driven Development

> Write failing tests before implementation.

## Cycle

```
CLARIFY → RED → GREEN → REFACTOR
```

## Workflow

1. **Clarify** - Interview until all inputs, outputs, edge cases, errors are clear
2. **Red** - Write failing test
3. **Green** - Minimal code to pass
4. **Refactor** - Clean up, tests stay green

## Enforcement

Hook blocks writes to implementation files unless test file exists or you're writing tests.

```
1. Create test file first (e.g., feature.test.ts)
2. Write failing test
3. Now edit implementation (feature.ts)
```

## Disable

```bash
touch .claude/tdd-disabled
```

## Auto-Exempt

`*.config.*`, `*.d.ts`, `types.ts`, `constants.ts`, `config/`, `types/`, `public/`, `assets/`
