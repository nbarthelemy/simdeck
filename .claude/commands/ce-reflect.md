---
description: Analyze session and consolidate learnings. Use after significant work to improve project knowledge. Triggers on "reflect", "consolidate learnings", "what did we learn".
allowed-tools: Read, Write, Edit, Glob, Grep
---

# /reflect - Session Reflection & Knowledge Consolidation

Analyze the current session and consolidate learnings into project knowledge.

## Modes

- `/reflect` - Quick reflection on current session
- `/reflect deep` - Comprehensive review of all learning files
- `/reflect prune` - Remove stale/obsolete entries
- `/reflect facts` - Review and consolidate Project Facts in CLAUDE.md
- `/reflect evolve` - Analyze failures and propose system improvements

## Core Philosophy

> "Merge over add — consolidate, don't accumulate"
> "Specific over vague — skip insights that aren't actionable"
> "Accurate over comprehensive — wrong info is worse than missing"

## Process

### Step 1: Gather Context

Read these files to understand current state:

```
.claude/learning/working/observations.md
.claude/learning/working/pending-skills.md
.claude/learning/working/pending-commands.md
.claude/learning/working/pending-hooks.md
.claude/project-context.json
.claude/CLAUDE.md
```

### Step 2: Analyze Session

Review the current conversation for:

1. **New Patterns** - Repeated actions, workflows, file operations
2. **Refined Understanding** - Better ways to do existing things
3. **Obsolete Knowledge** - Things that are no longer true
4. **User Preferences** - Explicit or implicit preferences revealed
5. **Common Issues** - Problems encountered and solutions found
6. **Architecture Insights** - Understanding of codebase structure

### Step 3: Categorize Changes

For each insight, determine the operation:

| Operation | When to Use | Example |
|-----------|-------------|---------|
| **MERGE** | Similar entry exists, combine them | Two Prisma patterns → one comprehensive entry |
| **REPLACE** | Entry exists but is outdated/wrong | Old test command → new test command |
| **ADD** | Genuinely new topic | First time using a new tool |
| **DELETE** | Entry is obsolete or wrong | Removed feature, deprecated pattern |
| **SKIP** | Already captured or not actionable | Vague insight, duplicate |

**Priority:** MERGE > REPLACE > DELETE > ADD > SKIP

### Step 4: Propose Changes

Present changes grouped by file and operation:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🔄 Session Reflection
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Proposed Changes

### observations.md

**MERGE** Pattern: TypeScript error handling
  Existing: "Uses try-catch in API routes"
  New insight: "Also uses error boundaries in React components"
  → Combined: "Error handling: try-catch in API routes, error boundaries in React"

**DELETE** Pattern: Old build command
  Reason: Project migrated from webpack to vite

**SKIP** Pattern: Uses git for version control
  Reason: Too generic, not actionable

### CLAUDE.md

**ADD** Section: Common Issues
  Content: "Hot reload fails after dependency changes - restart dev server"

### pending-skills.md

**REPLACE** Skill: api-client
  Was: 3 occurrences, basic fetch patterns
  Now: 5 occurrences, includes error handling and retry logic

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Apply these changes? (Requires confirmation)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Step 5: Apply Changes (After Confirmation)

Only after user confirms:

1. Apply MERGE operations (combine entries)
2. Apply REPLACE operations (update entries)
3. Apply DELETE operations (remove entries)
4. Apply ADD operations (new entries)
5. Update timestamps and metadata

### Step 6: Report Results

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Reflection Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Changes applied:
  MERGE: 3 entries consolidated
  REPLACE: 1 entry updated
  DELETE: 2 entries removed
  ADD: 1 new entry

Files updated:
  ✅ observations.md (was 47 entries → now 43)
  ✅ CLAUDE.md (added Common Issues section)
  ✅ pending-skills.md (1 skill updated)

Knowledge quality: Improved (less redundancy, more accurate)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Deep Reflection Mode

When `/reflect deep` is invoked:

1. Review ALL entries in observations.md (not just recent)
2. Cross-reference with project-context.json for accuracy
3. Check for contradictions between files
4. Identify patterns that should become skills
5. Suggest CLAUDE.md updates for stable knowledge
6. Propose archiving old entries (> 30 days, implemented)

## Prune Mode

When `/reflect prune` is invoked:

