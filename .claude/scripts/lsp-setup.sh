#!/bin/bash
# LSP Setup Script - Automatic language server installation
# Usage: lsp-setup.sh <action> [args]
#
# PRIORITY: Official Anthropic plugins > System package managers
# The script will output plugin installation commands for Claude to run,
# then install binaries as fallback.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$(dirname "$SCRIPT_DIR")"
MAPPINGS_FILE="$CLAUDE_DIR/skills/lsp-agent/lsp-mappings.json"
CONFIG_FILE="$CLAUDE_DIR/lsp-config.json"
LOG_FILE="$CLAUDE_DIR/logs/lsp-setup.log"

# Ensure log directory exists
mkdir -p "$CLAUDE_DIR/logs"

# Logging
log() {
    echo "[$(date -Iseconds)] $1" >> "$LOG_FILE"
    echo "$1"
}

# Get Anthropic plugin for a language
get_anthropic_plugin() {
    local lang="$1"

    if command -v jq &>/dev/null && [ -f "$MAPPINGS_FILE" ]; then
        jq -r ".anthropic_plugins[\"$lang\"] // empty" "$MAPPINGS_FILE" 2>/dev/null
    else
        # Fallback mappings for common languages
        case "$lang" in
            javascript|typescript|javascriptreact|typescriptreact) echo "typescript-lsp@claude-plugins-official" ;;
            python) echo "pyright-lsp@claude-plugins-official" ;;
            go) echo "gopls-lsp@claude-plugins-official" ;;
            rust) echo "rust-analyzer-lsp@claude-plugins-official" ;;
            c|cpp) echo "clangd-lsp@claude-plugins-official" ;;
            csharp) echo "csharp-lsp@claude-plugins-official" ;;
            java) echo "jdtls-lsp@claude-plugins-official" ;;
            php) echo "php-lsp@claude-plugins-official" ;;
            lua) echo "lua-lsp@claude-plugins-official" ;;
            swift) echo "swift-lsp@claude-plugins-official" ;;
            ruby) echo "ruby-lsp@claude-plugins-official" ;;
            kotlin) echo "kotlin-lsp@claude-plugins-official" ;;
            *) echo "" ;;
        esac
    fi
}

# Get plugin for a server
get_plugin_for_server() {
    local server="$1"

    if command -v jq &>/dev/null && [ -f "$MAPPINGS_FILE" ]; then
        jq -r ".servers[\"$server\"].plugin // empty" "$MAPPINGS_FILE" 2>/dev/null
    fi
}

# Detect available package managers
detect_package_managers() {
    local managers=""
    command -v npm &>/dev/null && managers="${managers}npm,"
    command -v pnpm &>/dev/null && managers="${managers}pnpm,"
    command -v yarn &>/dev/null && managers="${managers}yarn,"
    command -v pip &>/dev/null && managers="${managers}pip,"
    command -v pip3 &>/dev/null && managers="${managers}pip3,"
    command -v go &>/dev/null && managers="${managers}go,"
    command -v cargo &>/dev/null && managers="${managers}cargo,"
    command -v gem &>/dev/null && managers="${managers}gem,"
    command -v brew &>/dev/null && managers="${managers}brew,"
    command -v rustup &>/dev/null && managers="${managers}rustup,"
    echo "${managers%,}"
}

# Detect languages in project
detect_languages() {
    local extensions=""

    # Find all unique extensions
    extensions=$(find . -type f -name "*.*" \
        ! -path "./node_modules/*" \
        ! -path "./.git/*" \
        ! -path "./vendor/*" \
        ! -path "./venv/*" \
        ! -path "./.venv/*" \
        ! -path "./target/*" \
        ! -path "./build/*" \
        ! -path "./dist/*" \
        ! -path "./__pycache__/*" \
        ! -path "./.cache/*" \
        2>/dev/null | sed 's/.*\./\./' | sort | uniq)

    # Check for special files
    [ -f "Dockerfile" ] && extensions="${extensions}\nDockerfile"
    [ -f "Makefile" ] && extensions="${extensions}\nMakefile"

    echo -e "$extensions" | sort | uniq | grep -v '^$'
}

