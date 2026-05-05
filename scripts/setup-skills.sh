#!/bin/bash

# setup-skills.sh
# Parse awesome-agent-skills README and clone skill repositories

set -e

BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

SKILLS_DIR="$HOME/.config/opencode/skills"
CLONED_DIR="$SKILLS_DIR/cloned"
REGISTRY_FILE="$SKILLS_DIR/registry.json"
README_FILE="awesome-agent-skills/README.md"

echo -e "${BLUE}Parsing awesome-agent-skills...${RESET}"

# Check if README exists
if [ ! -f "$README_FILE" ]; then
    echo -e "${RED}Error: $README_FILE not found${RESET}"
    echo -e "${YELLOW}Run 'make setup' first to initialize the submodule${RESET}"
    exit 1
fi

# Create directories
mkdir -p "$CLONED_DIR"

# Extract GitHub URLs from the README
# This extracts URLs from markdown table format
echo -e "${BLUE}Extracting skill URLs...${RESET}"
grep -oE 'https://github\.com/[^)]+' "$README_FILE" | sort -u > /tmp/skill_repos.txt

TOTAL=$(wc -l < /tmp/skill_repos.txt | tr -d ' ')
echo -e "${GREEN}Found $TOTAL skill repositories${RESET}"

# Initialize registry
echo '{"skills": [], "categories": {}, "count": 0}' > "$REGISTRY_FILE"

# Counter for progress
CURRENT=0

# Clone each repository
while read -r repo_url; do
    CURRENT=$((CURRENT + 1))
    
    # Extract repo name from URL
    repo_name=$(echo "$repo_url" | sed 's|https://github.com/||' | sed 's|/tree/.*||' | sed 's|/blob/.*||')
    
    # Create a safe directory name
    dir_name=$(echo "$repo_name" | tr '/' '_')
    target_dir="$CLONED_DIR/$dir_name"
    
    echo -e "${BLUE}[$CURRENT/$TOTAL]${RESET} Processing ${YELLOW}$repo_name${RESET}"
    
    # Skip if already cloned
    if [ -d "$target_dir" ]; then
        echo -e "  ${YELLOW}Already cloned, skipping${RESET}"
        continue
    fi
    
    # Clone the repository (shallow clone for speed)
    if git clone --depth=1 "https://github.com/$repo_name.git" "$target_dir" 2>/dev/null; then
        echo -e "  ${GREEN}Cloned successfully${RESET}"
        
        # Find SKILL.md files
        skill_files=$(find "$target_dir" -type f -name "*.md" | grep -i skill || true)
        
        if [ -n "$skill_files" ]; then
            skill_count=$(echo "$skill_files" | wc -l | tr -d ' ')
            echo -e "  ${GREEN}Found $skill_count skill files${RESET}"
        fi
    else
        echo -e "  ${RED}Failed to clone${RESET}"
    fi
done < /tmp/skill_repos.txt

# Also scan existing ~/.claude/skills/
echo -e "${BLUE}Scanning existing skills in ~/.claude/skills/...${RESET}"
if [ -d "$HOME/.claude/skills" ]; then
    existing_skills=$(find "$HOME/.claude/skills" -maxdepth 1 -type d | wc -l | tr -d ' ')
    echo -e "${GREEN}Found $existing_skills existing skill directories${RESET}"
    
    # Create symlinks or copies
    # For now, we'll just note them in the registry
fi

# Build skill registry
echo -e "${BLUE}Building skill registry...${RESET}"

# Find all SKILL.md files and create registry
SKILL_MD_FILES=$(find "$CLONED_DIR" -type f -name "*.md" | grep -i skill || true)

# Create a simple registry
python3 << 'PYTHON_SCRIPT'
import json
import os
import re
from pathlib import Path

skills_dir = os.path.expanduser("~/.config/opencode/skills")
cloned_dir = os.path.join(skills_dir, "cloned")
registry_file = os.path.join(skills_dir, "registry.json")

registry = {
    "version": "1.0",
    "skills": [],
    "categories": {},
    "sources": [],
    "total_count": 0
}

# Scan cloned repositories
if os.path.exists(cloned_dir):
    for root, dirs, files in os.walk(cloned_dir):
        for file in files:
            if file.lower().endswith('.md') and 'skill' in file.lower():
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, skills_dir)
                
                # Try to extract description from frontmatter or content
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                    
                    # Simple extraction
                    skill_entry = {
                        "name": os.path.splitext(file)[0],
                        "path": rel_path,
                        "source": os.path.basename(os.path.dirname(file_path)),
                        "size": len(content)
                    }
                    
                    # Try to extract description from frontmatter
                    if content.startswith('---'):
                        parts = content.split('---', 2)
                        if len(parts) >= 3:
                            frontmatter = parts[1]
                            desc_match = re.search(r'description:\s*(.+)', frontmatter)
                            if desc_match:
                                skill_entry["description"] = desc_match.group(1).strip()
                    
                    registry["skills"].append(skill_entry)
                except Exception as e:
                    print(f"Warning: Could not parse {file_path}: {e}")

# Also add existing ~/.claude/skills/
claude_skills = os.path.expanduser("~/.claude/skills")
if os.path.exists(claude_skills):
    for item in os.listdir(claude_skills):
        item_path = os.path.join(claude_skills, item)
        if os.path.isdir(item_path) and not item.startswith('.'):
            skill_entry = {
                "name": item,
                "path": os.path.join("~/.claude/skills", item),
                "source": "claude-skills",
                "type": "local"
            }
            registry["skills"].append(skill_entry)

registry["total_count"] = len(registry["skills"])

# Save registry
with open(registry_file, 'w') as f:
    json.dump(registry, f, indent=2)

print(f"Registry built with {registry['total_count']} skills")
PYTHON_SCRIPT

echo -e "${GREEN}Skills setup complete!${RESET}"
echo -e "${YELLOW}Registry saved to: $REGISTRY_FILE${RESET}"
