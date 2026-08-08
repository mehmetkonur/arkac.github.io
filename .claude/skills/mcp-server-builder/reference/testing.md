# Testing an MCP Server

## MCP Inspector (do this first)

The Inspector is an interactive UI to exercise a server without wiring it into a client.

```bash
# TypeScript (after npm run build)
npx @modelcontextprotocol/inspector node dist/index.js

# Python
npx @modelcontextprotocol/inspector uv run server.py
```

In the Inspector you can:
- List tools, resources, and prompts and confirm names/descriptions/schemas look right.
- Call each tool with sample arguments and inspect the result.
- Verify error cases return `isError: true` with a readable message (not a crash).
- Read resources and check MIME types.

## Wiring into a client

### Claude Desktop

Add the server to `claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "my-server": {
      "command": "node",
      "args": ["/absolute/path/to/dist/index.js"],
      "env": { "API_KEY": "..." }
    }
  }
}
```

Python variant:
```json
{
  "mcpServers": {
    "my-server": {
      "command": "uv",
      "args": ["--directory", "/absolute/path/to/project", "run", "server.py"],
      "env": { "API_KEY": "..." }
    }
  }
}
```

Restart the client after editing config. Use **absolute paths**.

### Claude Code

```bash
claude mcp add my-server -- node /absolute/path/to/dist/index.js
# or, with env vars:
claude mcp add my-server --env API_KEY=... -- node /absolute/path/to/dist/index.js
```

## Manual JSON-RPC smoke test (stdio)

A stdio server speaks JSON-RPC over stdin/stdout. Pipe an `initialize` and
`tools/list` to confirm it responds:

```bash
printf '%s\n' \
  '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"smoke","version":"0"}}}' \
  '{"jsonrpc":"2.0","method":"notifications/initialized"}' \
  '{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}' \
  | node dist/index.js
```

You should see an `initialize` result followed by a `tools/list` result listing your
tools. If stdout contains anything that isn't JSON-RPC, you have a stray log write to
stdout — move it to stderr.

## Checklist before shipping

- [ ] Every tool/resource/prompt has a clear name and description.
- [ ] Inputs are typed and validated; out-of-range/invalid calls fail cleanly.
- [ ] Tool failures return `isError: true`, not thrown exceptions.
- [ ] No secrets/stack traces in error messages or logs.
- [ ] Logs go to stderr (stdio servers).
- [ ] Secrets come from env vars; documented in README.
- [ ] Tested in the Inspector and at least one real client.
