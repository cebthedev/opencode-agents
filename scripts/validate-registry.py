#!/usr/bin/env python3
"""Lint the oa registry + model fallback config.

Fails (exit 1) on:
  - bundle referencing a missing skill / mcp / plugin / agent def
  - malformed manifest (mcp without command|url, plugin without command)
  - fallback.json agent not defined in opencode.json
  - fallback model not provided by any opencode.json provider

Warns (exit 0) on registry entries no bundle references.
"""

import json
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent.parent
SEARCH_ROOTS = [ROOT / "lazy-skills", ROOT / "skills" / "global", ROOT / "skills" / "agents"]
BUNDLES = ROOT / "registry" / "bundles"
TOOL_DIRS = {"mcps": ROOT / "registry" / "mcps", "plugins": ROOT / "registry" / "plugins"}
AGENTS_DIR = ROOT / "agents"

errors, warnings = [], []


def check_bundles():
    referenced = {"mcps": set(), "plugins": set()}
    for f in sorted(BUNDLES.glob("*.yaml")):
        try:
            data = yaml.safe_load(f.read_text()) or {}
        except yaml.YAMLError as e:
            errors.append(f"{f.name}: invalid YAML: {e}")
            continue
        for skill in data.get("skills", []):
            if not any((r / skill / "SKILL.md").exists() for r in SEARCH_ROOTS):
                errors.append(f"{f.name}: skill '{skill}' not found in search roots")
        for kind in ("mcps", "plugins"):
            for tool in data.get(kind, []):
                referenced[kind].add(tool)
                if not (TOOL_DIRS[kind] / f"{tool}.yaml").exists():
                    errors.append(f"{f.name}: {kind[:-1]} '{tool}' has no manifest")
        for agent in data.get("agents", []):
            if not (AGENTS_DIR / f"{agent}.md").exists():
                errors.append(f"{f.name}: agent '{agent}' has no def in agents/")
    for kind, refs in referenced.items():
        for f in TOOL_DIRS[kind].glob("*.yaml"):
            if f.stem not in refs:
                warnings.append(f"unreferenced {kind[:-1]} manifest: {f.stem}")


def check_manifests():
    for kind, d in TOOL_DIRS.items():
        for f in sorted(d.glob("*.yaml")):
            try:
                data = yaml.safe_load(f.read_text()) or {}
            except yaml.YAMLError as e:
                errors.append(f"{f.name}: invalid YAML: {e}")
                continue
            if kind == "mcps" and not (data.get("command") or data.get("url")):
                errors.append(f"{f.name}: mcp manifest needs command or url")
            if kind == "plugins" and not data.get("command"):
                errors.append(f"{f.name}: plugin manifest needs command")


def check_fallback():
    cfg = json.loads((ROOT / "config" / "opencode.json").read_text())
    fb = json.loads((ROOT / "config" / "fallback.json").read_text())
    providers = cfg.get("provider", {})
    models = {f"{p}/{m}" for p, v in providers.items() for m in v.get("models", {})}
    # Agent defs can come from opencode.json or the oh-my-opencode-slim plugin presets.
    agents = set(cfg.get("agent", {}))
    slim_path = ROOT / "config" / "oh-my-opencode-slim.json"
    if slim_path.exists():
        slim = json.loads(slim_path.read_text())
        agents |= set(slim.get("presets", {}).get("custom", {}))

    def check_model(ref, where):
        name = ref["model"] if isinstance(ref, dict) else ref
        if name not in models:
            errors.append(f"fallback.json: {where} references unknown model '{name}'")

    for entry in fb.get("defaultFallback", []):
        check_model(entry, "defaultFallback")
    for agent, conf in fb.get("agents", {}).items():
        if agent not in agents:
            errors.append(f"fallback.json: agent '{agent}' not in opencode.json")
        for entry in conf.get("fallback", []):
            check_model(entry, f"agents.{agent}.fallback")
        if conf.get("largeContextModel"):
            check_model(conf["largeContextModel"], f"agents.{agent}.largeContextModel")


check_bundles()
check_manifests()
check_fallback()

for w in warnings:
    print(f"warning: {w}")
if errors:
    for e in errors:
        print(f"error: {e}", file=sys.stderr)
    sys.exit(1)
print("registry + fallback OK")
