# AG-UI Spec Refinement Example

This example demonstrates end-to-end refinement of an AG-UI agent specification using
the artifact-refiner skill with content type `direct:ag-ui`.

## What is being refined

The artifact is an **agent-side AG-UI spec** — a JSON document that declares which tools
a Rust-native research agent exposes, which AG-UI events those tools emit, and which
UI component fragments bind to each event. It is NOT a runtime event trace.

The example agent (`prometheus-research-agent`) exposes three tools:
- `search_knowledge_base` — RAG vector search
- `synthesize_answer` — streaming text synthesis
- `update_shared_state` — frontend state synchronization

## Files

| File | Purpose |
|---|---|
| `source.ag-ui.json` | The input AG-UI spec for the Rust-native research agent |
| `broken-duplicate.ag-ui.json` | Intentionally invalid spec demonstrating constraint violations |
| `artifact_manifest.json` | Manifest recording validation runs and their outcomes |
| `dist/previews/rust-agent/normalized.ag-ui.json` | Normalized output (tools sorted, rules ordered) |
| `dist/previews/rust-agent/normalize-report.json` | Validation report — all constraints passed |
| `dist/previews/rust-agent/coverage-report.json` | Binding coverage — which tools emit which events |
| `dist/previews/broken-duplicate/normalize-report.json` | Failure report — duplicate tool name, unresolved ref, duplicate rule |

## Running the normalizer

```bash
# Positive path — should succeed (exit 0)
node scripts/normalize-agui.mjs \
  --input examples/ag-ui-spec-refinement/source.ag-ui.json \
  --artifact-id rust-agent \
  --out-dir examples/ag-ui-spec-refinement/dist/previews/rust-agent

# Negative path — should fail (exit 1) with constraint violations
node scripts/normalize-agui.mjs \
  --input examples/ag-ui-spec-refinement/broken-duplicate.ag-ui.json \
  --artifact-id broken-duplicate \
  --out-dir examples/ag-ui-spec-refinement/dist/previews/broken-duplicate
```

## Constraint violations demonstrated

The `broken-duplicate.ag-ui.json` file demonstrates all three cross-reference
violation types the normalizer enforces:

1. **`duplicate_tool_name`** — `fetch_data` appears twice in `tools[]`
2. **`unresolved_tool_ref`** — `event_emission[1].tool` references `nonexistent_tool`
   which is not in `tools[]`
3. **`duplicate_emission_rule`** — `(fetch_data, TOOL_CALL_START)` appears twice in
   `event_emission[]`

## Difference from A2UI

| Aspect | A2UI (`direct:a2ui`) | AG-UI (`direct:ag-ui`) |
|---|---|---|
| Artifact | UI component tree spec | Agent tool + event wiring spec |
| Key constraint | No circular binding refs | No duplicate tools; all event refs resolve |
| Validation evidence | Normalized spec + HTML preview | Normalized spec + coverage report |
| Preview | HTML rendered via `render-preview.mjs` | No HTML; coverage report is the evidence |
| Schema | `references/schemas/a2ui-component.schema.json` | `references/schemas/ag-ui-spec.schema.json` |