1. Remove entries marked as "implemented"
2. Remove entries older than 30 days with < 3 occurrences
3. Archive (don't delete) to `.claude/learning/archive/`
4. Report what was pruned

## Facts Mode

When `/reflect facts` is invoked:

1. Read `## Project Facts` section from `.claude/CLAUDE.md`
2. Review all captured corrections for:
   - **Duplicates** - Same fact captured multiple ways
   - **Contradictions** - Facts that conflict with each other
   - **Stale facts** - Things that may have changed
   - **Uncategorized** - Facts not in proper subsection
3. Propose consolidations:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Project Facts Review
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current Facts: 12 entries

### Proposed Changes

**MERGE** (Tooling)
  - "Uses pnpm, not npm" + "Package manager is pnpm"
  → "Uses pnpm as package manager"

**MOVE** (Uncategorized → Structure)
  - "Tests are in __tests__/ folders"

**FLAG** (Possible contradiction)
  - "Uses vitest" vs project-context.json shows "jest"
  → Verify which is correct

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

4. Apply changes after confirmation
5. Update project-context.json if facts reveal detection errors

## Project Facts Section

The `## Project Facts` section in CLAUDE.md stores authoritative project knowledge captured from user corrections.

### Structure

```markdown
## Project Facts

> Auto-captured from user corrections. Authoritative project knowledge.

### Tooling
- [fact] (corrected YYYY-MM-DD)

### Structure
- [fact] (corrected YYYY-MM-DD)

### Conventions
- [fact] (corrected YYYY-MM-DD)

### Architecture
- [fact] (corrected YYYY-MM-DD)
```

### Creating the Section

If `## Project Facts` doesn't exist in CLAUDE.md:

1. Read `.claude/templates/project-facts.md.template`
2. Insert after first `---` or before `## Claudenv Framework`
3. Add fact to appropriate subsection

### Fact Lifecycle

1. **Captured** - User corrects Claude, fact auto-added
2. **Active** - Fact is in Project Facts section
3. **Consolidated** - Merged with similar facts via `/reflect facts`
4. **Promoted** - Moved to project-context.json if it's a detection-level fact
5. **Archived** - Removed if project changes (kept in git history)

## Entry Format

When adding/updating entries, use this format:

```markdown
### [Pattern Name]

**Type:** pattern | preference | issue | architecture
**Status:** monitoring | pending | implemented | obsolete
**Occurrences:** N
**First Seen:** YYYY-MM-DD
**Last Seen:** YYYY-MM-DD
**Evidence:**
- Specific example 1
- Specific example 2

**Insight:** [Actionable description]
```

## Integration with Learning System

- Reflection should be suggested at session end if significant work occurred
- Pattern-observer can trigger reflection when observations.md exceeds 50 entries
- `/learn:review` should suggest `/reflect` if many stale entries exist

## What NOT to Capture

- Generic best practices (use official docs instead)
- One-time fixes unlikely to recur
- Personal opinions without evidence
- Incomplete understanding (wait for more data)

## Evolve Mode

When `/reflect evolve` is invoked, analyze the system itself and propose improvements.

### Step 1: Gather Failure Data

Read recent history from:

```bash
ls -la .claude/loop/history/*.json | head -20
```

Parse each history file for:
- Loop/plan failures and their reasons
- Validation failures from `/ce:execute`
- Cancelled operations and why
- Error patterns in metrics

### Step 2: Identify Improvement Opportunities

Analyze failures to identify:

1. **Rules that could prevent errors**
   - Repeated mistakes that a rule would catch
   - Missing constraints or guidelines
   - Ambiguous situations that caused confusion

2. **Command templates needing updates**
   - Commands that frequently fail
   - Missing options or flags
   - Outdated process flows

3. **Missing reference docs**
   - External APIs or tools used without documentation
   - Patterns that aren't documented
   - Frameworks lacking skill support

4. **Process improvements**
   - Steps that should be automated
   - Validation gaps
   - Better defaults

### Step 3: Generate Proposals

Create `.claude/evolution-proposals.md`:

```markdown
# Evolution Proposals

> Generated: {YYYY-MM-DD HH:MM}
> Based on: {n} loop histories, {m} failures analyzed

## Summary

- **High Priority**: {count} proposals
- **Medium Priority**: {count} proposals
- **Low Priority**: {count} proposals

---

## High Priority

### Proposal 1: Add validation for {pattern}

**Problem**: {description of failure pattern}
**Evidence**: Occurred in {n} sessions
- loop_20260105_143022: {brief description}
- loop_20260107_091544: {brief description}

**Proposed Solution**:
- Add rule to `rules/claudenv.md`: {rule text}
- OR: Update command `{name}` to check for {condition}
- OR: Create reference doc for {topic}

**Impact**: Would have prevented {n} failures

---

### Proposal 2: ...

---

## Medium Priority

...

## Low Priority

...

---

## Implementation Checklist

- [ ] Proposal 1: {title}
- [ ] Proposal 2: {title}
...
```

### Step 4: Present Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧬 System Evolution Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Analyzed:
  Loop histories: {n}
  Failed operations: {m}
  Time period: {date range}

Proposals Generated:
  🔴 High Priority: {count}
  🟡 Medium Priority: {count}
  🟢 Low Priority: {count}

Top Issues:
  1. {Most common failure pattern}
  2. {Second most common}
  3. {Third most common}

Proposals saved to: .claude/evolution-proposals.md

Review proposals with:
  cat .claude/evolution-proposals.md

Apply changes manually or request implementation.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Proposal Categories

| Category | Example | Target File |
|----------|---------|-------------|
| Rule | "Always run lint before commit" | `rules/*.md` |
| Command | "Add --dry-run to /ce:execute" | `commands/*.md` |
| Reference | "Document Prisma error codes" | `reference/*.md` |
| Skill | "Create prisma-debug skill" | `skills/` |
| Hook | "Add pre-commit validation" | `settings.json` |
| Process | "Run tests after each phase" | Multiple files |

### When to Run Evolve

- After completing a large feature with issues
- Weekly during active development
- When patterns of failure emerge
- Before major refactors

### Auto-Detection

The pattern-observer skill can suggest `/reflect evolve` when:
- 3+ failures with similar error patterns
- Same validation fails repeatedly
- Commands are frequently cancelled
