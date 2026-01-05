---
name: skill-creator
description: Creates new skills with proper structure and validation. Use when creating a skill, initializing a new skill, scaffolding skill directories, or packaging skills for distribution. Provides templates, validation, and best practices for skill development.
allowed-tools: Write, Read, Glob, Bash(*), Edit
---

# Skill Creator

Guide for creating effective skills that extend Claude's capabilities.

## About Skills

Skills are modular, self-contained packages providing:
1. **Specialized workflows** - Multi-step procedures for specific domains
2. **Tool integrations** - Instructions for file formats or APIs
3. **Domain expertise** - Schemas, business logic, policies
4. **Bundled resources** - Scripts, references, and assets

## Core Principles

### Conciseness
The context window is a public good. Only add context Claude doesn't already have.

### Degrees of Freedom
- **High freedom**: Multiple approaches valid, heuristics guide
- **Medium freedom**: Preferred pattern exists, some variation OK
- **Low freedom**: Fragile operations, specific sequence required

### Skill Anatomy

```
skill-name/
├── SKILL.md (required)
│   ├── YAML frontmatter (name, description)
│   └── Markdown instructions
└── Bundled Resources (optional)
    ├── scripts/     - Executable code
    ├── references/  - Documentation for context
    └── assets/      - Files used in output
```

## Creation Process

### Step 1: Initialize

Run the init script:
```bash
python .claude/skills/skill-creator/scripts/init_skill.py <name> --path .claude/skills
```

### Step 2: Edit SKILL.md

**Frontmatter requirements:**
- `name`: Hyphen-case identifier (max 40 chars)
- `description`: What it does AND when to use it (max 1024 chars)

**Body patterns:**
- Workflow-based: Sequential steps
- Task-based: Different operations
- Reference: Standards or specs
- Capabilities: Interrelated features

### Step 3: Add Resources

- `scripts/`: Python/Bash for automation
- `references/`: Docs loaded into context as needed
- `assets/`: Templates, images, fonts for output

### Step 4: Validate

```bash
python .claude/skills/skill-creator/scripts/quick_validate.py .claude/skills/<name>
```

### Step 5: Package (optional)

```bash
python .claude/skills/skill-creator/scripts/package_skill.py .claude/skills/<name>
```

Creates a distributable `.skill` file.

## Progressive Disclosure

1. **Metadata** - Always in context (~100 words)
2. **SKILL.md body** - When triggered (<5k words)
3. **References** - As needed (unlimited)

Keep SKILL.md under 500 lines. Split into references when larger.

## Design Patterns

See `references/workflows.md` for sequential and conditional workflows.
See `references/output-patterns.md` for templates and examples.

## Delegation

This skill is invoked by `meta-skill` when creating new skills for unfamiliar technologies.
