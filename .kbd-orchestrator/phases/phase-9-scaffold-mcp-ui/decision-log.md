# Decision Log — phase-9-scaffold-mcp-ui

## D-001 — G-7 go/no-go: PROCEED

- **Date:** 2026-08-30
- **Decider:** operator
- **Question:** Has the MCP-UI standard solidified enough to run this phase?
  Both definitions of record made phase-9 conditional on it.
- **Decision:** **Go.** Rationale given: "the post-1.0 client is stable enough."
- **What this settles:** the client half. `@mcp-ui/client@7.1.1` is post-1.0 and
  is the package the render host depends on.
- **What this does NOT settle:** the *server* half. The operator's rationale
  names the client specifically, and assess F-4's evidence against was about
  `@mcp-ui/server` (last published 2026-02-13). Analyze must therefore treat the
  server-side package choice (G-6) as still open rather than reading "go" as
  blanket approval of the whole `@mcp-ui/*` line.

**Consequence for scope:** proceed on the "compliant host" reading (2–3
sessions), because a client-only deliverable cannot be demonstrated — there must
be something serving a `ui://` resource to render.
