# Design: p8-04 — A2UI render host

## Dependency pin

| Package | Version | Range | License |
|---|---|---|---|
| `@a2ui/react` | `0.10.2` | **exact — no caret** | Apache-2.0 |

Transitive set: `@a2ui/web_core@^0.10.5`, `@a2ui/markdown-it@*`, `clsx@^2.1.1`,
`markdown-it@^14.2.0`, `zod@^3.25.76`.
Peers: `react@^19.2.7`, `react-dom@^19.2.7`, `zod@^3.25.76` — **verified**
against the installed package metadata.

**Risks, as recorded in analyze and confirmed here:**

- Pre-1.0 (`0.10.2`); pinned exact so an upstream break is a deliberate bump.
- npm publish lags the repo — package `2026-07-17`, repo pushed `2026-08-28`.
- `@a2ui/markdown-it` is declared `*`, an unbounded range in a published
  dependency. A lockfile pins it in practice; the smell remains.

## The version discrepancy (found during execute)

`@a2ui/react@0.10.2` implements **protocol v0.9**, not v1.0. Its own README says
so:

> | Protocol | v0.8 (Legacy): `BeginRendering`, `SurfaceUpdate` | **v0.9 (Current): `createSurface`, `updateComponents`, `updateDataModel`** |

The shipped bundles contain `beginRendering` / `surfaceUpdate` /
`dataModelUpdate`; the v1.0 key names appear **only in the README**, never in
code. `deleteSurface` appears nowhere in the package.

Meanwhile p8-01's schema encodes v1.0 — `version: "v1.0"` and six operations —
taken from the upstream `specification/v1_0/` docs.

### What actually overlaps

| Operation | p8-01 schema (v1.0) | `@a2ui/react` (v0.9) |
|---|---|---|
| `createSurface` | ✅ | ✅ |
| `updateComponents` | ✅ | ✅ |
| `updateDataModel` | ✅ | ✅ |
| `deleteSurface` | ✅ | ❌ not implemented |
| `callFunction` | ✅ | ❌ |
| `actionResponse` | ✅ | ❌ |

Flat component arrays and `{"path": "/x"}` data-model bindings are identical
across both. **The example this repo ships is structurally renderable today** —
only the `version` string and the three unimplemented operations differ.

### Decision — operator, at execute

Build the store for the **overlap**, not for either version in isolation:

- The store reduces **all six** operations the schema admits, so it stays honest
  to the contract p8-01 defines and p8-02 validates.
- The **render path** and p8-05's browser-DOM gate exercise only the three the
  SDK implements. Nothing claims the renderer honours what it cannot.
- `deleteSurface` clears **store** state (task 2.6). That is a store guarantee,
  not a rendering guarantee, and is labelled as such in the code.

Rejected: re-speccing p8-01 down to v0.9 (reopens an archived change and
invalidates the example's version string for a gap that is three unused
operations wide), and hand-writing a v1.0 renderer (reverses analyze D-003 and
rebuilds what upstream maintains — the mistake the existing Lit renderer
already represents).

**Carry into p8-05:** the DOM gate must drive `createSurface` →
`updateDataModel` → `updateComponents`. A gate written around `deleteSurface`
would fail for a reason unrelated to the code under test.

## Streaming architecture

A2UI is streaming-first (assess got this wrong; analyze corrected it from
upstream). The host therefore applies messages **incrementally** — the same
shape phase-7 built for AG-UI.

Placement follows `references/scaffolds/state-architecture.md`: the store owns
the subscription and all I/O (line 20, 185), hooks read stores, components read
hooks, and attaching a listener anywhere else is the violation at line 210.

`reduceMessage` is exported as a standalone pure function so the reduction is
testable without a store, a network, or a React tree — the p7-04 pattern that
caught the append-vs-replace bug there.

## Path contract

`assets/scaffold/a2ui/{surface-store.ts,use-surface.ts,a2ui-surface.tsx,mock-surface-source.ts}`
are read **by name** by p8-05 task 1.4. Renaming breaks p8-05 with no gate
catching it — update both in the same commit.