# Map extension to language
extension_to_language() {
    local ext="$1"

    # Read from mappings if jq available
    if command -v jq &>/dev/null && [ -f "$MAPPINGS_FILE" ]; then
        local lang=$(jq -r ".extension_to_language[\"$ext\"] // empty" "$MAPPINGS_FILE" 2>/dev/null)
        if [ -n "$lang" ]; then
            echo "$lang"
            return
        fi
    fi

    # Fallback mappings
    case "$ext" in
        .js|.mjs|.cjs) echo "javascript" ;;
        .jsx) echo "javascriptreact" ;;
        .ts) echo "typescript" ;;
        .tsx) echo "typescriptreact" ;;
        .py|.pyi) echo "python" ;;
        .go) echo "go" ;;
        .rs) echo "rust" ;;
        .rb|.rake) echo "ruby" ;;
        .php) echo "php" ;;
        .java) echo "java" ;;
        .cs) echo "csharp" ;;
        .c|.h) echo "c" ;;
        .cpp|.cc|.hpp) echo "cpp" ;;
        .lua) echo "lua" ;;
        .sh|.bash|.zsh) echo "bash" ;;
        .yml|.yaml) echo "yaml" ;;
        .json) echo "json" ;;
        .html|.htm) echo "html" ;;
        .css) echo "css" ;;
        .scss) echo "scss" ;;
        .md|.markdown) echo "markdown" ;;
        .tf) echo "terraform" ;;
        .zig) echo "zig" ;;
        .svelte) echo "svelte" ;;
        .vue) echo "vue" ;;
        .graphql|.gql) echo "graphql" ;;
        .ex|.exs) echo "elixir" ;;
        .kt|.kts) echo "kotlin" ;;
        .scala|.sc) echo "scala" ;;
        Dockerfile) echo "dockerfile" ;;
        *) echo "" ;;
    esac
}

# Get server for language
get_server_for_language() {
    local lang="$1"

    if command -v jq &>/dev/null && [ -f "$MAPPINGS_FILE" ]; then
        # Find server that handles this language with priority 1
        jq -r ".servers | to_entries[] | select(.value.languages | index(\"$lang\")) | select(.value.priority == 1) | .key" "$MAPPINGS_FILE" 2>/dev/null | head -1
    else
        # Fallback mappings
        case "$lang" in
            javascript|typescript|javascriptreact|typescriptreact) echo "typescript-language-server" ;;
            python) echo "pyright" ;;
            go) echo "gopls" ;;
            rust) echo "rust-analyzer" ;;
            ruby) echo "solargraph" ;;
            php) echo "intelephense" ;;
            java) echo "jdtls" ;;
            csharp) echo "omnisharp" ;;
            c|cpp) echo "clangd" ;;
            lua) echo "lua-language-server" ;;
            bash) echo "bash-language-server" ;;
            yaml) echo "yaml-language-server" ;;
            json) echo "vscode-json-languageserver" ;;
            html|css|scss) echo "vscode-langservers-extracted" ;;
            markdown) echo "marksman" ;;
            terraform) echo "terraform-ls" ;;
            svelte) echo "svelte-language-server" ;;
            vue) echo "vue-language-server" ;;
            dockerfile) echo "dockerfile-language-server" ;;
            *) echo "" ;;
        esac
    fi
}

# Check if server is installed
is_server_installed() {
    local server="$1"
    local cmd=""

    # Get command for server
    if command -v jq &>/dev/null && [ -f "$MAPPINGS_FILE" ]; then
        cmd=$(jq -r ".servers[\"$server\"].command // empty" "$MAPPINGS_FILE" 2>/dev/null)
    fi

    # Fallback
    [ -z "$cmd" ] && cmd="$server"

    command -v "$cmd" &>/dev/null
}

