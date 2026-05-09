# Tasks: change-002-agui-spike-and-domain

## Spike tasks

- [x] Author `references/domain/ag-ui-spike.md` covering AG-UI event types, run lifecycle, message envelope, tool-call protocol
- [x] Decision documented: **PMPO fits — ship the domain**

## Domain tasks

- [x] Author `references/domain/ag-ui.md` mirroring the shape of `a2ui.md`
- [x] Author `references/schemas/ag-ui-spec.schema.json`
- [x] Add `examples/ag-ui-spec-refinement/` with Rust-native research agent example and broken-duplicate negative path
- [x] Wire routing into `prompts/meta-controller.md` (routing table + evaluation strategy row)
- [x] Wire detection into `prompts/specify.md` (file extension, spec marker, intent keywords)
- [x] Wire execution step into `prompts/execute.md` (normalization → coverage report)
- [x] Add `direct:ag-ui` to `references/schemas/content-type.schema.json`
- [x] Update `SKILL.md` triggers and supported domains; bump to v1.2.0
- [x] Rebase on top of merged change-001 (main @ 522d3da)
- [x] Commit: `feat(ag-ui): add direct:ag-ui content type domain`
- [x] Push branch `agui-spike-and-domain` to origin

## Verification

- [x] normalize-agui.mjs exits 0 on positive path (source.ag-ui.json)
- [x] normalize-agui.mjs exits 1 on negative path (broken-duplicate.ag-ui.json) with correct violations
- [x] All 9 JSON schemas parse without error
- [ ] Cut upstream tag (v1.2.0 — covers A2UI + AG-UI; cut after PR #2 merges to main)

## Pending

- [ ] Open PR: https://github.com/GQAdonis/artifact-refiner-skill/pull/new/agui-spike-and-domain
- [ ] Merge PR (requires user authorization)
- [ ] Cut tag v1.2.0 on merged main
