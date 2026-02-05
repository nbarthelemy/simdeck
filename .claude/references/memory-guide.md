# Memory System Guide

Persistent memory with hybrid FTS5 + sqlite-vss search.

## Overview

The memory system captures tool observations, generates searchable summaries, and surfaces relevant context automatically.

**Fully Automatic Operation:**
- **Capture:** PostToolUse hook queues significant operations (instant, non-blocking)
- **Process:** SessionStart processes pending queue before context injection
- **Surface:** Relevant memories auto-injected at session start + contextually during work

No manual `/ce:recall` needed for normal operation.

## Database Location

`.claude/memory/memory.db` - SQLite with FTS5 and optional sqlite-vss

## Commands

```bash
/ce:recall                    # Show status
/ce:recall search <query>     # Search memories
/ce:recall process            # Manually process pending
/ce:recall get <id>           # Get full observation

/ce:memory                    # Show current mode
/ce:memory auto               # Enable automatic surfacing (default)
/ce:memory manual             # Disable automatic, use /ce:do

/ce:do <task>                 # Execute task with memory context
```

## Memory Modes

| Mode | Session Start | During Work | Command |
|------|---------------|-------------|---------|
| Auto (default) | Injects context | Surfaces relevant | Just work normally |
| Manual | No injection | No surfacing | Use `/ce:do <task>` |

**Toggle mode:**
- `touch .claude/.memory-manual` to disable automatic
- `rm .claude/.memory-manual` to re-enable

## Search Modes

| Mode | Flag | Description |
|------|------|-------------|
| Keyword | `--keyword` | FTS5 only (fast, exact matches) |
| Semantic | `--semantic` | sqlite-vss (fuzzy, meaning-based) |
| Hybrid | (default) | Both, merged results |

**Examples:**
```bash
/ce:recall search "auth bug" --keyword
/ce:recall search "user session handling" --semantic
/ce:recall search "authentication" --limit 20
```

## Importance Levels

| Level | Description | Retention |
|-------|-------------|-----------|
| 3 (High) | Architectural decisions, critical fixes | Forever |
| 2 (Medium) | Feature implementations, significant edits | 30 days |
| 1 (Low) | Reads, minor edits, exploration | 7 days |

## Compression Strategy

| Age | Retention | Detail |
|-----|-----------|--------|
| < 24h | All | Full content |
| 1-7d | importance >= 2 | Full content |
| 7-30d | importance >= 2 | Summary only (compressed) |
| > 30d | importance = 3 only | Summary only |

## Summary Generation

When processing observations, Claude generates keyword-rich summaries:

**Format:**
- Start with action verb: Modified, Read, Implemented, Debugged, Created, Fixed
- Include file names and paths
- Include technology/framework terms
- Include domain concepts
- 50-100 words

**Good examples:**
- "Modified user authentication login component React TypeScript. Added password reset form validation error handling JWT token refresh."
- "Debugged API endpoint Node Express. Fixed rate limiting middleware async error handling memory leak."

**Bad examples:**
- "Made some changes to the file" (too vague)
- "Updated code" (no keywords)

## Embedding Generation

Local embeddings via `@xenova/transformers`:
- Model: `all-MiniLM-L6-v2`
- Dimensions: 384
- ~50ms per embedding
- No API key, no network, no cost

Requires: `npm install @xenova/transformers`

## sqlite-vss Setup

**macOS:**
```bash
brew install sqlite-vss
# Extension at: /opt/homebrew/lib/vss0.dylib
```

**Linux:**
```bash
pip install sqlite-vss  # Includes extension
```

**Fallback:** If sqlite-vss is not available, the system uses FTS5 only (keyword search).

## Migration

To migrate existing data:
```bash
bash .claude/scripts/memory-migrate.sh --dry-run  # Preview
bash .claude/scripts/memory-migrate.sh            # Execute
```

Archives original files to `.claude/memory/.archive/YYYY-MM-DD/`

## Scripts

| Script | Purpose |
|--------|---------|
| `memory-init.sh` | Initialize database with schema |
| `memory-status.sh` | Get system status (JSON) |
| `memory-search.sh` | Hybrid search |
| `memory-get.sh` | Get observation by ID |
| `memory-capture.sh` | PostToolUse hook (queues observations) |
| `memory-inject.sh` | Generate context for session start |
| `memory-compress.sh` | Age-based compression |
| `memory-migrate.sh` | Migrate existing data |
| `memory-embed.js` | Generate embeddings |

## Contextual Surfacing

Memory surfaces automatically in these scenarios:

1. **Session Start:** Based on current focus, recent files, active plan
2. **File Operations:** When opening files with history
3. **Error Handling:** When similar errors were seen before
4. **Pattern Detection:** When repeated actions are detected

## Troubleshooting

**Database not initialized:**
```bash
bash .claude/scripts/memory-init.sh
```

**VSS not working:**
```bash
# Check path detection
cat .claude/memory/.vss_path

# Test loading
sqlite3 :memory: ".load /opt/homebrew/lib/vss0.dylib" "SELECT vss_version();"
```

**Embeddings not generating:**
```bash
# Check Node.js can load transformers
node -e "require('@xenova/transformers')"

# Run batch processing
node .claude/scripts/memory-embed.js batch
```

**Database too large:**
```bash
bash .claude/scripts/memory-compress.sh --dry-run  # Preview
bash .claude/scripts/memory-compress.sh            # Execute
```
