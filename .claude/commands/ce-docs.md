---
description: "Update documentation: analyze project, document gaps, sync counts, optimize"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
---

# /docs - Documentation Updater

Comprehensively analyze and update project documentation.

## Phase 1: Project Analysis

**Before processing any files, analyze the entire project:**

### 1.1 Inventory Collection

Collect a complete inventory of project components.

**Framework Mode** (claudenv repo - uses `dist/`):

```bash
# Commands, Skills, Agents, Scripts, Rules
ls dist/commands/*.md 2>/dev/null
ls -d dist/skills/*/ 2>/dev/null
ls -d dist/agents/*/ 2>/dev/null
ls dist/scripts/*.sh 2>/dev/null
ls dist/rules/*.md 2>/dev/null
```

**Project Mode** (uses `.claude/`, separates framework vs project files):

```bash
# Framework (claudenv namespace)
FRAMEWORK_SKILLS=$(ls -d .claude/skills/claudenv/*/ 2>/dev/null | wc -l)

# Project (workspace namespace)
WORKSPACE_SKILLS=$(ls -d .claude/skills/workspace/*/ 2>/dev/null | wc -l)

# Agents
FRAMEWORK_AGENTS=$(ls .claude/agents/*.md 2>/dev/null | wc -l)
```

Report separately:
- **Framework**: {n} skills in `claudenv/`, {n} agents (managed by claudenv)
- **Project**: {n} skills in `workspace/` (project-specific, document these)

### 1.2 Documentation Gap Analysis

For each component found, check if it's documented:

| Component | Check Location |
|-----------|----------------|
| Commands | README.md commands table, command file has description |
| Skills | README.md skills section, SKILL.md has description |
| Agents | README.md or claudenv.md agents section |
| Scripts | Comment header in script, mentioned in relevant docs |
| Rules | Listed in claudenv.md @rules references |

### 1.3 Report Gaps

Output analysis before proceeding:

**Framework Mode:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Project Analysis (Framework Mode)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Components Found:
  Commands: {n}
  Skills: {n}
  Agents: {n}
  Scripts: {n}
  Rules: {n}

Documentation Gaps:
  ⚠ {component} - not in README commands table
  ⚠ {component} - missing description
  ✓ All components documented (if none)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Project Mode:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Project Analysis (Project Mode)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Framework (from claudenv - DO NOT MODIFY):
  Commands: {n} | Skills: {n} | Agents: {n}

Project-Specific (can document/modify):
  Commands: {n} ({list})
  Skills: {n} ({list})
  Agents: {n} ({list})
  Rules: {n} ({list})
  Reference docs: {n}

Documentation Gaps (project files only):
  ⚠ {component} - missing description in frontmatter
  ⚠ {component} - not mentioned in CLAUDE.md
  ✓ All project components documented (if none)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 1.4 Fix Gaps First

Before optimization, add documentation for any undocumented components:
- Add missing commands to README.md table
- Add missing skills to README.md skills section
- Ensure each command/skill file has a proper description in frontmatter
- Add script descriptions if missing

---

## Phase 2: Scope Detection

**Determine processing scope:**

1. Check if `dist/rules/claudenv.md` exists (indicates claudenv repo itself)
2. If YES → Process **Framework Files** (full list below)
3. If NO → Process **Project Files** only (README.md, docs/, CLAUDE.md)

---

## Phase 3: File Processing

### Files to Process

### Framework Files (claudenv repo only)

Only process these when running from the claudenv repository itself:

1. `dist/rules/autonomy.md`
2. `dist/rules/permissions/core.md`
3. `dist/rules/error-recovery/core.md`
4. `dist/rules/error-recovery/patterns.md`
5. `dist/rules/coordination.md`
6. `dist/rules/migration.md`
7. `dist/rules/triggers/reference.json` (regenerate from triggers.json)
8. `dist/rules/claudenv/core.md`
9. `dist/rules/claudenv/reference.md`
10. `README.md`

### Project Files (user projects)

For regular projects with claudenv installed:

1. `README.md`
2. `.claude/CLAUDE.md` (if exists)
3. `docs/**/*.md` (if docs/ exists)
4. `.claude/references/**/*.md` (project-specific reference docs)
5. Project-created commands, skills, agents, rules, scripts (see below)

**Framework vs Project Files:**

Projects CAN have their own commands, skills, agents, rules, and scripts. The distinction:

- **Framework files** = Listed in `.claude/manifest.json` → **DO NOT MODIFY**
- **Project files** = NOT in manifest → Safe to modify/document

```bash
# Check if a file is framework-managed:
jq -r '.files[]' .claude/manifest.json | grep -qF "relative/path" && echo "PROTECTED"

# List project-owned files (not in manifest):
comm -23 <(ls .claude/commands/*.md | sed 's|.claude/||' | sort) \
         <(jq -r '.files[]' .claude/manifest.json | grep '^commands/' | sort)
```

