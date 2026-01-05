#!/bin/bash
# LSP Status Script - JSON output for Claude to format

collect_lsp_status() {
    CONFIG_FILE=".claude/lsp-config.json"

    # Check config exists
    CONFIG_EXISTS=$([ -f "$CONFIG_FILE" ] && echo "true" || echo "false")

    # Get installed servers from config
    INSTALLED="[]"
    if [ "$CONFIG_EXISTS" = "true" ]; then
        INSTALLED=$(jq '.installed // []' "$CONFIG_FILE" 2>/dev/null)
        [ -z "$INSTALLED" ] && INSTALLED="[]"
    fi

    # Count files by language (limit depth for speed)
    TS_COUNT=$(find . -maxdepth 5 \( -name "*.ts" -o -name "*.tsx" \) 2>/dev/null | wc -l | tr -d ' ')
    JS_COUNT=$(find . -maxdepth 5 \( -name "*.js" -o -name "*.jsx" \) 2>/dev/null | wc -l | tr -d ' ')
    PY_COUNT=$(find . -maxdepth 5 -name "*.py" 2>/dev/null | wc -l | tr -d ' ')
    GO_COUNT=$(find . -maxdepth 5 -name "*.go" 2>/dev/null | wc -l | tr -d ' ')
    RS_COUNT=$(find . -maxdepth 5 -name "*.rs" 2>/dev/null | wc -l | tr -d ' ')

    # Check common LSP servers
    TS_LSP=$(which typescript-language-server >/dev/null 2>&1 && echo "true" || echo "false")
    PY_LSP=$(which pyright >/dev/null 2>&1 && echo "true" || echo "false")
    GO_LSP=$(which gopls >/dev/null 2>&1 && echo "true" || echo "false")
    RS_LSP=$(which rust-analyzer >/dev/null 2>&1 && echo "true" || echo "false")

    cat << JSONEOF
{
  "configExists": $CONFIG_EXISTS,
  "installed": $INSTALLED,
  "languages": {
    "typescript": $TS_COUNT,
    "javascript": $JS_COUNT,
    "python": $PY_COUNT,
    "go": $GO_COUNT,
    "rust": $RS_COUNT
  },
  "servers": {
    "typescript-language-server": $TS_LSP,
    "pyright": $PY_LSP,
    "gopls": $GO_LSP,
    "rust-analyzer": $RS_LSP
  }
}
JSONEOF
}

collect_lsp_status
