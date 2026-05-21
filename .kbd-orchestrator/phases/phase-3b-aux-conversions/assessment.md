# Phase Assessment: Auxiliary Conversion Execution Layers

**Phase:** `phase-3b-aux-conversions`
**Project:** `artifact-refiner`
**Date:** 2026-05-20
**Author:** Claude Code (Opus 4.7, 1m context)
**Mode:** Assessment only — no implementation
**Sycophancy correction:** applied
**Predecessors:** phase-0 (skill specs), phase-2 (template-forge + brand TOMLs), phase-3 (convert-htmx-react + rebrand-artifact patterns), phase-prefer-endpoint-consumption (chat() helper)

---

## 1. Goal Restatement

Phase-0 authored five conversion sub-skill specs. Phase-3 shipped execution for two of them (`convert-htmx-react`, `rebrand-artifact`) — those feed the headline scaffolder. **Three remain spec-only:**

1. `convert-md-to-htmx` — Markdown → branded HTMX document
2. `refine-moodboard` — use-case brief → branded HTMX moodboard
3. `design-svg-logo` — brand brief → SVG icon + wordmark + lockup + PNG export set

This phase ships the execution layers. Like phase-3, each delivers a Node script under `scripts/` and updates the SKILL.md to point at it. Each can optionally use `chat()` (from phase-prefer-endpoint-consumption) for the parts where deterministic transforms run out.

### What done looks like

Three new scripts:

```
scripts/convert-md-to-htmx.mjs       # markdown-it + brand-CSS injection
scripts/refine-moodboard.mjs         # synthesize moodboard from inputs (LLM-assisted)
scripts/design-svg-logo.mjs          # SVG icon/wordmark/lockup generator + PNG export
```

Plus updated SKILL.md files pointing at each. Plus smoke verification: each script produces a valid output file (HTML or SVG) when given representative input.

---

## 2. Sycophancy-Corrected Assessment

The original phase-0 spec is correct in shape. Five corrections shape the scope.

### Correction 1 — `convert-md-to-htmx` is mostly deterministic; `chat()` is a fallback for ambiguous regions

Markdown → HTML is a solved problem (`markdown-it`, `marked`, `remark`). The deterministic transform handles 100% of standard markdown. The brand-CSS injection is also deterministic (the existing `template-forge render --template vite-shell-css` pattern works as-is). **There is no LLM judgment needed for v1.**

Where `chat()` could help: nothing in v1. Save it for v2 features like "auto-summarize a section" or "suggest a TOC structure" — but those are scope creep.

**Corrected goal:** `convert-md-to-htmx` is a pure Node script. No LLM calls. Just markdown-it + brand-CSS injection + semantic HTML wrapping.

### Correction 2 — `refine-moodboard` is genuinely creative; `chat()` does the heavy lifting

A moodboard from a use-case brief is the opposite of `convert-md-to-htmx`. There's no deterministic "moodboard renderer" — the inputs (use case, audience, aesthetic keywords) don't map to a fixed shape. Generating the actual palette, typography pairing, motif descriptions, and tone phrases is genuinely creative.

**Corrected goal:** `refine-moodboard.mjs` uses `chat()` extensively. It prompts the LLM to produce structured JSON (palette + typography + motifs + tone), then renders the JSON through a Minijinja moodboard template via `template-forge`. Two-stage: LLM produces structured content, deterministic renderer produces HTML.

This is the **first script in the repo where LLM is the primary engine**, not a sidecar. The chat-routing layer from phase-prefer-endpoint-consumption gets its biggest customer here.

### Correction 3 — `design-svg-logo` needs both deterministic placement AND LLM-suggested visual concept

The SVG primitives (paths, circles, viewBox) are deterministic. What goes inside — the actual icon design — is creative. Two paths:

- **Pure deterministic v1:** scaffolder emits a placeholder icon (first letter of brand on solid color, like the PWA icon generator already does). Useful for proof-of-concept; not useful for real branding.
- **LLM-assisted v1:** prompt `chat()` for SVG markup. Modern LLMs (GPT-5.x via openai-proxy) can generate respectable SVG icons from a brief.

**Corrected goal:** ship both modes. `design-svg-logo.mjs --mode placeholder` (deterministic, fast, brand-letter on color). `design-svg-logo.mjs --mode llm` (calls `chat()` with a structured prompt, validates the response is parseable SVG, falls back to placeholder if not). Default to `llm` when the proxy is reachable; fall back to `placeholder`.

### Correction 4 — All three output through existing template-forge + brand TOML substrate

None of these need new Minijinja templates beyond what exists. Specifically:

