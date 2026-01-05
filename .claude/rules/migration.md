# CLAUDE.md Migration Rules

## Core Principle

**PRESERVE EVERYTHING**

When migrating existing CLAUDE.md files, every single line of the original content must be preserved verbatim. No summarizing, no condensing, no rewriting.

## Migration Scenarios

### Scenario 1: CLAUDE.md at Project Root

If `./CLAUDE.md` exists:

1. Read the ENTIRE file
2. Create `.claude/CLAUDE.md` with this structure:

```markdown
# Project Instructions

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<!-- ORIGINAL PROJECT INSTRUCTIONS - DO NOT MODIFY THIS SECTION -->
<!-- Preserved VERBATIM from: ./CLAUDE.md -->
<!-- Migrated on: [DATE] -->
<!-- Any modifications should be made BELOW the autonomy section -->
<!-- ═══════════════════════════════════════════════════════════════════════ -->

[PASTE ENTIRE ORIGINAL CLAUDE.MD CONTENT HERE - VERBATIM, NO CHANGES]

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<!-- END ORIGINAL CONTENT -->
<!-- ═══════════════════════════════════════════════════════════════════════ -->

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<!-- CLAUDENV INFRASTRUCTURE (Auto-generated) -->
<!-- ═══════════════════════════════════════════════════════════════════════ -->

[NEW AUTONOMY & INFRASTRUCTURE SECTIONS]
```

3. Replace root `./CLAUDE.md` with pointer file:

```markdown
# Project Instructions

> **Moved:** Full instructions are now in `.claude/CLAUDE.md`
>
> This file is kept for compatibility with tools that expect CLAUDE.md at root.
> **All original content has been preserved verbatim.**

See [.claude/CLAUDE.md](.claude/CLAUDE.md) for:
- Original project instructions (unchanged)
- Autonomy & permissions configuration
- Skill and command documentation
- Infrastructure overview
```

### Scenario 2: CLAUDE.md Already in .claude/

If `.claude/CLAUDE.md` exists:

1. Read ENTIRE existing content
2. Check if autonomy sections already exist
3. If NO autonomy sections: Append new sections at end
4. If autonomy sections exist: Update ONLY those sections

### Scenario 3: Multiple CLAUDE.md Files

If multiple files exist (e.g., `./CLAUDE.md` and `./docs/CLAUDE.md`):

1. Read ALL files completely
2. Concatenate with clear section markers:

```markdown
<!-- ═══════════════════════════════════════════════════════════════════════ -->
<!-- FROM: ./CLAUDE.md -->
<!-- ═══════════════════════════════════════════════════════════════════════ -->

[CONTENT FROM ./CLAUDE.md]

<!-- ═══════════════════════════════════════════════════════════════════════ -->
<!-- FROM: ./docs/CLAUDE.md -->
<!-- ═══════════════════════════════════════════════════════════════════════ -->

[CONTENT FROM ./docs/CLAUDE.md]
```

3. Do NOT deduplicate - preserve all instances
4. Replace originals with pointer files

## Verification

After migration, verify line counts:

```bash
ORIGINAL_LINES=$(wc -l < "./CLAUDE.md.backup" 2>/dev/null | tail -1)
NEW_LINES=$(grep -c "" .claude/CLAUDE.md)
echo "Original: $ORIGINAL_LINES lines, New: $NEW_LINES lines"
# New should be >= Original
```

## What to Preserve

- ALL project-specific instructions
- ALL custom commands defined by the user
- ALL workflow documentation
- ALL code style preferences
- ALL architectural notes
- ALL environment setup instructions
- ALL deployment procedures
- ALL team conventions
- ALL links and references
- ALL warnings and gotchas
- ALL TODO items or notes
- EXACT formatting where meaningful

## What NOT to Do

- Summarize or condense existing content
- Remove sections you think are covered elsewhere
- Rewrite in your own words
- Skip content that seems outdated
- Merge similar sections without preservation
- Change formatting unless broken
