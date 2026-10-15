# OpenCode Agents - Multi-Provider Agent Suite

A comprehensive agent configuration for [OpenCode](https://opencode.ai) with **cross-provider model fallback**, optimized for scientific research, clean code development, and literature analysis.

## Features

- **Multi-provider resilience** — 3 model providers with automatic fallback for every agent
- **oa bundle system** — per-project skills/MCPs/plugins selected by use case (`oa use backend-go research`)
- **Pantheon Agent Orchestration** — 8 specialized agents via oh-my-opencode-slim (@orchestrator auto-delegates)
- **Cavecrew Subagents** — 3 compressed-output agents for context-efficient delegation
- **Curated Skills** — 100+ skills, synced per project from use-case bundles
- **OpenSpec Workflow** — Structured planning and implementation workflow (auto-installed on dev bundles)
- **Vim-centric TUI** — Vim muscle memory keybinds, plus vim-mode prompt editing
- **Auto-fallback plugin** — Intelligent retry with provider switching
- **Caveman Compression** — 65-75% token savings via globally-loaded caveman skills (always-on, all agents)
- **Large context fallback** — Automatic switch to bigger context models
- **16 agent files** — From coding to research to architecture (including caveman compression)

## Quick Start — Generate Your `.config/opencode`

This repository is a **complete configuration generator** for OpenCode, managed by `oa` (see [docs/OA_SPEC.md](docs/OA_SPEC.md)):

```bash
# 1. Clone and enter the repository
git clone <repo-url> opencode-agents
cd opencode-agents

# 2. Set up your environment (edit with your API keys)
mkdir -p ~/.config/opencode
cp .env.example ~/.config/opencode/.env
# Edit ~/.config/opencode/.env and add your keys

# 3. Deploy global configs + agents (verified)
bin/oa deploy

# 4. Install Pantheon agents (run once)
bunx oh-my-opencode-slim@latest install

# 5. Install plugins (see Plugin Guide below)
# opencode plugin add opencode-plugin-openspec --global
# opencode plugin add opencode-kimi-full --global
# opencode plugin add @zenobius/opencode-skillful --global
# npm install -g opencode-auto-fallback

# 6. Start OpenCode
opencode
```

### Installing `oa` on PATH

The CLI is `bin/oa` inside the repo (it needs the repo — the registry and skill pools live there). Pick one:

```bash
# Option A — symlink into ~/.local/bin (live: git pull updates it)
make install-cli

# Option B — PATH entry in ~/.zshrc instead
export PATH="$HOME/Projects/opencode-agents/bin:$PATH"

# Option C — Homebrew (fresh laptop; published tap)
brew tap cebthedev/oa
brew install oa
```

### New Laptop Bootstrap

```bash
# 1. Get the repo
git clone git@github.com:cebthedev/opencode-agents.git ~/Projects/opencode-agents
cd ~/Projects/opencode-agents
# (or skip the clone entirely: brew tap cebthedev/oa && brew install oa)

# 2. oa on PATH
make install-cli

# 3. Env + deploy + plugins (same as Quick Start)
mkdir -p ~/.config/opencode && cp .env.example ~/.config/opencode/.env
# ...edit .env with your keys...
oa deploy
bunx oh-my-opencode-slim@latest install
npm install -g opencode-auto-fallback
```

Brew notes: the formula lives in the [homebrew-oa](https://github.com/cebthedev/homebrew-oa)
tap and builds from this repo's `main` branch. It installs the whole repo as
a keg (registry, skills, configs included) and vendors PyYAML in a private
venv (there is no Homebrew `pyyaml` formula). Update it with
`brew reinstall oa`. For a private repo, git must be able to fetch the URL.
Option A is better while you're iterating on bundles — a brew keg freezes
until you reinstall.

### Per-Project Setup

Each project loads only the bundles it needs (skills, MCPs, tools — all project-local):

```bash
cd your-project
oa detect                    # suggests bundles from repo signals
oa use backend-go devops     # writes .oa.yaml, syncs skills, renders opencode.json
oa doctor                    # verify the profile end-to-end
```

**Custom per-project config:** `.oa.yaml` is the config — it's a plain file, edit it directly to change bundles, or re-run `oa use`. Anything else you put in the project's `opencode.json` (keybinds, provider tweaks, custom agent defs) is preserved — `oa use` only touches the `mcp` block. Precedence: `./.oa.yaml` > `~/.config/oa/profile.yaml` (written by `oa use --global`) > base.

### Makefile Reference

```bash
make setup              # Create directories and copy .env template
make deploy             # Deploy configs + agents (via oa, verified)
make doctor             # Verify active profile (via oa)
make test-oa            # Run oa end-to-end tests
```

## Prerequisites

- [OpenCode](https://opencode.ai) installed
- Git
- Python 3.8+ (for skill parsing and validation)
- API keys (see `.env.example`)

## Model Providers

This configuration uses **multiple providers** with automatic fallback for maximum resilience:

| Provider | Provider ID | Models | API Key | Fallback Tier |
|----------|-------------|--------|---------|---------------|
| **Kimi OAuth** | `kimi-for-coding-oauth` | K2.7 (k2p7), K2.6 (k2p6), K2.5 (k2p5) with reasoning variants | `MOONSHOT_API_KEY` | Primary |
| **DeepSeek** | `deepseek` (built-in) | Chat, Reasoner | `DEEPSEEK_API_KEY` | Backup |
| **OpenCode** | `opencode` (built-in) | DeepSeek-V4-Flash, MiMo-V2.5, Qwen-3.6, North-Mini, Nemotron-3, MiniMax-M3, Big-Pickle | `OPENAI_API_KEY` | Free |

### Reasoning Variants (Kimi OAuth)

Kimi models support configurable reasoning effort:

| Variant | Use Case |
|---------|----------|
| `off` | Fast responses, no reasoning overhead |
| `auto` | Let the model decide reasoning depth |
| `low` | Quick tasks, simple queries |
| `medium` | Standard development and research (default for most agents) |
| `high` | Deep analysis, architecture review, complex reasoning |

Configure per-agent in the agent markdown frontmatter:
```yaml
model: kimi-for-coding-oauth/k2p7
variant: high  # or medium, low, auto, off
```

## Plugins

Plugins extend OpenCode with additional capabilities. See [`docs/PLUGIN_GUIDE.md`](docs/PLUGIN_GUIDE.md) for detailed installation and configuration instructions.

### Required Plugins

| Plugin | Install Command | Purpose | Check Updates |
|--------|----------------|---------|---------------|
| **opencode-auto-fallback** | `npm install -g opencode-auto-fallback` | Automatic model fallback on errors | `npm outdated -g opencode-auto-fallback` |
| **oh-my-opencode-slim** | `bunx oh-my-opencode-slim@latest install` | Pantheon agent orchestration | [GitHub Releases](https://github.com/HyeokjaeLee/oh-my-opencode-slim/releases) |
| **opencode-plugin-openspec** | `opencode plugin add opencode-plugin-openspec --global` | Structured planning workflow | `opencode plugin list` |
| **opencode-kimi-full** | `opencode plugin add opencode-kimi-full --global` | Enhanced Kimi model support | `opencode plugin list` |
| **@zenobius/opencode-skillful** | `opencode plugin add @zenobius/opencode-skillful --global` | Skill management enhancements | `opencode plugin list` |

### Plugin Update Checklist

Run these commands monthly to check for updates:

```bash
# NPM packages
npm outdated -g opencode-auto-fallback

# OpenCode plugins
opencode plugin list

# oh-my-opencode-slim (check for new releases)
bunx oh-my-opencode-slim@latest --version
```

### Plugin Configuration

Plugin configs are deployed to `~/.config/opencode/`:
- `opencode-auto-fallback` &rarr; `fallback.json`
- `oh-my-opencode-slim` &rarr; `oh-my-opencode-slim.json`
- `opencode-plugin-openspec` &rarr; integrated into agent prompts

## Agents

### Primary Agents (Tab to switch)

| Agent | Description | Model | Variant | Fallback Chain |
|-------|-------------|-------|---------|----------------|
| **build** | Full development with all tools | **Kimi K2.7** | medium | K2.7 &rarr; DeepSeek Chat &rarr; K2.6 &rarr; K2.5 &rarr; Qwen3.6 |
| **research** | Literature research & paper analysis | **Kimi K2.7** | medium | K2.7 &rarr; DeepSeek Chat &rarr; K2.6 &rarr; K2.5 &rarr; Qwen3.6 |
| **plan** | Analysis & planning (no changes) | **Kimi K2.7** | high | K2.7 (high) &rarr; DeepSeek Reasoner &rarr; K2.6 &rarr; K2.5 (high) &rarr; Qwen3.6 |

### Subagents (@ to invoke)

| Agent | Description | Model | Variant | Fallback Chain |
|-------|-------------|-------|---------|----------------|
| **coder** | Complex programming tasks | **Kimi K2.7** | medium | K2.7 &rarr; DeepSeek Chat &rarr; K2.6 &rarr; K2.5 &rarr; Qwen3.6 |
| **clean-coder** | TDD-focused clean code | **Kimi K2.7** | medium | K2.7 &rarr; DeepSeek Chat &rarr; K2.6 &rarr; K2.5 &rarr; Qwen3.6 |
| **code-reviewer** | Quality & security review | **Kimi K2.7** | high | K2.7 (high) &rarr; DeepSeek Chat &rarr; K2.6 &rarr; K2.5 (high) &rarr; Qwen3.6 |
| **beagle** | Web research & fact-checking | **MiMo-V2.5** | — | DeepSeek Chat &rarr; K2.7 (low) &rarr; MiMo-V2.5 |
| **paper-analyst** | Download & analyze papers | **DeepSeek Chat** | — | K2.7 &rarr; DeepSeek Chat &rarr; K2.6 &rarr; Qwen3.6 |
| **researcher** | Deep literature research | **Kimi K2.7** | high | K2.7 (high) &rarr; DeepSeek Chat &rarr; K2.6 &rarr; K2.5 (high) &rarr; Qwen3.6 |
| **architect** | Solution architecture | **DeepSeek Reasoner** | — | K2.7 (high) &rarr; DeepSeek Reasoner &rarr; K2.6 &rarr; K2.5 (high) |
| **writer** | Multilingual writing | **Kimi K2.7** | — | K2.7 &rarr; DeepSeek Chat &rarr; MiMo-V2.5 |
| **data-scientist** | Data analysis & visualization | **DeepSeek Reasoner** | — | K2.7 (high) &rarr; DeepSeek Chat &rarr; K2.6 &rarr; K2.5 (high) |

> **Note**: Model paths use `kimi-for-coding-oauth/k2p7` for Kimi models (OAuth provider) and built-in prefixes (`opencode/`, `deepseek/`) for others.

### Cavecrew Subagents (@cavecrew to invoke)

Compressed-output subagents that return ~60% smaller responses, preserving context in long sessions. Cavecrew agents speak caveman-style by default.

| Agent | Role | Trigger |
|-------|------|---------|
| **@cavecrew-investigator** | Locate code, find files, grep codebase | "find where X is defined" |
| **@cavecrew-builder** | 1-2 file scoped edits | "fix this bug in file Y" |
| **@cavecrew-reviewer** | Diff review, one-line comments | "review this PR" |

Use cavecrew when: main context is running long, or you need fast reconnaissance without verbose output. Main thread output stays caveman-compressed.

## Agent Orchestration

Primary agents can delegate to subagents:

- **build** &rarr; `clean-coder`, `code-reviewer`, `beagle`, `architect`, `writer`, `cavecrew-builder`, `cavecrew-investigator`
- **research** &rarr; `beagle`, `paper-analyst`, `researcher`, `data-scientist`, `writer`, `cavecrew-investigator`
- **plan** &rarr; `architect`, `beagle`, `cavecrew-investigator`

## Pantheon Agents (via oh-my-opencode-slim)

The Pantheon provides 8 specialized agents that auto-delegate via **@orchestrator**:

| Agent | Role | When to Use |
|-------|------|-------------|
| **@orchestrator** | Master delegator | Complex multi-step tasks requiring coordination |
| **@explorer** | Codebase reconnaissance | Deep codebase exploration and understanding |
| **@oracle** | Strategic advisor | Architecture decisions, hard debugging, trade-offs |
| **@council** | Multi-LLM consensus | When you need diverse perspectives |
| **@librarian** | Knowledge retrieval | Documentation lookup and research |
| **@designer** | UI/UX implementation | Frontend and visual work |
| **@fixer** | Fast implementation | Routine, scoped coding tasks |
| **@observer** | Visual analysis | Images, screenshots, PDFs |

### Pantheon Usage

```bash
# Orchestrator auto-delegates based on task
@orchestrator implement user authentication

# Manual delegation to specific agents
@explorer analyze this codebase structure
@oracle compare microservices vs monolith
@council evaluate these two approaches
```

### Presets

Switch between model presets at runtime:
```bash
/preset              # Show available presets
/preset custom       # Use custom preset (kimi/deepseek/gemini)
```

## Auto-Fallback Plugin

The `opencode-auto-fallback` plugin provides automatic model switching when APIs fail.

### How It Works

```
Primary model fails (rate limit, quota, error)
  &rarr; Retry with exponential backoff (2s &rarr; 4s &rarr; 8s)
  &rarr; If still failing &rarr; try fallback_models[0]
    &rarr; If that fails &rarr; fallback_models[1] &rarr; ...
      &rarr; All exhausted &rarr; surface error to user
```

### Features

- **Two-tier error handling** — Immediate fallback for auth/quota, backoff retry for transient errors
- **Per-agent chains** — Each agent has its own ordered fallback list
- **Provider diversity** — Falls back to different providers, not just different models
- **Cooldown & recovery** — Failed models enter cooldown (30s default), auto-switch back when recovered
- **Large context fallback** — Automatically switches to bigger context models when window fills up
- **TTFT timeout** — Aborts hung models, never interrupts actively streaming ones

### Configuration

Plugin config is in `config/fallback.json`:

```json
{
  "enabled": true,
  "cooldownMs": 30000,
  "maxRetries": 1,
  "logging": true
}
```

| Setting | Default | Description |
|---------|---------|-------------|
| `cooldownMs` | 30000 | Cooldown after failure (30s for rate limits) |
| `maxRetries` | 1 | Backoff retries before fallback chain |
| `logging` | true | Log fallback events to `~/.local/share/opencode/log/fallback.log` |

## TUI Configuration

Vim-centric keybinds optimized for tmux users. Config in `config/tui.json`.

### Message Buffer Scrolling (Vim Muscle Memory)

| Action | Key | Vim Equivalent |
|--------|-----|----------------|
| Half page down | `ctrl+d` | `^D` |
| Half page up | `ctrl+u` | `^U` |
| Line down | `ctrl+e` | `^E` |
| Line up | `ctrl+y` | `^Y` |
| Page down | `pagedown`, `ctrl+f` | `^F` |
| Page up | `pageup`, `alt+b` | `^B` (tmux-safe) |
| Go to bottom | `ctrl+shift+g`, `end` | `G` |
| Go to top | `ctrl+g`, `home` | `gg` |

### Session Management

| Action | Key |
|--------|-----|
| New session | `<leader>n` |
| List sessions | `<leader>l` |
| Compact session | `<leader>c` |
| Export session | `<leader>x` |
| Interrupt | `escape` |

### Agent & Model

| Action | Key |
|--------|-----|
| Cycle agents | `tab` / `shift+tab` |
| List agents | `<leader>a` |
| List models | `<leader>m` |
| Cycle recent models | `f2` / `shift+f2` |

### Tips

| Action | Key |
|--------|-----|
| Toggle tips | `<leader>?` |

> **Context-aware behavior**: Scroll keys (`ctrl+d/u`) work in the message buffer. In the input box, they retain their original meanings. OpenCode handles this automatically.

## MCP Servers

MCP servers are **assigned per bundle** (manifests in `registry/mcps/`) and rendered into each project's `opencode.json` by `oa use`. The table below shows the full registry:

| MCP | Purpose | Bundle(s) | Status Check |
|-----|---------|-----------|-------------|
| **lsp** | Language server protocol (Go, TS, Python, Rust, C/C++) | backend-go, fullstack | `lsp_get_server_capabilities` |
| **google-search** | Web search capabilities | research | Search via agent prompt |
| **sequential-thinking** | Structured reasoning | base | Automatic on complex tasks |
| **fetch** | Web content fetching | research | `fetch_fetch url="..."` |
| **aidex** | Code indexing and search | backend-go, fullstack, devops | `aidex_aidex_query term="..."` |
| **context7** | Documentation search | all dev + research | `context7_query_docs libraryId="..."` |
| **jupyter** | Jupyter notebook integration | research, data | `jupyter_execute_code code="..."` |
| **arxiv-mcp-server** | Academic paper search, download, analysis | research | `search_papers`, `download_paper`, `read_paper` |
| **github** | Repository management | backend-go, fullstack, devops | `github_search_repositories query="..."` |
| **filesystem** | Enhanced file operations | unassigned (enable per project) | `filesystem_read_text_file path="..."` |
| **sqlite** | Database queries | data | `sqlite_read_query query="..."` |
| **codegraph** | Semantic code graph, surgical context | backend-go, fullstack, devops | `codegraph_explore` |

> A project only loads the MCPs of its active bundles — keeping tool schemas small per session.

### MCP Usage Examples

#### LSP (Language Server Protocol)
```bash
# Check active servers
lsp_get_server_capabilities

# Go to definition
lsp_go_to_definition file_path="src/main.py" line=10 column=5

# Get diagnostics
lsp_get_diagnostics file_path="src/main.py"

# Format document
lsp_format_document file_path="src/main.py"
```

#### AiDex (Code Index)
```bash
# Search codebase
aidex_aidex_query term="UserService" path="/project"

# Get file signature without reading
aidex_aidex_signature file="src/services/user.py" path="/project"

# Update index after changes
aidex_aidex_update file="src/services/user.py" path="/project"
```

#### Jupyter
```bash
# Execute Python code
jupyter_execute_code code="import pandas as pd; df.head()"

# Run notebook cell
jupyter_execute_cell cell_index=0 notebook_name="analysis"
```

#### GitHub
```bash
# Search repos
github_search_repositories query="language:python machine learning"

# Get PR details
github_get_pull_request owner="owner" repo="repo" pull_number=42

# Create issue
github_create_issue owner="owner" repo="repo" title="Bug" body="Details..."
```

#### arXiv MCP Server
```bash
# Search papers
search_papers query="transformer architectures" max_results=10

# Download paper
download_paper paper_id="2401.12345"

# Read paper
read_paper paper_id="2401.12345"

# List downloaded papers
list_papers
```

#### Fetch
```bash
# Extract web content
fetch_fetch url="https://example.com" max_length=5000
```

## Skills

Skills are grouped into **bundles** (`registry/bundles/`) and synced per project by `oa use` into `.claude/skills` and `.cursor/skills`. Source trees:

**`lazy-skills/`** (100+ curated skills) — the skill pool bundles draw from:
- Research & papers (arxiv-to-md, perplexity-search, literature-review, peer-review)
- Machine learning (scikit-learn, pytorch, transformers, stable-baselines3)
- Data engineering (polars, dask, vaex, zarr-python)
- Visualization (matplotlib, seaborn, plotly, infographics)
- OpenSpec workflow skills (openspec-explore, openspec-new-change, etc.)
- And many more...

**`skills/global/`** (13 skills) — always included via the `base` bundle:
- caveman — Token compression (always-on, all agents)
- caveman-commit / caveman-review / caveman-compress / caveman-stats / caveman-help
- cavecrew — Subagent delegation guide
- deepthink — Structured reasoning
- python-design-patterns, python-qa, software-architecture
- decision-critic, content-humanizer

### Using Skills

Agents read skills from the project's `.claude/skills` / `.cursor/skills` (synced by `oa use`). To give a project a skill, add it to the relevant bundle and re-run `oa use`:

```yaml
# registry/bundles/research.yaml
skills:
  - literature-review
  - your-new-skill   # <- add here
```

`make validate` fails if a bundle references a skill that doesn't exist.

### Skill Bundles (oa)

Skills, MCPs, plugins, and subagents are grouped into use-case bundles:
```
registry/
├── bundles/    # base, backend-go, fullstack, devops, research, data, openspec
├── mcps/       # MCP server manifests (13, incl. opt-in filesystem)
└── plugins/    # CLI tools/plugins (opencode-vim, openspec)
```
Activate per project with `bin/oa use <bundle...>` — it writes `.oa.yaml`,
syncs skills into project-local agent dirs, and renders the repo's
`opencode.json` mcp block. See `oa list` / `oa detect` / `oa status`.

## Caveman Compression (Always-On)

All agents use **caveman-style communication** by default. This cuts ~65-75% of output tokens while keeping full technical accuracy. No command needed — it's always active.

### Caveman Sub-Skills

| Skill | Command | Purpose |
|---|---|---|
| **caveman** | (always on) | Compress all agent output to terse, accurate prose |
| **caveman-commit** | `/caveman-commit` | Conventional Commits, &le;50 char subject. Why over what. |
| **caveman-review** | `/caveman-review` | One-line PR comments: `L42: bug: user null. Add guard.` |
| **caveman-compress** | `/caveman-compress <file>` | Rewrite memory files to caveman-speak. Cuts ~46% input tokens. |
| **caveman-stats** | `/caveman-stats` | Session token usage + lifetime savings + USD. |
| **caveman-help** | `/caveman-help` | Quick reference card for all caveman modes. |

### Caveman Intensity Levels

| Level | Style |
|---|---|
| **lite** | No filler/hedging. Keep articles. Professional but tight. |
| **full** | Drop articles, fragments OK. Classic caveman. Default. |
| **ultra** | Maximum compression. Abbreviate prose words. |
| **wenyan-lite** | Semi-classical Chinese. |
| **wenyan-full** | Maximum classical terseness. |
| **wenyan-ultra** | Extreme abbreviation, classical Chinese feel. |

Auto-clarity: caveman temporarily pauses for security warnings, irreversible actions, or when user asks for clarification. Resumes after.

## OpenSpec Workflow (via opencode-plugin-openspec)

Structured workflow for planning and implementation. The `openspec` bundle
ships the full lifecycle (14 skills); dev bundles (backend-go, devops,
fullstack) include the core loop automatically:

```bash
oa use openspec        # full lifecycle + intent-driven extras, per project
openspec init          # required: activates the plugin's openspec-plan agent
```

Core loop:

```bash
# 1. Explore and clarify requirements
openspec-explore

# 2. Create structured change plan
openspec-new-change

# 3. Implement step-by-step
openspec-apply-change

# 4. Validate against specs
openspec-verify-change

# 5. Resume existing work
openspec-continue-change
```

Intent-driven extras (in the `openspec` bundle, per
[intent-driven.dev](https://intent-driven.dev/blog/2026/05/10/spec-driven-development-openspec-opencode/)):

- **grill-me** — interrogate the plan one question at a time before proposal
- **c4-diagrams** — architecture diagrams (ASCII/Mermaid) before detailed design
- **openspec-git-discipline** — every state change crosses `main` before the next phase
- **openspec-bulk-apply-change** — parallel apply in isolated worktrees

The `intent-driven` schema (proposal → specs → design → adr → tasks) is
vendored at `openspec-schemas/intent-driven/` — copy it into a project's
`openspec/schemas/` and select it in `openspec/config.yaml`. See
[docs/PLUGIN_GUIDE.md](docs/PLUGIN_GUIDE.md) for the full setup.

Note: the plugin only registers its `openspec-plan` agent in projects that
have been `openspec init`'d (it detects `openspec/config.yaml`).

## Configuration

### Environment Variables

Copy `.env.example` to `~/.config/opencode/.env` and configure:

```bash
# Required
OPENAI_API_KEY=your-opencodego-key
MOONSHOT_API_KEY=your-moonshot-key
DEEPSEEK_API_KEY=your-deepseek-key

# Optional
GITHUB_TOKEN=your-github-token
GOOGLE_API_KEY=your-google-key
GOOGLE_SEARCH_ENGINE_ID=your-search-engine-id
```

### Agent Configuration

Agents are defined in markdown files with YAML frontmatter:

```markdown
---
description: Agent description
mode: primary|subagent
model: provider/model-id
fallback_models:
  - provider/fallback-model-1
  - provider/fallback-model-2
temperature: 0.7
permission:
  read: allow
  edit: allow
  bash: allow
---

Agent instructions here...
```

## Commands

```bash
# oa (per-project + deploy)
bin/oa list [bundle]     # show bundles or bundle contents
bin/oa detect            # suggest bundles from repo signals
bin/oa use B... [--global] [--setup-tools]  # activate bundles, sync skills, render opencode.json
bin/oa status            # active bundles, skills, agents, mcps, plugins
bin/oa deploy            # deploy configs + agents to ~/.config/opencode (verified)
bin/oa doctor            # verify active profile end-to-end

# make
make all                # Full setup and deployment
make setup              # Create directories
make deploy             # Deploy configuration files (via oa)
make doctor             # Verify active profile (via oa)
make agents             # Deploy agent configurations
make plugins            # Show plugin installation commands
make install            # Full installation with next steps
make validate           # Lint registry + fallback coverage + validate configs
make test-oa            # Run oa end-to-end tests (tests/test_oa.py)
make test-skills        # Validate all skill YAML frontmatter and structure
make test-skill NAME=... # Test a specific skill
make clean              # Remove deployed configs
make help               # Show all targets
```

Global skill deployment (alternative to per-project `oa use`):
```bash
make skills-deploy      # Deploy all skills (lazy-skills + global)
make lazy-skills-deploy # Deploy lazy-loaded skills only
make global-skills-deploy # Deploy globally loaded skills only
make caveman-deploy     # Deploy caveman skills only
```

## Project Structure

```
opencode-agents/
├── Makefile                          # Main orchestrator
├── README.md                         # This file
├── VERSION                           # Version tag (1.0.0)
├── .env.example                      # API key template
├── logo.svg                          # Project logo
├── bin/
│   └── oa                            # Bundle-based skill/MCP loader (CLI)
├── oa/
│   └── cli.py                        # oa implementation
├── registry/                         # oa DB: bundles, MCP + plugin manifests
│   ├── bundles/                      # base, backend-go, fullstack, devops, research, data, openspec
│   ├── mcps/                         # 13 MCP server manifests
│   └── plugins/                      # opencode-vim, openspec, codegraph
├── lazy-skills/                      # 100+ curated on-demand skills
├── skills/
│   └── global/                       # Always-loaded skills (caveman family)
├── agents/                           # 15 agent definitions
│   ├── build.md                      # Primary: Development
│   ├── research.md                   # Primary: Research
│   ├── plan.md                       # Primary: Planning
│   ├── coder.md                      # Subagent: Coding
│   ├── clean-coder.md                # Subagent: TDD
│   ├── code-reviewer.md              # Subagent: Review
│   ├── beagle.md                     # Subagent: Research
│   ├── paper-analyst.md              # Subagent: Papers
│   ├── researcher.md                 # Subagent: Literature
│   ├── architect.md                  # Subagent: Architecture
│   ├── writer.md                     # Subagent: Writing
│   ├── data-scientist.md             # Subagent: Data Science
│   └── cavecrew/                     # Subagent: Compressed delegation
│       ├── cavecrew-builder.md
│       ├── cavecrew-investigator.md
│       └── cavecrew-reviewer.md
├── config/
│   ├── opencode.json                 # Main configuration
│   ├── tui.json                      # TUI keybinds
│   ├── fallback.json                 # Auto-fallback plugin config (all agents)
│   └── oh-my-opencode-slim.json      # Pantheon agent presets
├── docs/
│   └── PLUGIN_GUIDE.md               # Detailed plugin setup guide
└── scripts/
    ├── deploy.sh                     # Deploy configs to ~/.config/opencode/
    ├── test-skill.sh                 # Test a specific skill
    ├── test-skills.sh                # Test all skills
    ├── substitute_env_in_json.py     # JSON env substitution
    ├── validate-registry.py          # Lint registry + fallback coverage
    └── validate-skills-yaml.py       # YAML validation
```

## Usage Examples

### Switch to Research Agent
Press `Tab` to cycle through primary agents, or:
```
@research
```

### Invoke Subagent
```
@paper-analyst analyze https://arxiv.org/abs/2401.12345
```

### Research Workflow
```
# Start research agent
@research

# Ask to find papers
Find recent papers on transformer architectures

# Delegate to paper analyst
@paper-analyst analyze the top 3 papers

# Get code examples
@coder implement the approach from paper #2
```

### Coding Workflow
```
# Start build agent (default)

# Write feature
Implement a caching layer for the API

# Get review
@code-reviewer review the changes

# Refactor
@clean-coder refactor for testability
```

### Using Cavecrew for Long Sessions
```
# When context gets long, delegate to cavecrew
@cavecrew-investigator find all references to UserService
@cavecrew-builder fix the null pointer in src/auth.ts
@cavecrew-reviewer review the diff in PR #42
```

## Updating

```bash
git pull                # Update this repository
make deploy             # Re-deploy configs (verified by oa)
bin/oa use <bundles>    # Re-sync any project whose bundles changed
```

## Troubleshooting

### Agents not loading
1. Check `~/.config/opencode/agents/` exists
2. Verify markdown files have proper frontmatter (starts with `---`)
3. Run `make test` to validate

### MCP not connecting
1. Check if MCP command is installed: `which npx`, `which uvx`
2. Verify API keys in `~/.config/opencode/.env`
3. Check OpenCode logs: `~/.local/share/opencode/log/mcp.log`

### Model fallback triggered constantly
1. Check `~/.local/share/opencode/log/fallback.log` for fallback events
2. Verify API keys for all providers in `~/.config/opencode/.env`
3. Check if a provider is in cooldown (30s default)

### Skills not found
1. Run `bin/oa status` in your project to see the active bundles
2. Check the project has `.oa.yaml` (run `bin/oa detect` then `bin/oa use <bundles>`)
3. Verify skills synced into the project's `.claude/skills` / `.cursor/skills`

### Can't scroll in message buffer
1. Use `ctrl+d` / `ctrl+u` for half-page scrolling (Vim-style)
2. Use `ctrl+shift+g` to jump to bottom instantly
3. Check `config/tui.json` is deployed to `~/.config/opencode/tui.json`

## Contributing

This is a personal configuration optimized for:
- Scientific literature research
- Clean code development (Python, Rust, Go)
- Paper analysis and downloading
- Data science workflows

Feel free to adapt the agents and models to your needs!

## License

MIT - See LICENSE file for details
