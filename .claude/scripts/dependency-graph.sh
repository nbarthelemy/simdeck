#!/bin/bash
# Dependency Graph Manager - Build and query feature dependency graphs
# Usage: dependency-graph.sh <action> [args]
#
# Actions:
#   build                    Build dependency graph from TODO.md
#   next                     Get next executable feature
#   ready [max]              Get all ready features (for parallel)
#   blocked <feature>        Check if feature is blocked
#   update <feature> <status> Update feature status
#   visualize                Display ASCII graph
#   chain <feature>          Get dependency chain for feature

set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
TODO_FILE="$REPO_ROOT/.claude/TODO.md"
GRAPH_CACHE="$REPO_ROOT/.claude/loop/dependency-graph.json"

# Ensure cache directory exists
init_cache() {
    mkdir -p "$(dirname "$GRAPH_CACHE")"
}

# ==========================================
# BUILD - Parse TODO.md and build graph
# ==========================================
build_graph() {
    if [ ! -f "$TODO_FILE" ]; then
        cat << 'JSONEOF'
{
  "error": true,
  "message": "TODO.md not found"
}
JSONEOF
        return 1
    fi

    init_cache

    local features='[]'
    local edges='[]'

    # Read TODO.md and parse features
    local in_feature=false
    local current_feature=""
    local current_status=""
    local current_line=0
    local current_deps=""

    while IFS= read -r line || [ -n "$line" ]; do
        current_line=$((current_line + 1))

        # Check for feature lines: - [ ] **Name**: Description or - [x] **Name** or - [~] **Name**
        if [[ "$line" =~ ^-\ \[([\ x~!])\].*\*\*([^\*]+)\*\* ]]; then
            # Save previous feature if exists
            if [ -n "$current_feature" ]; then
                # Build feature node
                local deps_array='[]'
                if [ -n "$current_deps" ]; then
                    deps_array=$(echo "$current_deps" | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | grep -v '^$' | jq -R . | jq -s .)
                fi

                local feature_node=$(jq -n \
                    --arg name "$current_feature" \
                    --arg status "$current_status" \
                    --argjson line "$feature_line" \
                    --argjson deps "$deps_array" \
                    '{name: $name, status: $status, lineNumber: $line, dependencies: $deps}')

                features=$(echo "$features" | jq --argjson node "$feature_node" '. + [$node]')

                # Create edges for dependencies
                if [ -n "$current_deps" ]; then
                    IFS=',' read -ra DEP_ARRAY <<< "$current_deps"
                    for dep in "${DEP_ARRAY[@]}"; do
                        dep=$(echo "$dep" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                        [ -z "$dep" ] && continue
                        local edge=$(jq -n --arg from "$dep" --arg to "$current_feature" '{from: $from, to: $to}')
                        edges=$(echo "$edges" | jq --argjson edge "$edge" '. + [$edge]')
                    done
                fi
            fi

            # Parse new feature
            local checkbox="${BASH_REMATCH[1]}"
            current_feature="${BASH_REMATCH[2]}"
            feature_line=$current_line
            current_deps=""

            case "$checkbox" in
                " ") current_status="pending" ;;
                "x") current_status="completed" ;;
                "~") current_status="in_progress" ;;
                "!") current_status="blocked" ;;
            esac

            in_feature=true

        # Check for dependency line: → depends: A, B, C (supports both → and ->)
        elif [ "$in_feature" = true ] && [[ "$line" =~ ^[[:space:]]*(→|-\>)[[:space:]]*depends:[[:space:]]*(.+)$ ]]; then
            current_deps="${BASH_REMATCH[2]}"

        # Check for section header (ends current feature parsing context)
        elif [[ "$line" =~ ^##[[:space:]] ]]; then
            in_feature=false
        fi

    done < "$TODO_FILE"

    # Don't forget the last feature
    if [ -n "$current_feature" ]; then
        local deps_array='[]'
        if [ -n "$current_deps" ]; then
            deps_array=$(echo "$current_deps" | tr ',' '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//' | grep -v '^$' | jq -R . | jq -s .)
        fi

        local feature_node=$(jq -n \
            --arg name "$current_feature" \
            --arg status "$current_status" \
            --argjson line "$feature_line" \
            --argjson deps "$deps_array" \
            '{name: $name, status: $status, lineNumber: $line, dependencies: $deps}')

        features=$(echo "$features" | jq --argjson node "$feature_node" '. + [$node]')

        if [ -n "$current_deps" ]; then
            IFS=',' read -ra DEP_ARRAY <<< "$current_deps"
            for dep in "${DEP_ARRAY[@]}"; do
                dep=$(echo "$dep" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
                [ -z "$dep" ] && continue
                local edge=$(jq -n --arg from "$dep" --arg to "$current_feature" '{from: $from, to: $to}')
                edges=$(echo "$edges" | jq --argjson edge "$edge" '. + [$edge]')
            done
        fi
    fi

    # Detect circular dependencies (simple check)
    local circular='[]'
    # TODO: Implement proper cycle detection

    # Build final graph
    local graph=$(jq -n \
        --argjson features "$features" \
        --argjson edges "$edges" \
        --argjson circular "$circular" \
        '{
            version: 1,
            buildTime: (now | strftime("%Y-%m-%dT%H:%M:%S")),
            features: $features,
            edges: $edges,
            circular: $circular
        }')

    # Save to cache
    echo "$graph" > "$GRAPH_CACHE"

    echo "$graph"
}

# ==========================================
# NEXT - Get next executable feature
# ==========================================
get_next_feature() {
    # Build fresh graph
    local graph=$(build_graph)

    # Check for errors
    local error=$(echo "$graph" | jq -r '.error // false')
    if [ "$error" = "true" ]; then
        echo "$graph"
        return 1
    fi

    # Find first pending feature with all deps completed
    local result=$(echo "$graph" | jq -r '
        .features as $all |
        [.features[] | select(.status == "pending")] |
        map(select(
            if (.dependencies | length) == 0 then
                true
            else
                all(.dependencies[]; . as $dep |
                    any($all[]; .name == $dep and .status == "completed")
                )
            end
        )) |
        first // null
    ')

    if [ "$result" = "null" ]; then
        # Check if any pending features remain
        local pending=$(echo "$graph" | jq '[.features[] | select(.status == "pending")] | length')
        if [ "$pending" -gt 0 ]; then
            echo "BLOCKED"
        else
            echo "ALL_COMPLETE"
        fi
    else
        echo "$result"
    fi
}

# ==========================================
# READY - Get all features ready to execute
# ==========================================
get_ready_features() {
    local max_count="${1:-10}"

    # Build fresh graph
    local graph=$(build_graph)

    local error=$(echo "$graph" | jq -r '.error // false')
    if [ "$error" = "true" ]; then
        echo "$graph"
        return 1
    fi

    # Find all pending features with deps met
    echo "$graph" | jq --argjson max "$max_count" '
        .features as $all |
        [.features[] | select(.status == "pending")] |
        map(select(
            if (.dependencies | length) == 0 then
                true
            else
                all(.dependencies[]; . as $dep |
                    any($all[]; .name == $dep and .status == "completed")
                )
            end
        )) |
        .[:$max]
    '
}

# ==========================================
# BLOCKED - Check if feature is blocked
# ==========================================
is_blocked() {
    local feature_name="$1"

    if [ -z "$feature_name" ]; then
        echo '{"error": true, "message": "Feature name required"}'
        return 1
    fi

    # Build fresh graph
    local graph=$(build_graph)

    # Get feature dependencies
    local deps=$(echo "$graph" | jq -r --arg name "$feature_name" \
        '.features[] | select(.name == $name) | .dependencies[]' 2>/dev/null)

    if [ -z "$deps" ]; then
        echo "false"
        return 0
    fi

    # Check if any dependency is failed or blocked
    while IFS= read -r dep; do
        local dep_status=$(echo "$graph" | jq -r --arg name "$dep" \
            '.features[] | select(.name == $name) | .status' 2>/dev/null)

        if [ "$dep_status" = "failed" ] || [ "$dep_status" = "blocked" ]; then
            echo "true"
            return 0
        fi
    done <<< "$deps"

    echo "false"
}

# ==========================================
# UPDATE - Update feature status
# ==========================================
update_status() {
    local feature_name="$1"
    local new_status="$2"

    if [ -z "$feature_name" ] || [ -z "$new_status" ]; then
        echo '{"error": true, "message": "Feature name and status required"}'
        return 1
    fi

    # Validate status
    case "$new_status" in
        pending|in_progress|completed|failed|blocked) ;;
        *)
            echo '{"error": true, "message": "Invalid status. Use: pending, in_progress, completed, failed, blocked"}'
            return 1
            ;;
    esac

    # Build fresh graph if cache doesn't exist
    if [ ! -f "$GRAPH_CACHE" ]; then
        build_graph > /dev/null
    fi

    # Update in cache
    local updated=$(jq --arg name "$feature_name" --arg status "$new_status" \
        '.features |= map(if .name == $name then .status = $status else . end)' \
        "$GRAPH_CACHE")

    echo "$updated" > "$GRAPH_CACHE"

    cat << JSONEOF
{
  "success": true,
  "feature": $(echo "$feature_name" | jq -Rs .),
  "status": "$new_status"
}
JSONEOF
}

# ==========================================
# CHAIN - Get full dependency chain
# ==========================================
get_chain() {
    local feature_name="$1"

    if [ -z "$feature_name" ]; then
        echo '{"error": true, "message": "Feature name required"}'
        return 1
    fi

    local graph=$(build_graph)

    # Check for error in build
    local error=$(echo "$graph" | jq -r '.error // false')
    if [ "$error" = "true" ]; then
        echo "$graph"
        return 1
    fi

    # Get direct and transitive dependencies using iterative approach
    echo "$graph" | jq --arg name "$feature_name" '
        # Build a lookup map for feature dependencies
        (.features | map({(.name): .dependencies}) | add) as $deps_map |

        # Iterative dependency collection (max 10 levels deep to prevent infinite loops)
        def collect_deps($fname; $visited):
            if ($visited | index($fname)) then []
            elif ($deps_map[$fname] // []) == [] then []
            else
                ($deps_map[$fname] // []) as $direct |
                $direct + ([$direct[] | collect_deps(.; $visited + [$fname])] | flatten)
            end;

        {
            feature: $name,
            dependencies: (collect_deps($name; []) | unique)
        }
    '
}

# ==========================================
# VISUALIZE - Display ASCII graph
# ==========================================
visualize() {
    local graph=$(build_graph)

    local error=$(echo "$graph" | jq -r '.error // false')
    if [ "$error" = "true" ]; then
        echo "$graph" | jq -r '.message'
        return 1
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Feature Dependency Graph"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Status icons
    # pending: [ ] in_progress: [~] completed: [x] failed: [!] blocked: [B]

    echo "$graph" | jq -r '
        .features[] |
        (if .status == "pending" then "[ ]"
         elif .status == "in_progress" then "[~]"
         elif .status == "completed" then "[x]"
         elif .status == "failed" then "[!]"
         elif .status == "blocked" then "[B]"
         else "[?]" end) + " " + .name +
        (if (.dependencies | length) > 0 then
            "\n    → depends: " + (.dependencies | join(", "))
        else
            ""
        end)
    '

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Summary
    local pending=$(echo "$graph" | jq '[.features[] | select(.status == "pending")] | length')
    local in_progress=$(echo "$graph" | jq '[.features[] | select(.status == "in_progress")] | length')
    local completed=$(echo "$graph" | jq '[.features[] | select(.status == "completed")] | length')
    local failed=$(echo "$graph" | jq '[.features[] | select(.status == "failed")] | length')

    echo "Summary: $completed completed, $in_progress in progress, $pending pending, $failed failed"

    # Next executable
    local next=$(get_next_feature)
    if [ "$next" != "ALL_COMPLETE" ] && [ "$next" != "BLOCKED" ]; then
        local next_name=$(echo "$next" | jq -r '.name')
        echo "Next: $next_name"
    elif [ "$next" = "BLOCKED" ]; then
        echo "Next: BLOCKED (dependencies not met)"
    else
        echo "Next: All features complete"
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main dispatcher
case "${1:-}" in
    build)
        build_graph
        ;;
    next)
        get_next_feature
        ;;
    ready)
        shift
        get_ready_features "$@"
        ;;
    blocked)
        shift
        is_blocked "$@"
        ;;
    update)
        shift
        update_status "$@"
        ;;
    chain)
        shift
        get_chain "$@"
        ;;
    visualize)
        visualize
        ;;
    *)
        echo "Usage: dependency-graph.sh <action> [args]"
        echo ""
        echo "Actions:"
        echo "  build                      Build dependency graph from TODO.md"
        echo "  next                       Get next executable feature"
        echo "  ready [max]                Get all ready features (for parallel)"
        echo "  blocked <feature>          Check if feature is blocked"
        echo "  update <feature> <status>  Update feature status"
        echo "  chain <feature>            Get dependency chain for feature"
        echo "  visualize                  Display ASCII graph"
        exit 1
        ;;
esac
