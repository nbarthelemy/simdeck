---
description: Memory system - search, status, and manual processing
allowed-tools: Bash, Read
---

# /ce:recall - Memory System

Access the persistent memory system for searching past work, checking status, or processing pending observations.

## Usage

```
/ce:recall                    # Show status
/ce:recall search <query>     # Search memories
/ce:recall process            # Process pending observations
/ce:recall get <id>           # Get full observation
```

## Actions

### Status (default)

Run `bash .claude/scripts/memory-status.sh` to get system status.

**Display as:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 Memory System
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Database: {database.size}
Observations: {counts.observations} ({importance.high} high, {importance.medium} medium, {importance.low} low)
Sessions: {counts.sessions}
Embeddings: {counts.embeddings}

Pending: {pending.observations} observations, {pending.embeddings} embeddings
VSS: {vss.available ? "✓ Available" : "✗ Not available"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Search

Run `bash .claude/scripts/memory-search.sh "<query>" [--keyword|--semantic|--hybrid] --limit 10`

**Search modes:**
- `--keyword` - FTS5 only (fast, exact matches)
- `--semantic` - sqlite-vss only (fuzzy, meaning-based) - requires VSS
- `--hybrid` - Both combined (default)

**Display results as:**
```
Found {count} results for "{query}":

1. [{importance}] {summary} ({timestamp})
   Tool: {tool_name} | Files: {files_involved}

2. ...
```

### Process

Process pending observations. This is normally automatic at session start but can be triggered manually.

1. Check pending count: `bash .claude/scripts/memory-status.sh`
2. If pending > 0, read `.claude/memory/.pending-observations.jsonl`
3. For each observation, generate a keyword-rich summary following the memory skill guidelines
4. Insert into database using:
   ```bash
   sqlite3 .claude/memory/memory.db "INSERT INTO observations (session_id, timestamp, tool_name, tool_input, tool_output, files_involved, summary, keywords, importance, created_at) VALUES (...);"
   ```
5. Run `node .claude/scripts/memory-embed.js batch` if VSS is available
6. Clear the pending file

### Get

Run `bash .claude/scripts/memory-get.sh <id>` to retrieve full observation details.

**Display as:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📝 Observation #{id}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Summary: {summary}
Tool: {tool_name}
Timestamp: {timestamp}
Importance: {importance}
Files: {files_involved}

Input:
{tool_input}

Output:
{tool_output}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Automatic Operation

Memory capture and surfacing is fully automatic:

1. **Capture:** PostToolUse hook queues significant operations
2. **Process:** SessionStart processes pending queue
3. **Surface:** Relevant memories injected at session start

This command exists for:
- Manual search when needed
- Debugging/status checking
- Force reprocessing
