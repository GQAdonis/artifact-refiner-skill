# Proposal: p9-01 — `direct:mcp-ui` content type and schema

**Change ID**: p9-01-mcp-ui-content-type
**Phase**: phase-9-scaffold-mcp-ui
**Status**: specified
**Origin**: G-1 (D-008)
**Depends on**: nothing — this is the root of the graph

## Summary

Introduce `direct:mcp-ui` as a first-class content type: enum entry, JSON
schema, domain adapter, and routing. This is the contract every later change
validates against.

## Why the schema is the contract

D-005 declined `@mcp-ui/server`. That package's `createUIResource` builds a small
JSON object; the p9-02 normalizer and the p9-04 mock both need to emit that
shape, and taking a ~6-month-stale dependency to construct a literal buys
nothing. **The schema replaces it** — and unlike a dependency, a schema can be
tested against upstream's documented shape.

That makes this change load-bearing in a way p8-01 was not. If the schema is
wrong, the mock emits something the adopted renderer will not render, and the
failure surfaces in p9-04's browser gate rather than here.

## Cite upstream from the first commit

Two consecutive phases shipped a local artifact that diverged from an external
standard of the same name — the AG-UI event enum, then the A2UI document model.
Neither cited upstream, so nothing contradicted the drift.

This change is greenfield (assess: nothing in this repo claimed MCP-UI), so the
citation is cheap and there is nothing to correct. **The schema carries an
explicit provenance block** naming `@mcp-ui/client@7.1.1`, the `ui://` scheme,
and the vendored type declarations in
`.kbd-orchestrator/phases/phase-9-scaffold-mcp-ui/evidence/`.

## The shape being specified

An MCP-UI resource is an `EmbeddedResource` carried in a tool result's `content`
array (D-002, evidenced by `isUIResource` being typed against
`EmbeddedResource`):

```json
{
  "type": "resource",
  "resource": {
    "uri": "ui://server-name/widget",
    "mimeType": "text/html",
    "text": "<!DOCTYPE html>…"
  }
}
```

**One delivery mode in scope: inline HTML.** Two mimeType spellings are
admitted — `text/html;profile=mcp-app` (the MCP Apps form, which both shipped
packages emit) and bare `text/html` (the legacy form).

`remoteDom` and `externalUrl` are **out of scope**, and for a sharper reason
than "complexity": upstream models both as distinct *content shapes*
(`{type: 'remoteDom', script, framework}`, `{type: 'externalUrl', iframeUrl}`),
not as mimeType variants. Neither shipped package exposes a `text/uri-list`
mimeType at all — verified by grep. Supporting them would mean inventing a wire
format, which is exactly the failure mode phases 7 and 8 spent themselves
correcting.

## Scope

```
references/schemas/content-type.schema.json      # enum entry
references/schemas/mcp-ui-resource.schema.json   # new
references/domain/mcp-ui.md                      # new
prompts/meta-controller.md                       # routing table
SKILL.md                                         # domain table
references/content-types.md                      # taxonomy
prompts/specify.md                               # detection heuristics
```

## Non-goals

- No normalizer (p9-02), no examples (p9-03), no renderer (p9-04).
- No `remoteDom`.
- No `@mcp-ui/server` dependency.

## Open questions carried from analyze

None blocking this change. Q1 (sandbox origin) and Q2 (`AppRenderer` vs
`AppFrame`) are p9-04's. **Q3 (`externalUrl` in v1) is resolved here: no.** The
question presumed it was a mimeType variant that could be schema-supported
cheaply; it is a separate content shape with no wire format visible in the
shipped packages, so including it would mean guessing.
