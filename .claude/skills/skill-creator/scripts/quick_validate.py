#!/usr/bin/env python3
"""
Quick validation script for skills (no external dependencies)
"""

import sys
import re
from pathlib import Path


def parse_simple_yaml(text):
    """Parse simple YAML frontmatter without external dependencies."""
    result = {}
    for line in text.strip().split('\n'):
        if ':' in line:
            key, _, value = line.partition(':')
            key = key.strip()
            value = value.strip()
            # Handle multi-line descriptions that start on same line
            if value:
                result[key] = value
            else:
                result[key] = ''
    return result


def validate_skill(skill_path):
    """Validate a skill directory."""
    skill_path = Path(skill_path)

    skill_md = skill_path / 'SKILL.md'
    if not skill_md.exists():
        return False, "SKILL.md not found"

    content = skill_md.read_text()
    if not content.startswith('---'):
        return False, "No YAML frontmatter found"

    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return False, "Invalid frontmatter format"

    try:
        frontmatter = parse_simple_yaml(match.group(1))
    except Exception as e:
        return False, f"Error parsing frontmatter: {e}"

    ALLOWED = {'name', 'description', 'license', 'allowed-tools', 'metadata', 'model'}
    unexpected = set(frontmatter.keys()) - ALLOWED
    if unexpected:
        return False, f"Unexpected keys: {', '.join(unexpected)}"

    if 'name' not in frontmatter:
        return False, "Missing 'name' in frontmatter"
    if 'description' not in frontmatter:
        return False, "Missing 'description' in frontmatter"

    name = frontmatter.get('name', '').strip()
    if name:
        if not re.match(r'^[a-z0-9-]+$', name):
            return False, f"Name '{name}' must be hyphen-case"
        if name.startswith('-') or name.endswith('-') or '--' in name:
            return False, f"Name '{name}' has invalid hyphens"
        if len(name) > 64:
            return False, f"Name too long ({len(name)} chars, max 64)"

    description = frontmatter.get('description', '').strip()
    if description:
        if '<' in description or '>' in description:
            return False, "Description cannot contain < or >"
        if len(description) > 1024:
            return False, f"Description too long ({len(description)} chars, max 1024)"

    return True, "Valid!"


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python quick_validate.py <skill_directory>")
        sys.exit(1)

    valid, message = validate_skill(sys.argv[1])
    print(message)
    sys.exit(0 if valid else 1)
