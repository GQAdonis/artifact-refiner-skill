# Tasks: phase-3b-aux-conversions

Three execution layers ship together. Order matters only at the "shared substrate" level: install deps + templates first; scripts second; SKILL.md + smoke last.

## 1. Dependencies + sample inputs

- [ ] 1.1 `pnpm add -D markdown-it markdown-it-anchor gray-matter` at the artifact-refiner root. Verify `pnpm install` produces a clean lockfile.
- [ ] 1.2 Author `assets/templates/sample-md-document.md` — small Markdown doc exercising GFM (table, task list, code block, bold/italic, link, image alt-text, heading levels h1-h3).
- [ ] 1.3 Author `assets/templates/sample-moodboard-brief.json` — a use-case brief (audience, aesthetic, palette mode) to feed the moodboard smoke. Used as placeholder-mode input; LLM mode synthesizes from CLI flags.

## 2. Minijinja templates

- [ ] 2.1 Author `tools/template-forge-rs/templates/moodboard.html`. Sections:
  - Hero: brand name + tagline
  - Palette: light + dark swatches with hex labels + WCAG ratio annotations (rendered via culori at script time, passed as data)
  - Typography: display/ui/body/mono specimens (h1, h2, body, code) — uses brand.typography
  - Motifs: tile grid showing motif name + description + visual hint (placeholder rectangles colored from palette)
  - Tone: chip row of phrases
- [ ] 2.2 Author `tools/template-forge-rs/templates/logo-icon.svg` Minijinja template. Renders 512×512 SVG with brand initial centered on a rounded-rect of `brand.colors.dark.ember`. Same shape as the existing PWA icon generator in phase-4 B.4.
- [ ] 2.3 Smoke: render both via `template-forge render --brand knowme --template moodboard` and `--template logo-icon`. Verify output is well-formed HTML / SVG.

## 3. SVG validation helper

- [ ] 3.1 Author `scripts/lib/svg-validate.mjs`. Exports:
  - `isValidSvg(text)` → `{ valid: bool, reasons: string[] }`
  - Checks: parse5 parses without errors; opens with `<svg`; closes with `</svg>`; no `<script>` tags anywhere; no `on*=` event-handler attributes; no `javascript:` URLs in `href`/`xlink:href`.
- [ ] 3.2 Self-test: known-good SVG passes; SVG with `<script>` fails; SVG with `onclick=` fails; truncated SVG fails.

## 4. convert-md-to-htmx.mjs

- [ ] 4.1 Author `scripts/convert-md-to-htmx.mjs`. Inputs (flags):
  ```
  --source <md-path>      (required)
  --brand <brand-name>    (required)
  --output <html-path>    (required)
  [--document-type article|brief|spec|moodboard|none] (default: article)
  ```
