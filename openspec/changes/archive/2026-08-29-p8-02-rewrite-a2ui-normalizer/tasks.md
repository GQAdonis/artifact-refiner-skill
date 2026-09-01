# Tasks: p8-02-rewrite-a2ui-normalizer

**scope**: `scripts/normalize-a2ui.mjs`

**Contract note:** the accepted vocabulary and envelope shape come from
`references/schemas/a2ui-component.schema.json` (p8-01). Derive them by reading
that file at runtime — do not hardcode a second copy. A hand-maintained duplicate
is exactly how p7-02's `TOOL_CALL_ARGS_DELTA` survived in two places at once.

## Envelope

- [x] 1.1 Accept a message with `version` plus exactly one operation key; reject
      zero or multiple with a named error.
- [x] 1.2 Validate `createSurface` requires `surfaceId`, `catalogId`,
      `components`.
- [x] 1.3 Reject the old dialect shape with an error that *names* it —
      "this is the pre-alignment a2ui format; see p8-01" — rather than a generic
      schema failure. Anyone with an old spec should learn why, not just that.

## Flat component graph

- [x] 2.1 Index `components[]` by `id`; error on duplicate ids.
- [x] 2.2 Resolve `child` / `children[]` id references; error on any id with no
      matching component.
- [x] 2.3 Detect cycles over the id-reference graph. Losing cycle detection while
      changing models would be a silent regression of shipped behaviour.
- [x] 2.4 Error on components unreachable from the root — orphans indicate a
      generation bug and currently pass unnoticed.

## Data model

- [x] 3.1 Resolve `{"path": "/x"}` leaves against `dataModel`; error on a path
      that resolves to nothing.
- [x] 3.2 Accept plain JSON primitives as static leaves.

## Expression rejection (closes assess Q3)

- [x] 3.3 Reject any expression-like construct in a `DynamicString` leaf — a
      string that is neither a plain primitive nor a `{"path": …}` reference —
      with a named error. Assess Q3 asked whether to evaluate, sandbox, or reject
      arbitrary expressions and recommended rejection for v1.
      **Q3 is closed here, not by `callFunction`.** The G-8 decision table called
      it moot because the protocol defines `callFunction`, but p8-04 explicitly
      defers `callFunction` round-tripping — so nothing in this change set would
      have closed it. An unreviewed evaluator must not reach a scaffolded app by
      omission.
- [x] 3.4 The old dialect's `{"kind": "expression", "expression": "..."}` form is
      rejected by 1.3's format check; assert it explicitly so the arbitrary-JS
      path cannot survive the migration.

## Vocabulary

- [x] 4.1 Validate each `component` against the catalog the schema declares,
      read from the schema rather than duplicated here.
- [x] 4.2 An unknown component is a **hard error**, never a fallback render.
      Silent degradation is what let the Lit renderer look functional while
      rendering nothing (assess F-2).

## Gate

- [x] 5.1 The upstream canonical example normalizes clean, exit 0.
- [x] 5.2 Cycle rejected with the participating ids named — verified against an
      equivalent fixture (`a.child=b`, `b.child=a`) built here, reporting
      `reference_cycle: ['a','b','a']`. The *shipped* `broken-circular` example
      is rewritten by p8-03; re-assert there against the real file.
- [x] 5.3 Old dialect rejected with the format-specific message, asserted by
      matching on 'pre-alignment' rather than exit code alone. Verified against
      a fixture here; p8-03 adds the permanent corpus fixture.
- [x] 5.4 A `{"path": "/missing"}` reference is rejected.
- [x] 5.5 An unknown component type is rejected (4.2).
- [x] 5.6 A duplicate id is rejected.
- [x] 5.8 An expression-like `DynamicString` leaf is rejected with the named
      error from 3.3 (asserted by matching the message, not just a non-zero
      exit).
- [x] 5.7 `node --check scripts/normalize-a2ui.mjs` passes and
      `bash scripts/validate-marketplace.sh` exits 0 (`marketplace-validates`).
- [x] 5.9 `schemas-parse` (blocking): every schema under `references/schemas/`
      still parses. This change reads the schema at runtime, so a malformed one
      would surface here as a confusing runtime failure rather than a parse error.
