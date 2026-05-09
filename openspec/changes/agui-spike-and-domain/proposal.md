# Proposal: AG-UI Agent Specification Domain

**Change ID**: change-002-agui-spike-and-domain
**Status**: branch-pushed
**Branch**: agui-spike-and-domain
**Repo**: GQAdonis/artifact-refiner-skill
**PR URL**: https://github.com/GQAdonis/artifact-refiner-skill/pull/new/agui-spike-and-domain
**Depends on**: change-001-finish-a2ui-domain (merged via PR #1, SHA 522d3da)

## Summary

Add `direct:ag-ui` as a first-class content type for refining AG-UI agent
specifications — the static JSON/YAML documents that declare an agent's tools,
event emission rules, and UI fragment bindings for AG-UI / CopilotKit frontends.

The spike confirms PMPO fit: AG-UI specs are structured, schema-validatable,
have cross-reference integrity constraints, and converge deterministically. The
domain mirrors the A2UI domain in scope and implementation style.

## Spike Decision

**Yes — ship the domain.**

See `references/domain/ag-ui-spike.md` for the full fit assessment. Key finding:
the refiner processes the *spec document* (a static authored artifact), not live
event streams (which are ephemeral and not refinable by PMPO).

## Files Added

- `references/domain/ag-ui-spike.md` — Fit assessment and spike decision
- `references/domain/ag-ui.md` — Domain adapter (mirrors a2ui.md shape)
- `references/schemas/ag-ui-spec.schema.json` — JSON Schema draft-07
- `scripts/normalize-agui.mjs` — Zero-dependency normalizer and coverage reporter
- `examples/ag-ui-spec-refinement/source.ag-ui.json` — Positive path example (Rust-native research agent)
- `examples/ag-ui-spec-refinement/broken-duplicate.ag-ui.json` — Negative path example
- `examples/ag-ui-spec-refinement/README.md` — Example walkthrough
- `openspec/changes/agui-spike-and-domain/proposal.md` — This file
- `openspec/changes/agui-spike-and-domain/tasks.md` — Task checklist
- `openspec/changes/agui-spike-and-domain/design.md` — Design rationale

## Files Modified

- `SKILL.md` — Bumped to v1.2.0; added AG-UI to description, triggers, domains
- `prompts/specify.md` — AG-UI detection heuristics (file extension, spec marker, intent keywords)
- `prompts/meta-controller.md` — Routing row and evaluation strategy row for direct:ag-ui
- `prompts/execute.md` — AG-UI normalization step (coverage report as evidence artifact)
- `references/schemas/content-type.schema.json` — Added `direct:ag-ui` to enum

## Verification

- `node scripts/normalize-agui.mjs --input examples/ag-ui-spec-refinement/source.ag-ui.json ...` exits 0
- `node scripts/normalize-agui.mjs --input examples/ag-ui-spec-refinement/broken-duplicate.ag-ui.json ...` exits 1 with duplicate_tool_name, unresolved_tool_ref, duplicate_emission_rule violations
- All 9 JSON schemas parse without error
