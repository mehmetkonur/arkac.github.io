# Scaffolding an MCP Server

## TypeScript

### Project layout

```
my-mcp-server/
├── package.json
├── tsconfig.json
└── src/
    └── index.ts        # start from templates/typescript-server.ts
```

### package.json

```json
{
  "name": "my-mcp-server",
  "version": "0.1.0",
  "type": "module",
  "bin": { "my-mcp-server": "dist/index.js" },
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "tsc --watch"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "zod": "^3.23.0"
  },
  "devDependencies": {
    "typescript": "^5.5.0",
    "@types/node": "^22.0.0"
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "Node16",
    "moduleResolution": "Node16",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"]
}
```

### Commands

```bash
npm install
npm run build
node dist/index.js          # runs a stdio server (talks JSON-RPC over stdin/stdout)
```

## Python

### Project layout

```
my-mcp-server/
├── pyproject.toml
└── server.py           # start from templates/python-server.py
```

### pyproject.toml

```toml
[project]
name = "my-mcp-server"
version = "0.1.0"
requires-python = ">=3.10"
dependencies = ["mcp>=1.0.0"]

[project.scripts]
my-mcp-server = "server:main"
```

### Commands

```bash
# uv (recommended)
uv init
uv add "mcp[cli]"
uv run server.py

# or pip
python -m venv .venv && source .venv/bin/activate
pip install "mcp[cli]"
python server.py
```

## Transports

- **stdio** (default for local servers): the client launches the server as a subprocess
  and speaks JSON-RPC over stdin/stdout. Use this for local tools and for Claude Desktop /
  Claude Code. The templates use stdio.
- **Streamable HTTP** (for remote/hosted servers): the server runs as an HTTP service.
  Use this when the server must be shared or deployed. Both SDKs support it — swap the
  stdio transport for the HTTP transport in the entry point; keep the tool/resource/prompt
  definitions unchanged.

Design the tools/resources/prompts first and keep them transport-agnostic; the transport
is a thin outer layer you can switch later.
