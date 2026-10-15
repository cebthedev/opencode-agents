#!/bin/bash

# test-skill.sh
# Test a single skill for validity and usability
# Usage: ./scripts/test-skill.sh <skill-name>
# Example: ./scripts/test-skill.sh arxiv-database

set -e

BLUE='\033[36m'
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

SKILL_NAME="$1"

if [ -z "$SKILL_NAME" ]; then
    echo -e "${RED}Usage: $0 <skill-name>${RESET}"
    echo -e "${YELLOW}Example: $0 arxiv-database${RESET}"
    echo ""
    echo "Available skills:"
    ls "$REPO_DIR/lazy-skills/" 2>/dev/null | head -20
    echo "..."
    exit 1
fi

# Find skill directory
SKILL_DIR=""
if [ -d "$REPO_DIR/lazy-skills/$SKILL_NAME" ]; then
    SKILL_DIR="$REPO_DIR/lazy-skills/$SKILL_NAME"
elif [ -d "$REPO_DIR/skills/global/$SKILL_NAME" ]; then
    SKILL_DIR="$REPO_DIR/skills/global/$SKILL_NAME"
else
    echo -e "${RED}Error: Skill '$SKILL_NAME' not found${RESET}"
    echo -e "${YELLOW}Checked:${RESET}"
    echo "  - $REPO_DIR/lazy-skills/$SKILL_NAME"
    echo "  - $REPO_DIR/skills/global/$SKILL_NAME"
    exit 1
fi

echo -e "${BLUE}Testing Skill: $SKILL_NAME${RESET}"
echo -e "${BLUE}Location: $SKILL_DIR${RESET}"
echo -e "${BLUE}====================================${RESET}"
echo ""

# 1. Check SKILL.md exists
echo -n "1. SKILL.md exists: "
if [ -f "$SKILL_DIR/SKILL.md" ]; then
    echo -e "${GREEN}✓ Yes${RESET}"
else
    echo -e "${RED}✗ No${RESET}"
    exit 1
fi

# 2. Check YAML frontmatter
echo -n "2. YAML frontmatter: "
if head -1 "$SKILL_DIR/SKILL.md" | grep -q '^---'; then
    echo -e "${GREEN}✓ Present${RESET}"
else
    echo -e "${RED}✗ Missing${RESET}"
    exit 1
fi

# 3. Validate YAML
echo -n "3. YAML validity: "
if command -v python3 >/dev/null 2>&1; then
    python3 << EOF
import yaml
import sys

with open('$SKILL_DIR/SKILL.md', 'r') as f:
    content = f.read()

if not content.startswith('---'):
    print("FAIL: Missing opening ---")
    sys.exit(1)

end_idx = content.find('\n---', 3)
if end_idx == -1:
    print("FAIL: Missing closing ---")
    sys.exit(1)

frontmatter = content[3:end_idx].strip()

try:
    data = yaml.safe_load(frontmatter)
except Exception as e:
    print(f"FAIL: {e}")
    sys.exit(1)

if not isinstance(data, dict):
    print("FAIL: Not a dictionary")
    sys.exit(1)

required = ['name', 'description']
missing = [f for f in required if f not in data]

if missing:
    print(f"FAIL: Missing fields: {', '.join(missing)}")
    sys.exit(1)

print(f"PASS: name='{data.get('name')}', description='{data.get('description', '')[:60]}...'")
EOF
else
    echo -e "${YELLOW}⚠ python3 not available, skipping YAML validation${RESET}"
fi

# 4. Check directory structure
echo ""
echo -e "${BLUE}Directory Structure:${RESET}"
find "$SKILL_DIR" -maxdepth 2 -type f | while read f; do
    rel_path="${f#$SKILL_DIR/}"
    echo "  📄 $rel_path"
done

# 5. Check for scripts
echo ""
echo -n "5. Contains scripts: "
if [ -d "$SKILL_DIR/scripts" ]; then
    script_count=$(find "$SKILL_DIR/scripts" -type f | wc -l | tr -d ' ')
    echo -e "${GREEN}✓ Yes ($script_count files)${RESET}"
else
    echo -e "${YELLOW}⚠ No scripts directory${RESET}"
fi

# 6. Check for references
echo -n "6. Contains references: "
if [ -d "$SKILL_DIR/references" ]; then
    ref_count=$(find "$SKILL_DIR/references" -type f | wc -l | tr -d ' ')
    echo -e "${GREEN}✓ Yes ($ref_count files)${RESET}"
else
    echo -e "${YELLOW}⚠ No references directory${RESET}"
fi

# 7. Show first 30 lines of SKILL.md
echo ""
echo -e "${BLUE}SKILL.md Preview (first 30 lines):${RESET}"
echo -e "${BLUE}------------------------------------${RESET}"
head -30 "$SKILL_DIR/SKILL.md"
echo -e "${BLUE}------------------------------------${RESET}"

# 8. Check if skill is referenced by any oa bundle
echo ""
echo -n "7. In an oa bundle: "
if grep -rq "\b$SKILL_NAME\b" "$REPO_DIR/registry/bundles/" 2>/dev/null; then
    echo -e "${GREEN}✓ Yes${RESET}"
else
    echo -e "${YELLOW}⚠ Not in any bundle (add it to registry/bundles/<bundle>.yaml to deploy it)${RESET}"
fi

echo ""
echo -e "${GREEN}✓ Skill test complete for: $SKILL_NAME${RESET}"
