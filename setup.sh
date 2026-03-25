#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COMPOSE_FILE="$SCRIPT_DIR/docker-compose.yml"
CLAUDE_MCP="$HOME/.claude/mcp.json"

echo ""
echo "Softagram Analyzer MCP — Setup"
echo "==============================="
echo ""

# --- Step 1: Docker login ---
echo "Step 1/5: Docker registry login"
echo "  Credentials required from Softagram (support@softagram.com)."
echo ""
read -rp "  Already logged in to registry.softagram.com? [y/N] " logged_in
if [[ ! "$logged_in" =~ ^[Yy] ]]; then
    echo ""
    docker login registry.softagram.com
fi

# --- Step 2: Collect repository paths ---
echo ""
echo "Step 2/5: Select repositories to analyze"
echo "  Enter absolute paths to repositories, one per line."
echo "  Press Enter on an empty line when done."
echo ""

repos=()
while true; do
    read -rp "  Path (or Enter to finish): " repo_path
    [[ -z "$repo_path" ]] && break
    repo_path="${repo_path/#\~/$HOME}"
    if [[ ! -d "$repo_path" ]]; then
        echo "    Warning: not found: $repo_path (skipping)"
        continue
    fi
    repos+=("$repo_path")
    name=$(basename "$repo_path")
    echo "    Added: $repo_path -> /input/$name"
done

# --- Step 3: Generate docker-compose.yml ---
echo ""
echo "Step 3/5: Generating docker-compose.yml..."

{
    cat <<'HEADER'
services:
  analyzer:
    image: registry.softagram.com/analyzer-mcp:latest
    container_name: softagram-analyzer
    ports:
      - "8008:8008"
    tmpfs:
      - /tmp:size=2G
    volumes:
HEADER

    if [[ ${#repos[@]} -gt 0 ]]; then
        for repo in "${repos[@]}"; do
            name=$(basename "$repo")
            echo "      - ${repo}:/input/${name}:ro"
        done
    else
        cat <<'EMPTY'
      # No repositories configured. Add your repos:
      # - ~/code/my-project:/input/my-project:ro
EMPTY
    fi

    cat <<'FOOTER'
      # Persist analysis results (optional):
      # - ./analysis-outputs:/tmp/analysis-outputs
    restart: unless-stopped
FOOTER
} > "$COMPOSE_FILE"

echo "  Done: docker-compose.yml written"

# --- Step 4: Configure Claude Code MCP ---
echo ""
echo "Step 4/5: Configuring Claude Code MCP..."

mkdir -p "$HOME/.claude"

python3 -c "
import json, sys

path = sys.argv[1]
try:
    with open(path) as f:
        config = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    config = {}

config.setdefault('mcpServers', {})

if 'softagram' in config['mcpServers']:
    print('  Already configured in ' + path)
else:
    config['mcpServers']['softagram'] = {
        'type': 'streamable-http',
        'url': 'http://localhost:8008/mcp'
    }
    with open(path, 'w') as f:
        json.dump(config, f, indent=2)
        f.write('\n')
    print('  Added softagram to ' + path)
" "$CLAUDE_MCP"

# --- Step 5: Start and verify ---
echo ""
echo "Step 5/5: Starting the analyzer..."

docker compose -f "$COMPOSE_FILE" up -d --pull always

echo ""
echo "  Waiting for the server to be ready..."
ready=false
for i in $(seq 1 30); do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8008/mcp 2>/dev/null || true)
    if [[ -n "$status" && "$status" != "000" ]]; then
        ready=true
        break
    fi
    sleep 2
done

if $ready; then
    echo "  Analyzer is ready at http://localhost:8008/mcp"
else
    echo "  Not responding yet. Check logs: docker logs softagram-analyzer"
fi

# --- Done ---
echo ""
echo "Setup complete! Start a new Claude Code session and try:"
echo ""
if [[ ${#repos[@]} -gt 0 ]]; then
    name=$(basename "${repos[0]}")
    echo "  \"Analyze /input/$name\""
else
    echo "  \"Analyze /input/my-project\""
fi
echo ""
