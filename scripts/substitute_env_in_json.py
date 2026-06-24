#!/usr/bin/env python3
"""Substitute ${VAR} placeholders in a JSON file using environment variables.

Values are read from an optional .env file and merged with the current process
environment (.env takes precedence). The output is valid, indented JSON.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path

_PLACEHOLDER_RE = re.compile(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}")


def parse_env_file(path: str) -> dict[str, str]:
    """Parse a simple KEY=VALUE .env file.

    Supports optional ``export `` prefix, ``#`` comments, and blank lines.
    Values are stripped of surrounding whitespace and matching single/double
    quotes are removed.
    """
    env: dict[str, str] = {}
    env_path = Path(path)
    if not env_path.is_file():
        return env

    with env_path.open("r", encoding="utf-8") as handle:
        for raw_line in handle:
            line = raw_line.strip()
            if not line or line.startswith("#"):
                continue
            if line.startswith("export "):
                line = line[7:]
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            key = key.strip()
            value = value.strip()
            if len(value) >= 2 and value[0] == value[-1] and value[0] in ('"', "'"):
                value = value[1:-1]
            env[key] = value
    return env


def substitute(value: object, env: dict[str, str]) -> object:
    """Recursively replace ${VAR} placeholders inside JSON data."""
    if isinstance(value, dict):
        return {k: substitute(v, env) for k, v in value.items()}
    if isinstance(value, list):
        return [substitute(item, env) for item in value]
    if isinstance(value, str):

        def repl(match: re.Match[str]) -> str:
            var = match.group(1)
            if var in env:
                return env[var]
            print(
                f"Warning: environment variable '{var}' not set, leaving placeholder",
                file=sys.stderr,
            )
            return match.group(0)

        return _PLACEHOLDER_RE.sub(repl, value)
    return value


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Substitute ${VAR} placeholders in a JSON file using .env values."
    )
    parser.add_argument("--input", required=True, help="Source JSON file path.")
    parser.add_argument("--output", required=True, help="Destination JSON file path.")
    parser.add_argument(
        "--env",
        default=os.path.expanduser("~/.config/opencode/.env"),
        help="Path to the .env file to load.",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.is_file():
        print(f"Error: input file not found: {input_path}", file=sys.stderr)
        return 1

    env = {**os.environ, **parse_env_file(args.env)}

    with input_path.open("r", encoding="utf-8") as handle:
        data = json.load(handle)

    data = substitute(data, env)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2)
        handle.write("\n")

    # Restrict read access because the file may now contain secrets.
    os.chmod(output_path, 0o600)

    return 0


if __name__ == "__main__":
    sys.exit(main())