- `convert-md-to-htmx` renders into a `brand-guide.html`-shaped scaffold with the markdown body as `{{ content }}` — already templatable.
- `refine-moodboard` needs a new `moodboard.html` Minijinja template (one new template file).
- `design-svg-logo` writes SVG directly + uses `pwa-icon.svg`-style logic if we have it (need to add a `logo-icon.svg` template for the placeholder path).

**Corrected goal:** add **two** new Minijinja templates (`moodboard.html`, `logo-icon.svg` placeholder). Reuse `vite-shell-css.html`'s brand-CSS for moodboard's `<style>` block.

### Correction 5 — Don't reinvent `markdown-it` config; ship sensible defaults

Markdown processing has 30+ knobs (GFM tables, footnotes, container divs, code-block syntax highlighting, etc.). v1 ships:

- GFM-flavored markdown (tables, strikethrough, task lists)
- Auto-link bare URLs
- Code blocks with language class preserved (no syntax highlighting — users add Prism/Shiki post-build if they want)
- Heading anchors via `markdown-it-anchor`

Beyond that — escape hatch for users to bring their own config later. The scaffolder is opinionated; users tune per project.

---

## 3. Current state inventory

| Surface | Status |
|---|---|
| `scripts/convert-md-to-htmx.mjs` | does not exist |
| `scripts/refine-moodboard.mjs` | does not exist |
| `scripts/design-svg-logo.mjs` | does not exist |
| `tools/template-forge-rs/templates/moodboard.html` | does not exist |
| `tools/template-forge-rs/templates/logo-icon.svg` | does not exist |
| `tools/template-forge-rs/templates/md-document.html` | does not exist (might need; or reuse brand-guide pattern) |
| `skills/convert-md-to-htmx/SKILL.md` | exists; specs procedure only |
| `skills/refine-moodboard/SKILL.md` | exists; specs procedure only |
| `skills/design-svg-logo/SKILL.md` | exists; specs procedure only |
| `scripts/lib/openai-client.mjs` | exists (phase-prefer-endpoint-consumption) — ready to consume |
| `assets/library/brands/knowme.toml` + `prometheus-ags.toml` | exist (brand sources) |
| `markdown-it` Node package | not installed in package.json yet |

---

## 4. Architecture choices

### A. Two new Minijinja templates

`tools/template-forge-rs/templates/moodboard.html`:

Renders a moodboard from a structured JSON spec passed in via the template-forge `--data` or a custom render path. Layout:
- Hero with brand palette swatches
- Typography specimen grid (display, ui, body)
- Motif tiles (text descriptions in placeholder cards)
- Tone descriptor pills

`tools/template-forge-rs/templates/logo-icon.svg`:

A simple branded SVG icon (similar to the PWA icon generator) for the placeholder path of `design-svg-logo`. First letter of brand name centered on rounded-rect background colored with the brand's ember.

### B. Script shapes

**`scripts/convert-md-to-htmx.mjs`:**
```
node scripts/convert-md-to-htmx.mjs \
  --source <path-to-md> \
  --brand <brand-name> \
  --output <path-to-html> \
  [--document-type article|brief|spec|moodboard]
```

Pipeline: read MD → markdown-it → wrap in semantic HTML (`<article>`, `<section>`) → inject brand CSS (rendered via `template-forge render --template vite-shell-css`) → write single-file HTML.

**`scripts/refine-moodboard.mjs`:**
```
node scripts/refine-moodboard.mjs \
  --use-case <description> \
  --audience <descriptor> \
  --aesthetic <keywords> \
  [--brand <brand-name>] \
  --output <path-to-html> \
  [--mode llm|placeholder] (default: llm when proxy reachable)
```

Pipeline:
1. If `--mode llm`: prompt `chat("refiner-iterate", ...)` with a structured request → expect JSON back with `{ palette, typography, motifs, tone }`. Validate JSON; fall back to `placeholder` if invalid.
2. If `--mode placeholder` (or fallback): use a generic neutral moodboard (gray palette, system font, "design TBD" placeholder motifs).
3. Render via `template-forge render --template moodboard` with the spec as `{{ brand }}`-shaped context (or `--data` if template-forge supports it; otherwise extend the brand-data shape).

**`scripts/design-svg-logo.mjs`:**
```
node scripts/design-svg-logo.mjs \
  --brand-name <name> \
  --brief <one-line> \
  [--style <keywords>] \
  [--primary-color <hex>] \
  --output-dir <dir> \
  [--mode llm|placeholder] (default: llm)
  [--variants icon,wordmark,lockup] (default: all three)
  [--png-sizes 16,32,64,128,256,512] (default)
```

