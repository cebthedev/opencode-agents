#!/bin/bash

# test-skills.sh
# Validate all skills in the lazy-skills and global directories
# Checks: YAML frontmatter, required fields, directory structure

set -e

BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

LAZY_SKILLS_DIR="$REPO_DIR/lazy-skills"
GLOBAL_SKILLS_DIR="$REPO_DIR/skills/global"

PASSED=0
FAILED=0
WARNINGS=0

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

echo -e "${BLUE}OpenCode Agents - Skill Validation${RESET}"
echo -e "${BLUE}====================================${RESET}"
echo ""

# Check for Python and PyYAML
if ! command_exists python3; then
    echo -e "${RED}Error: python3 is required${RESET}"
    exit 1
fi

# Check if PyYAML is installed
if ! python3 -c "import yaml" 2>/dev/null; then
    echo -e "${YELLOW}Warning: PyYAML not installed. Installing...${RESET}"
    pip3 install pyyaml 2>/dev/null || pip install pyyaml 2>/dev/null || {
        echo -e "${RED}Error: Could not install PyYAML${RESET}"
        exit 1
    }
fi

# Function to validate a single skill directory
validate_skill() {
    local skill_dir="$1"
    local skill_name=$(basename "$skill_dir")
    local skill_md="$skill_dir/SKILL.md"
    local has_error=0
    local has_warning=0
    
    # Check SKILL.md exists
    if [ ! -f "$skill_md" ]; then
        echo -e "  ${RED}✗ Missing SKILL.md${RESET}"
        return 1
    fi
    
    # Check frontmatter exists (starts with ---)
    if ! head -1 "$skill_md" | grep -q '^---'; then
        echo -e "  ${RED}✗ Missing YAML frontmatter (should start with ---)${RESET}"
        return 1
    fi
    
    # Extract and validate YAML frontmatter
    local frontmatter=$(python3 << EOF
import sys
with open('$skill_md', 'r') as f:
    content = f.read()
if not content.startswith('---'):
    sys.exit(1)
end_idx = content.find('\n---', 3)
if end_idx == -1:
    sys.exit(1)
print(content[3:end_idx].strip())
EOF
)
    
    if [ $? -ne 0 ]; then
        echo -e "  ${RED}✗ Could not extract YAML frontmatter${RESET}"
        return 1
    fi
    
    # Parse YAML and check required fields
    local yaml_check=$(python3 << EOF
import yaml
import sys

try:
    data = yaml.safe_load("""$frontmatter""")
except Exception as e:
    print(f"YAML_ERROR: {e}")
    sys.exit(1)

if not isinstance(data, dict):
    print("YAML_ERROR: Frontmatter is not a dictionary")
    sys.exit(1)

errors = []
if 'name' not in data:
    errors.append("Missing 'name' field")
if 'description' not in data:
    errors.append("Missing 'description' field")

if errors:
    print(f"YAML_ERROR: {'; '.join(errors)}")
    sys.exit(1)

print(f"NAME: {data.get('name', 'N/A')}")
print(f"DESC: {data.get('description', 'N/A')[:50]}...")
EOF
)
    
    if [ $? -ne 0 ]; then
        echo -e "  ${RED}✗ ${yaml_check}${RESET}"
        return 1
    fi
    
    # Extract name and description for display
    local name=$(echo "$yaml_check" | grep '^NAME:' | cut -d' ' -f2-)
    local desc=$(echo "$yaml_check" | grep '^DESC:' | cut -d' ' -f2-)
    
    # Check for scripts directory (optional but good to note)
    if [ -d "$skill_dir/scripts" ]; then
        local script_count=$(find "$skill_dir/scripts" -type f | wc -l | tr -d ' ')
        echo -e "  ${GREEN}✓ Valid${RESET} (scripts: $script_count)"
    else
        echo -e "  ${GREEN}✓ Valid${RESET} (no scripts)"
    fi
    
    return 0
}

# Validate lazy-loaded skills
echo -e "${BLUE}Validating Lazy-Loaded Skills...${RESET}"
if [ -d "$LAZY_SKILLS_DIR" ]; then
    skill_count=0
    for skill_dir in "$LAZY_SKILLS_DIR"/*; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            # Skip hidden directories and special files
            [[ "$skill_name" == .* ]] && continue
            [[ "$skill_name" == "CLAUDE.md" ]] && continue
            
            skill_count=$((skill_count + 1))
            echo -n "$skill_count. $skill_name: "
            
            if validate_skill "$skill_dir"; then
                PASSED=$((PASSED + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        fi
    done
    echo ""
    echo -e "${BLUE}Lazy skills checked: $skill_count${RESET}"
else
    echo -e "${YELLOW}⚠ Lazy-skills directory not found${RESET}"
fi

echo ""

# Validate global skills
echo -e "${BLUE}Validating Global Skills...${RESET}"
if [ -d "$GLOBAL_SKILLS_DIR" ]; then
    global_count=0
    for skill_dir in "$GLOBAL_SKILLS_DIR"/*; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            global_count=$((global_count + 1))
            echo -n "$global_count. $skill_name: "
            
            if validate_skill "$skill_dir"; then
                PASSED=$((PASSED + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        fi
    done
    echo ""
    echo -e "${BLUE}Global skills checked: $global_count${RESET}"
else
    echo -e "${YELLOW}⚠ Global skills directory not found${RESET}"
fi

echo ""
echo -e "${BLUE}====================================${RESET}"
echo -e "${GREEN}✓ Passed: $PASSED${RESET}"
echo -e "${RED}✗ Failed: $FAILED${RESET}"
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}⚠ Warnings: $WARNINGS${RESET}"
fi

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}All skills validated successfully!${RESET}"
    exit 0
else
    echo -e "${RED}Some skills have validation errors.${RESET}"
    exit 1
fi
