# OpenCode Agents - Multi-Provider Agent Suite

A comprehensive agent configuration for [OpenCode](https://opencode.ai) with **cross-provider model fallback**, optimized for scientific research, clean code development, and literature analysis.

## Features

- **Multi-provider resilience** — 4 model providers with automatic fallback
- **Pantheon Agent Orchestration** — 8 specialized agents via oh-my-opencode-slim (@orchestrator auto-delegates)
- **Lazy-Loaded Skills** — 220+ skills on-demand via skill_find/skill_use
- **OpenSpec Workflow** — Structured planning and implementation workflow
- **Vim-centric TUI** — Vim muscle memory keybinds for comfortable scrolling
- **Auto-fallback plugin** — Intelligent retry with provider switching
- **Large context fallback** — Automatic switch to bigger context models
- **12 specialized agents** — From coding to research to architecture

## Quick Start

```bash
# Full installation (deploys configs, skills, agents)
make all

# Install Pantheon agents (run once)
bunx oh-my-opencode-slim@latest install

# Or step by step
make setup              # Create directories
make skills-deploy      # Deploy lazy-loaded and global skills
make agents             # Deploy agent configurations
make deploy             # Deploy configuration files
make plugins            # Show plugin installation commands
```

## Prerequisites

- [OpenCode](https://opencode.ai) installed
- Git
- Python 3.8+ (for skill parsing)
- API keys (see `.env.example`)

## Model Providers

This configuration uses **4 model providers** for maximum resilience:

| Provider | Models | API Key | Tier |
|----------|--------|---------|------|
| **Moonshot AI** | Kimi K2.6, Kimi K2.5 | `MOONSHOT_API_KEY` | Free |
| **Google AI Studio** | Gemini 2.5 Pro/Flash, 1.5 Pro/Flash | `GEMINI_API_KEY` | **Free** |
| **DeepSeek** | DeepSeek Chat, DeepSeek Reasoner | `DEEPSEEK_API_KEY` | **Free** |
| **OpenCodeGo** | GLM-5, GLM-5.1, Qwen, DeepSeek | `OPENAI_API_KEY` | Free |

## Agents

### Primary Agents (Tab to switch)

| Agent | Description | Model | Fallback Chain |
|-------|-------------|-------|----------------|
| **build** | Full development with all tools | **Kimi K2.6** | Gemini → DeepSeek → GLM-5.1 |
| **research** | Literature research & paper analysis | **Kimi K2.6** | Gemini → DeepSeek → GLM-5.1 |
| **plan** | Analysis & planning (no changes) | **Gemini 2.5 Pro** | DeepSeek → GLM-5 → Kimi |

### Subagents (@ to invoke)

| Agent | Description | Model | Fallback Chain |
|-------|-------------|-------|----------------|
| **coder** | Complex programming tasks | **Kimi K2.6** | Gemini → DeepSeek → GLM-5.1 |
| **clean-coder** | TDD-focused clean code | Kimi K2.6 | GLM-5.1 → Gemini |
| **code-reviewer** | Quality & security review | Kimi K2.6 | GLM-5.1 → Gemini |
| **beagle** | Web research & fact-checking | **Gemini 2.5 Flash** | Kimi → GLM-5.1 |
| **paper-analyst** | Download & analyze papers | **DeepSeek Chat** | Kimi → Gemini → DeepSeek-v4 |
| **researcher** | Deep literature research | Kimi K2.6 | Gemini → DeepSeek |
| **architect** | Solution architecture | **Gemini 2.5 Pro** | DeepSeek → GLM-5 → Kimi |
| **writer** | Multilingual writing | **Gemini 2.5 Pro** | GLM-5 → Kimi |
| **data-scientist** | Data analysis & visualization | **DeepSeek Reasoner** | Gemini → Qwen → Kimi |

## Agent Orchestration

Primary agents can delegate to subagents:

- **build** → `clean-coder`, `code-reviewer`, `beagle`, `architect`, `writer`
- **research** → `beagle`, `paper-analyst`, `researcher`, `data-scientist`, `writer`
- **plan** → `architect`, `beagle`

## Auto-Fallback Plugin

The `opencode-auto-fallback` plugin provides automatic model switching when APIs fail.

### How It Works

```
Primary model fails (rate limit, quota, error)
  → Retry with exponential backoff (2s → 4s → 8s)
  → If still failing → try fallback_models[0]
    → If that fails → fallback_models[1] → ...
      → All exhausted → surface error to user
```

### Features

- **Two-tier error handling** — Immediate fallback for auth/quota, backoff retry for transient errors
- **Per-agent chains** — Each agent has its own ordered fallback list
- **Provider diversity** — Falls back to different providers, not just different models
- **Cooldown & recovery** — Failed models enter cooldown, auto-switch back when recovered
- **Large context fallback** — Automatically switches to bigger context models when window fills up
- **TTFT timeout** — Aborts hung models, never interrupts actively streaming ones

### Configuration

Plugin config is in `config/fallback.json`:

```json
{
  "enabled": true,
  "cooldownMs": 120000,
  "maxRetries": 3,
  "logging": true,
  "largeContextFallback": {
    "agents": ["build", "coder", "research", "clean-coder", "paper-analyst"],
    "model": "deepseek/deepseek-chat"
  }
}
```

| Setting | Default | Description |
|---------|---------|-------------|
| `cooldownMs` | 120000 | Cooldown after failure (2 min for rate limits) |
| `maxRetries` | 3 | Backoff retries before fallback chain |
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

| MCP | Purpose | Status Check |
|-----|---------|-------------|
| **lsp** | Language server protocol (Go, TS, Python, Rust, C/C++) | `lsp_get_server_capabilities` |
| **google-search** | Web search capabilities | Search via agent prompt |
| **sequential-thinking** | Structured reasoning | Automatic on complex tasks |
| **fetch** | Web content fetching | `fetch_fetch url="..."` |
| **aidex** | Code indexing and search | `aidex_aidex_query term="..."` |
| **context7** | Documentation search | `context7_query_docs libraryId="..."` |
| **jupyter** | Jupyter notebook integration | `jupyter_execute_code code="..."` |
| **arxiv-mcp-server** | Academic paper search, download, analysis | `search_papers`, `download_paper`, `read_paper` |
| **github** | Repository management | `github_search_repositories query="..."` |
| **filesystem** | Enhanced file operations | `filesystem_read_text_file path="..."` |
| **sqlite** | Database queries | `sqlite_read_query query="..."` |

### MCP Usage Examples

#### LSP (Language Server Protocol)
```bash
# Check active servers
lsp_get_server_capabilities

# Go to definition
lsp_go_to_definition file="src/main.py" line=10 column=5

# Get diagnostics
lsp_get_diagnostics file="src/main.py"

# Format document
lsp_format_document file="src/main.py"
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

### Lazy-Loaded Skills (219 skills)

Skills are organized into **lazy-loaded** (on-demand) and **globally loaded** (always available):

**`lazy-skills/`** (219 skills) — Loaded on-demand via `skill_find` and `skill_use`:
- Scientific computing (bioinformatics, chemistry, astronomy)
- Data analysis (pandas, polars, dask, vaex)
- Machine learning (scikit-learn, pytorch, transformers)
- Visualization (matplotlib, seaborn, plotly)
- OpenSpec workflow skills (openspec-explore, openspec-new-change, etc.)
- And many more...

**`skills/global/`** (6 skills) — Always loaded:
- deepthink — Structured reasoning
- python-design-patterns — Architecture patterns
- python-qa — Code quality
- software-architecture — Design decisions
- decision-critic — Validation
- content-humanizer — Writing style

### Using Skills

Agents discover and load skills automatically:

```bash
# Find skills by keyword
skill_find('data visualization')

# Load specific skills
skill_use(['seaborn', 'matplotlib'])

# Read files from a skill
skill_resource('python-design-patterns', 'SKILL.md')
```

### Skill Registry

The registry maps skills to agents by category:
```
skills/registry.json
```

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

### Usage

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

## OpenSpec Workflow (via opencode-plugin-openspec)

Structured workflow for planning and implementation:

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

## Configuration

### Environment Variables

Copy `.env.example` to `~/.config/opencode/.env` and configure:

```bash
# Required
OPENAI_API_KEY=your-opencodego-key
MOONSHOT_API_KEY=your-moonshot-key
GEMINI_API_KEY=your-gemini-key
DEEPSEEK_API_KEY=your-deepseek-key

# Optional
GITHUB_TOKEN=your-github-token
GOOGLE_API_KEY=your-google-key
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
make all                # Full setup and deployment
make setup              # Create directories
make skills-deploy      # Deploy lazy-loaded and global skills
make lazy-skills-deploy # Deploy lazy-loaded skills only
make global-skills-deploy # Deploy global skills only
make agents             # Deploy agent configurations
make deploy             # Deploy configuration files
make plugins            # Show plugin installation commands
make install            # Full installation with next steps
make validate           # Validate all JSON configs
make test               # Validate configuration
make clean              # Remove deployed configs
make help               # Show all targets
```

## Project Structure

```
opencode-agents/
├── Makefile                          # Main orchestrator
├── README.md                         # This file
├── .env.example                      # API key template
├── lazy-skills/                      # 219 lazy-loaded skills
├── skills/
│   ├── global/                       # 6 always-loaded skills
│   └── registry.json                 # Skill-to-agent mappings
├── agents/                           # 12 agent definitions
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
│   └── data-scientist.md             # Subagent: Data Science
├── config/
│   ├── opencode.json                 # Main configuration
│   ├── tui.json                      # TUI keybinds
│   ├── fallback.json                 # Auto-fallback plugin config
│   └── oh-my-opencode-slim.json      # Pantheon agent presets
├── scripts/
│   └── deploy.sh                     # Deploy configs to ~/.config/opencode/
└── lazy.config.json                  # Lazy-loading configuration
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

## Updating

Update submodules:
```bash
make submodules
make skills
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
3. Check if a provider is in cooldown (2 min default)

### Skills not found
1. Run `make skills-deploy` to deploy skills
2. Check `~/.config/opencode/lazy-skills/` exists
3. Verify `lazy.config.json` is deployed to `~/.config/opencode/lazy.config.json`

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
