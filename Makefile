.PHONY: all setup skills-deploy lazy-skills-deploy global-skills-deploy agents deploy clean test help plugins validate

# Default target - full build and deploy
all: setup skills-deploy lazy-skills-deploy global-skills-deploy agents deploy plugins
	@echo "$(GREEN)✓ Full build complete!$(RESET)"

# Colors for output
BLUE := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

help: ## Show this help message
	@echo "$(BLUE)OpenCode Agents - Makefile$(RESET)"
	@echo ""
	@echo "$(GREEN)Available targets:$(RESET)"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-20s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Quick start:$(RESET)"
	@echo "  make all                - Full setup and deployment"
	@echo "  make setup              - Create target directories"
	@echo "  make skills-deploy      - Deploy all skills (lazy + global)"
	@echo "  make lazy-skills-deploy - Deploy lazy-loaded skills"
	@echo "  make global-skills-deploy- Deploy globally loaded skills"
	@echo "  make agents             - Deploy agent configurations"
	@echo "  make deploy             - Deploy main configuration"
	@echo "  make plugins            - Install OpenCode plugins"
	@echo "  make validate           - Validate configuration files"
	@echo "  make test               - Run validation tests"
	@echo "  make clean              - Remove deployed configurations"

setup: ## Create target directories and copy environment template
	@echo "$(BLUE)Setting up OpenCode Agents...$(RESET)"
	@echo "$(BLUE)Creating target directories...$(RESET)"
	@mkdir -p ~/.config/opencode/agents
	@mkdir -p ~/.config/opencode/skills
	@mkdir -p ~/.config/opencode/lazy-skills
	@mkdir -p ~/.config/opencode/mcp
	@echo "$(BLUE)Copying environment template...$(RESET)"
	@if [ ! -f ~/.config/opencode/.env ]; then \
		cp .env.example ~/.config/opencode/.env; \
		echo "$(GREEN)Created ~/.config/opencode/.env$(RESET)"; \
		echo "$(YELLOW)Please edit ~/.config/opencode/.env with your API keys$(RESET)"; \
	else \
		echo "$(YELLOW)~/.config/opencode/.env already exists, skipping$(RESET)"; \
	fi
	@echo "$(GREEN)Setup complete!$(RESET)"

skills-deploy: lazy-skills-deploy global-skills-deploy ## Deploy all skills (lazy + global)
	@echo "$(GREEN)✓ All skills deployed!$(RESET)"

lazy-skills-deploy: ## Deploy lazy-loaded skills to ~/.config/opencode/lazy-skills/
	@echo "$(BLUE)Deploying lazy-loaded skills...$(RESET)"
	@mkdir -p ~/.config/opencode/lazy-skills
	@if [ -d "lazy-skills" ] && [ "$$(ls -A lazy-skills)" ]; then \
		rm -rf ~/.config/opencode/lazy-skills/*; \
		cp -R lazy-skills/* ~/.config/opencode/lazy-skills/; \
		echo "$(GREEN)✓ Deployed $$(ls lazy-skills/ | wc -l) lazy-loaded skills$(RESET)"; \
	else \
		echo "$(YELLOW)! No lazy-skills/ directory found or empty$(RESET)"; \
	fi

global-skills-deploy: ## Deploy globally loaded skills to ~/.config/opencode/skills/
	@echo "$(BLUE)Deploying global skills...$(RESET)"
	@mkdir -p ~/.config/opencode/skills
	@if [ -d "skills/global" ] && [ "$$(ls -A skills/global 2>/dev/null)" ]; then \
		rm -rf ~/.config/opencode/skills/*; \
		cp -R skills/global/* ~/.config/opencode/skills/; \
		echo "$(GREEN)✓ Deployed $$(ls skills/global/ | wc -l) global skills$(RESET)"; \
	else \
		echo "$(YELLOW)! No skills/global/ directory found or empty$(RESET)"; \
	fi

agents: ## Deploy agent configurations to ~/.config/opencode/agents/
	@echo "$(BLUE)Deploying agents...$(RESET)"
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --agents
	@echo "$(GREEN)✓ Agents deployed!$(RESET)"

deploy: ## Deploy main configuration files
	@echo "$(BLUE)Deploying configuration...$(RESET)"
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --config
	@echo "$(GREEN)✓ Configuration deployed!$(RESET)"

install: all ## Full installation (setup + skills + agents + config + plugins)
	@echo "$(GREEN)Installation complete!$(RESET)"
	@echo "$(YELLOW)Next steps:$(RESET)"
	@echo "  1. Edit ~/.config/opencode/.env with your API keys"
	@echo "  2. Run 'opencode' to start"
	@echo "  3. Use Tab to switch between primary agents"
	@echo "  4. Use @ to invoke subagents"

plugins: ## Install and update OpenCode plugins
	@echo "$(BLUE)Installing plugins...$(RESET)"
	@npm install -g opencode-auto-fallback@latest 2>/dev/null || true
	@echo "$(YELLOW)Install these plugins manually:$(RESET)"
	@echo "  1. bunx oh-my-opencode-slim@latest install"
	@echo "     (generates oh-my-opencode-slim.json with Pantheon agents)"
	@echo "  2. opencode plugin add @zenobius/opencode-skillful --global"
	@echo "  3. opencode plugin add opencode-plugin-openspec --global"
	@echo "$(YELLOW)Skipped (known issues):$(RESET)"
	@echo "  - @tarquinen/opencode-dcp"
	@echo "$(GREEN)✓ Plugin references updated!$(RESET)"

validate: ## Validate all JSON configs
	@echo "$(BLUE)Validating configuration...$(RESET)"
	@python3 -c "import json; json.load(open('config/opencode.json'))" && echo "  $(GREEN)✓ opencode.json$(RESET)"
	@python3 -c "import json; json.load(open('config/tui.json'))" && echo "  $(GREEN)✓ tui.json$(RESET)"
	@python3 -c "import json; json.load(open('config/fallback.json'))" && echo "  $(GREEN)✓ fallback.json$(RESET)"
	@python3 -c "import json; json.load(open('lazy.config.json'))" && echo "  $(GREEN)✓ lazy.config.json$(RESET)"
	@echo "$(GREEN)All configs valid!$(RESET)"

clean: ## Remove deployed configurations
	@echo "$(RED)Cleaning deployed configurations...$(RESET)"
	@rm -rf ~/.config/opencode/agents/*.md
	@rm -rf ~/.config/opencode/lazy-skills/*
	@rm -rf ~/.config/opencode/skills/*
	@rm -f ~/.config/opencode/opencode.json
	@rm -f ~/.config/opencode/.mcp.json
	@echo "$(GREEN)Clean complete!$(RESET)"

test: validate ## Run validation tests
	@echo "$(BLUE)Running tests...$(RESET)"
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --validate
	@echo "$(GREEN)Tests complete!$(RESET)"
