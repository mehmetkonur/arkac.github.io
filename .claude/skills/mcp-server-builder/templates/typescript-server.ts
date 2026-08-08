#!/usr/bin/env node
/**
 * Minimal, production-shaped MCP server (stdio transport).
 *
 * Demonstrates one tool, one resource, and one prompt with:
 *  - typed input schemas (Zod) with per-field descriptions
 *  - tool-level error handling (isError results, not thrown exceptions)
 *  - logging to stderr only (stdout is the JSON-RPC channel)
 *
 * Build:  tsc
 * Run:    node dist/index.js
 * Debug:  npx @modelcontextprotocol/inspector node dist/index.js
 */
import { McpServer, ResourceTemplate } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

// Log to stderr ONLY. Writing to stdout corrupts the protocol stream.
const log = (...args: unknown[]) => console.error("[my-mcp-server]", ...args);

const server = new McpServer({
  name: "my-mcp-server",
  version: "0.1.0",
});

/* ----------------------------------------------------------------------- Tool */
// A tool is a model-invoked action. Name it for the task, describe every field,
// and return tool failures as isError results so the model can recover.
server.registerTool(
  "search_documents",
  {
    title: "Search documents",
    description:
      "Full-text search across the knowledge base. Returns the top matches ranked by relevance.",
    inputSchema: {
      query: z.string().min(1).describe("Search terms (natural language or keywords)."),
      limit: z
        .number()
        .int()
        .min(1)
        .max(50)
        .default(10)
        .describe("Maximum number of results to return (1-50)."),
    },
  },
  async ({ query, limit }) => {
    try {
      // Replace with a real search (parameterized query / scoped API call).
      const results = await fakeSearch(query, limit);
      return {
        content: [{ type: "text", text: JSON.stringify(results, null, 2) }],
      };
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      log("search_documents failed:", message);
      // Tool execution error → return isError, do NOT throw across the boundary.
      return {
        content: [{ type: "text", text: `Search failed: ${message}` }],
        isError: true,
      };
    }
  },
);

/* ------------------------------------------------------------------- Resource */
// A resource is app-exposed readable data addressed by URI. Templates allow
// parameterized reads. Always set the correct mimeType.
server.registerResource(
  "customer",
  new ResourceTemplate("db://customers/{id}", { list: undefined }),
  { title: "Customer record", description: "A single customer record as JSON." },
  async (uri, { id }) => ({
    contents: [
      {
        uri: uri.href,
        mimeType: "application/json",
        text: JSON.stringify({ id, name: "Example Customer" }),
      },
    ],
  }),
);

/* --------------------------------------------------------------------- Prompt */
// A prompt is a user-invoked, parameterized template (surfaces as a slash command).
server.registerPrompt(
  "summarize",
  {
    title: "Summarize text",
    description: "Summarize a block of text.",
    argsSchema: { text: z.string().describe("The text to summarize.") },
  },
  ({ text }) => ({
    messages: [
      { role: "user", content: { type: "text", text: `Summarize the following:\n\n${text}` } },
    ],
  }),
);

/* ----------------------------------------------------------------------- Boot */
async function fakeSearch(query: string, limit: number) {
  return Array.from({ length: Math.min(limit, 3) }, (_, i) => ({
    id: i + 1,
    title: `Result ${i + 1} for "${query}"`,
    score: 1 - i * 0.1,
  }));
}

async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
  log("server running on stdio");
}

main().catch((err) => {
  log("fatal:", err);
  process.exit(1);
});
