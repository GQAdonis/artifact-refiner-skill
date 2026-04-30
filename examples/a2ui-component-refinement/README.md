# A2UI Component Refinement Example

End-to-end demonstration of the `direct:a2ui` content type: schema validation, binding-graph cycle detection, and deterministic normalization.

## What's here

| File | Purpose |
|---|---|
| `source.a2ui.json` | Hand-authored login-card spec — three components, four bindings (literal, expression, ref), one inline `$ref` from a component. The positive path. |
| `broken-circular.a2ui.json` | Same shape, but with bindings forming the cycle `a → b → c → a`. The negative path. |
| `dist/previews/login-card/` | Output of running the normalizer against `source.a2ui.json`. |
| `dist/previews/broken-circular/` | Output of running the normalizer against the broken spec — only the failure report is written. |
| `artifact_manifest.json` | Manifest covering both runs, including the `validation.negative_path_proven` flag. |

## Reproducing

From the repo root:

```bash
node scripts/normalize-a2ui.mjs \
  --input examples/a2ui-component-refinement/source.a2ui.json \
  --artifact-id login-card \
  --out-dir examples/a2ui-component-refinement/dist/previews/login-card
# OK — exit 0, writes normalized.a2ui.json + normalize-report.json

node scripts/normalize-a2ui.mjs \
  --input examples/a2ui-component-refinement/broken-circular.a2ui.json \
  --artifact-id broken-circular \
  --out-dir examples/a2ui-component-refinement/dist/previews/broken-circular
# Failed — exit 1, prints binding_cycle violation, writes normalize-report.json
```

## What the normalizer guarantees

- **Schema conformance** against `references/schemas/a2ui-component.schema.json` (required `version` field, PascalCase component types, kebab-case ids, valid binding shapes).
- **No undefined bindings**: every `$ref` from a component or `kind: ref` binding must point to a key that exists in `spec.bindings`.
- **No binding cycles**: the bindings graph is checked with iterative DFS; cycles are reported as the offending path.
- **Deterministic output**: `bindings` keys are sorted alphabetically; component fields appear in the order `id, type, props, bindings, children`.

## What it does NOT do

- It does not generate HTML. That stays with the existing `render-preview.mjs` pipeline plus `assets/templates/a2ui-preview-template.html`.
- It does not enforce per-component-type prop schemas. `props` is opaque. A future change can add type-specific schemas under `references/schemas/a2ui-types/`.
- It does not resolve expression bindings. `kind: expression` strings are kept as-is and evaluated by the runtime.

## Linking

Routed via `direct:a2ui` (see `references/content-types.md`). Domain adapter: `references/domain/a2ui.md`. Schema: `references/schemas/a2ui-component.schema.json`.
