---
description: Run comprehensive stack-aware validation (lint, type-check, test, build)
allowed-tools: Read, Bash, Glob
---

# /ce:validate - Stack-Aware Validation

Run comprehensive validation checks appropriate for the project's tech stack. Automatically detects and runs the right commands for linting, type checking, testing, and building.

**Usage:** `/ce:validate [options]`

**Options:**
- `--fix` - Auto-fix linting issues where possible
- `--quick` - Skip slow checks (full test suite, build)
- `--pre-commit` - Run only pre-commit relevant checks

## Process

### 1. Detect Tech Stack

Read `.claude/project-context.json` to determine:
- Languages (TypeScript, Python, Go, Rust, etc.)
- Frameworks (React, FastAPI, etc.)
- Package manager (npm, pnpm, yarn, pip, cargo, etc.)
- Test framework (Jest, pytest, etc.)

If no context file, detect from config files:
```bash
[ -f "package.json" ] && echo "node"
[ -f "pyproject.toml" ] || [ -f "requirements.txt" ] && echo "python"
[ -f "Cargo.toml" ] && echo "rust"
[ -f "go.mod" ] && echo "go"
```

### 2. Run Validation Steps

Execute each validation step sequentially. Stop on critical failures.

#### Step 1: Linting

**Node.js/TypeScript:**
```bash
# ESLint
[ -f "node_modules/.bin/eslint" ] && npx eslint . --ext .ts,.tsx,.js,.jsx

# Biome
[ -f "biome.json" ] && npx biome check .

# With --fix
npx eslint . --fix
```

**Python:**
```bash
# Ruff (preferred)
[ -f "pyproject.toml" ] && grep -q "ruff" pyproject.toml && ruff check .

# With --fix
ruff check . --fix

# Black formatting check
black --check .

# With --fix
black .
```

**Go:**
```bash
go fmt ./...
golangci-lint run
```

**Rust:**
```bash
cargo fmt --check
cargo clippy
```

#### Step 2: Type Checking

**TypeScript:**
```bash
npx tsc --noEmit
```

**Python (with mypy/pyright):**
```bash
# Mypy
[ -f "mypy.ini" ] || grep -q "mypy" pyproject.toml && mypy .

# Pyright
[ -f "pyrightconfig.json" ] && pyright
```

**Go:**
```bash
go vet ./...
```

**Rust:**
```bash
cargo check
```

#### Step 3: Tests

**Node.js:**
```bash
# Jest
[ -f "jest.config.*" ] && npm test

# Vitest
[ -f "vitest.config.*" ] && npm test

# With coverage
npm test -- --coverage
```

**Python:**
```bash
# pytest
pytest -v

# With coverage
pytest --cov=. --cov-report=term-missing
```

**Go:**
```bash
go test ./...

# With coverage
go test -cover ./...
```

**Rust:**
```bash
cargo test
```

#### Step 4: Build

**Node.js:**
```bash
npm run build
```

**Python:**
```bash
# If using build tools
python -m build
```

**Go:**
```bash
go build ./...
```

**Rust:**
```bash
cargo build
```

### 3. Generate Report

After all checks complete:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Validation Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Stack: {detected_stack}

1. Linting
   ✅ ESLint: Passed (0 errors, 2 warnings)
   ✅ Prettier: Formatted

2. Type Check
   ✅ TypeScript: No errors

3. Tests
   ✅ Jest: 47 passed, 0 failed
   📊 Coverage: 82% (target: 80%)

4. Build
   ✅ Build successful
   📦 Output: dist/

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Overall: ✅ PASS (4/4 checks passed)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Or if failures:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔍 Validation Results
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Stack: Python/FastAPI

1. Linting
   ❌ Ruff: 3 errors
      src/api/routes.py:45 - E501 line too long
      src/models/user.py:12 - F401 unused import
      src/services/auth.py:78 - E711 comparison to None

2. Type Check
   ✅ Mypy: No errors

3. Tests
   ❌ pytest: 45 passed, 2 failed
      FAILED tests/test_auth.py::test_login_invalid
      FAILED tests/test_user.py::test_create_duplicate

4. Build
   ⏭️  Skipped (tests failed)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Overall: ❌ FAIL (2/4 checks passed)

Fix with:
  ruff check . --fix  # Auto-fix lint errors
  # Then fix failing tests manually

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Stack Detection Priority

For each check type, use the first available tool:

| Check | Priority Order |
|-------|----------------|
| **Node Lint** | Biome > ESLint > Standard |
| **Node Test** | Vitest > Jest > Mocha |
| **Node Build** | package.json scripts |
| **Python Lint** | Ruff > Flake8 > Pylint |
| **Python Format** | Black > autopep8 > yapf |
| **Python Test** | pytest > unittest |
| **Go Lint** | golangci-lint > go vet |
| **Rust Lint** | clippy |

## Subcommands

### /ce:validate:lint
Run only linting checks.

### /ce:validate:types
Run only type checking.

### /ce:validate:test
Run only test suite.

### /ce:validate:build
Run only build step.

### /ce:validate:coverage
Run tests with coverage report.

## Markers

Output these markers for loop detection:
- `VALIDATION_STARTED`
- `LINT_PASS` / `LINT_FAIL`
- `TYPES_PASS` / `TYPES_FAIL`
- `TESTS_PASS` / `TESTS_FAIL`
- `BUILD_PASS` / `BUILD_FAIL`
- `VALIDATION_PASS` / `VALIDATION_FAIL`

## Integration

After successful validation:
- Ready for `/commit` if all checks pass
- Ready for PR if on feature branch
- Consider `/ce:validate --pre-commit` before committing
