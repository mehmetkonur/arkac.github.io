---
name: mcp-server-builder
description: Build high-quality, production-ready Model Context Protocol (MCP) servers. Use when the user wants to create a new MCP server, scaffold server boilerplate, add tools/resources/prompts to an MCP server, connect Claude to an external system (database, API, filesystem, SaaS), or asks about MCP server best practices, error handling, transports (stdio/HTTP), or testing an MCP server. Triggers on phrases like "create an MCP server", "add a tool to my MCP server", "expose my database over MCP", "MCP resource/prompt", or "wrap this API as an MCP server".
---

# MCP Server Builder

Guide the creation of production-ready Model Context Protocol (MCP) servers. MCP is an
open protocol that lets an LLM host (like Claude) connect to external tools, data, and
prompts through a uniform interface. This skill covers scaffolding, tools, resources,
prompts, transports, error handling, security, and testing.

## When to use this skill

Use it whenever the user wants to:

- Scaffold a brand-new MCP server (TypeScript or Python).
- Add a **tool** (a function the model can call), a **resource** (data the model can
  read), or a **prompt** (a reusable prompt template) to an existing server.
- Wrap an existing API, database, or system so Claude can use it.
- Fix error handling, validation, logging, or transport issues in an MCP server.

## Core workflow

Follow these steps in order. Do not skip the design step — most MCP server quality
problems come from poorly-scoped tools, not from code bugs.

### 1. Clarify intent and pick a language

Ask (or infer) what system the server exposes and which language fits the user's stack:

- **TypeScript** (`@modelcontextprotocol/sdk`) — best when the target has a JS/TS SDK,
  or the user already ships Node tooling.
- **Python** (`mcp` package, FastMCP) — best for data/ML, scientific, or Python-native
  integrations.

Both are first-class. If the user has no preference, default to the language their
target system's SDK is written in.

### 2. Design the interface before writing code

Decide what to expose as **tools** vs **resources** vs **prompts** — this is the single
most important decision:

| Primitive   | Controlled by | Use for                                                        |
| ----------- | ------------- | -------------------------------------------------------------- |
| **Tool**    | Model         | Actions with side effects or computation (search, write, call) |
| **Resource**| App/user      | Readable data addressed by URI (files, records, config)        |
| **Prompt**  | User          | Reusable, parameterized prompt templates (slash-command style) |

Design rules:

- **Name tools for tasks, not endpoints.** `create_customer` beats `post_v2_customers`.
  Model a workflow, not a REST surface.
- **Keep the tool set small and orthogonal.** Fewer, well-named tools with clear
  descriptions beat dozens of thin wrappers. Combine related calls where it helps the
  model complete a task in one step.
- **Every input needs a typed schema** with a human-readable description per field. The
  description is what the model reads to decide how to call the tool — write it for a
  reader who cannot see the code.
- **Return concise, structured results.** Trim payloads to what the model needs; large
  blobs waste context. Prefer resources for bulk/readable data.

Read `reference/best-practices.md` before finalizing the design.

### 3. Scaffold the server

Copy the matching template as the starting point:

- `templates/typescript-server.ts` — TypeScript stdio server with one tool, one
  resource, and one prompt.
- `templates/python-server.py` — Python FastMCP server with the same three primitives.

Set up the project (package.json / pyproject) using `reference/scaffolding.md`.

### 4. Implement tools, resources, and prompts

- **Tools:** validate input with the schema, do the work, return content. On failure,
  return an error result (see error handling below) — do **not** throw raw exceptions
  across the protocol boundary.
- **Resources:** expose static resources for fixed data and resource *templates*
  (`scheme://{param}`) for parameterized reads. Set the correct MIME type.
- **Prompts:** return message arrays; accept typed arguments.

See `reference/tools-resources-prompts.md` for schema, validation, pagination, and
content-type details.

### 5. Handle errors correctly

MCP distinguishes two failure kinds — get this right:

- **Protocol errors** (unknown tool, malformed request): throw/return a JSON-RPC error.
- **Tool execution errors** (the API returned 404, validation failed): return a normal
  tool result with `isError: true` and a message the model can read and recover from.
  This lets the model retry or explain the failure instead of the whole call crashing.

Never leak secrets, stack traces, or internal hostnames in error messages.

### 6. Add logging and test

- Log to **stderr** only (stdout is the protocol channel for stdio servers) — writing
  logs to stdout corrupts the JSON-RPC stream.
- Test with the **MCP Inspector** (`npx @modelcontextprotocol/inspector`) before wiring
  into a client.
- See `reference/testing.md` for Inspector usage, client config (Claude Desktop /
  Claude Code), and a manual JSON-RPC smoke test.

### 7. Secure and document

- Validate and sanitize every input; never interpolate untrusted input into shell
  commands or SQL — use parameterized queries.
- Read secrets from environment variables; never hardcode credentials.
- Scope permissions to the minimum the server needs.
- Document each tool/resource/prompt and the required env vars in a README.

See `reference/best-practices.md` for the full security and performance checklist.

## Reference files

- `reference/best-practices.md` — interface design, security, performance, DO/DON'T.
- `reference/scaffolding.md` — project setup, dependencies, run/build commands.
- `reference/tools-resources-prompts.md` — schemas, validation, pagination, URI templates.
- `reference/testing.md` — Inspector, client config, smoke tests.

## Templates

- `templates/typescript-server.ts`
- `templates/python-server.py`

## Quick reference

```
Tool     → model-invoked action        → return content, isError on failure
Resource → app-exposed readable data   → URI + MIME type, supports templates
Prompt   → user-invoked template       → returns messages, takes arguments

Transports: stdio (local, default) | Streamable HTTP (remote/hosted)
Logging:    stderr only for stdio servers
Errors:     protocol error (throw) vs tool error (isError: true)
```
