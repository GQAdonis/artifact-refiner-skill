## Design Notes — finish-a2ui-domain

### Schema source decision (open)

Two options for `references/schemas/a2ui-component.schema.json`:

1. **Codify in this repo** — write a JSON Schema that captures the rules currently described in prose at `references/domain/a2ui.md`. Pro: zero external dependency; we control evolution. Con: drift risk if there is or emerges a canonical A2UI spec we should track.
2. **Import a canonical upstream A2UI schema** — if A2UI ships a published JSON Schema (search before authoring), embed it and pin the version. Pro: stays in sync with the protocol. Con: external dependency; need a sync process when upstream changes.

**Decision (to be filled in during task 2.1)**: search for an upstream canonical schema first. If one exists with a permissive license, prefer option 2 with a vendoring note in this design file. If none exists or the existing one is incomplete, use option 1 and document the divergence here.

### Why a normalization step before render-preview.mjs

`render-preview.mjs` shipped in `add-browser-rendering-for-htmx-react-artifacts` is HTML-document-oriented. A2UI specs are JSON component trees. Trying to render an A2UI spec as-is treats it as opaque text. The normalization step:

- Validates structurally before any render attempt (fails fast on schema/constraint violations)
- Resolves binding references (so the renderer sees concrete component instances, not symbolic refs)
- Writes a deterministic field ordering so screenshot diffs are stable

The renderer itself stays unchanged — it consumes the normalized HTML produced by an A2UI-aware adapter that ships as part of this change. The adapter is a small Node module called by `prompts/execute.md`.

### Circular-reference detection

JSON Schema cannot express "no cycles in the bindings graph." Two options:

- Add a graph-walk helper in `scripts/lib/` and call it from `validate-constraints.sh` when content type is `direct:a2ui`.
- Inline the cycle check inside the A2UI normalization adapter (since it walks the tree anyway).

Default choice: **inline the cycle check inside the normalization adapter** — single pass, single failure point, no extra script to maintain. The script-side check stays generic and JSON-Schema-only.

### Example layout discipline

`examples/a2ui-component-refinement/` mirrors `examples/ui-preview-refinement/` exactly to keep the mental model consistent. The only legitimate divergence is file extensions (`.a2ui.json` vs `.tsx`/`.html`). If we deviate from the reference layout, document why here.

### What this change explicitly avoids

- **No new render script.** `render-preview.mjs` is reused; we add a normalization adapter, not a parallel renderer.
- **No new MCP tool.** Detection and routing live in prompts; validation lives in schemas.
- **No A2UI-specific hooks.** The existing PostToolUse / SubagentStop hooks cover the lifecycle.
- **No AG-UI work.** That is a separate change (`agui-spike-and-domain`) gated on this one.
