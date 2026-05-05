# OpenCode Agents - Research & Clean Code Suite

A comprehensive agent configuration for [OpenCode](https://opencode.ai) optimized for scientific research, clean code development, and literature analysis.

## Quick Start

```bash
# Full installation
make all

# Or step by step
make setup    # Initialize submodule and directories
make skills   # Parse and clone skill repositories
make agents   # Deploy agent configurations
make deploy   # Deploy main configuration
```

## Prerequisites

- [OpenCode](https://opencode.ai) installed
- Git
- Python 3.8+ (for skill parsing)
- API keys (see `.env.example`)

## Model Providers

This configuration uses multiple model providers:

| Provider | Models | API Key |
|----------|--------|---------|
| **OpenCodeGo** | GLM-5, GLM-5.1, Kimi K2.5/2.6, MiMo, MiniMax, Qwen, DeepSeek | `OPENAI_API_KEY` |
| **Moonshot AI** | Kimi K2.6, Kimi K2.5 (direct) | `MOONSHOT_API_KEY` |

## Agents

### Primary Agents (Tab to switch)

| Agent | Description | Model | Temperature |
|-------|-------------|-------|-------------|
| **build** | Full development with all tools | GLM-5.1 | 0.7 |
| **research** | Literature research & paper analysis | Kimi K2.6 | 0.8 |
| **plan** | Analysis & planning (no changes) | GLM-5 | 0.1 |

### Subagents (@ to invoke)

| Agent | Description | Model | Temperature |
|-------|-------------|-------|-------------|
| **coder** | Complex programming tasks | GLM-5.1 | 0.7 |
| **clean-coder** | TDD-focused clean code | Kimi K2.6 | 0.6 |
| **code-reviewer** | Quality & security review | Kimi K2.6 | 0.5 |
| **beagle** | Web research & fact-checking | GLM-5.1 | 0.8 |
| **paper-analyst** | Download & analyze papers | DeepSeek V4 Pro | 0.7 |
| **researcher** | Deep literature research | Kimi K2.6 | 0.8 |
| **architect** | Solution architecture | GLM-5 | 0.8 |
| **writer** | Multilingual writing | GLM-5 | 1.0 |
| **data-scientist** | Data analysis & visualization | Qwen 3.6 Plus | 0.7 |

## Agent Orchestration

Primary agents can delegate to subagents:

- **build** → `clean-coder`, `code-reviewer`, `beagle`, `architect`, `writer`
- **research** → `beagle`, `paper-analyst`, `researcher`, `data-scientist`, `writer`
- **plan** → `architect`, `beagle`

## MCP Servers

| MCP | Purpose |
|-----|---------|
| **lsp** | Language server protocol (Python, Go, Rust, TypeScript, C/C++) |
| **google-search** | Web search capabilities |
| **sequential-thinking** | Structured reasoning |
| **fetch** | Web content fetching |
| **aidex** | Code indexing and search |
| **context7** | Documentation search |
| **jupyter** | Jupyter notebook integration |
| **webresearch** | Advanced web research |
| **github** | Repository management |
| **filesystem** | Enhanced file operations |
| **sqlite** | Database queries |

## Skills

Skills are automatically parsed from [awesome-agent-skills](https://github.com/kodustech/awesome-agent-skills) and integrated with your existing `~/.claude/skills/`.

### Skill Categories

- Frontend Development
- Backend Development
- DevOps
- Testing & QA
- Security
- Observability
- Performance
- Mobile Development
- Blockchain
- Infrastructure
- Data Science
- AI/ML
- Tooling
- Code Review

### Skill Registry

After running `make skills`, a searchable registry is created at:
```
~/.config/opencode/skills/registry.json
```

## Configuration

### Environment Variables

Copy `.env.example` to `~/.config/opencode/.env` and configure:

```bash
# Required
OPENAI_API_KEY=your-opencodego-key
MOONSHOT_API_KEY=your-moonshot-key

# Optional
GITHUB_TOKEN=your-github-token
GOOGLE_API_KEY=your-google-key
PERPLEXITY_API_KEY=your-perplexity-key
```

### Agent Configuration

Agents are defined in markdown files with YAML frontmatter:

```markdown
---
description: Agent description
mode: primary|subagent
model: provider/model-id
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
make all        # Full setup and deployment
make setup      # Initialize submodule and directories
make skills     # Parse and clone skills
make agents     # Deploy agents
make deploy     # Deploy configuration
make install    # Full installation with next steps
make test       # Validate configuration
make clean      # Remove deployed configs
make update     # Update awesome-agent-skills submodule
make help       # Show all targets
```

## Project Structure

```
opencode-agents/
├── Makefile                          # Main orchestrator
├── README.md                         # This file
├── .env.example                      # API key template
├── .gitmodules                       # Git submodule config
├── awesome-agent-skills/             # Git submodule (skills list)
├── agents/                           # Agent definitions
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
│   └── opencode.json                 # Main configuration
└── scripts/
    ├── setup-skills.sh               # Parse & clone skills
    └── deploy.sh                     # Deploy configs
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

Update the awesome-agent-skills submodule:
```bash
make update
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
3. Check opencode logs for errors

### Skills not found
1. Run `make skills` to parse and clone
2. Check `~/.config/opencode/skills/registry.json`
3. Verify Python 3.8+ is installed

## Contributing

This is a personal configuration optimized for:
- Scientific literature research
- Clean code development (Python, Rust, Go)
- Paper analysis and downloading
- Data science workflows

Feel free to adapt the agents and models to your needs!

## License

MIT - See LICENSE file for details