Pipeline:
1. If `--mode llm`: prompt `chat()` for each variant separately ("produce an SVG icon for ...", "produce an SVG wordmark for ...") → validate SVG parses → if not, fall back to placeholder
2. If `--mode placeholder`: render via `template-forge render --template logo-icon`
3. Rasterize to PNG via `rsvg-convert` if available (per the existing PWA icon code path)
4. Write `<output-dir>/<brand>-{icon,wordmark,lockup}.svg` + `<output-dir>/png/<brand>-icon-<size>.png`

### C. SVG validation

LLM-generated SVG must be **parseable**. Use a quick check: `parse5` (already a devDep) actually parses HTML; SVG inside HTML works. Or use `node:dom-parser`. Simplest: regex-check for `<svg` ... `</svg>` envelope and that it doesn't contain `<script>`. If invalid → fall back to placeholder + log.

### D. No new top-level dependencies needed

- `markdown-it` — new devDep (`pnpm add -D markdown-it markdown-it-anchor`)
- Everything else reuses existing devDeps from phase-3 (`@iarna/toml`, `culori`, `parse5`)
- LLM calls reuse `scripts/lib/openai-client.mjs` from phase-prefer-endpoint-consumption

### E. Phase-routing consistency

All three scripts use `chat(phaseKey, ...)` with `phaseKey: "refiner-iterate"` for generative work (moodboard JSON, SVG suggestion). This means:
- Their LLM calls show up in `.refiner/<artifact>/model-routing.log` like everything else
- They cost-route through openai-proxy when healthy, fall back to host-harness when down
- `--mode llm` becomes a no-op fallback to placeholder when `HostHarnessRoutingError` fires

---

## 5. Scope of this phase

### In scope

1. `scripts/convert-md-to-htmx.mjs` — deterministic markdown-it pipeline
2. `scripts/refine-moodboard.mjs` — LLM-driven palette/typography/motifs/tone synthesis + Minijinja render
3. `scripts/design-svg-logo.mjs` — LLM or placeholder SVG generator + PNG export
4. `tools/template-forge-rs/templates/moodboard.html` — new Minijinja template
5. `tools/template-forge-rs/templates/logo-icon.svg` — new placeholder SVG template
6. `scripts/lib/svg-validate.mjs` — small helper for parseability checks
7. SKILL.md updates for all three skills pointing at scripts
8. `package.json` devDep additions: `markdown-it`, `markdown-it-anchor`
9. Smoke tests for each script with representative inputs

### Out of scope (deferred)

- Syntax highlighting in `convert-md-to-htmx` (users add Prism/Shiki post-build)
- Custom markdown plugins (footnotes, definition lists, math) — bring-your-own
- Multi-page moodboard outputs (v1 is single-file)
- Animated SVG logos — placeholders are static; LLM may produce static SVG; defer animation
- AI image generation (DALL-E, Stable Diffusion) — text-to-SVG only, no raster generation
- Brand-tone phrase library (just-in-time via LLM is fine)
- Logo trademark uniqueness checking — out of scope for any phase

---

## 6. Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| LLM-generated SVG doesn't parse | Medium | Low | Fall back to placeholder; documented in `--mode` flag |
| LLM-generated SVG contains `<script>` (XSS surface) | Low | Medium | Reject any SVG with `<script>`; log + fall back |
| LLM-generated moodboard JSON malformed | Medium | Low | Validate against shape; fall back to placeholder; log |
| markdown-it produces unexpected output for edge MD | Low | Low | Pin version; document known edges |
| `template-forge` doesn't support `--data` for arbitrary JSON | Medium | Medium | Add a generic `--data <json-file>` flag to template-forge (small Rust change) OR shape input to look like a brand TOML |
| Network latency on LLM calls for SVG (multiple variants) | Medium | Low | Each variant is a separate small call; user can `--mode placeholder` to skip |
| PNG rasterization missing | Medium | Low | Falls back to copying SVG to .png (same pattern as phase-4 B.4) |

No high-severity unmitigated risk. The template-forge `--data` flag is the one new bit of infrastructure that may need a small Rust addition.

---

## 7. Acceptance criteria

