# Tools, Resources, and Prompts

## Tools

A tool is a model-invoked function. It needs a name, description, an input schema, and a
handler that returns content.

### Input schema

Every parameter must be typed and described. The description is what the model reads to
decide how to call the tool.

TypeScript (Zod, with the high-level `McpServer` API):

```ts
server.registerTool(
  "search_documents",
  {
    title: "Search documents",
    description: "Full-text search across the knowledge base. Returns the top matches ranked by relevance.",
    inputSchema: {
      query: z.string().describe("Search terms (natural language or keywords)."),
      limit: z.number().int().min(1).max(50).default(10)
        .describe("Maximum number of results to return (1-50)."),
    },
  },
  async ({ query, limit }) => {
    // ... do the work ...
    return { content: [{ type: "text", text: JSON.stringify(results) }] };
  },
);
```

Python (FastMCP infers the schema from type hints + docstring):

```python
@mcp.tool()
def search_documents(query: str, limit: int = 10) -> str:
    """Full-text search across the knowledge base.

    Args:
        query: Search terms (natural language or keywords).
        limit: Maximum number of results to return (1-50).
    """
    ...
    return json.dumps(results)
```

### Returning results

- Return concise, structured content (JSON text is fine). Trim fields the model won't use.
- On failure, return an error result rather than throwing:

TypeScript:
```ts
return { content: [{ type: "text", text: `Search failed: ${message}` }], isError: true };
```

Python (FastMCP): raise `ToolError` for a clean tool-level error, or return an error string.
```python
from mcp.server.fastmcp.exceptions import ToolError
raise ToolError("Search failed: upstream returned 503")
```

### Validation

- Validate before doing work; return validation failures as error results.
- Enforce ranges, allow-lists, and size limits in the schema so bad calls fail fast.

### Pagination

For large result sets, page instead of returning everything:

- Accept `limit` and a `cursor`/`offset` argument.
- Return the page plus a `nextCursor` (or `hasMore`) in the result so the model can
  request the next page. Document the cursor format in the tool description.

## Resources

Resources expose readable data addressed by URI.

Static resource (TypeScript):
```ts
server.registerResource(
  "config",
  "config://app",
  { title: "App configuration", mimeType: "application/json" },
  async (uri) => ({
    contents: [{ uri: uri.href, mimeType: "application/json", text: JSON.stringify(config) }],
  }),
);
```

Resource template (parameterized, TypeScript):
```ts
import { ResourceTemplate } from "@modelcontextprotocol/sdk/server/mcp.js";

server.registerResource(
  "customer",
  new ResourceTemplate("db://customers/{id}", { list: undefined }),
  { title: "Customer record" },
  async (uri, { id }) => ({
    contents: [{ uri: uri.href, mimeType: "application/json", text: await loadCustomer(id) }],
  }),
);
```

Python (FastMCP):
```python
@mcp.resource("db://customers/{id}")
def customer(id: str) -> str:
    """Return a single customer record as JSON."""
    return load_customer(id)
```

Guidance:
- Set the correct `mimeType` (`text/plain`, `application/json`, `text/markdown`, …).
- Use templates for parameterized reads; static URIs for fixed data.
- For large content, paginate or chunk rather than returning one huge blob.

## Prompts

Prompts are user-invoked, parameterized templates (they appear as slash commands in
clients).

TypeScript:
```ts
server.registerPrompt(
  "summarize",
  {
    title: "Summarize text",
    argsSchema: { text: z.string().describe("The text to summarize.") },
  },
  ({ text }) => ({
    messages: [{ role: "user", content: { type: "text", text: `Summarize:\n\n${text}` } }],
  }),
);
```

Python (FastMCP):
```python
@mcp.prompt()
def summarize(text: str) -> str:
    """Summarize the provided text."""
    return f"Summarize:\n\n{text}"
```

Keep arguments minimal and typed; describe each one.
