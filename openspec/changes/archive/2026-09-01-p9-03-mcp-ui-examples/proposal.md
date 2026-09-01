# Proposal: p9-03 — MCP-UI example corpus

**Change ID**: p9-03-mcp-ui-examples
**Phase**: phase-9-scaffold-mcp-ui
**Status**: specified
**Origin**: G-1 (D-008)
**Depends on**: p9-01, p9-02

## Summary

The example corpus for `direct:mcp-ui`: positive fixtures that validate, and
negative fixtures that must not.

## Why negatives matter as much as positives

Phase-8 retained a negative fixture in the *old* A2UI dialect specifically so the
superseded format could not creep back unnoticed. The analogue here is different
but the principle holds: the corpus should pin the decisions this phase made, so
a later change cannot quietly widen them.

Four decisions, **five** negative fixtures — one per fixture-reachable check,
because a fixture carrying two defects only ever reports the first, and the
out-of-scope decision covers two distinct content shapes:
- the `ui://` scheme is the identifying marker → a non-`ui://` fixture rejected
- the mimeType allowlist is closed → an `application/json` fixture rejected
- a declared mimeType must arrive with its payload → a fixture missing `text`
  rejected as `missing_content`
- `remoteDom` **and** `externalUrl` content shapes are out of scope → **two**
  fixtures, one per shape, each well-formed in every other respect so the
  precedence rule actually reaches the shape check

What the corpus **cannot** pin is that `oneOf` is genuine exclusivity rather
than first-match-wins. A single `mimeType` field cannot hold two values, so no
static fixture distinguishes the two implementations; that proof is p9-01 task
1.5b's transient duplicate-branch probe.

## The Q3 decision

Analyze's Q3 asked whether `externalUrl` belongs in v1, presuming it was a
mimeType variant that a schema could support cheaply. **Resolved in p9-01: no.**
Upstream models it as a distinct content shape (`{type: 'externalUrl',
iframeUrl}`) and neither shipped package exposes a `text/uri-list` mimeType, so
including it would mean inventing a wire format.

What the corpus covers instead is the **two mimeType spellings** of the one
in-scope mode: `text/html;profile=mcp-app` (MCP Apps, what the packages emit)
and bare `text/html` (legacy).

## Scope

```
examples/mcp-ui-refinement/                      # new directory, this change owns it
```

Sibling corpora for reference: `examples/a2ui-component-refinement/`,
`examples/ag-ui-spec-refinement/`.

## Non-goals

- No schema or normalizer edits. If a fixture cannot be expressed, that is a
  p9-01/p9-02 defect to report, not to patch here.