1. `scripts/convert-md-to-htmx.mjs` exists; given a sample MD file + `--brand knowme`, produces a self-contained HTML with brand CSS injected.
2. `scripts/refine-moodboard.mjs` exists; with `--mode placeholder`, produces a generic moodboard HTML; with `--mode llm` and proxy reachable, produces an LLM-synthesized moodboard.
3. `scripts/design-svg-logo.mjs` exists; with `--mode placeholder`, produces SVG variants; with `--mode llm`, produces or falls back to placeholders cleanly.
4. `tools/template-forge-rs/templates/moodboard.html` and `logo-icon.svg` exist; render via template-forge with knowme.
5. `scripts/lib/svg-validate.mjs` exists with `isValidSvg(string)` checks.
6. All three SKILL.md files updated — point at scripts; document `--mode` flags.
7. `package.json` devDeps include `markdown-it` and `markdown-it-anchor`.
8. End-to-end smoke: a sample MD converts cleanly; a placeholder moodboard renders; placeholder logo SVGs are emitted.
9. LLM smoke (when proxy reachable): moodboard JSON request returns a valid spec; SVG request returns parseable SVG (or falls back cleanly).

9 acceptance gates.

---

## 8. Phase decomposition

| # | Sub-change | Effort |
|---|---|---|
| 1 | Install `markdown-it` + `markdown-it-anchor` devDeps; sample MD input | small |
| 2 | Author `tools/template-forge-rs/templates/moodboard.html` Minijinja template | medium |
| 3 | Author `tools/template-forge-rs/templates/logo-icon.svg` Minijinja template | small |
| 4 | Author `scripts/lib/svg-validate.mjs` | small |
| 5 | Author `scripts/convert-md-to-htmx.mjs` (deterministic pipeline) | medium |
| 6 | Author `scripts/refine-moodboard.mjs` (LLM-primary with fallback) | medium |
| 7 | Author `scripts/design-svg-logo.mjs` (mode-switching) | medium |
| 8 | Update three SKILL.md files | small |
| 9 | Decide on template-forge `--data` flag vs shape input as brand-data — implement if needed | medium (only if needed) |
| 10 | Acceptance gate sweep | small |

Estimated effort: one focused session if template-forge doesn't need extension; two if `--data` flag must be added.

---

## 9. Open questions

1. **template-forge `--data <json>` flag:** add it now (small Rust feature) or shape moodboard input to look like brand-data? Recommendation: shape input as brand-data for v1 (the shapes are similar enough); add `--data` as a separate phase if a real need surfaces.
2. **SVG `<script>` rejection:** strict (reject any SVG containing `<script>`) or lax (allow but warn)? Recommendation: strict. SVG with script is a CSS/HTML injection risk; placeholder is safer.
3. **Default `--mode` for `refine-moodboard` and `design-svg-logo`:** `llm` (with placeholder fallback) or `placeholder` (with `--mode llm` opt-in)? Recommendation: `llm` default — that's where the value lives. Falls back to placeholder when proxy down.
4. **Heading anchor style:** `markdown-it-anchor` defaults work or do we want GitHub-style?  Recommendation: defaults. Users override per project.
5. **PNG export sizes for logos:** `[16, 32, 64, 128, 256, 512]` matches the phase-0 spec. Match it or trim? Recommendation: match the spec.
6. **Should `convert-md-to-htmx` support frontmatter (YAML/TOML)?** Recommendation: yes — `gray-matter` is a tiny addition; lets users override `document-type`, `title`, etc. via frontmatter.

---

## 10. Honest verdict

This phase rounds out the phase-0 promise without inventing new architecture. Three small-to-medium scripts, two new Minijinja templates, one small validation helper. The LLM consumer pattern from `convert-htmx-react` extends naturally to `refine-moodboard` (which is its biggest use case yet) and `design-svg-logo`.

**Strategic value:** modest. Internally completes the conversion-skill set. Externally not a new headline capability — moodboards and quick logos are convenience features, not pipeline foundations.

**Recommendation:** proceed to `/kbd-plan phase-3b-aux-conversions`. Expected: one to two focused sessions. The `refine-moodboard` LLM integration is the most interesting work; the rest is glue.

---

## 11. Assessment metadata

```yaml
assessment_complete: true
phase: phase-3b-aux-conversions
prerequisites_met:
  phase-0: skill specs exist for all three
  phase-2: template-forge + brand TOMLs available
  phase-3: conversion-script pattern established
  phase-prefer-endpoint-consumption: chat() helper ready
scope_discipline_applied:
  - Three scripts, not more
  - convert-md-to-htmx is deterministic (no LLM)
  - refine-moodboard is LLM-primary
  - design-svg-logo has both modes
  - Reuse existing template-forge + brand-CSS substrate
  - Reuse phase-prefer-endpoint-consumption chat() helper
recommendation: |
  Proceed to /kbd-plan phase-3b-aux-conversions. One focused session if
  template-forge doesn't need extension; two if --data flag must be added.
next_command: /kbd-plan phase-3b-aux-conversions
```

Completed kbd-assess — phase-3b-aux-conversions
