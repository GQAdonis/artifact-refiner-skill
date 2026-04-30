## Why

A2UI is listed as a supported artifact domain in `SKILL.md` and has a domain doc at `references/domain/a2ui.md`, but the type system and routing do not yet recognize it as a first-class content type. There is no `direct:a2ui` value in `references/schemas/content-type.schema.json`, no JSON Schema codifying A2UI structural rules, no detection heuristic in `prompts/specify.md`, no routing entry in `prompts/meta-controller.md`, and no example demonstrating end-to-end A2UI refinement.

The previous browser-rendering change (`add-browser-rendering-for-htmx-react-artifacts`) shipped a generic `render-preview.mjs` that A2UI can already use. What is missing is the **type identity and validation** layer that makes A2UI specs distinguishable from generic UI/HTML and validates them against their actual structural rules rather than rendering only.

This change finishes the A2UI domain so refinement can flow Specify → Plan → Execute → Reflect with deterministic content-type detection, schema-backed constraint validation, and a working end-to-end example.

## What Changes

- Register `direct:a2ui` as a content-type value in `references/schemas/content-type.schema.json`.
- Add `references/schemas/a2ui-component.schema.json` codifying the A2UI component structural rules currently described prose-only in `references/domain/a2ui.md` (component hierarchy, no circular references, no undefined bindings, naming conventions, required fields).
- Add A2UI detection heuristics to `prompts/specify.md` Content Type Detection section so files with `.a2ui.json` extension or `version: "a2ui/v1"` field auto-classify as `direct:a2ui`.
- Add a `direct:a2ui` row to the Content Type Routing table in `prompts/meta-controller.md` mapping the type to `references/domain/a2ui.md`.
- Add an A2UI normalization pre-step to `prompts/execute.md` that runs before the existing preview rendering pipeline (validates against the new component schema; normalizes field ordering).
- Add `examples/a2ui-component-refinement/` with `artifact_manifest.json`, a starter A2UI spec, dist output, and README — mirrors the layout of `examples/ui-preview-refinement/`.
- Update root `SKILL.md` Supported Artifact Domains row for A2UI to reference the new schema and example paths.

## Capabilities

### New Capabilities

- `a2ui-content-type` — Registers `direct:a2ui` as a content type so detection, routing, and evaluation can branch on it explicitly.
- `a2ui-component-schema` — JSON Schema for A2UI component specs that constraint validation can reference for deterministic structural checks.
- `a2ui-detection-routing` — Specify-phase detection heuristics and meta-controller routing so A2UI specs are recognized without explicit user typing.
- `a2ui-example` — End-to-end A2UI refinement example covering manifest, source spec, dist output, and validation report.

### Modified Capabilities

- None. The browser preview rendering capabilities from `add-browser-rendering-for-htmx-react-artifacts` are reused unchanged; A2UI plugs into the existing render pipeline rather than replacing it.

## Impact

- **Affected files**: `references/schemas/content-type.schema.json`, `references/schemas/a2ui-component.schema.json` (new), `prompts/specify.md`, `prompts/meta-controller.md`, `prompts/execute.md`, `examples/a2ui-component-refinement/` (new), `SKILL.md`.
- **No new dependencies**. Validation uses existing JSON Schema tooling; rendering uses existing `scripts/render-preview.mjs`.
- **No breaking changes**. Adding a new enum value to `content_type` is additive. Existing artifacts continue to type as `direct:html`, `direct:react`, etc.
- **MCP/tooling impact**: none. No `.mcp.json` change required.
