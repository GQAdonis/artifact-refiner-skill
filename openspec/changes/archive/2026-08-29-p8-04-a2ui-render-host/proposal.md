# Proposal: p8-04 — A2UI render host (adopt @a2ui/react)

**Change ID**: p8-04-a2ui-render-host
**Phase**: phase-8-scaffold-a2ui-host
**Status**: specified
**Origin**: analyze D-003 (ADOPT, condition now satisfied); G-1/G-4 moot under alignment
**Depends on**: p8-01, p8-02

## Summary

Template sources that render an A2UI surface in React, using the official
renderer. p8-05 wires them into a scaffolded app.

## Adopt `@a2ui/react@0.10.2` (Apache-2.0)

Analyze recorded this as ADOPT conditional on G-8; the operator chose alignment,
so the condition holds. Hand-writing a component interpreter that upstream
already ships and maintains would be rebuilding, not building — and the existing
Lit `renderNode` is proof of how that goes: three lowercase cases that could
never match our own schema, shipped and never exercised.

**Costs, stated plainly:**

- Pre-1.0 at `0.10.2` — **pin exact**, as p7-03/p7-04 did for `@ag-ui/*`.
- **npm lags the repo:** repo pushed 2026-08-28, package last published
  2026-07-17 (~6 weeks). Do not depend on a protocol feature newer than the
  package.
- **`@a2ui/markdown-it` is declared `*`** — an unbounded range in a published
  dependency. A lockfile pins it in practice; the smell remains.
- peer `react@^19.2.7` — verified satisfied (npm latest `19.2.8`;
  `scaffold-react-vite.sh:148` targets React 19).

`@a2ui/web_core@0.10.6` arrives transitively and is the framework-agnostic seam
if a non-React host is ever needed.

## Streaming, because A2UI is streaming-first

Assess claimed A2UI was a static document; analyze corrected that from upstream
("streaming JSON objects from an agent to a renderer… progressive rendering").
The host therefore applies envelope messages **incrementally** — a
`createSurface` followed by `updateComponents` and `updateDataModel` must update
the rendered surface without a reload.

This is the same architecture phase-7 built for AG-UI: a store owning the
subscription, reducing a message stream into renderable state. Placement follows
`references/scaffolds/state-architecture.md` (stores own I/O, hooks read stores,
components read hooks) exactly as p7-04 did.

## Scope

- `assets/scaffold/a2ui/surface-store.ts` (new)
- `assets/scaffold/a2ui/use-surface.ts` (new)
- `assets/scaffold/a2ui/a2ui-surface.tsx` (new)
- `assets/scaffold/a2ui/mock-surface-source.ts` (new)
- `package.json` — `@a2ui/react` pinned exact

## Out of scope

`callFunction` / `actionResponse` round-tripping, multi-surface management, and
custom catalogs. v1 renders a surface and applies updates to it.