# Get server version
get_server_version() {
    local server="$1"
    local cmd=""

    if command -v jq &>/dev/null && [ -f "$MAPPINGS_FILE" ]; then
        cmd=$(jq -r ".servers[\"$server\"].command // empty" "$MAPPINGS_FILE" 2>/dev/null)
    fi
    [ -z "$cmd" ] && cmd="$server"

    $cmd --version 2>/dev/null | head -1 || echo "unknown"
}

# Install a server
install_server() {
    local server="$1"
    local managers=$(detect_package_managers)
    local installed=false

    log "Installing $server..."

    if command -v jq &>/dev/null && [ -f "$MAPPINGS_FILE" ]; then
        local install_cmds=$(jq -r ".servers[\"$server\"].install // {}" "$MAPPINGS_FILE" 2>/dev/null)

        # Try each available package manager
        for manager in npm pnpm yarn pip pip3 go cargo gem brew rustup; do
            if [[ "$managers" == *"$manager"* ]]; then
                local cmd=$(echo "$install_cmds" | jq -r ".[\"$manager\"] // empty" 2>/dev/null)
                if [ -n "$cmd" ]; then
                    log "Trying: $cmd"
                    if eval "$cmd" 2>&1 | tee -a "$LOG_FILE"; then
                        installed=true
                        break
                    fi
                fi
            fi
        done
    else
        # Fallback installation
        case "$server" in
            typescript-language-server)
                npm install -g typescript-language-server typescript && installed=true ;;
            pyright)
                npm install -g pyright && installed=true ;;
            gopls)
                go install golang.org/x/tools/gopls@latest && installed=true ;;
            rust-analyzer)
                if [[ "$managers" == *"rustup"* ]]; then
                    rustup component add rust-analyzer && installed=true
                elif [[ "$managers" == *"brew"* ]]; then
                    brew install rust-analyzer && installed=true
                fi ;;
            bash-language-server)
                npm install -g bash-language-server && installed=true ;;
            yaml-language-server)
                npm install -g yaml-language-server && installed=true ;;
            vscode-json-languageserver)
                npm install -g vscode-json-languageserver && installed=true ;;
            vscode-langservers-extracted)
                npm install -g vscode-langservers-extracted && installed=true ;;
            marksman)
                brew install marksman 2>/dev/null && installed=true ;;
        esac
    fi

    if $installed; then
        log "✅ Installed $server"
        return 0
    else
        log "❌ Failed to install $server"
        return 1
    fi
}

# Update config file
update_config() {
    local languages="$1"
    local servers="$2"

    mkdir -p "$(dirname "$CONFIG_FILE")"

    # Build JSON
    local json="{"
    json="$json\"detected_languages\": $(echo "$languages" | jq -R . | jq -s .),"
    json="$json\"servers\": {"

    local first=true
    for server in $servers; do
        if is_server_installed "$server"; then
            $first || json="$json,"
            first=false
            local version=$(get_server_version "$server")
            json="$json\"$server\": {\"installed\": true, \"version\": \"$version\"}"
        fi
    done

    json="$json},"
    json="$json\"last_setup\": \"$(date -Iseconds)\""
    json="$json}"

    echo "$json" | jq . > "$CONFIG_FILE" 2>/dev/null || echo "$json" > "$CONFIG_FILE"
}

