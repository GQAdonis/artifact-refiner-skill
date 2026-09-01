# Proposal: p9-04 — MCP-UI render host

**Change ID**: p9-04-mcp-ui-render-host
**Phase**: phase-9-scaffold-mcp-ui
**Status**: specified
**Origin**: G-3, G-5 (D-003, D-003a, D-006)
**Depends on**: p9-01, p9-02, p9-03

**p9-03 is a real dependency, not a courtesy.** The browser gate (§6) drives the
host with the `rawHtml` fixture, and the negative fixtures back the
discrimination gate. Phase-8 shipped a spec where the declared graph was
satisfiable without its example change ever running, so the smoke gate would have
used old-dialect fixtures. Declaring it here prevents the same hole.

## Summary

React components that render an MCP-UI resource in a sandboxed iframe, plus a
Vite dev-server middleware mock that serves one over JSON-RPC.

## This is the change the analyze finding reshaped

`@mcp-ui/client@7.1.1` **does not export `UIResourceRenderer`** — the legacy
single-iframe renderer upstream docs still describe. Verified against
declarations vendored at
`.kbd-orchestrator/phases/phase-9-scaffold-mcp-ui/evidence/`. Only `AppRenderer`
and `AppFrame` ship, both require `SandboxConfig.url`, and
`@modelcontextprotocol/ext-apps` is a hard dependency of the client.

So this change ships the **double-iframe MCP Apps architecture**. There is no
lighter path available in the authorized version.

## Two coupled decisions, made here

**Renderer** (analyze Q2) and **mock method set** (D-003a) are one decision:

| Host configuration | Mock implements |
|---|---|
| `AppFrame` / `AppRenderer` with pre-fetched `html` | `initialize`, `tools/list`, `tools/call` |
| `AppRenderer` with `client`, no `html` | **also `resources/read`** |

**Specified: extract the resource from the tool result and pass `html`**, keeping
the mock at three methods. Task 3.1 verifies that against the running app rather
than against the types — twice in this phase upstream documentation and shipped
behaviour diverged, and the second time it invalidated a recommendation.

## The sandbox origin question (analyze Q1) — specified, then verified

The library default is `allow-scripts allow-same-origin allow-forms`. That
pairing is safe **only** because upstream serves the sandbox proxy from a
separate origin, so `allow-same-origin` names the proxy's origin rather than the
host app's. Serving the proxy from another path on the same Vite dev server would
silently void the isolation while looking identical.

**Specified: serve the proxy same-origin AND override `permissions` to drop
`allow-same-origin`.** This keeps the phase-7/8 "no second process" property and
does not rely on an origin separation the scaffolder cannot guarantee.

Task 5.2 verifies the rendered attribute. If dropping `allow-same-origin` breaks
the `AppBridge` handshake, that is a real finding: record it, and fall back to a
genuine second origin rather than restoring the permissive default. **Do not
resolve a broken handshake by re-adding `allow-same-origin`.**

## Layering

`references/scaffolds/state-architecture.md`: stores own I/O, hooks read stores,
components read hooks. Phase-8 caught a violation here via the ESLint rule
repaired in p7-05 — a component importing a type from `stores/`. Types the
component needs are re-exported through the hook.

Per assess F-1 there is little to reduce: the store tracks resources rather than
accumulating deltas.

## Scope

```
assets/scaffold/mcp-ui/resource-store.ts          # new
assets/scaffold/mcp-ui/use-mcp-ui.ts              # new
assets/scaffold/mcp-ui/mcp-ui-surface.tsx         # new
assets/scaffold/mcp-ui/trust-boundary.test.ts     # new — homes gates 5.3/5.4
assets/scaffold/mcp-ui/vite-plugin-mcp-mock.ts    # new
assets/scaffold/mcp-ui/sandbox-proxy.html         # new
```

Assets only. The scaffolder that emits them is p9-05.

## Non-goals

- No scaffolder (p9-05).
- No `remoteDom` and no `externalUrl` — both are separate content shapes with
  no wire format in the shipped packages (p9-01 tasks 1.3b/1.3c).
- No real MCP server. The mock is development-only and p9-05's README says so.
