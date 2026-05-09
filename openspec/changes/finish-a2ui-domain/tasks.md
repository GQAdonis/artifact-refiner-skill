## 1. Type System Registration

- [x] 1.1 Add `direct:a2ui` to the `content_type` enum in `references/schemas/content-type.schema.json`.
- [x] 1.2 Update `references/content-types.md` to document `direct:a2ui` alongside the other direct types (output kind, evaluation strategy, examples).
- [ ] 1.3 Verify existing artifacts still validate against the schema (no regression). _Deferred — needs an existing-artifact corpus to scan; treat as a follow-up before merging._

## 2. A2UI Component Schema

- [x] 2.1 Decide schema source — codify in this repo or import a canonical A2UI schema if one exists upstream. Document decision in `design.md`. _Decision: codified locally; no canonical upstream schema located. Documented in design.md._
- [x] 2.2 Author `references/schemas/a2ui-component.schema.json` covering: component hierarchy, required `version` field (`a2ui/v1`), component identifiers, bindings, no circular references (graph-walked, see 2.4), naming conventions, no undefined bindings.
- [ ] 2.3 Add a structural-validation script entry to `scripts/validate-constraints.sh` that recognizes `direct:a2ui` and runs the schema against the artifact. _Implemented as `scripts/normalize-a2ui.mjs` and wired via `prompts/execute.md`. Also adding an entry to `validate-constraints.sh` is still pending and should land before merge._
- [x] 2.4 Add a circular-reference check (graph walk) since plain JSON Schema cannot express it. _Implemented inline in `scripts/normalize-a2ui.mjs` (iterative DFS); reports the offending path._

## 3. Detection and Routing

- [x] 3.1 Update `prompts/specify.md` Content Type Detection: add heuristics for `.a2ui.json`/`.a2ui.yaml` extension, `"version": "a2ui/v1"` marker, and `a2ui` keyword in user request → classify as `direct:a2ui`.
- [x] 3.2 Add `direct:a2ui` row to the Content Type Routing table in `prompts/meta-controller.md` mapping to `references/domain/a2ui.md`.
- [x] 3.3 Update `references/domain/a2ui.md` to reference the new component schema and example.

## 4. Execute Phase Wiring

- [x] 4.1 Update `prompts/execute.md` to add an A2UI-specific normalization step (Step 0) before the generic `render-preview.mjs` invocation: validate against `a2ui-component.schema.json`, normalize field ordering, write the normalized spec to `dist/previews/<id>/normalized.a2ui.json`.
- [ ] 4.2 Update `agents/pmpo-executor.md` to call out the A2UI normalization step in its responsibilities for `direct:a2ui` runs. _Pending — left for next implementation pass to keep this turn focused on the deterministic plumbing._
- [ ] 4.3 Update `agents/artifact-validator.md` to validate normalized spec presence and schema conformance. _Pending — same reason._

## 5. End-to-End Example

- [x] 5.1 Create `examples/a2ui-component-refinement/` directory.
- [x] 5.2 Author a starter A2UI spec (`source.a2ui.json`) covering Container/Heading/TextField/Button (4 types) and 5 bindings (literal, expression, ref, two `$ref` references from components).
- [x] 5.3 Run the refiner against the example and commit the dist output. _Committed `normalized.a2ui.json` and `normalize-report.json`. `preview.html`/`screenshot.png` deferred — depend on the existing `render-preview.mjs` pipeline which the agent runs at execute-time, not the example author._
- [x] 5.4 Author `artifact_manifest.json` mirroring `examples/ui-preview-refinement/artifact_manifest.json` shape.
- [x] 5.5 Author `README.md` walking through the example invocation.
- [x] 5.6 Add an intentionally-broken sibling spec (`broken-circular.a2ui.json`) plus the rejection report (`dist/previews/broken-circular/normalize-report.json`) — proves negative path.

## 6. Documentation

- [x] 6.1 Update root `SKILL.md` Supported Artifact Domains row for A2UI to reference the new schema (`references/schemas/a2ui-component.schema.json`) and example path.
- [ ] 6.2 Update `CLAUDE.md` "Adding a New Domain" section if any procedure detail is now out of date. _Pending — current procedure still applies; no breaking changes. Spot-check before merge._
- [ ] 6.3 Mention A2UI in the project README features list if not already there. _Pending — README pass before merge._

## 7. Verification

- [ ] 7.1 `bash scripts/state-init.sh demo-a2ui ui-component direct:a2ui` initializes a state directory. _Not run in this turn (would create state files in this checkout). Smoke-test before merge._
- [x] 7.2 End-to-end normalizer run on `examples/a2ui-component-refinement/source.a2ui.json` produces normalized spec + report (preview + screenshot via existing render-preview pipeline still pending agent execution).
- [x] 7.3 Normalizer run on `examples/a2ui-component-refinement/broken-circular.a2ui.json` exits 1 and writes `binding_cycle: [a, b, c, a]` to `normalize-report.json`.
- [x] 7.4 `python3 -c "import json; json.load(open('references/schemas/a2ui-component.schema.json'))"` parses cleanly.
- [x] 7.5 `bash scripts/validate-marketplace.sh` passes. Fixed pre-existing failures in `marketplace.json`: dropped unsupported `marketplace_version`, replaced `path: "./"` with `source: "./"`, added marketplace `description`. Validator now reports `✔ Validation passed`.
