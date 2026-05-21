# Tasks: phase-3-conversion-layer

Sequenced. Convert script first; then rebrand (which reuses some of convert's helpers); then integration smoke.

## 1. Dependencies + sample inputs

- [ ] 1.1 Add npm devDependencies via `pnpm add -D parse5 @babel/parser @babel/generator @babel/traverse @babel/types culori @iarna/toml`.
- [ ] 1.2 Verify `pnpm install` produces a clean lockfile.
- [ ] 1.3 Author `assets/templates/sample-htmx.html` — small HTMX + Alpine.js artifact. Must exercise:
  - Plain HTML elements (h1, p, div, button)
  - `class="..."` attributes (must become `className`)
  - Inline `style="background: var(--color-bg)"`
  - One Alpine `x-data="{ count: 0 }"` controller
  - One `@click="count++"` handler
  - One `x-text="count"` binding
  - One `hx-post="/api/foo" hx-target="#bar" hx-swap="innerHTML"` button (the ambiguous region)
- [ ] 1.4 Author `assets/library/brands/prometheus-ags.toml` using the session-doc Prometheus tokens (Cinzel/Syne/DM Sans display, ember `#E96A12`, charcoal surfaces).

## 2. WCAG contrast helper

- [ ] 2.1 Author `scripts/lib/wcag-contrast.mjs`. Exports:
  - `contrastRatio(fg, bg)` → number (uses culori for color parsing)
  - `wcagLevel(ratio, size?)` → "AAA" | "AA" | "A" | "FAIL"
  - `report(pairs)` → array of `{ fg, bg, ratio, level }`
- [ ] 2.2 Self-test: black on white = 21.0; white on white = 1.0.

## 3. convert-htmx-react.mjs

- [ ] 3.1 Author `scripts/convert-htmx-react.mjs` with sections:
  - CLI parsing (`--source`, `--feature-name`, `--output`, `--ambiguous-sidecar` (default: `<output>.ambiguous.md`))
  - HTML parsing via `parse5.parseFragment`
  - Walker that emits JSX as a string (or via babel AST → generator) handling:
    - HTML element name → JSX (preserve case for custom components; lowercase for HTML)
    - `class` → `className`, `for` → `htmlFor`
    - `style="a: b"` → `style={{ a: "b" }}`
    - Self-closing tags closed properly
    - Text nodes preserved
  - Alpine detection + lift: `x-data="..."` → `useState` calls; emit a named hook `use<FeatureName>State` if present
  - Event handler conversion: `@click="expr"` → `onClick={() => expr}` (with simple-expr safety guard)
  - HTMX detection: any `hx-*` attribute → write to ambiguous sidecar, leave a marker comment in JSX
  - Emit:
    - `export default function <PascalName>() { ... }` (kebab feature name → PascalCase component name)
    - Named hook exports (if Alpine present)
    - Imports for any shadcn `Button`, `Input`, etc. (detect by tag name like `<Button>` if user wrote them; otherwise none)
- [ ] 3.2 Make script executable (`chmod +x` not required for `.mjs`; invoke via `node`).
- [ ] 3.3 Smoke: `node scripts/convert-htmx-react.mjs --source assets/templates/sample-htmx.html --feature-name smoke-htmx --output /tmp/converted.tsx`. Output must:
  - Parse as TSX (`pnpm dlx -p typescript tsc --noEmit --jsx preserve --target es2022 --moduleResolution bundler /tmp/converted.tsx` exits 0, modulo `Cannot find module 'react'` which is acceptable in standalone check)
  - Contain `export default function`
  - Contain a `useState` call (from the Alpine lift)
  - Have generated `<artifact>.ambiguous.md` listing the HTMX swap region

## 4. rebrand-artifact.mjs

- [ ] 4.1 Author `scripts/rebrand-artifact.mjs`:
  - CLI: `--source <tsx> --from-brand <name> --to-brand <name> --output <tsx> [--css-output <css>] [--ignore-contrast]`
  - Load both brand TOMLs via `@iarna/toml`
  - Build token delta: list every `from.<path>` whose value ≠ `to.<path>`
  - AST-parse source via `@babel/parser` (with JSX + TS plugins)
  - `@babel/traverse` walks `StringLiteral` nodes whose value matches any from-brand hex; replace with corresponding to-brand value
  - For `var(--color-*)` references: do NOT modify the TSX; the CSS file holds the canonical values
  - Regenerate the brand-vars CSS via `template-forge render --template vite-shell-css --brand <to-brand> ...` written to `--css-output` (default: `<output-dir>/index.css`)
  - Post-step: WCAG contrast report on the new palette pairs; if any FAIL and `--ignore-contrast` not set, print a warning but still emit the output
- [ ] 4.2 Smoke: `node scripts/rebrand-artifact.mjs --source assets/templates/sample-app.tsx --from-brand knowme --to-brand prometheus-ags --output /tmp/rebranded.tsx --css-output /tmp/rebranded.css`. Must:
  - Produce non-empty rebranded.tsx + rebranded.css
  - `rebranded.css` contains the prometheus-ags ember color
  - Print a contrast report

## 5. Integration smoke (the critical gate)

- [ ] 5.1 End-to-end: `node scripts/convert-htmx-react.mjs --source assets/templates/sample-htmx.html --feature-name smoke-htmx --output /tmp/converted.tsx`
- [ ] 5.2 `bash scripts/scaffold-react-vite.sh --name smoke-htmx --source /tmp/converted.tsx --brand knowme --target /tmp/smoke-converted`
- [ ] 5.3 Verify `pnpm build` inside `/tmp/smoke-converted` succeeds.
- [ ] 5.4 If step 5.3 fails, diagnose: is it a converter issue (bad TSX) or a scaffolder issue (something about the converted shape the scaffolder didn't expect)? Fix the appropriate side.

## 6. Update SKILL.md files

- [ ] 6.1 Update `skills/convert-htmx-react/SKILL.md`:
  - Replace the "Procedure" section's "use code-interpreter" hand-wave with a "Procedure: Dispatch to script" block pointing at `node scripts/convert-htmx-react.mjs --source ... --feature-name ... --output ...`
  - Add "Reviewing Ambiguous Regions" section explaining the sidecar markdown and the LLM's role
- [ ] 6.2 Update `skills/rebrand-artifact/SKILL.md`:
  - Replace the "Procedure" section with dispatch to `node scripts/rebrand-artifact.mjs ...`
  - Add "Contrast Validation" section explaining the report + `--ignore-contrast` override

## 7. Acceptance gates

- [ ] 7.1 `scripts/convert-htmx-react.mjs` exists and runs.
- [ ] 7.2 `scripts/rebrand-artifact.mjs` exists and runs.
- [ ] 7.3 `scripts/lib/wcag-contrast.mjs` exists; self-test passes.
- [ ] 7.4 `assets/templates/sample-htmx.html` exists.
- [ ] 7.5 `assets/library/brands/prometheus-ags.toml` exists; loads correctly via template-forge.
- [ ] 7.6 Converted TSX passes `tsc --noEmit` standalone check.
- [ ] 7.7 Rebrand produces non-empty deltas when from-brand ≠ to-brand.
- [ ] 7.8 **End-to-end integration:** convert → scaffold → `pnpm build` succeeds.
- [ ] 7.9 Both SKILL.md files point at the new scripts.
- [ ] 7.10 Ambiguous-region sidecar is generated when HTMX `hx-*` is present in source.

## Out of scope

- `convert-md-to-htmx` execution
- `refine-moodboard` execution
- `design-svg-logo` execution
- React → HTMX (reverse direction)
- Multi-file source artifacts
- Tailwind class normalization (left to refine-ui)

## Recommended agents

| Tasks | Agent |
|---|---|
| 1.* | direct authoring |
| 2.* | direct + self-test |
| 3.* | direct (largest single task — may want `code-architect` for the walker design) |
| 4.* | direct |
| 5.* | verify-app |
| 6.* | direct edit |
| 7.* | verify-app |
| Post-execute review | code-reviewer + typescript-reviewer |
