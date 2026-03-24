# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Is

This is a **configuration-only repository** for the Softagram Analyzer MCP — a Docker-based code analysis service that exposes architectural intelligence via the Model Context Protocol (MCP). There is no application source code here; the analyzer runs inside the `softagram/analyzer-mcp:latest` Docker image.

The repo contains:
- `docker-compose.yml` — container configuration
- `mcp.json.example` — MCP client configuration template
- `README.md` — user-facing documentation

## Running the Analyzer

```bash
docker compose up -d          # Start the container
docker logs softagram-analyzer  # Check logs / troubleshoot
docker compose down            # Stop
```

Repositories to analyze are mounted read-only under `/input` in `docker-compose.yml`. Analysis results go to `/tmp/analysis-outputs` inside the container (optionally persisted via volume mount).

## MCP Connection

- **Default transport:** Streamable HTTP at `http://localhost:8008/mcp`
- **Legacy SSE:** `http://localhost:8008/sse` (set `MCP_TRANSPORT=sse` env var)
- **Client config:** Copy `mcp.json.example` to `~/.claude/mcp.json` (global) or `.mcp.json` (project-specific)

## Available MCP Tools

`analyze_repo`, `get_analysis_status`, `load_model`, `search_elements`, `get_dependencies`, `get_structure`, `analyze_change_impact`, `download_model`

## Key Details

- Proprietary license — image contains compiled/obfuscated code, no reverse engineering
- Container port `8008` (configurable via `MCP_PORT` env var and docker-compose port mapping)
- `.gitignore` excludes `analysis-outputs/` and `.env`
- Supports 20+ languages including Python, Java, Kotlin, JS/TS, C#, Go, C/C++
