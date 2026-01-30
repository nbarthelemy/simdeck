#!/bin/bash
# Cleanup duplicate framework files in subprojects
# Removes framework directories that exist in both workspace root and subproject

set -e

# Find workspace root (parent with .claude/version.json)
find_workspace_root() {
    local check_dir="$PWD"
    while [ "$check_dir" != "/" ]; do
        local parent_dir=$(dirname "$check_dir")
        if [ -f "$parent_dir/.claude/version.json" ] && [ "$parent_dir" != "$PWD" ]; then
            echo "$parent_dir/.claude"
            return 0
        fi
        check_dir="$parent_dir"
    done
    return 1
}

# Framework directories that should only exist at workspace root
FRAMEWORK_DIRS=(
    "skills"
    "commands"
    "rules"
    "scripts"
    "templates"
    "agents"
    "orchestration"
)

# Files that should only exist at workspace root
FRAMEWORK_FILES=(
    "manifest.json"
    "version.json"
)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Claudenv Workspace Cleanup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if we're in a subproject
WORKSPACE_ROOT=$(find_workspace_root)
if [ -z "$WORKSPACE_ROOT" ]; then
    echo "❌ Not in a workspace subproject"
    echo "   This script only runs in subprojects with a workspace root"
    exit 1
fi

echo "📁 Workspace root: $WORKSPACE_ROOT"
echo "📁 Current project: $PWD/.claude"
echo ""

if [ ! -d ".claude" ]; then
    echo "❌ No .claude directory found"
    exit 1
fi

# Track what we remove
REMOVED_DIRS=0
REMOVED_FILES=0
PRESERVED_ITEMS=()

echo "Cleaning up framework directories..."
echo ""

for dir in "${FRAMEWORK_DIRS[@]}"; do
    LOCAL_DIR=".claude/$dir"
    WORKSPACE_DIR="$WORKSPACE_ROOT/$dir"

    if [ -d "$LOCAL_DIR" ] && [ -d "$WORKSPACE_DIR" ]; then
        # Count items before removal
        local_count=$(find "$LOCAL_DIR" -type f 2>/dev/null | wc -l | tr -d ' ')

        # Check for project-specific content (items not in workspace)
        has_custom=false
        custom_items=()

        if [ "$dir" = "skills" ]; then
            # For skills, check each skill directory
            for skill_dir in "$LOCAL_DIR"/*/; do
                if [ -d "$skill_dir" ]; then
                    skill_name=$(basename "$skill_dir")
                    if [ ! -d "$WORKSPACE_DIR/$skill_name" ]; then
                        has_custom=true
                        custom_items+=("$skill_name")
                    fi
                fi
            done
        elif [ "$dir" = "agents" ]; then
            # For agents, check each agent file
            for agent_file in "$LOCAL_DIR"/*.md; do
                if [ -f "$agent_file" ]; then
                    agent_name=$(basename "$agent_file")
                    if [ ! -f "$WORKSPACE_DIR/$agent_name" ]; then
                        has_custom=true
                        custom_items+=("$agent_name")
                    fi
                fi
            done
        elif [ "$dir" = "references" ]; then
            # Always preserve references - they're project-specific
            has_custom=true
            custom_items+=("(all - project-specific)")
        fi

        if [ "$has_custom" = true ]; then
            echo "  ⚠️  $dir/ has project-specific content:"
            for item in "${custom_items[@]}"; do
                echo "      - $item"
            done

            # Remove only framework items, keep custom
            if [ "$dir" = "skills" ]; then
                for skill_dir in "$LOCAL_DIR"/*/; do
                    if [ -d "$skill_dir" ]; then
                        skill_name=$(basename "$skill_dir")
                        if [ -d "$WORKSPACE_DIR/$skill_name" ]; then
                            rm -rf "$skill_dir"
                        fi
                    fi
                done
                # Remove triggers.json if duplicate
                if [ -f "$LOCAL_DIR/triggers.json" ] && [ -f "$WORKSPACE_DIR/triggers.json" ]; then
                    rm -f "$LOCAL_DIR/triggers.json"
                fi
                echo "      Removed duplicates, kept custom"
            elif [ "$dir" = "agents" ]; then
                for agent_file in "$LOCAL_DIR"/*.md; do
                    if [ -f "$agent_file" ]; then
                        agent_name=$(basename "$agent_file")
                        if [ -f "$WORKSPACE_DIR/$agent_name" ]; then
                            rm -f "$agent_file"
                        fi
                    fi
                done
                # Remove triggers.json if duplicate
                if [ -f "$LOCAL_DIR/triggers.json" ] && [ -f "$WORKSPACE_DIR/triggers.json" ]; then
                    rm -f "$LOCAL_DIR/triggers.json"
                fi
                echo "      Removed duplicates, kept custom"
            else
                PRESERVED_ITEMS+=("$dir (has custom content)")
            fi
        else
            echo "  🗑️  Removing $dir/ ($local_count files)"
            rm -rf "$LOCAL_DIR"
            ((REMOVED_DIRS++))
        fi
    elif [ -d "$LOCAL_DIR" ]; then
        echo "  ⚠️  Keeping $dir/ (not in workspace root)"
        PRESERVED_ITEMS+=("$dir")
    fi
done

echo ""
echo "Cleaning up framework files..."
echo ""

for file in "${FRAMEWORK_FILES[@]}"; do
    LOCAL_FILE=".claude/$file"
    WORKSPACE_FILE="$WORKSPACE_ROOT/$file"

    if [ -f "$LOCAL_FILE" ] && [ -f "$WORKSPACE_FILE" ]; then
        echo "  🗑️  Removing $file"
        rm -f "$LOCAL_FILE"
        ((REMOVED_FILES++))
    fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Cleanup Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Removed: $REMOVED_DIRS directories, $REMOVED_FILES files"

if [ ${#PRESERVED_ITEMS[@]} -gt 0 ]; then
    echo ""
    echo "  Preserved (project-specific):"
    for item in "${PRESERVED_ITEMS[@]}"; do
        echo "    - $item"
    done
fi

# Fix settings.json hooks to point to workspace root scripts
if [ -f ".claude/settings.json" ]; then
    LOCAL_SCRIPTS="$PWD/.claude/scripts"
    WORKSPACE_SCRIPTS="$WORKSPACE_ROOT/scripts"

    if grep -q "$LOCAL_SCRIPTS" .claude/settings.json 2>/dev/null; then
        echo ""
        echo "Updating settings.json hooks to use workspace scripts..."
        sed -i.bak "s|$LOCAL_SCRIPTS|$WORKSPACE_SCRIPTS|g" .claude/settings.json
        rm -f .claude/settings.json.bak
        echo "  ✅ Updated hook paths to workspace root"
    fi
fi

echo ""
echo "  Subproject now inherits framework from workspace root."
echo ""
