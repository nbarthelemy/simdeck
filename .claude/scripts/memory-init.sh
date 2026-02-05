#!/bin/bash
# Memory System Initialization
# Creates SQLite database with FTS5 and sqlite-vss for hybrid search
# Usage: memory-init.sh [--force]

set -e

# Find project root
find_project_root() {
    local dir="$PWD"
    while [ "$dir" != "/" ]; do
        if [ -d "$dir/.claude" ]; then
            echo "$dir"
            return 0
        fi
        dir=$(dirname "$dir")
    done
    return 1
}

PROJECT_ROOT=$(find_project_root) || {
    echo '{"error": true, "message": "Not in a claudenv project"}'
    exit 1
}
cd "$PROJECT_ROOT" || exit 1

MEMORY_DIR=".claude/memory"
DB_FILE="$MEMORY_DIR/memory.db"
FORCE="${1:-}"

# Create memory directory
mkdir -p "$MEMORY_DIR"

# Check if database already exists
if [ -f "$DB_FILE" ] && [ "$FORCE" != "--force" ]; then
    echo '{"error": false, "message": "Database already exists", "path": "'"$DB_FILE"'"}'
    exit 0
fi

# Detect sqlite-vec extension path (successor to sqlite-vss)
detect_vec_path() {
    # macOS Homebrew locations
    local paths=(
        "/opt/homebrew/lib/vec0.dylib"
        "/usr/local/lib/vec0.dylib"
        "/opt/homebrew/lib/vec0.so"
        "/usr/local/lib/vec0.so"
        # Linux locations
        "/usr/lib/sqlite3/vec0.so"
        "/usr/local/lib/vec0.so"
        # Python package location
        "$(python3 -c 'import sqlite_vec; print(sqlite_vec.loadable_path())' 2>/dev/null || echo '')"
    )

    for path in "${paths[@]}"; do
        if [ -n "$path" ] && [ -f "$path" ]; then
            echo "$path"
            return 0
        fi
    done

    return 1
}

# Detect sqlite3 that supports extensions
detect_sqlite3() {
    # Prefer Homebrew sqlite3 which supports .load
    local candidates=(
        "/opt/homebrew/opt/sqlite/bin/sqlite3"
        "/usr/local/opt/sqlite/bin/sqlite3"
        "sqlite3"
    )

    for sqlite in "${candidates[@]}"; do
        if [ -x "$sqlite" ] || command -v "$sqlite" &>/dev/null; then
            # Test if it supports .load by trying to load a non-existent file
            # Homebrew sqlite shows "dlopen" or "no such file" errors
            # System sqlite shows "unknown command" error
            local err=$("$sqlite" :memory: ".load /nonexistent" 2>&1)
            if echo "$err" | grep -qE "(dlopen|no such file|cannot open)"; then
                echo "$sqlite"
                return 0
            fi
        fi
    done

    # Fall back to system sqlite3
    echo "sqlite3"
}

SQLITE3=$(detect_sqlite3)

VEC_PATH=$(detect_vec_path 2>/dev/null) || VEC_PATH=""
VEC_AVAILABLE="false"

if [ -n "$VEC_PATH" ]; then
    # Test if vec0 loads correctly
    if $SQLITE3 :memory: ".load $VEC_PATH" "SELECT vec_version();" >/dev/null 2>&1; then
        VEC_AVAILABLE="true"
    fi
fi

# Create database with schema
$SQLITE3 "$DB_FILE" << 'SCHEMA'
-- Enable foreign keys
PRAGMA foreign_keys = ON;

-- Observations table - core memory storage
CREATE TABLE IF NOT EXISTS observations (
    id INTEGER PRIMARY KEY,
    session_id TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    tool_name TEXT NOT NULL,
    tool_input TEXT,
    tool_output TEXT,
    files_involved TEXT,
    summary TEXT NOT NULL,
    keywords TEXT,
    importance INTEGER DEFAULT 1,
    stack TEXT,
    platform TEXT,
    compressed INTEGER DEFAULT 0,
    created_at TEXT NOT NULL
);

-- Sessions table
CREATE TABLE IF NOT EXISTS sessions (
    id TEXT PRIMARY KEY,
    project_path TEXT NOT NULL,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    observation_count INTEGER DEFAULT 0,
    session_summary TEXT,
    created_at TEXT NOT NULL
);

-- FTS5 for full-text search with Porter stemming
CREATE VIRTUAL TABLE IF NOT EXISTS observations_fts USING fts5(
    summary, keywords, tool_name, files_involved,
    content=observations, content_rowid=id,
    tokenize='porter unicode61'
);

-- Triggers to keep FTS5 in sync
CREATE TRIGGER IF NOT EXISTS observations_ai AFTER INSERT ON observations BEGIN
    INSERT INTO observations_fts(rowid, summary, keywords, tool_name, files_involved)
    VALUES (new.id, new.summary, new.keywords, new.tool_name, new.files_involved);
