# Tasks: p8-01-align-a2ui-schema

**scope**:
- `references/schemas/a2ui-component.schema.json` (rewritten)
- `references/domain/a2ui.md` (rewritten to describe the real protocol)

## Re-verify upstream before writing

- [x] 1.1 Re-query Context7 `/a2ui-project/a2ui` for the v1.0 envelope keys,
      `ComponentCommon`, and `DynamicString`. The repo was pushed the same day as
      this spec; do not write a schema against a stale reading.
- [x] 1.2 **On any divergence from what this proposal records: HALT and
      re-spec.** Tasks 2.x hard-code the envelope key set and the flat-array
      shape. Writing them against a changed protocol produces a *new* wrong
      schema that looks authoritative — the exact failure this phase exists to
      correct.

## Schema

- [x] 2.1 Replace the root shape: a message is an object with `version` plus
      **exactly one** of `createSurface`, `updateComponents`, `updateDataModel`,
      `deleteSurface`, `callFunction`, `actionResponse`. Enforce
      exactly-one — `oneOf`, not `anyOf`, so a message carrying two operations
      is rejected rather than silently taking the first.
- [x] 2.2 `createSurface` requires `surfaceId`, `catalogId`, `components`;
      `dataModel` and `surfaceParams` optional.
- [x] 2.3 Components are a **flat array**, not a nested tree. Each entry requires
      `id` and `component`. Parent-child links are id *strings* (`child`,
      `children[]`), never inline objects.
- [x] 2.4 `component` is the discriminator. Do not reintroduce a `type` key
      anywhere.
- [x] 2.5 Model `DynamicString`: a leaf is either a JSON primitive or a
      `{"path": "/pointer"}` reference into `dataModel`.
- [x] 2.6 Set `$id` to a path under our namespace but record the upstream
      `catalogId` it targets, so the file states plainly that it *expresses*
      someone else's protocol rather than defining one.
- [x] 2.7 Remove `bindings`, `binding`, `bindingRef`, and `componentType` — the
      dialect's definitions. Leaving them would let old-shape specs partially validate.

## Domain doc

- [x] 3.1 Rewrite `references/domain/a2ui.md` to describe the real protocol:
      envelope operations, flat components, `dataModel` + `path` refs, catalogs.
- [x] 3.2 Cite upstream explicitly (repo, spec paths, Context7 library id) with
      the re-verification command. The absence of any upstream citation is what
      let the dialect drift unnoticed.
- [x] 3.3 Record that A2UI is **streaming-first** — messages arrive
      progressively over a JSON Lines transport. The prior doc implied a static
      document, which is what produced the wrong architecture in assess.

## Gate

- [x] 4.1 `python3 -c "import json; json.load(open('references/schemas/a2ui-component.schema.json'))"`
      exits 0.
- [x] 4.2 The upstream canonical example (proposal, `createSurface` with
      `Card`/`Column`/`Text`/`Button`) **validates** against the new schema.
- [x] 4.3 Our old shipped example (`{version, metadata, bindings, root}`) is
      **rejected**. If it still validates, the dialect survived.
- [x] 4.4 A message carrying two envelope operations is rejected (2.1).
- [x] 4.5 `grep -n '"type"\|bindings\|componentType' references/schemas/a2ui-component.schema.json`
      returns no dialect remnants.
- [x] 4.6 `bash scripts/validate-marketplace.sh` exits 0 (`marketplace-validates`).
- [x] 4.8 `schemas-parse` (blocking): EVERY schema under `references/schemas/`
      parses, not just the one edited —
      `for f in references/schemas/*.json; do python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" || exit 1; done`.
      Task 4.1 checks only the a2ui schema; this change hand-edits JSON, and the
      constraint is directory-wide.
- [x] 4.9 `references-resolve` (blocking): every `references/...` path cited in
      `prompts/` still resolves. This change rewrites
      `references/domain/a2ui.md`, which `prompts/` cites.
- [x] 4.7 The schema records its upstream provenance (task 2.6): assert by grep
      that it contains both the target `catalogId` and a reference to
      `a2ui.org`/`a2ui-project`. Without this check 2.6 is unverifiable, and an
      un-cited schema is precisely how the dialect drifted unnoticed.
