---
description: Execute task with memory context injection
allowed-tools: Bash, Read, Write, Edit, Glob, Grep
---

# /ce:do - Memory-Aware Task Execution

Execute a task with relevant memory context automatically injected.

## Usage

```
/ce:do <task description>
```

## Examples

```
/ce:do fix the authentication bug
/ce:do implement user settings page
/ce:do refactor the API client
/ce:do add validation to the form
```

## How It Works

1. **Search Memory** - Hybrid search (FTS5 + semantic) for relevant observations
2. **Inject Context** - Add top matches to prompt (~2000 tokens max)
3. **Execute Task** - Perform the requested task with context

## When to Use

**In Manual Mode:**
Required to get memory context. Without `/ce:do`, you won't benefit from past observations.

**In Auto Mode:**
Optional but useful for:
- Ensuring specific memory context is loaded
- Searching for patterns related to a specific task
- Getting more focused context than session-start provides

## Process

### 1. Search for Context

Run hybrid memory search based on task description:

```bash
bash .claude/scripts/memory-search.sh "<task>" --hybrid --limit 10
```

### 2. Display Retrieved Context

If results found, show summary:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📚 Memory Context for: <task>
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Found {count} relevant observations:

1. [{importance}] {summary}
   {timestamp} | {tool_name}

2. [{importance}] {summary}
   {timestamp} | {tool_name}

...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If no results: "No relevant memory found. Proceeding without historical context."

### 3. Execute Task

With the memory context now in your working context, proceed to execute the user's task.

**Key behaviors:**
- Use retrieved observations to inform your approach
- Reference past patterns when making decisions
- Avoid repeating past mistakes mentioned in memory
- Build on successful approaches from history

## Context Budget

Maximum ~2000 tokens for memory context:
- Up to 10 observations (summaries only)
- Prioritized by relevance score
- High importance observations weighted higher

## Notes

- Works in both auto and manual mode
- In auto mode, supplements session-start context
- Task description becomes the search query
- Semantic search handles fuzzy matching ("auth issue" finds "authentication bug")
