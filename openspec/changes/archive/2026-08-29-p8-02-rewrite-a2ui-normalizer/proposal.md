# Proposal: p8-02 — Rewrite the A2UI normalizer for the real protocol

**Change ID**: p8-02-rewrite-a2ui-normalizer
**Phase**: phase-8-scaffold-a2ui-host
**Status**: specified
**Origin**: G-8 ALIGN; G-3 reshaped
**Depends on**: p8-01 (the schema is the contract)

## Summary

Rework `scripts/normalize-a2ui.mjs` (350 lines) from the dialect to the real
protocol.

## What changes

The normalizer's core assumptions all move:

| Assumption | Was | Becomes |
|---|---|---|
| Document root | `{version, metadata, bindings, root}` | envelope with one operation key |
| Traversal | recursive descent through nested `children` objects | index a **flat array** by `id`, then walk id references |
| Cycle detection | over the `bindings` graph | over `child`/`children` **id references** |
| Reference integrity | `bindingRef` → `bindings` key | `{"path": "/x"}` → `dataModel` pointer |
| Vocabulary check | regex `^[A-Z][A-Za-z0-9]*$` | membership in the declared catalog |

## Cycle detection still matters, for a different graph

The current normalizer detects cycles in the bindings graph — the schema comment
notes JSON Schema cannot express acyclicity, so the adapter enforces it. That
requirement survives alignment, but the graph changes: a flat component array
with id references can describe a cycle (`a.child = b`, `b.child = a`) that no
JSON Schema catches either. Losing this while switching models would be a
silent regression.

`broken-circular.a2ui.json` exists to prove this path works. p8-03 rewrites it
against the new model rather than deleting it.

## Scope

- `scripts/normalize-a2ui.mjs`

## Out of scope

HTML emission. Under alignment the renderer is `@a2ui/react` at runtime (p8-04),
so the normalizer stays a validator/normalizer and never produces markup. This
is why assess's G-2 (template injector) is not in this change set.
