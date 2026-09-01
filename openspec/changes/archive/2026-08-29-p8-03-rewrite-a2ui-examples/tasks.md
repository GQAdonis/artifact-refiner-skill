# Tasks: p8-03-rewrite-a2ui-examples

**scope**:
- `examples/a2ui-component-refinement/{source,broken-circular}.a2ui.json`
- `examples/a2ui-component-refinement/artifact_manifest.json`
- `prompts/{meta-controller,specify,execute}.md`
- `references/content-types.md`
- `references/schemas/content-type.schema.json`

**Shared-file note:** `references/domain/a2ui.md` is rewritten by **p8-01**, not
here, even though it also references `direct:a2ui`. p8-03 depends on p8-01, so
the doc is already correct by the time this change runs. Do not edit it twice.

## Positive example

- [x] 1.1 Rewrite `source.a2ui.json` as a `createSurface` envelope with a flat
      `components` array.
- [x] 1.2 Include a `dataModel` and at least two `{"path": "/…"}` leaves, so a
      renderer that ignores data binding cannot pass the example.
- [x] 1.3 Include nested structure via `children` **id references**, proving the
      flat-array-with-links model rather than a disguised tree.
- [x] 1.4 Include an `action` with an `event`, so the interaction surface is
      covered — the current corpus tests no interactivity at all.
- [x] 1.5 Target the upstream `basic` catalog by `catalogId`.

## Negative example

- [x] 2.1 Rewrite `broken-circular.a2ui.json` as a cycle in the **id-reference**
      graph (`a.child = b`, `b.child = a`), preserving what the file has always
      tested under the new model.
- [x] 2.2 Add a second negative fixture in the **old dialect** (`{version,
      metadata, bindings, root}`) that must be rejected. Without it, nothing
      guards against the dialect creeping back — the same corpus blind spot that
      hid `TOOL_CALL_ARGS_DELTA` for a whole phase.

## Manifest and references

- [x] 3.1 Update `artifact_manifest.json` for the new example set.
- [x] 3.2 Update `references/content-types.md` — `direct:a2ui` now denotes the
      real protocol; note the alignment and that it was previously a local
      dialect.
- [x] 3.3 Verify `references/schemas/content-type.schema.json` still lists
      `direct:a2ui` and needs no enum change (the name is unchanged).
- [x] 3.4 Update the three `prompts/` files where their A2UI descriptions
      reference the old document shape.

## Gate

- [x] 4.1 `node scripts/normalize-a2ui.mjs` on the new positive example exits 0.
- [x] 4.2 The rewritten circular example is rejected with a cycle error.
- [x] 4.3 The old-dialect fixture is rejected with the format-specific message
      from p8-02 task 1.3.
- [x] 4.4 `grep -rn "bindings\|\"root\":" examples/a2ui-component-refinement/*.a2ui.json`
      returns nothing except the deliberate old-dialect fixture.
- [x] 4.5 `references-resolve`: every `references/...` path cited in `prompts/`
      still resolves.
- [x] 4.6 `schemas-parse`: every schema under `references/schemas/` parses.
- [x] 4.7 `no-brand-leakage` over shipped content returns nothing.
- [x] 4.8 `bash scripts/validate-marketplace.sh` exits 0.
