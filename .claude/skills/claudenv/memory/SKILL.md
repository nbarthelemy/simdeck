---
name: memory
description: Process pending observations into searchable memory. Generates keyword-rich summaries for FTS5 and embeddings for semantic search. Auto-invoked at session start.
allowed-tools: Bash, Read
auto_surface: true
---

# Memory Processing Skill

Process pending observations into the memory database with Claude-generated summaries.

## When to Use

- Automatically invoked at session start if pending observations exist
- Called by `/ce:recall process` for manual processing
- Triggered when pending queue exceeds threshold

## Processing Flow

1. Read pending observations from `.claude/memory/.pending-observations.jsonl`
2. For each observation:
   - Generate keyword-rich summary (50-100 words)
   - Extract keywords for boosting
   - Assign importance level
   - Insert into SQLite with FTS5 indexing
3. If sqlite-vss available, generate embeddings via `memory-embed.js batch`
4. Clear processed observations from pending file

## Summary Generation Guidelines

Generate summaries optimized for search, not prose:

**Format:**
- Start with action verb: Modified, Read, Implemented, Debugged, Created, Fixed
- Include file names and paths
- Include technology/framework terms
- Include domain concepts
- 50-100 words

**Examples:**
- "Modified user authentication login component React TypeScript. Added password reset form validation error handling JWT token refresh."
- "Debugged API endpoint Node Express. Fixed rate limiting middleware async error handling memory leak."
- "Created database migration script PostgreSQL. Added user roles table foreign key constraints indexes."

## Importance Levels

- **3 (High):** Architectural decisions, major refactors, critical fixes
- **2 (Medium):** Feature implementations, significant edits, configuration changes
- **1 (Low):** Reads, minor edits, exploration

## Output

Return processing summary:
```
Processed N observations:
- High importance: X
- Medium importance: Y
- Low importance: Z
- Embeddings generated: W (if VSS available)
```
