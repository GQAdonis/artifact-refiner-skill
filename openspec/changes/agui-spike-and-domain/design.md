# Design: AG-UI Domain

## Artifact boundary decision

The refiner processes **agent-side AG-UI specs** (static JSON/YAML authored by the
agent developer) — NOT runtime event traces. This boundary is the key finding from
the spike and is documented in `references/domain/ag-ui-spike.md`.

Runtime traces are ephemeral stream output; they are not refinable by PMPO.
Specs are static and converge deterministically.

## Schema design

`ag-ui-spec.schema.json` uses JSON Schema draft-07 with `additionalProperties: false`
on all top-level and nested objects. Cross-reference integrity (tool names in
event_emission must reference declared tools; on_event values must be valid AG-UI
event kinds) is enforced by the normalizer, not the schema, because JSON Schema
cannot express cross-property referential integrity.

## Normalizer design

`normalize-agui.mjs` mirrors `normalize-a2ui.mjs` in architecture:

- Zero external dependencies (hand-rolled draft-07 subset validator)
- Deterministic key ordering: version → metadata → agent → tools → event_emission → custom_events
- Tools sorted by name; event_emission rules sorted by (tool, on_event)
- Three outputs: normalized.ag-ui.json, normalize-report.json, coverage-report.json
- Exit 0 on success; exit 1 on schema or cross-reference violations; exit 2 on I/O error

## Coverage report

AG-UI specs do not produce HTML previews (unlike A2UI). The evidence artifact
is `coverage-report.json`, which maps each tool to its emitted event kinds and
reports uncovered event kinds and tools with no emission rules.

This is the Reflect phase's primary signal for completeness — if a tool has no
emission rules, it may be an oversight worth flagging.

## Routing

The domain is wired at three points:
1. `prompts/specify.md` — detection heuristics (file extension `.ag-ui.json`, spec
   marker `"version": "ag-ui/v*"`, intent keywords)
2. `prompts/meta-controller.md` — routing table (ag-ui → references/domain/ag-ui.md)
   and evaluation strategy (direct:ag-ui → output_inspection via normalizer)
3. `prompts/execute.md` — normalization step (run normalize-agui.mjs; coverage report
   is the evidence artifact; no HTML preview)

## Tag strategy

A single `v1.2.0` tag will cover both A2UI (change-001) and AG-UI (change-002),
since both merged into main before any tag was cut. Tag is cut after PR #2 merges.
