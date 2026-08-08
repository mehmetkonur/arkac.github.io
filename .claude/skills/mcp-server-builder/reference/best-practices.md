# MCP Server Best Practices

## Interface design

The quality of an MCP server is decided almost entirely by its interface, not its
implementation. A well-designed set of tools lets the model accomplish real tasks; a
poorly-designed one produces confused, multi-step failures.

### Tools

- **Model tasks, not endpoints.** Wrap a *workflow* the user cares about, not a 1:1 copy
  of a REST API. `find_available_slots(date_range)` is better than exposing `GET /slots`,
  `GET /calendars`, and `GET /timezones` separately.
- **Name for intent.** Use verb_noun names a reader understands without docs:
  `search_documents`, `create_issue`, `refund_payment`.
- **Write descriptions for the model.** The tool description and each parameter
  description are the model's only guide. State what the tool does, when to use it, units,
  formats, and constraints. Mention side effects explicitly ("This permanently deletes…").
- **Keep the set small.** Prefer 5 sharp tools over 25 thin ones. Overlapping or
  near-duplicate tools cause the model to pick wrong.
- **Make inputs forgiving, outputs strict.** Accept reasonable variations on input;
  return consistent, structured output.
- **Return only what's needed.** Trim verbose API responses to the fields the model uses.
  Large results burn context and degrade reasoning. Offer a `fields`/`limit` parameter
  when payloads can be large.

### Resources

- Use resources for data the model *reads* rather than *acts on*: file contents, records,
  configuration, documentation.
- Give every resource a stable URI and correct MIME type.
- Use resource templates (`db://customers/{id}`) for parameterized reads.

### Prompts

- Use prompts for reusable, user-triggered templates (they surface as slash commands in
  clients). Keep arguments typed and minimal.

## Error handling

Two distinct categories — handle them differently:

| Situation                                   | Response                                        |
| ------------------------------------------- | ----------------------------------------------- |
| Unknown tool, malformed params, bad request | JSON-RPC **protocol error** (throw / error code)|
| Tool ran but the operation failed (404, validation, timeout) | Normal result with **`isError: true`** and a readable message |

Returning tool failures as `isError` results (not thrown exceptions) lets the model see
the error and recover — retry with different args, or explain the problem to the user.

Rules:

- Never expose secrets, tokens, stack traces, internal hostnames, or SQL in error text.
- Make error messages actionable: say what failed and what a valid call looks like.
- Validate inputs *before* doing work; return validation errors as `isError` results.

## Security

- **Secrets from env vars only.** Never hardcode API keys or connection strings. Document
  the required variables.
- **Parameterize everything.** Never build SQL or shell commands by string
  concatenation with untrusted input — use parameterized queries / arg arrays.
- **Least privilege.** Give the server the narrowest DB role / API scope / filesystem
  path that works. Prefer read-only where possible.
- **Validate and bound inputs.** Enforce types, ranges, allow-lists, and size limits.
  Reject path traversal (`..`), oversized payloads, and out-of-range values.
- **Confirm destructive actions.** For irreversible tools (delete, transfer, send),
  make the effect explicit in the description so the host can gate it.
- **Don't log sensitive data.** Keep credentials and PII out of logs.

## Performance

- **Reuse connections.** Create DB/HTTP clients once at startup, not per call.
- **Set timeouts.** Every outbound call needs a timeout so a hung dependency can't stall
  the server.
- **Paginate large result sets** instead of returning everything (see
  tools-resources-prompts.md).
- **Cache** stable, expensive lookups where correctness allows.
- **Stream / chunk** large content rather than buffering it all in memory.

## Logging

- For **stdio** servers, stdout is the JSON-RPC channel — **log to stderr only**. A stray
  `print`/`console.log` to stdout corrupts the protocol stream.
- Log tool invocations, errors, and latency; keep secrets out.

## DO / DON'T

**DO**
- Design the tool set around user tasks.
- Give every input a typed schema with descriptions.
- Return tool failures as `isError` results.
- Read secrets from environment variables.
- Test with the MCP Inspector before shipping.

**DON'T**
- Mirror a REST API endpoint-for-endpoint.
- Throw raw exceptions across the protocol boundary.
- Write logs to stdout on a stdio server.
- Concatenate untrusted input into SQL/shell.
- Return giant unfiltered payloads.
