# MCP Server Builder Skill

A Claude Code skill that guides building high-quality, production-ready
[Model Context Protocol](https://modelcontextprotocol.io) (MCP) servers.

## What it does

Given a request like *"create an MCP server that connects to my PostgreSQL database"* or
*"add a search tool to my MCP server"*, this skill walks Claude through:

- **Designing the interface** — choosing tools vs resources vs prompts, and naming/scoping
  them around real user tasks.
- **Scaffolding** — TypeScript (`@modelcontextprotocol/sdk`) or Python (FastMCP) project
  setup.
- **Implementing** tools, resources, and prompts with typed, validated inputs.
- **Error handling** — the protocol-error vs tool-error distinction, returning `isError`
  results the model can recover from.
- **Security & performance** — env-var secrets, parameterized queries, least privilege,
  connection reuse, pagination.
- **Testing** — MCP Inspector, client config, and a manual JSON-RPC smoke test.

## Layout

```
mcp-server-builder/
├── SKILL.md                 # entry point (frontmatter + workflow)
├── README.md                # this file
├── reference/
│   ├── best-practices.md    # interface design, security, performance, DO/DON'T
│   ├── scaffolding.md       # project setup + transports
│   ├── tools-resources-prompts.md
│   └── testing.md           # Inspector, client config, smoke test
└── templates/
    ├── typescript-server.ts # stdio server: 1 tool, 1 resource, 1 prompt
    └── python-server.py     # FastMCP equivalent
```

## Usage

Place this directory under `.claude/skills/`. Claude invokes it automatically when a
request matches the description in `SKILL.md`, or you can call it explicitly with
`/mcp-server-builder`.

## Example prompts

- "Create an MCP server that connects to my PostgreSQL database"
- "Add a tool to my MCP server for searching documents"
- "Generate proper error handling for my MCP server"
- "Expose my internal API as MCP resources"