- [ ] 4.2 Pipeline:
  - Read MD source; extract YAML/TOML frontmatter via `gray-matter` (optional — frontmatter overrides flags)
  - markdown-it config: GFM, auto-link, heading anchors via `markdown-it-anchor`
  - Wrap output in semantic HTML based on `--document-type`:
    - `article` → `<article>` with `<header>`, `<main>`, `<footer>`
    - `brief` / `spec` → similar, with optional TOC
    - `moodboard` → routes to `refine-moodboard.mjs` instead (with a warning that this isn't the right tool for that)
    - `none` → bare HTML
  - Render brand CSS via `template-forge render --template vite-shell-css --brand <brand>` → inline `<style>` block
  - Single self-contained HTML file
- [ ] 4.3 Smoke: convert `sample-md-document.md` with `--brand knowme` → produces valid HTML, brand colors present, semantic structure intact.

## 5. refine-moodboard.mjs

- [ ] 5.1 Author `scripts/refine-moodboard.mjs`. Inputs (flags):
  ```
  --use-case <description>      (required)
  --audience <descriptor>        (required)
  --aesthetic <keywords>         (required, comma-separated)
  [--brand <brand-name>]         (optional — anchors the palette to an existing brand)
  --output <html-path>           (required)
  [--mode llm|placeholder]       (default: llm when proxy reachable)
  [--palette-mode light|dark|both] (default: both)
  ```
- [ ] 5.2 LLM path (when `--mode llm`):
  - Construct a structured prompt requesting JSON: `{ palette: { light, dark }, typography: { display, ui, body, mono }, motifs: [...], tone: [...] }`
  - Call `chat("refiner-evaluate", ...)` — moodboard generation needs the medium tier per `model_policy`
  - Validate JSON shape against expected schema (hand-rolled validator); fall back to placeholder if invalid
  - Reject responses containing prompt-injection markers (`SYSTEM:`, `IGNORE PREVIOUS`, etc.) — strict tone for v1
- [ ] 5.3 Placeholder path (or LLM fallback):
  - If `--brand` supplied: use that brand's palette + typography
  - Else: neutral gray palette, system fonts, "design TBD" placeholder motifs
- [ ] 5.4 Render via `template-forge` against the `moodboard.html` template with the spec passed as brand-data-shaped context.
  - For non-branded moodboards, generate a synthetic in-memory BrandData object and write it to a temp TOML; render against that.
- [ ] 5.5 Compute WCAG contrast via `culori` for each text-on-background pair in the rendered palette; embed the table in the HTML output as part of the palette section.
- [ ] 5.6 Smoke (placeholder): `node scripts/refine-moodboard.mjs --use-case "developer tool" --audience "backend engineers" --aesthetic "minimal, mono" --brand knowme --output /tmp/mb.html --mode placeholder` → produces HTML.
- [ ] 5.7 Smoke (LLM): same command without `--mode` → either LLM result OR placeholder fallback; log line in `.refiner/moodboard/model-routing.log`.

## 6. design-svg-logo.mjs

- [ ] 6.1 Author `scripts/design-svg-logo.mjs`. Inputs (flags):
  ```
  --brand-name <name>           (required)
  --brief <one-line>            (required)
  [--style <keywords>]
  [--primary-color <hex>]
  --output-dir <dir>            (required)
  [--mode llm|placeholder]      (default: llm)
  [--variants icon,wordmark,lockup]  (default: all three)
  [--png-sizes 16,32,64,128,256,512] (default)
  ```
- [ ] 6.2 LLM path per variant:
  - Construct a structured prompt: "Produce a self-contained SVG <variant> for brand '<name>'. Style: <keywords>. Primary color: <hex>. Must be valid SVG, no scripts, no event handlers, viewBox set, all paths flattened."
  - Call `chat("refiner-iterate", ...)` — small tier per `model_policy`
  - Validate via `isValidSvg()`; if invalid OR if `HostHarnessRoutingError`, fall back to placeholder for that variant
- [ ] 6.3 Placeholder path:
  - Render `tools/template-forge-rs/templates/logo-icon.svg` via template-forge
  - For wordmark / lockup variants: deterministic SVG generation in JS (text element with brand display font, centered)
- [ ] 6.4 PNG export: for each PNG size requested, use `rsvg-convert` if available; else copy SVG to `.png` filename with warning (same pattern as phase-4 B.4 PWA icons).
- [ ] 6.5 Smoke (placeholder): `--brand-name "KnowMe" --brief "identity layer" --primary-color "#E04E28" --output-dir /tmp/logo --mode placeholder` → produces 3 SVG + 18 PNG (3 variants × 6 sizes).
- [ ] 6.6 Smoke (LLM): same command without `--mode` → produces 3 SVGs (some may be LLM, some may fall back) + PNG exports + audit log lines.

## 7. SKILL.md updates

- [ ] 7.1 Update `skills/convert-md-to-htmx/SKILL.md`:
  - Replace "Procedure" section with dispatch to `node scripts/convert-md-to-htmx.mjs ...`
  - Document frontmatter override behavior
  - Document supported document types
- [ ] 7.2 Update `skills/refine-moodboard/SKILL.md`:
  - Replace "Procedure" section with dispatch to `node scripts/refine-moodboard.mjs ...`
  - Document `--mode llm|placeholder` behavior + fallback semantics
  - Note that this is the first LLM-primary skill; the LLM produces structured JSON, template renders
- [ ] 7.3 Update `skills/design-svg-logo/SKILL.md`:
  - Replace "Procedure" section with dispatch to `node scripts/design-svg-logo.mjs ...`
  - Document mode + validation behavior + PNG fallback
  - Cross-reference to `refine-logo` for production brand-system work

## 8. Acceptance gates

- [ ] 8.1 `scripts/convert-md-to-htmx.mjs` exists; sample MD converts cleanly with brand CSS.
- [ ] 8.2 `scripts/refine-moodboard.mjs` exists; placeholder mode produces HTML; LLM mode produces HTML or falls back cleanly.
- [ ] 8.3 `scripts/design-svg-logo.mjs` exists; placeholder mode produces 3 valid SVG + PNG; LLM mode same with fallback.
- [ ] 8.4 `scripts/lib/svg-validate.mjs` self-test passes (good SVG OK; `<script>`/`on*=`/truncated all rejected).
- [ ] 8.5 `tools/template-forge-rs/templates/moodboard.html` renders for `knowme` with valid HTML output.
- [ ] 8.6 `tools/template-forge-rs/templates/logo-icon.svg` renders for `knowme` with valid SVG output.
- [ ] 8.7 All three SKILL.md files updated; head -5 frontmatter validates.
- [ ] 8.8 `package.json` includes the three new devDeps.

## Out of scope

- Syntax highlighting, advanced markdown plugins, multi-page moodboards, animated SVG, AI raster generation, trademark checking, template-forge `--data` flag.

## Recommended agents

| Tasks | Agent |
|---|---|
| 1.*, 2.* | direct authoring |
| 3.* | direct + self-test |
| 4.*, 5.*, 6.* | direct authoring + verify-app for smoke |
| 7.* | direct edit |
| 8.* | verify-app |
| Post-execute review | code-reviewer + typescript-reviewer |
