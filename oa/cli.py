"""oa — bundle-based skill loader for AI coding agents.

DB = registry/{bundles,mcps,plugins}/*.yaml (git-versioned). Bundles union
on `oa use`. Skills resolved from local search roots, synced into every
detected agent's skill dir. Project profiles also sync into project-local
agent dirs so each repo loads only its own bundles. MCPs/plugins with a
`setup` command delegate agent wiring to their own installer.
"""

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
BUNDLES_DIR = REPO_ROOT / "registry" / "bundles"
TOOL_DIRS = {"mcps": REPO_ROOT / "registry" / "mcps", "plugins": REPO_ROOT / "registry" / "plugins"}
# Search order matters: later roots override earlier on name conflict.
SEARCH_ROOTS = [REPO_ROOT / "lazy-skills", REPO_ROOT / "skills" / "global", REPO_ROOT / "skills" / "agents"]

PROJECT_PROFILE = Path.cwd() / ".oa.yaml"
GLOBAL_PROFILE = Path(os.environ.get("OA_HOME", Path.home())) / ".config" / "oa" / "profile.yaml"

# Agent skill dirs, relative to home. Detection = dir exists.
AGENT_TARGETS = {
    "opencode": ".config/opencode/skills",
    "claude": ".claude/skills",
    "cursor": ".cursor/skills",
}
# Project-local agent skill dirs (repo-relative), synced when profile is project-level.
LOCAL_TARGETS = {
    "claude": ".claude/skills",
    "cursor": ".cursor/skills",
}
MANIFEST_NAME = ".oa-manifest.json"  # tracks what oa installed, per target dir


def bundle_data(name):
    f = BUNDLES_DIR / f"{name}.yaml"
    if not f.exists():
        sys.exit(f"error: unknown bundle '{name}'. Run: oa list")
    return yaml.safe_load(f.read_text())


def resolve_items(bundle_names, key):
    """Union of base + bundles for a list field ('skills'|'mcps'|'plugins')."""
    seen, ordered = set(), []
    for name in ["base"] + list(bundle_names):
        for item in bundle_data(name).get(key, []):
            if item not in seen:
                seen.add(item)
                ordered.append(item)
    return ordered


def load_tool(kind, name):
    f = TOOL_DIRS[kind] / f"{name}.yaml"
    if not f.exists():
        sys.exit(f"error: unknown {kind} '{name}' (no registry/{TOOL_DIRS[kind].name}/{name}.yaml)")
    return yaml.safe_load(f.read_text())


def find_skill_dir(name):
    for root in SEARCH_ROOTS:
        d = root / name
        if d.is_dir() and (d / "SKILL.md").exists():
            return d
    return None


def active_bundles():
    """Profile precedence: project file > global profile > base."""
    if PROJECT_PROFILE.exists():
        data = yaml.safe_load(PROJECT_PROFILE.read_text()) or {}
        return data.get("bundles", []), "project"
    if GLOBAL_PROFILE.exists():
        data = yaml.safe_load(GLOBAL_PROFILE.read_text()) or {}
        return data.get("bundles", []), "global"
    return [], "none"


def cmd_list(args):
    bundles = sorted(p.stem for p in BUNDLES_DIR.glob("*.yaml"))
    if args:
        for name in args:
            data = bundle_data(name)
            print(f"{name} ({len(data.get('skills', []))} skills, "
                  f"{len(data.get('mcps', []))} mcps, {len(data.get('plugins', []))} plugins)")
            for s in data.get("skills", []):
                print(f"  skill:  {s}")
            for m in data.get("mcps", []):
                print(f"  mcp:    {m}")
            for p in data.get("plugins", []):
                print(f"  plugin: {p}")
        return
    for name in bundles:
        data = bundle_data(name)
        extras = [f"mcp: {', '.join(data[k])}" for k in ("mcps", "plugins") if data.get(k)]
        suffix = f"  [{' | '.join(extras)}]" if extras else ""
        print(f"{name:12} {data.get('description', '')}{suffix}")


PRUNE_DIRS = {".git", ".venv", "node_modules", "__pycache__", ".idea", ".vscode",
              "lazy-skills", "skills", "vendor", "dist", "build"}


def walk_files(root):
    """Yield files under root, skipping dot-dirs and dependency dirs."""
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if not d.startswith(".") and d not in PRUNE_DIRS]
        for f in filenames:
            yield Path(dirpath) / f


def cmd_detect(_args):
    import fnmatch
    root = Path.cwd()
    hits = set()
    files = list(walk_files(root))
    names = {f.name for f in files}
    exts = {f.suffix for f in files}
    top_dirs = {d.name for d in root.iterdir() if d.is_dir()}

    def has_glob(patterns):
        return any(fnmatch.fnmatch(str(f.relative_to(root)), p) for f in files for p in patterns)

    if "go.mod" in names or ".go" in exts:
        hits.add("backend-go")
    pkg = root / "package.json"
    if pkg.exists():
        text = pkg.read_text(errors="ignore")
        if any(k in text for k in ("react", "vue", "svelte", "next", "vite")):
            hits.add("fullstack")
    if "Dockerfile" in names or has_glob(["docker-compose*.yml", "**/*.tf", ".github/workflows/*"]):
        hits.add("devops")
    if ".bib" in exts or "papers" in top_dirs or "references" in top_dirs:
        hits.add("research")
    if ".ipynb" in exts or "data" in top_dirs and (".csv" in exts or ".parquet" in exts):
        hits.add("data")

    if hits:
        print("suggested bundles: " + " ".join(sorted(hits)))
        print(f"activate: oa use {' '.join(sorted(hits))}")
    else:
        print("no signals found — base bundle only")


