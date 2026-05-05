.PHONY: all setup skills agents deploy clean test help

# Default target
all: setup skills skills-deploy agents deploy

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
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(RESET) %s\n", $$1, $$2}' $(MAKEFILE_LIST)
	@echo ""
	@echo "$(GREEN)Quick start:$(RESET)"
	@echo "  make all          - Full setup and deployment"
	@echo "  make setup        - Initialize submodule and directories"
	@echo "  make skills       - Parse and clone skill repositories"
	@echo "  make skills-deploy- Deploy local skills to config"
	@echo "  make agents       - Deploy agent configurations"
	@echo "  make deploy       - Deploy main configuration"
	@echo "  make test         - Validate configuration"

setup: ## Initialize git submodule and create target directories
	@echo "$(BLUE)Setting up OpenCode Agents...$(RESET)"
	@echo "$(BLUE)Initializing git submodule...$(RESET)"
	@git submodule update --init --recursive
	@echo "$(BLUE)Creating target directories...$(RESET)"
	@mkdir -p ~/.config/opencode/agents
	@mkdir -p ~/.config/opencode/skills/cloned
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

skills: ## Parse awesome-agent-skills and clone skill repositories
	@echo "$(BLUE)Setting up skills...$(RESET)"
	@chmod +x scripts/setup-skills.sh
	@./scripts/setup-skills.sh
	@echo "$(GREEN)Skills setup complete!$(RESET)"

skills-deploy: ## Deploy local skills to ~/.config/opencode/skills/
	@echo "$(BLUE)Deploying skills...$(RESET)"
	@mkdir -p ~/.config/opencode/skills/local
	@cp -r skills/claude/* ~/.config/opencode/skills/local/ 2>/dev/null || true
	@cp -r skills/agents/* ~/.config/opencode/skills/local/ 2>/dev/null || true
	@echo "$(GREEN)Skills deployed!$(RESET)"

agents: ## Deploy agent configurations to ~/.config/opencode/agents/
	@echo "$(BLUE)Deploying agents...$(RESET)"
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --agents
	@echo "$(GREEN)Agents deployed!$(RESET)"

deploy: ## Deploy main configuration (opencode.json)
	@echo "$(BLUE)Deploying configuration...$(RESET)"
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --config
	@echo "$(GREEN)Configuration deployed!$(RESET)"

install: all ## Full installation (setup + skills + agents + config)
	@echo "$(GREEN)Installation complete!$(RESET)"
	@echo "$(YELLOW)Next steps:$(RESET)"
	@echo "  1. Edit ~/.config/opencode/.env with your API keys"
	@echo "  2. Run 'opencode' to start"
	@echo "  3. Use Tab to switch between primary agents"
	@echo "  4. Use @ to invoke subagents"


plugins: ## Install and update OpenCode plugins
	@echo "$(BLUE)Installing plugins...$(RESET)"
	@npm install -g opencode-auto-fallback@latest
	@echo "$(GREEN)Plugins installed!$(RESET)"

validate: ## Validate all JSON configs
	@echo "$(BLUE)Validating configuration...$(RESET)"
	@python3 -c "import json; json.load(open('config/opencode.json'))" && echo "  $(GREEN)✓ opencode.json$(RESET)"
	@python3 -c "import json; json.load(open('config/tui.json'))" && echo "  $(GREEN)✓ tui.json$(RESET)"
	@python3 -c "import json; json.load(open('config/fallback.json'))" && echo "  $(GREEN)✓ fallback.json$(RESET)"
	@echo "$(GREEN)All configs valid!$(RESET)"

submodules: ## Update all git submodules
	@echo "$(BLUE)Updating submodules...$(RESET)"
	@git submodule update --init --recursive
	@git submodule update --remote
	@echo "$(GREEN)Submodules updated!$(RESET)"

clean: ## Remove deployed configurations
	@echo "$(RED)Cleaning deployed configurations...$(RESET)"
	@rm -rf ~/.config/opencode/agents/*.md
	@rm -f ~/.config/opencode/opencode.json
	@rm -f ~/.config/opencode/.mcp.json
	@echo "$(GREEN)Clean complete!$(RESET)"

test: ## Validate opencode configuration
	@echo "$(BLUE)Validating configuration...$(RESET)"
	@chmod +x scripts/deploy.sh
	@./scripts/deploy.sh --validate
	@echo "$(GREEN)Validation complete!$(RESET)"

update: ## Update awesome-agent-skills submodule
	@echo "$(BLUE)Updating submodule...$(RESET)"
	@git submodule update --remote
	@echo "$(GREEN)Submodule updated!$(RESET)"
	@echo "$(YELLOW)Run 'make skills' to re-parse updated skills$(RESET)"
