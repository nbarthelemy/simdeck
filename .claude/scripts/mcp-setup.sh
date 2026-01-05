#!/bin/bash
# MCP Server Setup Script
# Detects referenced MCP servers and installs them if possible

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if an MCP server is installed
check_mcp_installed() {
    local server_name="$1"
    claude mcp list 2>/dev/null | grep -q "$server_name" && return 0 || return 1
}

# Get referenced MCP servers from settings.json
get_referenced_mcps() {
    local settings_file="${1:-.claude/settings.json}"
    if [ -f "$settings_file" ]; then
        grep -o 'mcp__[^_]*__' "$settings_file" 2>/dev/null | sed 's/mcp__//g; s/__//g' | sort -u
    fi
}

# MCP installation commands
install_mcp() {
    local mcp_name="$1"

    case "$mcp_name" in
        "filesystem")
            echo -e "${GREEN}Installing filesystem MCP server...${NC}"
            claude mcp add filesystem -s user -- npx -y @anthropic/mcp-filesystem "$HOME"
            ;;
        "github")
            echo -e "${GREEN}Installing GitHub MCP server...${NC}"
            claude mcp add github -s user -- npx -y @anthropic/mcp-github
            ;;
        "postgres"|"postgresql")
            echo -e "${GREEN}Installing PostgreSQL MCP server...${NC}"
            claude mcp add postgres -s user -- npx -y @anthropic/mcp-postgres
            ;;
        "sqlite")
            echo -e "${GREEN}Installing SQLite MCP server...${NC}"
            claude mcp add sqlite -s user -- npx -y @anthropic/mcp-sqlite
            ;;
        "puppeteer")
            echo -e "${GREEN}Installing Puppeteer MCP server...${NC}"
            claude mcp add puppeteer -s user -- npx -y @anthropic/mcp-puppeteer
            ;;
        "memory")
            echo -e "${GREEN}Installing Memory MCP server...${NC}"
            claude mcp add memory -s user -- npx -y @anthropic/mcp-memory
            ;;
        "fetch")
            echo -e "${GREEN}Installing Fetch MCP server...${NC}"
            claude mcp add fetch -s user -- npx -y @anthropic/mcp-fetch
            ;;
        "slack")
            echo -e "${GREEN}Installing Slack MCP server...${NC}"
            claude mcp add slack -s user -- npx -y @anthropic/mcp-slack
            ;;
        "ide")
            echo -e "${YELLOW}⚠ mcp__ide__* is provided by VS Code extension${NC}"
            echo "  Install 'Claude Code' extension in VS Code to enable"
            return 1
            ;;
        "claudeinchrome"|"claude-in-chrome")
            echo -e "${YELLOW}⚠ Chrome automation now uses /chrome command${NC}"
            echo "  No MCP server needed - just run /chrome in Claude"
            return 0
            ;;
        *)
            echo -e "${YELLOW}⚠ Unknown MCP server: $mcp_name${NC}"
            echo "  Check https://github.com/anthropics/mcp-servers for available servers"
            return 1
            ;;
    esac
}

# Main
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔌 MCP Server Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

SETTINGS_FILE="${1:-.claude/settings.json}"
INSTALLED=0
SKIPPED=0
EXTENSION_BASED=0

# Get referenced MCPs
MCPS=$(get_referenced_mcps "$SETTINGS_FILE")

if [ -z "$MCPS" ]; then
    echo "No MCP servers referenced in settings"
    exit 0
fi

echo "Found MCP references: $MCPS"
echo ""

for mcp in $MCPS; do
    # Normalize name
    mcp_normalized=$(echo "$mcp" | tr '[:upper:]' '[:lower:]' | tr '-' '')

    if check_mcp_installed "$mcp"; then
        echo -e "${GREEN}✓${NC} $mcp already installed"
        ((SKIPPED++))
    else
        if install_mcp "$mcp_normalized"; then
            ((INSTALLED++))
        else
            ((EXTENSION_BASED++))
        fi
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Installed: $INSTALLED | Already present: $SKIPPED | Extension-based: $EXTENSION_BASED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
