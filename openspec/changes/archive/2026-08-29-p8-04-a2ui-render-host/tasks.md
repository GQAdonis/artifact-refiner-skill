# Tasks: p8-04-a2ui-render-host

**scope**:
- `assets/scaffold/a2ui/{surface-store.ts,use-surface.ts,a2ui-surface.tsx,mock-surface-source.ts}`
- `package.json` (`@a2ui/react` pinned exact)

**Path contract (consumed downstream).** These filenames are read by name by
p8-05. Renaming breaks p8-05 with no gate catching it — update both in the same
commit if a path must change.

## Dependency

- [x] 1.1 Add `@a2ui/react` at **exact** `0.10.2` — no caret (pre-1.0).
- [x] 1.2 Record in design notes the transitive set and the two risks: npm
      publish lags the repo by ~6 weeks, and `@a2ui/markdown-it` is declared `*`.
- [x] 1.3 Verify the installed peer `react` satisfies `^19.2.7` in the target,
      rather than assuming from npm's latest.

## Store (owns all I/O)

- [x] 2.1 `surface-store.ts` — zustand+immer store holding
      `{ surfaceId, catalogId, components: Record<id, Component>, componentOrder,
      dataModel, status, error }`.
- [x] 2.2 Expose `initRealtime()` per `state-architecture.md:185`; subscribing
      anywhere else violates line 210.
- [x] 2.3 `createSurface` replaces the surface wholesale.
- [x] 2.4 `updateComponents` **merges by id** — updating one component must not
      drop the others. Replacing the map would look correct on a single-component
      surface and silently lose siblings on any real one.
- [x] 2.5 `updateDataModel` merges into `dataModel` so `{"path": …}` leaves
      re-resolve; existing components must re-render without being re-sent.
- [x] 2.6 `deleteSurface` clears **store** state, and records itself in
      `unrenderableOps`. Scoped deliberately: `@a2ui/react@0.10.2` implements
      protocol v0.9 and does not implement `deleteSurface` at all (grep: 0
      occurrences in the package). The store honours the validated v1.0
      contract; the renderer cannot, and nothing here claims it does.
- [x] 2.7 Export the reducer as a standalone pure function so it is testable
      without a store, a network, or React — the p7-04 pattern.
- [x] 2.8 The store must not import `react`.

## Hook and component

- [x] 3.1 `use-surface.ts` selects store state; no `fetch`, no `EventSource`, no
      subscription logic.
- [x] 3.2 `a2ui-surface.tsx` renders via `@a2ui/react`, feeding it the resolved
      components and `dataModel`. Do not hand-write a component switch — that is
      the defect this change exists to avoid.
- [x] 3.3 An unknown component surfaces the renderer's own error rather than
      falling back to a JSON dump.

## Mock source

- [x] 4.1 `mock-surface-source.ts` yields a scripted envelope sequence:
      `createSurface` → `updateDataModel` → `updateComponents`, so progressive
      application is exercised rather than a single create.

## Verification

- [x] 5.1 Unit: `createSurface` then `updateComponents` on one id leaves the
      other components intact (guards 2.4).
- [x] 5.2 Unit: `updateDataModel` changes what a `{"path": …}` leaf resolves to,
      with no component message in between (guards 2.5).
- [x] 5.3 Unit: `deleteSurface` clears state.
- [x] 5.4 Unit: applying an envelope sequence defined **inline in this change's
      test** produces a component map matching its ids. Deliberately does NOT
      read `examples/a2ui-component-refinement/` — p8-03 is a sibling, not an
      ancestor, so that fixture may still be in the old dialect when p8-04 runs.
      The example-based check belongs to p8-05's smoke gate, where both are
      already upstream.
- [x] 5.5 `grep -n "EventSource\|fetch(" ` over hook and component (comments
      stripped) returns nothing.
- [x] 5.6 `grep -n "from 'react'" assets/scaffold/a2ui/surface-store.ts` returns
      nothing.
- [x] 5.7 `no-hardcoded-secrets` (blocking): the mock surface source needs no
      credentials — assert none were introduced.
      `grep -rn 'sk-\|api_key\|API_KEY' assets/scaffold/a2ui/` returns nothing.
- [x] 5.8 `marketplace-validates` (blocking):
      `bash scripts/validate-marketplace.sh` exits 0. This change edits
      `package.json`, which the manifest validation reads.
- [x] 5.9 `no-stub-comments` (warning): no TODO/FIXME/STUB/HACK in the new
      template sources.
