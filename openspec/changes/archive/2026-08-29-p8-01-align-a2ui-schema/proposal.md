# Proposal: p8-01 — Align the A2UI schema to the real protocol

**Change ID**: p8-01-align-a2ui-schema
**Phase**: phase-8-scaffold-a2ui-host
**Status**: specified
**Origin**: analyze G-8, resolved by the operator at the spec stage → ALIGN
**Depends on**: nothing — this is the contract every other p8-* change builds on

## Summary

Replace our locally-invented A2UI schema with one that expresses the actual
A2UI v1.0 protocol.

## Why

`direct:a2ui` shipped in PR #1 against a schema we authored
(`$id: https://artifact-refiner.dev/schemas/a2ui-component.schema.json`) that
cites no upstream. A2UI is a real protocol — `a2ui-project/a2ui`, 16,230 stars,
Apache-2.0, pushed 2026-08-28, with independent implementations in .NET, Swift,
Android, and React Native.

The two are not variants of one idea. They disagree about what a document *is*:

| | Ours (shipped) | Upstream A2UI v1.0 |
|---|---|---|
| Envelope | `{version, metadata, bindings, root}` | one of `createSurface` / `updateComponents` / `updateDataModel` / `deleteSurface` / `callFunction` / `actionResponse` |
| Component key | `"type": "Container"` | `"component": "Text"` — a `const` discriminator |
| Structure | nested tree, `children` inline | **flat array**, `children` are id strings |
| Data | `bindings` map (`literal`/`ref`/`expression`) | `dataModel` object + `{"path": "/title"}` refs |
| Vocabulary | open `^[A-Z][A-Za-z0-9]*$` | `catalog.json` declares the component set |

A spec our refiner validates is therefore not an A2UI document. Real agent output
fails our validator; ours cannot drive any real renderer.

## Upstream contract (external authority)

These paths live in `a2ui-project/a2ui`, **not in this repo**. Retrieved via
Context7 (`/a2ui-project/a2ui`); re-verify there rather than expecting them to
resolve locally.

- `specification/v1_0/docs/a2ui_protocol.md` — envelope model, the seven schema rules
- `specification/v1_0/common_types.json` — `ComponentCommon`, `DynamicString`
- `specification/v1_0/catalogs/basic/catalog.json` — the basic catalog

Canonical example of the target shape:

```json
{
  "version": "v1.0",
  "createSurface": {
    "surfaceId": "main",
    "catalogId": "basic",
    "components": [
      {"id": "root",   "component": "Card",   "child": "node_0"},
      {"id": "node_0", "component": "Column", "children": ["node_1", "node_2"]},
      {"id": "node_1", "component": "Text",   "text": {"path": "/title"}},
      {"id": "node_2", "component": "Button", "child": "node_3",
       "action": {"event": {"name": "accept"}}}
    ],
    "dataModel": { "title": "Enable notification" }
  }
}
```

## Breaking change — stated plainly

Both shipped examples become invalid. Anything authored against the old shape
breaks. The operator chose this explicitly: interoperability over compatibility
with a format that was never interoperable.

This change replaces the **contract only**. p8-02 reworks the normalizer and
p8-03 rewrites the examples; splitting them keeps each reviewable.

## Scope

- `references/schemas/a2ui-component.schema.json` — rewritten
- `references/domain/a2ui.md` — document the real protocol and cite upstream

## Out of scope

Catalog *authoring*. v1 targets the upstream `basic` catalog by id rather than
defining our own; a custom catalog is a later change if ever needed.