# Main detect and setup
detect_and_setup() {
    log "Starting LSP auto-detection..."

    local extensions=$(detect_languages)
    local languages=""
    local servers=""
    local needed_servers=""
    local installed_servers=""
    local new_servers=""
    local plugins_to_install=""
    local unique_plugins=""

    # Map extensions to languages
    while IFS= read -r ext; do
        [ -z "$ext" ] && continue
        local lang=$(extension_to_language "$ext")
        if [ -n "$lang" ] && [[ "$languages" != *"$lang"* ]]; then
            languages="$languages $lang"
        fi
    done <<< "$extensions"

    log "Detected languages:$languages"

    # Get required servers and plugins
    for lang in $languages; do
        local server=$(get_server_for_language "$lang")
        local plugin=$(get_anthropic_plugin "$lang")

        # Track unique plugins
        if [ -n "$plugin" ] && [[ "$unique_plugins" != *"$plugin"* ]]; then
            unique_plugins="$unique_plugins $plugin"
            plugins_to_install="$plugins_to_install $plugin"
        fi

        if [ -n "$server" ] && [[ "$servers" != *"$server"* ]]; then
            servers="$servers $server"
            if is_server_installed "$server"; then
                installed_servers="$installed_servers $server"
            else
                needed_servers="$needed_servers $server"
            fi
        fi
    done

    # Output summary with plugin recommendations FIRST
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 LSP AUTO-SETUP"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Languages detected:$languages"
    echo ""

    # PRIORITY 1: Recommend Anthropic plugins
    if [ -n "$plugins_to_install" ]; then
        echo "📦 RECOMMENDED: Install official Anthropic plugins first:"
        echo ""
        for plugin in $plugins_to_install; do
            echo "   /plugin install $plugin"
        done
        echo ""
        echo "   Plugins provide pre-configured LSP integration."
        echo ""
    fi

    # PRIORITY 2: Install missing server binaries
    if [ -n "$needed_servers" ]; then
        echo "📥 Installing required binaries..."
        for server in $needed_servers; do
            if install_server "$server"; then
                new_servers="$new_servers $server"
            fi
        done
    fi

    # Update config
    update_config "$languages" "$servers"

    # Final summary
    echo ""
    if [ -n "$new_servers" ]; then
        echo "✅ Binaries installed:$new_servers"
    fi
    if [ -n "$installed_servers" ]; then
        echo "✅ Already available:$installed_servers"
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Return plugin list for Claude to install
    if [ -n "$plugins_to_install" ]; then
        echo ""
        echo "PLUGINS_TO_INSTALL:$plugins_to_install"
    fi
}

# Status check
status() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 LSP STATUS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    local extensions=$(detect_languages)
    local languages=""

    while IFS= read -r ext; do
        [ -z "$ext" ] && continue
        local lang=$(extension_to_language "$ext")
        if [ -n "$lang" ] && [[ "$languages" != *"$lang"* ]]; then
            languages="$languages$lang "
        fi
    done <<< "$extensions"

    echo "Languages detected: $languages"
    echo ""
    printf "%-15s %-30s %s\n" "Language" "Server" "Status"
    echo "───────────────────────────────────────────────────────"

    for lang in $languages; do
        local server=$(get_server_for_language "$lang")
        if [ -n "$server" ]; then
            if is_server_installed "$server"; then
                local version=$(get_server_version "$server")
                printf "%-15s %-30s ✅ %s\n" "$lang" "$server" "$version"
            else
                printf "%-15s %-30s ❌ Missing\n" "$lang" "$server"
            fi
        fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Check for new languages (for hooks)
check_new_language() {
    local file="$1"
    local ext=".${file##*.}"
    local lang=$(extension_to_language "$ext")

    if [ -z "$lang" ]; then
        return 0
    fi

    # Check if we already have this language configured
    if [ -f "$CONFIG_FILE" ] && command -v jq &>/dev/null; then
        local configured=$(jq -r ".detected_languages | index(\"$lang\")" "$CONFIG_FILE" 2>/dev/null)
        if [ "$configured" != "null" ]; then
            return 0
        fi
    fi

    # New language detected
    local server=$(get_server_for_language "$lang")
    if [ -n "$server" ] && ! is_server_installed "$server"; then
        echo "NEW_LANGUAGE:$lang:$server"
        return 1
    fi

    return 0
}

# Main dispatcher
case "${1:-}" in
    detect|setup|"")
        detect_and_setup
        ;;
    status)
        status
        ;;
    install)
        shift
        for server in "$@"; do
            install_server "$server"
        done
        ;;
    check-new)
        shift
        check_new_language "$1"
        ;;
    *)
        echo "Usage: lsp-setup.sh [detect|status|install <server>|check-new <file>]"
        exit 1
        ;;
esac