END;

CREATE TRIGGER IF NOT EXISTS observations_ad AFTER DELETE ON observations BEGIN
    INSERT INTO observations_fts(observations_fts, rowid, summary, keywords, tool_name, files_involved)
    VALUES ('delete', old.id, old.summary, old.keywords, old.tool_name, old.files_involved);
END;

CREATE TRIGGER IF NOT EXISTS observations_au AFTER UPDATE ON observations BEGIN
    INSERT INTO observations_fts(observations_fts, rowid, summary, keywords, tool_name, files_involved)
    VALUES ('delete', old.id, old.summary, old.keywords, old.tool_name, old.files_involved);
    INSERT INTO observations_fts(rowid, summary, keywords, tool_name, files_involved)
    VALUES (new.id, new.summary, new.keywords, new.tool_name, new.files_involved);
END;

-- Embeddings table (links vss rowid to observation id)
CREATE TABLE IF NOT EXISTS observation_embeddings (
    observation_id INTEGER PRIMARY KEY,
    vss_rowid INTEGER,
    model TEXT DEFAULT 'all-MiniLM-L6-v2',
    created_at TEXT NOT NULL,
    FOREIGN KEY (observation_id) REFERENCES observations(id)
);

-- Usage tracking (replaces usage.json + usage-history.json)
CREATE TABLE IF NOT EXISTS usage_records (
    id INTEGER PRIMARY KEY,
    session_id TEXT,
    timestamp TEXT NOT NULL,
    input_tokens INTEGER DEFAULT 0,
    output_tokens INTEGER DEFAULT 0,
    tool_name TEXT,
    command TEXT,
    cost_estimate REAL DEFAULT 0,
    created_at TEXT NOT NULL
);

-- Loop history (replaces loop/history/*.json)
CREATE TABLE IF NOT EXISTS loop_runs (
    id INTEGER PRIMARY KEY,
    task TEXT NOT NULL,
    status TEXT DEFAULT 'running',
    started_at TEXT NOT NULL,
    ended_at TEXT,
    iterations INTEGER DEFAULT 0,
    max_iterations INTEGER,
    until_condition TEXT,
    error_message TEXT,
    checkpoint_data TEXT,
    created_at TEXT NOT NULL
);

-- Loop iterations (detailed per-iteration log)
CREATE TABLE IF NOT EXISTS loop_iterations (
    id INTEGER PRIMARY KEY,
    loop_id INTEGER NOT NULL,
    iteration_number INTEGER NOT NULL,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    action_taken TEXT,
    result TEXT,
    tokens_used INTEGER DEFAULT 0,
    FOREIGN KEY (loop_id) REFERENCES loop_runs(id)
);

-- Schema versioning for migrations
CREATE TABLE IF NOT EXISTS schema_version (
    version INTEGER PRIMARY KEY,
    applied_at TEXT NOT NULL,
    description TEXT
);

-- Insert initial version if not exists
INSERT OR IGNORE INTO schema_version VALUES (1, datetime('now'), 'Initial schema with memory, usage, loops');

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_observations_session ON observations(session_id);
CREATE INDEX IF NOT EXISTS idx_observations_timestamp ON observations(timestamp);
CREATE INDEX IF NOT EXISTS idx_observations_importance ON observations(importance);
CREATE INDEX IF NOT EXISTS idx_observations_tool ON observations(tool_name);
CREATE INDEX IF NOT EXISTS idx_usage_session ON usage_records(session_id);
CREATE INDEX IF NOT EXISTS idx_usage_timestamp ON usage_records(timestamp);
CREATE INDEX IF NOT EXISTS idx_loop_status ON loop_runs(status);
CREATE INDEX IF NOT EXISTS idx_loop_iterations_loop ON loop_iterations(loop_id);
SCHEMA

# Create vec table if extension is available
if [ "$VEC_AVAILABLE" = "true" ]; then
    $SQLITE3 "$DB_FILE" \
        ".load $VEC_PATH" \
        "CREATE VIRTUAL TABLE IF NOT EXISTS vec_observations USING vec0(embedding float[384]);"
fi

# Store paths for later use
echo "$VEC_PATH" > "$MEMORY_DIR/.vec_path"
echo "$SQLITE3" > "$MEMORY_DIR/.sqlite3_path"

# Output status
cat << JSONEOF
{
  "error": false,
  "message": "Memory database initialized",
  "path": "$DB_FILE",
  "vec": {
    "available": $VEC_AVAILABLE,
    "path": "$VEC_PATH"
  },
  "tables": ["observations", "sessions", "observations_fts", "observation_embeddings", "usage_records", "loop_runs", "loop_iterations", "schema_version"]
}
JSONEOF
