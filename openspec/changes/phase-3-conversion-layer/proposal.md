# Proposal: phase-3-conversion-layer

## Why

Phase-0 authored five spec-only conversion skills that describe procedures but defer execution to "the PMPO loop with code-interpreter". Phase-2 shipped the scaffolder that expects a specific TSX input shape. The two are disconnected — users hand-edit TSX to match the scaffolder's expectations, or invoke the LLM in chat for each conversion.

Phase-3 ships the **execution layer** for the two conversion skills directly feeding phase-2:

- `convert-htmx-react` — HTMX/Alpine → React TSX
- `rebrand-artifact` — swap one brand TOML's tokens for another's

Both produce phase-2-ready output (single .tsx, default export, optional named hooks, brand-vars consumption). The remaining three phase-0 skills (`convert-md-to-htmx`, `refine-moodboard`, `design-svg-logo`) defer to `phase-3b-aux-conversions`.

## What Changes

- **ADDED** `scripts/convert-htmx-react.mjs` — Node script: `parse5` for HTML, `@babel/parser` for JSX emission, ambiguous-region sidecar for HTMX/Alpine constructs requiring LLM judgment.
- **ADDED** `scripts/rebrand-artifact.mjs` — Node script: load from-brand + to-brand TOMLs, compute token delta, AST-walk source TSX, swap matching hex literals, regenerate brand-CSS via existing `template-forge render --template vite-shell-css`.
- **ADDED** `scripts/lib/wcag-contrast.mjs` — small helper computing WCAG AA contrast ratios using `culori`; produces a report, not a gate.
- **ADDED** `assets/templates/sample-htmx.html` — small HTMX + Alpine.js artifact for smoke testing.
- **ADDED** `assets/library/brands/prometheus-ags.toml` — second brand for rebrand smoke testing (uses tokens from session doc §3).
- **MODIFIED** `skills/convert-htmx-react/SKILL.md` — point at the script + describe ambiguous-region review path.
- **MODIFIED** `skills/rebrand-artifact/SKILL.md` — point at the script + describe `--ignore-contrast` override path.
- **MODIFIED** `package.json` — add `parse5`, `@babel/parser`, `@babel/generator`, `@babel/traverse`, `@babel/types`, `culori`, `@iarna/toml` to devDependencies.

## Impact

### Affected surfaces

- `scripts/`, `scripts/lib/`, `skills/convert-htmx-react/`, `skills/rebrand-artifact/`, `assets/templates/`, `assets/library/brands/`, `package.json`

### Affected dependencies

New Node devDependencies:

- `parse5` (current major)
- `@babel/parser`, `@babel/generator`, `@babel/traverse`, `@babel/types`
- `culori`
- `@iarna/toml` (already used implicitly via toml plugin? confirm; if missing, add)

### Risk surface

- **Low** for `rebrand-artifact` — token swap is mechanical.
- **Medium** for `convert-htmx-react` — HTMX/Alpine surface is large; ambiguous-region sidecar is the safety valve.
- **Zero** for SKILL.md updates and brand TOML additions.

### Out of scope (deferred)

- `convert-md-to-htmx` execution → `phase-3b-aux-conversions`
- `refine-moodboard` execution → `phase-3b-aux-conversions`
- `design-svg-logo` execution → `phase-3b-aux-conversions`
- React → HTMX reverse direction (v1 is forward only)
- React → Flutter / A2UI / AG-UI fragment conversions (own phases)

## Integration contract with phase-2

Both scripts emit output that `scripts/scaffold-react-vite.sh` consumes without modification:

```
convert-htmx-react.mjs --source X.html --feature-name foo --output Y.tsx
  produces Y.tsx with:
    - default export = <component>
    - optional named hooks (extracted from inline Alpine `x-data` controllers)
    - imports from @/shared/components/ui/<name> for any shadcn primitives
    - JSX consuming var(--color-*) where source used branded styles

rebrand-artifact.mjs --source X.tsx --from-brand knowme --to-brand prometheus-ags --output Y.tsx
  produces Y.tsx with:
    - all from-brand hex literals swapped to to-brand equivalents
    - var(--color-*) references untouched (CSS file holds the actual values)
  plus Y.css regenerated for the to-brand
```

End-to-end smoke:

```
node scripts/convert-htmx-react.mjs --source assets/templates/sample-htmx.html --feature-name smoke-htmx --output /tmp/converted.tsx
bash scripts/scaffold-react-vite.sh --name smoke-htmx --source /tmp/converted.tsx --brand knowme --target /tmp/smoke-converted
# pnpm build inside /tmp/smoke-converted must succeed
```
