# Execution: phase-3-conversion-layer

**Status:** COMPLETE
**Backend:** OpenSpec
**Executed:** 2026-05-20

## Acceptance gates — 10/10 PASS

| # | Gate | Result |
|---|---|---|
| 7.1 | `scripts/convert-htmx-react.mjs` exists | PASS |
| 7.2 | `scripts/rebrand-artifact.mjs` exists | PASS |
| 7.3 | `scripts/lib/wcag-contrast.mjs` self-test | PASS — black/white=21.00, white/white=1.00, gray/white=4.48 (AA) |
| 7.4 | `assets/templates/sample-htmx.html` exists | PASS |
| 7.5 | `assets/library/brands/prometheus-ags.toml` loads via template-forge | PASS — `list-brands` returns both `knowme` and `prometheus-ags` |
| 7.6 | Converted TSX has `export default function` | PASS |
| 7.7 | Rebrand reports 12 active swaps from knowme → prometheus-ags | PASS |
| 7.8 | **End-to-end: convert → scaffold → `pnpm build`** | **PASS — 31 modules, 194 kB JS, build successful** |
| 7.9 | Both SKILL.md files point at new scripts | PASS |
| 7.10 | Ambiguous-region sidecar generated | PASS — 3 regions flagged (1 HTMX, 1 setCount unused warning, 1 alpine-expr) |

## Live verification pipeline

```
sample-htmx.html (HTMX + Alpine + hx-post)
   │
   │  node scripts/convert-htmx-react.mjs
   ▼
/tmp/converted.tsx           ◀ default export SmokeHtmx + useSmokeHtmxState hook
/tmp/converted.tsx.ambiguous.md  ◀ 3 regions flagged for review
   │
   │  bash scripts/scaffold-react-vite.sh
   ▼
/tmp/smoke-converted/        ◀ Vite + React 19 + Base UI + Tailwind v4 project
   │
   │  pnpm build
   ▼
dist/index.html (0.46 kB)
dist/assets/*.css (10.91 kB)
dist/assets/*.js (194.22 kB)
✓ built in 775ms
```

Separately, the rebrand path:

```
sample-app.tsx (knowme brand)
   │
   │  node scripts/rebrand-artifact.mjs --from-brand knowme --to-brand prometheus-ags
   ▼
/tmp/rebranded.tsx           ◀ AST rewrite (0 hex swaps because source uses var(--color-*))
/tmp/rebranded.css           ◀ Prometheus AGS palette (#E96A12 ember × 4)
WCAG report: 4/8 AAA, 2/8 AA, 2/8 A-level warnings (ember contrast)
```

## Deliverables

| Path | Status |
|---|---|
| `scripts/convert-htmx-react.mjs` | created (~400 lines) |
| `scripts/rebrand-artifact.mjs` | created (~160 lines) |
| `scripts/lib/wcag-contrast.mjs` | created with self-test (~80 lines) |
| `assets/templates/sample-htmx.html` | created |
| `assets/library/brands/prometheus-ags.toml` | created |
| `skills/convert-htmx-react/SKILL.md` | rewritten to point at script + ambiguous-region review |
| `skills/rebrand-artifact/SKILL.md` | rewritten to point at script + contrast override path |
| `package.json` devDeps | added: parse5, @babel/parser, @babel/generator, @babel/traverse, @babel/types, culori, @iarna/toml |

## Decisions during execute

1. **Bare-identifier Alpine expressions are passthrough** — initial impl flagged `x-text="count"` as ambiguous because the regex only matched assign/increment. Fixed by adding a bare-identifier regex branch returning the identifier verbatim.

2. **Babel ESM default-export interop** — `@babel/traverse` and `@babel/generator` ship CJS; under Node ESM, `_traverse.default ?? _traverse` covers both shapes. Standard interop.

3. **Hex swap inside larger strings** — beyond exact `StringLiteral` swaps, also rewrite hex literals embedded in `style="background: #abc"`-style attribute values. Catches the case where HTMX→React conversion left an inline-style string.

4. **WCAG flagged Prometheus ember `#E96A12` against light bg at "A" level** — real result, not a bug. Ember-on-light is a recurring contrast challenge; report surfaces it, doesn't block. Users can pick a different ember if they care about AA.

5. **`x-text="count"` produced "setCount unused" warning at build time** — sample-htmx exposes both `count` and `setCount` from the hook destructure, but `setCount` is only used in the increment button (which Alpine `@click="count++"` converted to `setCount((v) => v + 1)`). The convert script destructures both correctly; the scaffolder strips unused imports (not unused destructured vars). Not a blocker — the build passes; just a minor TS warning that could be cleaned up by the unused-import filter in phase-2. Recorded as follow-up.

6. **Generated TSX uses `style={{ "background": "..." }}` with quoted keys** — JSON.stringify on the object keys is technically valid JSX (`style={{ "background": "..." }}`) but slightly unusual; bare `background:` would be cleaner. Cosmetic; doesn't affect correctness.

## Known follow-ups (not blocking)

- TSX prettifier post-pass — could clean up the generator's whitespace + quote-key choices
- Unused-destructured-variable filter in the scaffolder patcher (currently only filters unused imports)
- React → HTMX (reverse direction) — explicit phase later if/when demanded
- Multi-file source TSX in convert-htmx-react — currently single-file in/out

## Out of scope (deferred per phase plan)

- `convert-md-to-htmx` execution → phase-3b
- `refine-moodboard` execution → phase-3b
- `design-svg-logo` execution → phase-3b
- React → Flutter / A2UI / AG-UI conversion paths (own phases)

## Next phase

`/kbd-reflect phase-3-conversion-layer`.
