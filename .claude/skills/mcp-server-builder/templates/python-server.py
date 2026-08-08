#!/usr/bin/env python3
"""Minimal, production-shaped MCP server (stdio transport) using FastMCP.

Demonstrates one tool, one resource, and one prompt with:
  - typed inputs (FastMCP derives the schema from type hints + docstrings)
  - tool-level error handling (ToolError, not raw exceptions across the boundary)
  - logging to stderr only (stdout is the JSON-RPC channel)

Run:    python server.py           (or: uv run server.py)
Debug:  npx @modelcontextprotocol/inspector uv run server.py
"""
from __future__ import annotations

import json
import logging
import sys

from mcp.server.fastmcp import FastMCP
from mcp.server.fastmcp.exceptions import ToolError

# Log to stderr ONLY. Writing to stdout corrupts the protocol stream.
logging.basicConfig(stream=sys.stderr, level=logging.INFO, format="[my-mcp-server] %(message)s")
log = logging.getLogger("my-mcp-server")

mcp = FastMCP("my-mcp-server")


# ------------------------------------------------------------------------ Tool
# A tool is a model-invoked action. Name it for the task and describe every
# argument in the docstring — that text is what the model reads to call it.
@mcp.tool()
def search_documents(query: str, limit: int = 10) -> str:
    """Full-text search across the knowledge base.

    Returns the top matches ranked by relevance, as a JSON string.

    Args:
        query: Search terms (natural language or keywords).
        limit: Maximum number of results to return (1-50).
    """
    if not query.strip():
        # Validation failure → surface a clean tool error, don't crash.
        raise ToolError("query must not be empty")
    limit = max(1, min(limit, 50))
    try:
        results = _fake_search(query, limit)  # replace with a real, scoped query
        return json.dumps(results, indent=2)
    except Exception as err:  # noqa: BLE001 - convert to a readable tool error
        log.error("search_documents failed: %s", err)
        raise ToolError(f"Search failed: {err}") from err


# -------------------------------------------------------------------- Resource
# A resource is app-exposed readable data addressed by URI. The {id} makes this
# a parameterized resource template.
@mcp.resource("db://customers/{id}")
def customer(id: str) -> str:
    """Return a single customer record as JSON."""
    return json.dumps({"id": id, "name": "Example Customer"})


# ---------------------------------------------------------------------- Prompt
# A prompt is a user-invoked, parameterized template (a slash command in clients).
@mcp.prompt()
def summarize(text: str) -> str:
    """Summarize the provided text."""
    return f"Summarize the following:\n\n{text}"


# ------------------------------------------------------------------------ Boot
def _fake_search(query: str, limit: int) -> list[dict]:
    return [
        {"id": i + 1, "title": f'Result {i + 1} for "{query}"', "score": round(1 - i * 0.1, 2)}
        for i in range(min(limit, 3))
    ]


def main() -> None:
    log.info("server running on stdio")
    mcp.run()  # defaults to stdio transport


if __name__ == "__main__":
    main()
