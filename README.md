# Softagram Analyzer MCP

Run [Softagram](https://softagram.com) code analysis in a Docker container and query architectural intelligence via [Model Context Protocol (MCP)](https://modelcontextprotocol.io/).

Claude (or any MCP-compatible AI assistant) can analyze your repositories and answer questions like:
- "What depends on this class?"
- "What would break if I change this function?"
- "Show me the structure of this module"

## Quick Start

### 1. Start the analyzer

```bash
docker compose up -d
```

Or without Compose:

```bash
docker run -d --name softagram-analyzer \
  --tmpfs /tmp:size=2G \
  -v ~/code/my-project:/input/my-project:ro \
  -p 8008:8008 \
  softagram/analyzer-mcp:latest
```

### 2. Configure Claude Code

Copy the example configuration:

```bash
# Global (all projects)
cp mcp.json.example ~/.claude/mcp.json

# Or project-specific
cp mcp.json.example /path/to/your/project/.mcp.json
```

### 3. Use with Claude

```
You: "Analyze my project at /input/my-project"
You: "What depends on the UserService class?"
You: "What would break if I change the validate function?"
You: "Show me the architecture of the auth module"
```

## Mounting Your Code

The container needs access to the repositories you want to analyze. Mount them
under `/input`:

```yaml
# docker-compose.yml — add your repos under volumes:
services:
  analyzer:
    volumes:
      - ~/code/my-frontend:/input/my-frontend:ro
      - ~/code/my-backend:/input/my-backend:ro
```

Or with `docker run`:

```bash
docker run -d --name softagram-analyzer \
  -v ~/code/my-frontend:/input/my-frontend:ro \
  -v ~/code/my-backend:/input/my-backend:ro \
  -p 8008:8008 \
  softagram/analyzer-mcp:latest
```

Repositories are mounted read-only (`:ro`) — the analyzer never modifies your code.

You can also analyze public repositories by URL without mounting:

```
"Analyze https://github.com/expressjs/express"
```

## Persisting Results

Analysis results are stored inside the container at `/tmp/analysis-outputs`.
To keep them across container restarts:

```yaml
# docker-compose.yml
services:
  analyzer:
    volumes:
      - ./analysis-outputs:/tmp/analysis-outputs
```

## Available Tools

Once connected, Claude has access to these tools:

| Tool | What it does |
|------|-------------|
| **analyze_repo** | Run full code analysis on a repository |
| **get_analysis_status** | List completed analyses |
| **load_model** | Load an analysis model for querying |
| **search_elements** | Find classes, functions, files by name |
| **get_dependencies** | What does X depend on? What depends on X? |
| **get_structure** | Explore the code hierarchy |
| **analyze_change_impact** | What breaks if I change X? |
| **download_model** | Export the analysis model |

### Example Workflow

```
1. "Analyze /input/my-backend"
   → runs full analysis, produces architectural model

2. "What does the OrderService depend on?"
   → loads model, searches for OrderService, queries outgoing dependencies

3. "What would break if I change the PaymentGateway interface?"
   → traces all direct and transitive dependents, grouped by file

4. "Show me the structure of the api/ directory"
   → displays file/class/function hierarchy
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MCP_PORT` | `8008` | Port the MCP server listens on |
| `MCP_TRANSPORT` | `streamable-http` | Protocol: `streamable-http` or `sse` |

### MCP Transport

The default transport is **Streamable HTTP** — the current MCP standard for
remote servers. It uses stateless HTTP POST requests and works well with proxies
and load balancers.

**Endpoint:** `http://localhost:8008/mcp`

If your MCP client only supports SSE (legacy), set the environment variable:

```yaml
# docker-compose.yml
services:
  analyzer:
    environment:
      - MCP_TRANSPORT=sse
```

SSE endpoint: `http://localhost:8008/sse`

### Changing the Port

```yaml
# docker-compose.yml
services:
  analyzer:
    ports:
      - "9090:8008"
```

Update `mcp.json` accordingly:

```json
{
  "mcpServers": {
    "softagram": {
      "type": "streamable-http",
      "url": "http://localhost:9090/mcp"
    }
  }
}
```

## System Requirements

- Docker (Docker Desktop or Docker Engine)
- ~4 GB disk space for the image
- ~2 GB RAM recommended
- Network access for cloning Git repositories (optional)

## Supported Languages

Softagram analyzes dependencies, structure, and metrics for:

Python, Java, Kotlin, JavaScript, TypeScript, C#, F#, C/C++, Go, Dart, Ruby,
PHP, Scala, Groovy, Swift, Objective-C, Haskell, Clojure, COBOL, MATLAB,
and more.

## Troubleshooting

**Container won't start:**
```bash
docker logs softagram-analyzer
```

**"Connection refused" on port 8008:**
Wait a few seconds after starting — the server needs time to initialize.

**Analysis takes a long time:**
First analysis of a large codebase can take several minutes. Subsequent
analyses are faster due to caching.

**Image not found:**
```bash
docker pull softagram/analyzer-mcp:latest
```

## License

This software is proprietary. See [LICENSE](LICENSE) for details.
Usage requires a valid Softagram license.

## Support

- Documentation: [docs.softagram.com](https://docs.softagram.com)
- Email: [support@softagram.com](mailto:support@softagram.com)
