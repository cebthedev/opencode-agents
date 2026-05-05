#!/bin/bash

# deploy.sh
# Deploy agent configurations and main config to ~/.config/opencode/

set -e

BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_DIR="$HOME/.config/opencode"
AGENTS_SOURCE="$REPO_DIR/agents"
CONFIG_SOURCE="$REPO_DIR/config"

show_help() {
    echo -e "${BLUE}OpenCode Agents Deployment Script${RESET}"
    echo ""
    echo "Usage: deploy.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --agents      Deploy agent markdown files"
    echo "  --skills      Deploy local skills"
    echo "  --config      Deploy opencode.json configuration"
    echo "  --all         Deploy everything (default)"
    echo "  --validate    Validate configuration"
    echo "  --help        Show this help message"
}

deploy_agents() {
    echo -e "${BLUE}Deploying agents...${RESET}"
    
    # Create agents directory
    mkdir -p "$TARGET_DIR/agents"
    
    # Copy all agent markdown files
    if [ -d "$AGENTS_SOURCE" ]; then
        for agent_file in "$AGENTS_SOURCE"/*.md; do
            if [ -f "$agent_file" ]; then
                agent_name=$(basename "$agent_file")
                cp "$agent_file" "$TARGET_DIR/agents/$agent_name"
                echo -e "  ${GREEN}Deployed: $agent_name${RESET}"
            fi
        done
    else
        echo -e "${RED}Error: Agents directory not found at $AGENTS_SOURCE${RESET}"
        exit 1
    fi
    
    echo -e "${GREEN}Agents deployed successfully!${RESET}"
}

deploy_config() {
    echo -e "${BLUE}Deploying configuration...${RESET}"
    
    # Copy opencode.json
    if [ -f "$CONFIG_SOURCE/opencode.json" ]; then
        cp "$CONFIG_SOURCE/opencode.json" "$TARGET_DIR/opencode.json"
        echo -e "  ${GREEN}Deployed: opencode.json${RESET}"
    else
        echo -e "${RED}Error: opencode.json not found at $CONFIG_SOURCE/opencode.json${RESET}"
        exit 1
    fi
    
    echo -e "${GREEN}Configuration deployed successfully!${RESET}"
}

deploy_skills() {
    echo -e "${BLUE}Deploying skills...${RESET}"
    
    # Create skills directory
    mkdir -p "$TARGET_DIR/skills/local"
    
    # Copy local skills from repo
    if [ -d "$REPO_DIR/skills/claude" ]; then
        echo -e "${BLUE}Copying claude skills...${RESET}"
        cp -r "$REPO_DIR/skills/claude/"* "$TARGET_DIR/skills/local/" 2>/dev/null || true
    fi
    
    if [ -d "$REPO_DIR/skills/agents" ]; then
        echo -e "${BLUE}Copying agents skills...${RESET}"
        cp -r "$REPO_DIR/skills/agents/"* "$TARGET_DIR/skills/local/" 2>/dev/null || true
    fi
    
    # Copy skill registry
    if [ -f "$REPO_DIR/skills/registry.json" ]; then
        cp "$REPO_DIR/skills/registry.json" "$TARGET_DIR/skills/registry.json"
        echo -e "  ${GREEN}Deployed: registry.json${RESET}"
    fi
    
    echo -e "${GREEN}Skills deployed successfully!${RESET}"
}

validate_config() {
    echo -e "${BLUE}Validating configuration...${RESET}"
    
    # Check if agents directory exists
    if [ ! -d "$TARGET_DIR/agents" ]; then
        echo -e "${RED}Error: Agents directory not found at $TARGET_DIR/agents${RESET}"
        exit 1
    fi
    
    # Count agent files
    agent_count=$(find "$TARGET_DIR/agents" -name "*.md" | wc -l | tr -d ' ')
    echo -e "  ${GREEN}Found $agent_count agent files${RESET}"
    
    # Check opencode.json
    if [ -f "$TARGET_DIR/opencode.json" ]; then
        echo -e "  ${GREEN}opencode.json exists${RESET}"
        
        # Validate JSON syntax
        if python3 -c "import json; json.load(open('$TARGET_DIR/opencode.json'))" 2>/dev/null; then
            echo -e "  ${GREEN}opencode.json is valid JSON${RESET}"
        else
            echo -e "  ${RED}opencode.json is invalid JSON${RESET}"
            exit 1
        fi
    else
        echo -e "  ${RED}opencode.json not found${RESET}"
        exit 1
    fi
    
    # Check environment file
    if [ -f "$TARGET_DIR/.env" ]; then
        echo -e "  ${GREEN}.env file exists${RESET}"
    else
        echo -e "  ${YELLOW}.env file not found (copy .env.example)${RESET}"
    fi
    
    # Validate each agent file has proper frontmatter
    echo -e "${BLUE}Validating agent files...${RESET}"
    for agent_file in "$TARGET_DIR/agents"/*.md; do
        if [ -f "$agent_file" ]; then
            agent_name=$(basename "$agent_file")
            
            # Check for frontmatter
            if head -1 "$agent_file" | grep -q '^---'; then
                echo -e "  ${GREEN}✓ $agent_name has frontmatter${RESET}"
            else
                echo -e "  ${RED}✗ $agent_name missing frontmatter${RESET}"
            fi
        fi
    done
    
    echo -e "${GREEN}Validation complete!${RESET}"
}

# Main logic
if [ $# -eq 0 ]; then
    # Default: deploy everything
    deploy_agents
    deploy_skills
    deploy_config
else
    case "$1" in
        --agents)
            deploy_agents
            ;;
        --skills)
            deploy_skills
            ;;
        --config)
            deploy_config
            ;;
        --all)
            deploy_agents
            deploy_skills
            deploy_config
            ;;
        --validate)
            validate_config
            ;;
        --help)
            show_help
            ;;
        *)
            echo -e "${RED}Unknown option: $1${RESET}"
            show_help
            exit 1
            ;;
    esac
fi