When analyzing project documentation:
1. Read manifest.json to get list of framework files
2. Any .claude/* file NOT in manifest is project-owned
3. Document and optimize project-owned files only

## Process

For each file:

1. **Read** the file and count lines
2. **Check** for issues (see rules below)
3. **Edit** to fix issues found
4. **Report** what changed

## Optimization Rules

### 1. Size Limits

| File Type | Warning | Max |
|-----------|---------|-----|
| Rule files | 200 lines | 300 lines |
| README.md | 700 lines | 800 lines |
| Other docs | 500 lines | 700 lines |

If over warning threshold: Remove redundant content first.
If over max after cleanup: **Trigger file split workflow** (see below).

### 2. Syntax Consistency

Fix deprecated colon syntax → space syntax:
- `/cmd:action` → `/cmd action`
- `Bash(npm:*)` → `Bash(npm *)`

### 3. Accuracy (Framework Mode Only)

**For README.md**, verify and update:
- Command count in "# XX slash commands" matches `ls dist/commands/*.md | wc -l`
- Skills count matches `ls -d dist/skills/*/ | wc -l`
- Commands table lists all commands in `dist/commands/`

**For trigger-reference.md**, regenerate sections:
- Read `dist/skills/triggers.json` and format as skill triggers
- Read `dist/agents/triggers.json` and format as agent triggers

### 4. Redundancy Elimination

Remove content that is:
- Duplicated verbatim in another file
- Examples that don't add value
- Overly verbose explanations

### 5. Self-Contained

Each doc file should:
- State its purpose in the first paragraph
- Not require reading other files to understand basics

---

## Large File Split Workflow

When a file exceeds the max line threshold and can't be reduced through cleanup:

### Step 1: Analyze Structure

Identify natural breakpoints:
- `## ` level-2 headings (primary split points)
- `---` horizontal rules (secondary split points)
- Logical topic boundaries

Group related sections and calculate lines per group.

### Step 2: Propose Concrete Splits

Present a specific split proposal to the user:

```
⚠ {filename} exceeds {max} line limit ({actual} lines)

Proposed split into {n} files:

  {original}.md ({lines} lines)
    - {kept section 1}
    - {kept section 2}

  {new-file-1}.md ({lines} lines)
    - {section moved}
    - {section moved}

  {new-file-2}.md ({lines} lines)
    - {section moved}

Proceed with split? (y/N)
```

Use AskUserQuestion to get confirmation before proceeding.

### Step 3: Execute Split

If approved:

1. **Create new files** with extracted sections
   - Each new file gets a title heading and brief intro
   - Preserve all content verbatim (no summarizing)

2. **Update original file** to use @imports:
   ```markdown
   ## Section Name

   @rules/{new-file}.md
   ```

3. **Update cross-references** in other files if needed
   - Search for references to the original file
   - Add references to new files where appropriate

### Step 4: Report Changes

```
Split complete:
  ✓ Created {new-file-1}.md ({lines} lines)
  ✓ Created {new-file-2}.md ({lines} lines)
  ✓ Updated {original}.md ({before} → {after} lines)
  ✓ Added @imports for split sections
```

### Split Naming Convention

New files should be named based on their primary content:
- `claudenv.md` sections → `piv-workflow.md`, `orchestration.md`, `loop-system.md`
- `README.md` sections → Keep in README (don't split READMEs, trim instead)

### When NOT to Split

- **README.md**: Trim content instead of splitting (READMEs should be single files)
- **Files just barely over**: If <10% over max, try harder to trim first
- **Highly interconnected content**: If sections heavily reference each other

---

## Output Format

### Phase 1 Output (Analysis)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Project Analysis
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Components Found:
  Commands: {n}
  Skills: {n}
  Agents: {n}
  Scripts: {n}
  Rules: {n}

Documentation Gaps:
  {list of gaps or "✓ All components documented"}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Phase 2 Output (Scope)

```
Scope: {Framework Mode | Project Mode}
```

### Phase 3 Output (File Processing)

After processing each file:

```
Processing: {filename}
  Lines: {before} → {after} ({change})
  {list of changes made, each prefixed with ✓}
```

### Final Summary

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📄 Documentation Update Complete
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Analysis: {n} components, {g} gaps found
Updates: {n} files processed, {m} updated, {s} split
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## trigger-reference.md Regeneration (Framework Mode Only)

When processing trigger-reference.md:

1. Read `dist/skills/triggers.json`
2. Read `dist/agents/triggers.json`
3. Generate markdown with this structure:

```markdown
# Trigger Reference

> Auto-generated from triggers.json - DO NOT EDIT MANUALLY

## Skill Triggers

### {skill-name}
**Keywords:** {comma-separated keywords or "none"}
**Phrases:** {comma-separated phrases in quotes}

## Agent Triggers

### {agent-name}
**Keywords:** {comma-separated keywords}
**Phrases:** {comma-separated phrases in quotes}
**File patterns:** {comma-separated patterns, if present}

## Matching Rules

1. **Case-insensitive** - match regardless of capitalization
2. **Partial match** - trigger phrase can be part of larger request
3. **Multiple matches** - if multiple skills/agents match, prefer the most specific
4. **Skills vs Agents** - Skills run in main context; Agents run as subagents via Task tool

## Invocation

- **Skills**: Use the `Skill` tool with the skill name
- **Agents**: Use the `Task` tool with `subagent_type` matching the agent name
```
