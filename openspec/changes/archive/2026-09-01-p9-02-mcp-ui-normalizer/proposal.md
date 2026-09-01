# Proposal: p9-02 — `normalize-mcp-ui.mjs`

**Change ID**: p9-02-mcp-ui-normalizer
**Phase**: phase-9-scaffold-mcp-ui
**Status**: specified
**Origin**: G-1 (D-008) — the executable half of the contract
**Depends on**: p9-01

## Summary

A normalizer that validates and canonicalizes a `direct:mcp-ui` resource,
following `normalize-a2ui.mjs` and `normalize-agui.mjs`.

## Derive from the schema, never duplicate it

`normalize-agui.mjs` was corrected in phase-7 to derive its event enum from the
schema at runtime rather than restating it, precisely because the duplicate had
drifted. **This normalizer does the same**: mimeTypes and the `ui://` pattern
come from `mcp-ui-resource.schema.json`, not from literals in the script.

## The validator must actually implement its operators

Phase-8's most consequential finding: the built-in validator implemented `oneOf`
as `anyOf` and lacked `not`/`anyOf` entirely, so every schema guard was silently
inert — p8-01's envelope exclusivity existed on paper until p8-02 fixed it.

`normalize-a2ui.mjs` now has real `oneOf`/`anyOf`/`not`. **This change must
either reuse that validator or prove its own handles the same cases.** Task 2.1
makes the choice explicit rather than assuming inheritance.

Proving it needs care. The obvious test — a fixture presenting "both delivery
modes" — **is not constructible**: delivery mode is carried by a single
`mimeType` string, and one field holds one value. A fixture matching *zero*
branches is constructible but proves nothing, since correct and first-match-wins
implementations both reject it. The only discriminating test is to temporarily
duplicate a schema branch and confirm a conformant fixture is then **rejected**
(task 2.3) — run against a scratchpad copy, never the repo schema.

## Security is in scope here, not only in the host

p9-01's schema constrains structure. It cannot constrain *content*: a conformant
resource can carry `<script>` doing anything, and the renderer's sandbox is the
real boundary (p9-04).

The normalizer's security role is narrower than a first reading suggests. With
`externalUrl` out of scope (p9-01 task 1.3c) there is no URL in its input to
scheme-check, so it rejects out-of-scope **content shapes** instead — a
`script`/`framework`/`iframeUrl` payload never reaches the host. Link-scheme
validation lives at runtime in p9-04 task 2.7, where the URLs actually appear.

## Scope

```
scripts/normalize-mcp-ui.mjs                     # new — the only file edited
```

`references/schemas/mcp-ui-resource.schema.json` is a **read-only input**, not
scope: p9-01 owns it. If this change needs a schema fix, that signals p9-01's
verification was insufficient — record it rather than patching across the
boundary. Tests needing a modified schema use a scratchpad copy via the
normalizer's schema-path override (task 1.2).

## Non-goals

- No HTML emission. Phase-8 found two `prompts/execute.md` instructions
  directing an HTML-injection step that does not exist; the renderer is a
  runtime component (p9-04), not a template substitution.
- No `remoteDom`.
