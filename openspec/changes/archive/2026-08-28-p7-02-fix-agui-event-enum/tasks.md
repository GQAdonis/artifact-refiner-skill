# Tasks: p7-02-fix-agui-event-enum

**scope**:
- `references/schemas/ag-ui-spec.schema.json`
- `scripts/normalize-agui.mjs`
- `references/domain/ag-ui.md`
- `references/domain/ag-ui-spike.md`
- `examples/ag-ui-spec-refinement/` (new fixture)

## Re-verify before editing

- [x] 1.1 Re-run the tarball extraction against `@ag-ui/core@0.0.59` and confirm
      the 23-kind list still matches what this change assumes. The package is
      pre-1.0 and published the same day as the analysis; do not edit the schema
      against a stale reading.
- [x] 1.2 **On mismatch: HALT and escalate — do not proceed.** Tasks 2.x and 3.x
      hard-code the specific kind list; running them against a different reading
      would write a new wrong enum while appearing to succeed. Report the actual
      diff (added/removed/renamed kinds) and re-spec before editing anything.
      A mismatch means the protocol moved, which is a re-analysis trigger, not
      a mechanical retry.

## Rename (the live defect)

- [x] 2.1 `references/schemas/ag-ui-spec.schema.json:76` — `TOOL_CALL_ARGS_DELTA` → `TOOL_CALL_ARGS`
- [x] 2.2 `scripts/normalize-agui.mjs:35` — same rename
- [x] 2.3 `references/domain/ag-ui.md:79` — same rename
- [x] 2.4 `references/domain/ag-ui-spike.md:16` — same rename
- [x] 2.5 Assert zero occurrences remain:
      `grep -rn "TOOL_CALL_ARGS_DELTA" . --include='*.json' --include='*.mjs' --include='*.md'`
      must return nothing (excluding `.kbd-orchestrator/` phase records, which
      document the defect deliberately).

## Add the ten missing kinds

- [x] 3.1 Add to the schema enum: `RAW`, `REASONING_MESSAGE_START`,
      `REASONING_MESSAGE_CONTENT`, `REASONING_MESSAGE_END`,
      `REASONING_MESSAGE_CHUNK`, `STEP_STARTED`, `STEP_FINISHED`,
      `TOOL_CALL_ARGS`, `TOOL_CALL_CHUNK`, `TOOL_CALL_RESULT`
- [x] 3.2 Mirror the same list into `scripts/normalize-agui.mjs`
- [x] 3.3 Document the new kinds in `references/domain/ag-ui.md`
- [x] 3.4 Assert schema and normalizer agree — extract both enums
      programmatically and compare as sets. They drifted apart once already.

## Close the corpus blind spot

- [x] 4.1 Add an example spec exercising the tool-call path
      (`TOOL_CALL_START` → `TOOL_CALL_ARGS` → `TOOL_CALL_END` →
      `TOOL_CALL_RESULT`). No current example covers it, which is why the
      wrong name survived review and shipped.
- [x] 4.2 Add a negative-path example using the old `TOOL_CALL_ARGS_DELTA` and
      assert the validator now **rejects** it.

## Gate

- [x] 5.1 `node scripts/normalize-agui.mjs` on both existing examples still passes
      (no regression).
- [x] 5.2 The new tool-call example validates clean.
- [x] 5.3 The negative-path example is rejected with a clear error.
- [x] 5.4 `bash scripts/validate-marketplace.sh` exits 0.
- [x] 5.5 `schemas-parse` (blocking): every schema still parses —
      `for f in references/schemas/*.json; do python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" || exit 1; done`
      exits 0. This change hand-edits an enum; a trailing comma would ship a
      broken schema that no other gate here catches.
- [x] 5.6 `references-resolve` (blocking): every `references/...` path cited in
      `prompts/` resolves —
      `grep -roh 'references/[a-zA-Z0-9/_.-]*' prompts/ | sort -u | while read f; do [ -e "$f" ] || exit 1; done`
      exits 0. This change edits two `references/domain/` files.
- [x] 5.7 `no-brand-leakage` (blocking): shipped content carries no legacy brand
      references —
      `grep -rn 'sediment://' prompts/ skills/ agents/ references/ assets/ README.md SKILL.md --include='*.md'`
      returns no matches (exit 1). This change adds example fixtures.
