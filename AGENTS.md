# AGENTS.md — opencode-agents

Repository-specific guidance for AI agents working in this codebase.

## What this repo is

Configuration generator for OpenCode — deploys 12+ agents, 104+ lazy-loaded skills, and multi-provider fallback to `~/.config/opencode/`.

## Critical: always use caveman compression

All agents in this repo **must** use caveman-style communication. This cuts ~65-75% of output tokens while keeping full technical accuracy.

**Caveman skills are globally loaded** in `skills/global/caveman/`. They are always available to all agents. No `/caveman` command needed.

### Caveman intensity levels

| Level | When to use |
|-------|-------------|
| **lite** | No filler/hedging. Keep articles + full sentences. Professional but tight |
| **full** | Drop articles, fragments OK. Classic caveman. Default. |
| **ultra** | Abbreviate prose words. Strip conjunctions. Maximum compression. |
| **wenyan-lite** | Semi-classical Chinese. Drop filler but keep grammar. |
| **wenyan-full** | Maximum classical terseness. Fully 文言文. |
| **wenyan-ultra** | Extreme abbreviation, classical Chinese feel. |

Default: **full** for all agents. Override per-task only when clarity demands it.

### Caveman rules (always active)

- Drop articles, filler, pleasantries, hedging
- Fragments OK. Short synonyms. No tool-call narration.
- No decorative tables/emoji unless necessary
- No dumping long raw error logs unless asked — quote shortest decisive line
- Standard acronyms OK (DB/API/HTTP); never invent new abbreviations
- Preserve user's dominant language. Compress style, not language.
- Technical terms exact. Code blocks unchanged. Errors quoted exact.
- No self-reference. Never announce "caveman mode on" or similar.
- Pattern: `[thing] [action] [reason]. [next step].`

### Auto-clarity (temporary caveman pause)

Drop caveman when:
- Security warnings
- Irreversible action confirmations
- Multi-step sequences where fragment order risks misread
- User asks to clarify or repeats question
- Compression creates technical ambiguity

Resume caveman after clear part done.

### Caveman sub-skills (also globally loaded)

| Skill | Trigger | Use |
|---|---|---|
| `caveman-commit` | `/caveman-commit` | Conventional Commits, ≤50 char subject. Why over what. |
| `caveman-review` | `/caveman-review` | One-line PR comments: `L42: 🔴 bug: user null. Add guard.` |
| `caveman-compress` | `/caveman-compress <file>` | Rewrite memory files to caveman-speak. Cuts ~46% input tokens. |
| `caveman-stats` | `/caveman-stats` | Session token usage + lifetime savings + USD. |

## Fallback behavior

This config uses `opencode-auto-fallback` plugin with cross-provider fallback chains.

### Fallback strategy

- **Primary**: `kimi-for-coding-oauth/k2p7` (fast, reliable, paid)
- **Fallback**: `deepseek/deepseek-chat` (paid backup, different provider)
- **Last resort**: `kimi-for-coding-oauth/k2p6` (cheaper, older)
- **Emergency**: `opencode/qwen3.6-plus-free` (free with reasoning)

### Key rule: don't retry same provider

All `opencode/*` free models share rate limits. If `opencode/deepseek-v4-flash-free` fails, `opencode/qwen3.6-plus-free` likely fails too. The fallback chains in `config/fallback.json` jump to **different providers** (kimi → deepseek → opencode) rather than wasting retries on the same provider's free tier.

### Pantheon agents also have fallbacks

All Pantheon agents (`orchestrator`, `explorer`, `oracle`, `council`, `librarian`, `designer`, `fixer`, `observer`) are now in `fallback.json` with proper chains. Previously missing — caused silent failures.

## Model assignments

| Agent | Primary | Fallback chain |
|---|---|---|
| **build** | k2p7 | k2p7 → deepseek-chat → k2p6 → k2p5 → qwen3.6-free |
| **research** | k2p7 | k2p7 → deepseek-chat → k2p6 → k2p5 → qwen3.6-free |
| **plan** | k2p7 (high) | k2p7 (high) → deepseek-reasoner → k2p6 → k2p5 (high) → qwen3.6-free |
| **coder** | k2p7 | k2p7 → deepseek-chat → k2p6 → k2p5 → qwen3.6-free |
| **clean-coder** | k2p7 | k2p7 → deepseek-chat → k2p6 → k2p5 → qwen3.6-free |
| **code-reviewer** | k2p7 (high) | k2p7 (high) → deepseek-chat → k2p6 → k2p5 (high) → qwen3.6-free |
| **researcher** | k2p7 (high) | k2p7 (high) → deepseek-chat → k2p6 → k2p5 (high) → qwen3.6-free |
| **writer** | k2p7 | k2p7 → deepseek-chat → mimo-v2.5-free |
| **beagle** | opencode/mimo-v2.5-free | deepseek-chat → k2p7 (low) → mimo-v2.5-free |
| **paper-analyst** | deepseek-chat | k2p7 → deepseek-chat → k2p6 → qwen3.6-free |
| **architect** | deepseek-reasoner | k2p7 (high) → deepseek-reasoner → k2p6 → k2p5 (high) |
| **data-scientist** | deepseek-reasoner | k2p7 (high) → deepseek-chat → k2p6 → k2p5 (high) |

## Running tests and validation

```bash
# Validate all configs
make validate

# Test all skills
make test-skills

# Test specific skill
make test-skill NAME=caveman
```

## Deployment

```bash
# Full deploy (configs, skills, agents)
make all

# Deploy only caveman skills
make global-skills-deploy
```

## Reference

- `config/opencode.json` — Main agent configuration
- `config/fallback.json` — Auto-fallback plugin configuration
- `config/oh-my-opencode-slim.json` — Pantheon agent presets
- `skills/global/` — Always-loaded skills (including caveman)
- `lazy-skills/` — Lazy-loaded skills (on-demand via `skill_find`/`skill_use`)
- `agents/` — Agent markdown definitions