def sync_targets(skills, local=False):
    """Copy resolved skills into agent skill dirs. local=True syncs into the
    current repo's .claude/.cursor dirs instead of the global ones."""
    if local:
        targets = {a: Path.cwd() / rel for a, rel in LOCAL_TARGETS.items()}
    else:
        home = Path(os.environ.get("OA_HOME", Path.home()))
        targets = {a: home / rel for a, rel in AGENT_TARGETS.items() if (home / rel).parent.exists()}
    if not targets:
        print("no agent configs found under home (set OA_HOME to override)")
        return

    missing = [s for s in skills if not find_skill_dir(s)]
    resolved = [s for s in skills if find_skill_dir(s)]

    for agent, dest in targets.items():
        dest.mkdir(parents=True, exist_ok=True)
        manifest_path = dest / MANIFEST_NAME
        prev = set(json.loads(manifest_path.read_text())) if manifest_path.exists() else set()
        curr = set(resolved)

        stale = prev - curr
        for name in stale:
            shutil.rmtree(dest / name, ignore_errors=True)
        for name in resolved:
            shutil.copytree(find_skill_dir(name), dest / name, dirs_exist_ok=True)
        manifest_path.write_text(json.dumps(sorted(curr), indent=2))

        print(f"{agent} ({'project' if local else 'global'}): synced {len(curr)} skills, removed {len(stale)}")
    if missing:
        print("warning: not found in search roots: " + ", ".join(missing))


def handle_tools(kind, names, setup=False):
    """Check + optionally wire MCP servers / plugins listed by active bundles."""
    for name in names:
        data = load_tool(kind, name)
        command = data.get("command", name)
        if shutil.which(command) is None:
            print(f"{kind}: {name} — CLI not found. Bootstrap with:")
            print(f"        {data.get('bootstrap', '(no bootstrap command in manifest)')}")
            print(f"        then: {data.get('setup', '(no setup command)')}")
            continue
        if setup and data.get("setup"):
            print(f"{kind}: {name} — running: {data['setup']}")
            subprocess.run(data["setup"], shell=True, check=False)
        else:
            print(f"{kind}: {name} — CLI found. Wire with: {data.get('setup', '')}")


def cmd_use(args):
    bundles = [a for a in args if not a.startswith("-")]
    global_flag = "--global" in args
    setup_tools = "--setup-tools" in args or "--setup-mcps" in args  # latter = legacy alias
    if not bundles:
        sys.exit("usage: oa use <bundle...> [--global] [--setup-tools]")

    for b in bundles:
        bundle_data(b)  # validates

    profile = GLOBAL_PROFILE if global_flag else PROJECT_PROFILE
    profile.parent.mkdir(parents=True, exist_ok=True)
    profile.write_text(yaml.safe_dump({"bundles": bundles}, default_flow_style=False))

    skills = resolve_items(bundles, "skills")
    tools = [(k, resolve_items(bundles, k)) for k in ("mcps", "plugins")]
    n_tools = sum(len(t) for _, t in tools)
    print(f"active: base + {' + '.join(bundles)} -> {len(skills)} skills, {n_tools} tools")
    print(f"profile: {profile}")
    sync_targets(skills, local=not global_flag)
    if global_flag:
        sync_targets(skills, local=False)
    for kind, names in tools:
        if names:
            handle_tools(kind, names, setup=setup_tools)


def cmd_status(_args):
    bundles, source = active_bundles()
    skills = resolve_items(bundles, "skills")
    print(f"bundles: {'base' if not bundles else 'base + ' + ' + '.join(bundles)}")
    print(f"profile: {source}")
    print(f"skills ({len(skills)}):")
    for s in skills:
        loc = find_skill_dir(s)
        mark = "" if loc else "  [MISSING]"
        print(f"  {s}{mark}")
    for kind in ("mcps", "plugins"):
        names = resolve_items(bundles, kind)
        if names:
            print(f"{kind} ({len(names)}):")
            for m in names:
                data = load_tool(kind, m)
                command = data.get("command", m)
                state = "installed" if shutil.which(command) else "NOT INSTALLED"
                print(f"  {m} ({state})")


COMMANDS = {
    "list": cmd_list,
    "detect": cmd_detect,
    "use": cmd_use,
    "status": cmd_status,
}


def main():
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print("usage: oa <list|detect|use|status> [args]")
        print("  oa list [bundle]           show bundles or bundle contents")
        print("  oa detect                  suggest bundles from repo signals")
        print("  oa use B... [--global]     activate bundles, sync skills")
        print("                             project profile -> repo-local sync")
        print("                             --global        -> global profile + sync")
        print("                             --setup-tools   run MCP/plugin installers")
        print("  oa status                  active bundles, skills, mcps, plugins")
        sys.exit(1 if len(sys.argv) < 2 else 0)
    COMMANDS[sys.argv[1]](sys.argv[2:])


if __name__ == "__main__":
    main()
