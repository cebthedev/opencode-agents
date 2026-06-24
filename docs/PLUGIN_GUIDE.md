# Plugin Guide

Complete guide to installing, configuring, and maintaining OpenCode plugins used by this agent suite.

## Table of Contents

- [Plugin Overview](#plugin-overview)
- [Installation](#installation)
- [Configuration](#configuration)
- [Update Tracking](#update-tracking)
- [Troubleshooting](#troubleshooting)

## Plugin Overview

| Plugin | Type | Purpose | Priority |
|--------|------|---------|----------|
| **opencode-auto-fallback** | NPM Global | Automatic model fallback when APIs fail | Required |
| **oh-my-opencode-slim** | Bun/NPX | Pantheon agent orchestration (@orchestrator, @explorer, etc.) | Required |
| **opencode-plugin-openspec** | OpenCode Plugin | Structured planning and implementation workflow | Recommended |
| **opencode-kimi-full** | OpenCode Plugin | Enhanced Kimi model support and variants | Recommended |
| **@zenobius/opencode-skillful** | OpenCode Plugin | Advanced skill management and discovery | Recommended |

## Installation

### 1. opencode-auto-fallback

Automatic fallback to alternative models when the primary model fails.

```bash
# Install
npm install -g opencode-auto-fallback

# Verify installation
npm list -g opencode-auto-fallback

# Configuration
# Automatically reads ~/.config/opencode/fallback.json
```

**What it does:**
- Monitors model API calls for failures (rate limits, timeouts, errors)
- Retries with exponential backoff (2s → 4s → 8s)
- Falls back to alternative models in configured chain
- Manages cooldown periods for failed models (2 min default)
- Supports large context fallback when context window fills

**Config file:** `config/fallback.json` (deployed to `~/.config/opencode/fallback.json`)

### 2. oh-my-opencode-slim

Pantheon agent orchestration system. Provides 8 specialized subagents.

```bash
# Install (run once)
bunx oh-my-opencode-slim@latest install

# This creates ~/.config/opencode/oh-my-opencode-slim.json
# Our custom preset is already in config/oh-my-opencode-slim.json

# Verify
bunx oh-my-opencode-slim@latest --version
```

**What it does:**
- `@orchestrator` — Auto-delegates complex tasks to specialists
- `@explorer` — Deep codebase reconnaissance
- `@oracle` — Strategic architecture advice
- `@council` — Multi-LLM consensus
- `@librarian` — Documentation and research lookup
- `@designer` — UI/UX implementation
- `@fixer` — Fast scoped coding tasks
- `@observer` — Visual analysis (images, PDFs)

**Config file:** `config/oh-my-opencode-slim.json` (deployed to `~/.config/opencode/`)

**Update checks:**
- Visit: https://github.com/HyeokjaeLee/oh-my-opencode-slim/releases
- Or run: `bunx oh-my-opencode-slim@latest --version`

### 3. opencode-plugin-openspec

Structured workflow for planning and implementing changes.

```bash
# Install
opencode plugin add opencode-plugin-openspec --global

# Verify
opencode plugin list | grep openspec
```

**What it does:**
- `openspec-explore` — Clarify requirements before planning
- `openspec-new-change` — Create structured change artifacts
- `openspec-apply-change` — Implement step-by-step from specs
- `openspec-verify-change` — Validate implementation matches plan
- `openspec-continue-change` — Resume existing work

**Usage workflow:**
```
openspec-explore → openspec-new-change → openspec-apply-change → openspec-verify-change
```

### 4. opencode-kimi-full

Enhanced support for Kimi models with full feature set.

```bash
# Install
opencode plugin add opencode-kimi-full --global

# Verify
opencode plugin list | grep kimi
```

**What it does:**
- Enables reasoning effort variants (off/auto/low/medium/high)
- Supports multimodal inputs (text, image, video)
- Provides attachment handling
- Integrates with kimi-for-coding-oauth provider

### 5. @zenobius/opencode-skillful

Advanced skill management and discovery.

```bash
# Install
opencode plugin add @zenobius/opencode-skillful --global

# Verify
opencode plugin list | grep skillful
```

**What it does:**
- Enhanced skill_find with fuzzy matching
- Skill categorization and tagging
- Automatic skill recommendations based on context

## Configuration

After installing plugins, deploy the configuration files:

```bash
make deploy  # Copies config/*.json to ~/.config/opencode/
```

### Config File Mapping

| Source | Destination | Plugin |
|--------|-------------|--------|
| `config/opencode.json` | `~/.config/opencode/opencode.json` | Core config |
| `config/fallback.json` | `~/.config/opencode/fallback.json` | opencode-auto-fallback |
| `config/oh-my-opencode-slim.json` | `~/.config/opencode/oh-my-opencode-slim.json` | oh-my-opencode-slim |
| `config/tui.json` | `~/.config/opencode/tui.json` | TUI keybinds |
| `lazy.config.json` | `~/.config/opencode/lazy.config.json` | Skill loader |

## Update Tracking

### Monthly Update Checklist

```bash
#!/bin/bash
# save as: check-updates.sh

echo "=== Checking for plugin updates ==="

# 1. NPM packages
echo ""
echo "NPM Global Packages:"
npm outdated -g opencode-auto-fallback 2>/dev/null || echo "  opencode-auto-fallback: up to date or not installed"

# 2. OpenCode plugins
echo ""
echo "OpenCode Plugins:"
opencode plugin list

# 3. oh-my-opencode-slim
echo ""
echo "oh-my-opencode-slim:"
current=$(bunx oh-my-opencode-slim@latest --version 2>/dev/null || echo "unknown")
echo "  Current version: $current"
echo "  Check releases: https://github.com/HyeokjaeLee/oh-my-opencode-slim/releases"

echo ""
echo "=== Update complete ==="
```

### Update Commands

```bash
# Update NPM package
npm update -g opencode-auto-fallback

# Update OpenCode plugins
opencode plugin update opencode-plugin-openspec
opencode plugin update opencode-kimi-full
opencode plugin update @zenobius/opencode-skillful

# Update oh-my-opencode-slim
bunx oh-my-opencode-slim@latest install

# Update all at once
opencode plugin update --all
```

## Troubleshooting

### Plugin not found

```bash
# Check if plugin is installed
opencode plugin list

# Reinstall if missing
opencode plugin add <plugin-name> --global
```

### opencode-auto-fallback not working

1. Check config is deployed: `cat ~/.config/opencode/fallback.json`
2. Verify plugin is installed: `npm list -g opencode-auto-fallback`
3. Check logs: `cat ~/.local/share/opencode/log/fallback.log`
4. Ensure `fallback.json` has `"enabled": true`

### oh-my-opencode-slim agents not responding

1. Verify installation: `bunx oh-my-opencode-slim@latest --version`
2. Check config: `cat ~/.config/opencode/oh-my-opencode-slim.json`
3. Try reinstalling: `bunx oh-my-opencode-slim@latest install`
4. Ensure preset is set to "custom" for our configuration

### Kimi variants not available

1. Verify plugin: `opencode plugin list | grep kimi`
2. Check provider config in `~/.config/opencode/opencode.json`
3. Ensure `opencode-kimi-full` is installed
4. Verify API key has access to reasoning features

### General plugin issues

```bash
# Reset plugin state
opencode plugin reset <plugin-name>

# Clear plugin cache
rm -rf ~/.local/share/opencode/plugins/<plugin-name>

# Reinstall from scratch
opencode plugin remove <plugin-name> --global
opencode plugin add <plugin-name> --global
```

## Version History

| Date | Changes |
|------|---------|
| 2026-05-17 | Added kimi-for-coding-oauth provider, updated agent model paths |
| 2026-05-06 | Migrated skills to lazy-skills structure |
| 2026-05-04 | Initial plugin setup with auto-fallback and oh-my-opencode-slim |
