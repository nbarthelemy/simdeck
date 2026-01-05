#!/usr/bin/env python3
"""
Skill Initializer - Creates a new skill from template

Usage:
    init_skill.py <skill-name> --path <path>

Examples:
    init_skill.py my-new-skill --path .claude/skills
"""

import sys
from pathlib import Path


SKILL_TEMPLATE = """---
name: {skill_name}
description: [TODO: What this skill does and when to use it. Include trigger scenarios.]
allowed-tools: Read, Write, Edit, Bash(*)
---

# {skill_title}

## Overview

[TODO: 1-2 sentences explaining what this skill enables]

## When to Activate

- [TODO: Specific triggers]
- [TODO: File patterns or keywords]

## Instructions

[TODO: Add workflow steps, patterns, or guidance]

## Resources

- `scripts/` - Executable automation scripts
- `references/` - Documentation loaded as needed
- `assets/` - Templates and files for output

Delete unused directories.
"""

EXAMPLE_SCRIPT = '''#!/usr/bin/env python3
"""
Example helper script for {skill_name}
Replace with actual implementation or delete if not needed.
"""

def main():
    print("Example script for {skill_name}")
    # TODO: Add script logic

if __name__ == "__main__":
    main()
'''

EXAMPLE_REFERENCE = """# Reference Documentation

[TODO: Add detailed documentation here]

This file is loaded into context when Claude needs it.
Keep SKILL.md lean; put details here.
"""


def title_case_skill_name(skill_name):
    return ' '.join(word.capitalize() for word in skill_name.split('-'))


def init_skill(skill_name, path):
    skill_dir = Path(path).resolve() / skill_name

    if skill_dir.exists():
        print(f"Error: Directory already exists: {skill_dir}")
        return None

    try:
        skill_dir.mkdir(parents=True, exist_ok=False)
        print(f"Created: {skill_dir}")
    except Exception as e:
        print(f"Error creating directory: {e}")
        return None

    skill_title = title_case_skill_name(skill_name)
    skill_content = SKILL_TEMPLATE.format(
        skill_name=skill_name,
        skill_title=skill_title
    )

    skill_md_path = skill_dir / 'SKILL.md'
    try:
        skill_md_path.write_text(skill_content)
        print("Created: SKILL.md")
    except Exception as e:
        print(f"Error creating SKILL.md: {e}")
        return None

    try:
        scripts_dir = skill_dir / 'scripts'
        scripts_dir.mkdir(exist_ok=True)
        example_script = scripts_dir / 'example.py'
        example_script.write_text(EXAMPLE_SCRIPT.format(skill_name=skill_name))
        example_script.chmod(0o755)
        print("Created: scripts/example.py")

        references_dir = skill_dir / 'references'
        references_dir.mkdir(exist_ok=True)
        example_ref = references_dir / 'reference.md'
        example_ref.write_text(EXAMPLE_REFERENCE)
        print("Created: references/reference.md")

        assets_dir = skill_dir / 'assets'
        assets_dir.mkdir(exist_ok=True)
        print("Created: assets/")
    except Exception as e:
        print(f"Error creating resources: {e}")
        return None

    print(f"\nSkill '{skill_name}' initialized at {skill_dir}")
    print("\nNext steps:")
    print("1. Edit SKILL.md - complete TODOs and description")
    print("2. Customize or delete example files")
    print("3. Run quick_validate.py to check structure")

    return skill_dir


def main():
    if len(sys.argv) < 4 or sys.argv[2] != '--path':
        print("Usage: init_skill.py <skill-name> --path <path>")
        print("\nRequirements:")
        print("  - Hyphen-case (lowercase, hyphens)")
        print("  - Max 40 characters")
        print("\nExample:")
        print("  init_skill.py stripe-payments --path .claude/skills")
        sys.exit(1)

    skill_name = sys.argv[1]
    path = sys.argv[3]

    print(f"Initializing skill: {skill_name}")
    print(f"Location: {path}\n")

    result = init_skill(skill_name, path)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
