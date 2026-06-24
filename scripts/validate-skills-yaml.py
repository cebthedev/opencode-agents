#!/usr/bin/env python3
"""Validate YAML frontmatter in all SKILL.md files.

Scans skill directories for SKILL.md files and validates that:
1. YAML frontmatter exists (between --- delimiters)
2. Frontmatter parses as valid YAML
3. Required fields (name, description) are present
4. No duplicate skill names exist across directories

Usage:
    python3 scripts/validate-skills-yaml.py [--strict] [directories...]

    --strict   Exit with error on warnings (duplicate names)
    directories   Paths to scan (default: skills/ lazy-skills/)
"""

import sys
import os
import yaml
from pathlib import Path
from collections import defaultdict


def extract_frontmatter(content: str, filepath: str) -> tuple[str, int]:
    """Extract YAML frontmatter from a SKILL.md file.

    Returns (frontmatter_text, line_number_of_closing_delimiter) or raises ValueError.
    """
    if not content.startswith("---"):
        raise ValueError(f"{filepath}: missing opening --- delimiter")

    # Find the closing ---
    # Skip the first --- (lines start at 1)
    end_idx = content.find("\n---", 3)
    if end_idx == -1:
        raise ValueError(f"{filepath}: missing closing --- delimiter")

    frontmatter = content[3:end_idx].strip()
    return frontmatter


def validate_skill_md(filepath: str) -> list[str]:
    """Validate a single SKILL.md file. Returns list of error strings."""
    errors = []
    content = Path(filepath).read_text(encoding="utf-8")

    try:
        frontmatter = extract_frontmatter(content, filepath)
    except ValueError as e:
        return [str(e)]

    try:
        data = yaml.safe_load(frontmatter)
    except yaml.YAMLError as e:
        return [f"{filepath}: YAML parse error: {e}"]

    if not isinstance(data, dict):
        return [f"{filepath}: frontmatter is not a YAML mapping (got {type(data).__name__})"]

    # Check required fields
    if "name" not in data:
        errors.append(f"{filepath}: missing required field 'name'")
    if "description" not in data:
        errors.append(f"{filepath}: missing required field 'description'")

    # Check for common issues
    if "description" in data and isinstance(data["description"], str):
        desc = data["description"]
        # These should have been caught by YAML parsing, but double-check
        if not desc.strip():
            errors.append(f"{filepath}: description is empty")

    return errors


def find_skill_files(directories: list[str]) -> list[str]:
    """Find all SKILL.md files in the given directories."""
    files = []
    for dir_path in directories:
        base = Path(dir_path)
        if not base.exists():
            print(f"  ⚠  Directory not found: {dir_path}", file=sys.stderr)
            continue
        for skill_md in base.rglob("SKILL.md"):
            files.append(str(skill_md))
    return sorted(files)


def main() -> int:
    import argparse
    parser = argparse.ArgumentParser(description="Validate YAML frontmatter in SKILL.md files")
    parser.add_argument("--strict", action="store_true", help="Exit with error on warnings")
    parser.add_argument("directories", nargs="*", default=["skills/", "lazy-skills/"],
                        help="Directories to scan (default: skills/ lazy-skills/)")
    args = parser.parse_args()

    # Resolve directories relative to project root
    script_dir = Path(__file__).resolve().parent
    project_root = script_dir.parent
    dirs = [str(project_root / d) for d in args.directories]

    print("🔍 Validating SKILL.md YAML frontmatter...")
    print(f"   Scanning: {', '.join(dirs)}")

    skill_files = find_skill_files(dirs)
    if not skill_files:
        print("  ⚠  No SKILL.md files found", file=sys.stderr)
        return 1

    print(f"   Found {len(skill_files)} SKILL.md files\n")

    all_errors = []
    names_by_dir: dict[str, list[tuple[str, str]]] = defaultdict(list)  # name -> [(filepath, dir)]

    for filepath in skill_files:
        errors = validate_skill_md(filepath)
        if errors:
            for e in errors:
                print(f"  ❌ {e}")
                all_errors.append(e)
        else:
            print(f"  ✓ {filepath}")

            # Track names for duplicate detection
            content = Path(filepath).read_text(encoding="utf-8")
            try:
                frontmatter = extract_frontmatter(content, filepath)
                data = yaml.safe_load(frontmatter)
                if isinstance(data, dict) and "name" in data:
                    # Determine which top-level directory this belongs to
                    rel_path = os.path.relpath(filepath, str(project_root))
                    top_dir = rel_path.split(os.sep)[0]
                    names_by_dir[data["name"]].append((filepath, top_dir))
            except (ValueError, yaml.YAMLError):
                pass

    # Check for duplicates
    warnings = []
    for name, locations in names_by_dir.items():
        if len(locations) > 1:
            dirs_list = ", ".join(set(d for _, d in locations))
            warning = f"Duplicate skill name '{name}' found in: {dirs_list}"
            print(f"  ⚠  {warning}")
            for filepath, dir_name in locations:
                print(f"      → {filepath}")
            warnings.append(warning)

    print()
    if all_errors:
        print(f"❌ Validation failed with {len(all_errors)} error(s)")
        return 1

    if warnings and args.strict:
        print(f"⚠  Validation passed with {len(warnings)} warning(s) (--strict mode)")
        return 1

    if warnings:
        print(f"✅ Validation passed with {len(warnings)} warning(s) (run with --strict to treat as errors)")
    else:
        print("✅ All SKILL.md files have valid YAML frontmatter")

    return 0


if __name__ == "__main__":
    sys.exit(main())