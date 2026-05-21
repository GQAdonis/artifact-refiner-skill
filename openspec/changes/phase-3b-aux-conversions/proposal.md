# Proposal: phase-3b-aux-conversions

## Why

Phase-0 authored five conversion sub-skill specs. Phase-3 shipped execution for two (`convert-htmx-react`, `rebrand-artifact`) — those feed the headline scaffolder. Three remain spec-only:

1. `convert-md-to-htmx` — Markdown → branded HTMX document
2. `refine-moodboard` — use-case brief → branded HTMX moodboard
3. `design-svg-logo` — brand brief → SVG icon + wordmark + lockup + PNG export

This phase rounds out the phase-0 commitment. It also pressure-tests the chat() routing layer from `phase-prefer-endpoint-consumption` — `refine-moodboard` becomes the **first LLM-primary** consumer (LLM is the engine, not a sidecar).

## What Changes

- **ADDED** `scripts/convert-md-to-htmx.mjs` — deterministic markdown-it pipeline; renders into a brand-CSS-wrapped single-file HTML.
- **ADDED** `scripts/refine-moodboard.mjs` — LLM-primary: `chat()` returns structured JSON, Minijinja renders HTML; falls back to placeholder when proxy unhealthy.
- **ADDED** `scripts/design-svg-logo.mjs` — mode-switching: `--mode llm` requests SVG variants from `chat()` (with SVG parseability + XSS validation); `--mode placeholder` uses Minijinja template; LLM mode falls back to placeholder on validation failure.
- **ADDED** `scripts/lib/svg-validate.mjs` — `isValidSvg(string)` checks parseable, well-formed, no `<script>`, no event handlers.
- **ADDED** `tools/template-forge-rs/templates/moodboard.html` — Minijinja moodboard template (palette swatches, typography specimens, motif cards, tone pills).
- **ADDED** `tools/template-forge-rs/templates/logo-icon.svg` — Minijinja SVG placeholder (brand initial on ember rounded-rect).
- **MODIFIED** `skills/convert-md-to-htmx/SKILL.md` — points at the script + documents frontmatter support.
- **MODIFIED** `skills/refine-moodboard/SKILL.md` — points at the script + documents `--mode` flags.
- **MODIFIED** `skills/design-svg-logo/SKILL.md` — points at the script + documents mode + validation behavior.
- **MODIFIED** `package.json` — devDeps: `markdown-it`, `markdown-it-anchor`, `gray-matter`.

## Impact

### Affected surfaces

`scripts/`, `scripts/lib/`, `tools/template-forge-rs/templates/`, `skills/{convert-md-to-htmx,refine-moodboard,design-svg-logo}/`, `package.json`.

### Affected dependencies

New devDeps (small, well-known): `markdown-it`, `markdown-it-anchor`, `gray-matter`. No new MCP servers, no new submodules.

### Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| LLM-generated SVG fails parse / contains `<script>` | Medium | Low | `isValidSvg()` strict rejection → fall back to placeholder |
| LLM moodboard JSON malformed | Medium | Low | Validate shape; fall back to placeholder |
| markdown-it edge cases (unusual MD) | Low | Low | Pin version; document quirks |
| template-forge can't render moodboard's non-brand-shaped data | Medium | Low | Shape moodboard spec as brand-data extension (already what knowme.toml looks like with colors+typography) |
| PNG rasterization missing on user machine | Medium | Low | Same SVG-as-PNG-fallback pattern as phase-4 B.4 |

No high-severity unmitigated risk.

### Out of scope (deferred)

- Syntax highlighting in markdown output (Prism/Shiki post-build)
- Custom markdown plugins (footnotes, math) — bring-your-own
- Multi-page moodboards (single-file v1)
- Animated SVG logos
- AI raster image generation (DALL-E, Stable Diffusion)
- Logo trademark uniqueness checking
- template-forge `--data <json>` generic flag (use brand-data shape instead for v1)

## Integration with existing substrate

| Reused | Source phase | This phase's use |
|---|---|---|
| `scripts/lib/openai-client.mjs` (`chat()`) | phase-prefer-endpoint-consumption | LLM calls in moodboard + svg-logo scripts |
| `tools/template-forge-rs` Minijinja engine | phase-rust-workspace-bootstrap | Render moodboard + logo-icon templates |
| `vite-shell-css.html` brand-CSS rendering | phase-2 | Brand styling for md-to-htmx output + moodboard |
| `assets/library/brands/*.toml` | phase-2 | Brand data source |
| `culori` color science (for contrast in moodboard) | phase-3 | WCAG reporting on moodboard palettes |
| `parse5` (for SVG parseability) | phase-3 | SVG validation in svg-validate |

Net new: 3 scripts + 2 templates + 1 helper. ~700 lines total.
