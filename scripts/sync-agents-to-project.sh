#!/bin/bash

# sync-agents-to-project.sh
# Syncs agents from global config to a project directory

set -e

if [ $# -eq 0 ]; then
    echo "Usage: $0 <project-directory>"
    echo "Example: $0 ~/Projects/consistent_rag"
    exit 1
fi

PROJECT_DIR="$1"
GLOBAL_CONFIG="$HOME/.config/opencode/opencode.json"
PROJECT_CONFIG="$PROJECT_DIR/opencode.json"

if [ ! -d "$PROJECT_DIR" ]; then
    echo "Error: Project directory $PROJECT_DIR does not exist"
    exit 1
fi

if [ ! -f "$GLOBAL_CONFIG" ]; then
    echo "Error: Global config not found at $GLOBAL_CONFIG"
    exit 1
fi

echo "Syncing agents to $PROJECT_DIR..."

# Check if project has existing config
if [ -f "$PROJECT_CONFIG" ]; then
    echo "Found existing project config. Merging agents..."
    
    # Use Python to merge configs
    python3 << EOF
import json

with open("$GLOBAL_CONFIG") as f:
    global_config = json.load(f)

with open("$PROJECT_CONFIG") as f:
    project_config = json.load(f)

# Merge: project MCPs + global agents
if "agent" in global_config:
    project_config["agent"] = global_config["agent"]

# Also copy permission settings
if "permission" in global_config:
    project_config["permission"] = global_config["permission"]

with open("$PROJECT_CONFIG", "w") as f:
    json.dump(project_config, f, indent=2)

print(f"Updated $PROJECT_CONFIG")
EOF
else
    echo "No project config found. Copying global config..."
    cp "$GLOBAL_CONFIG" "$PROJECT_CONFIG"
fi

# Also create .opencode/agents directory with symlinks
mkdir -p "$PROJECT_DIR/.opencode/agents"
for agent_file in "$HOME/.config/opencode/agents"/*.md; do
    if [ -f "$agent_file" ]; then
        agent_name=$(basename "$agent_file")
        ln -sf "$agent_file" "$PROJECT_DIR/.opencode/agents/$agent_name"
    fi
done

echo "Done! Agents synced to $PROJECT_DIR"
echo "Restart opencode in that directory to see the agents."
