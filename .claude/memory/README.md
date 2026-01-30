# Memory Directory

Simple markdown files for persistent agent memory. No embeddings, no vectors - just files.

## Philosophy

From industry convergence (Anthropic, Cloudflare, Cursor, Vercel):
> "Give agents a file system and get out of the way"

Memory = just files that agents can read, write, and search naturally.

## Structure

```
memory/
├── README.md           # This file
├── decisions.md        # Architectural decisions made
├── patterns.md         # Discovered patterns
├── preferences.md      # User preferences
└── {topic}.md          # Topic-specific knowledge
```

## vs Other Storage

| Storage | Purpose | Format |
|---------|---------|--------|
| `project-context.json` | Tech stack detection | Structured JSON |
| `memory/` | Freeform knowledge | Markdown files |
| `learning/` | Pattern observations | Markdown + proposals |
| `CLAUDE.md` | Project instructions | Markdown |

## Usage

### Reading
```bash
# Find relevant memory
grep -ri "topic" .claude/memory/

# Read specific file
cat .claude/memory/decisions.md
```

### Writing
```bash
# Append to memory file
echo "## Decision: Use PostgreSQL" >> .claude/memory/decisions.md
```

### Searching
```bash
# Find all memory about a topic
grep -l "authentication" .claude/memory/*.md
```

## Best Practices

1. **Keep files focused** - One topic per file
2. **Use clear names** - `auth-decisions.md` not `notes.md`
3. **Date entries** - Add timestamps for context
4. **Link related files** - Reference other memory files when relevant

## Auto-Population

Agents may write to this directory when:
- Making significant architectural decisions
- Discovering project-specific patterns
- Learning user preferences
- Capturing context that shouldn't be forgotten

## Token Efficiency

Memory files are NOT loaded into base context. They are:
- Discovered via search when relevant
- Read on-demand when needed
- Updated incrementally

This keeps the working context small while maintaining persistent knowledge.
