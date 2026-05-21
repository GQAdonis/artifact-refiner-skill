# Plan: phase-3-conversion-layer

**Backend:** OpenSpec (`openspec/changes/phase-3-conversion-layer/`)
**Tasks:** `openspec/changes/phase-3-conversion-layer/tasks.md`
**Proposal:** `openspec/changes/phase-3-conversion-layer/proposal.md`
**Integration target:** phase-2-scaffold-react-vite

## Decisions baked in

- **Node, not Rust** — matches `compile-tsx-preview.mjs` / `render-preview.mjs` pattern
- **`parse5` for HTML** — spec-conformant
- **`@babel/parser`/`@babel/generator`/`@babel/traverse` for TSX AST** — most mature for JSX
- **`culori` for color science + WCAG** — handles OKLCH literals natively
- **`@iarna/toml` for brand TOML loading** — pure JS, no native bindings
- **Ambiguous-region sidecar** — bounded LLM judgment, deterministic scripts
- **WCAG is a report, not a gate** — `--ignore-contrast` flag overrides
- **Output destination** — caller controls via `--output`; convention is `.refiner/artifacts/<name>/converted.tsx`

## Ordered change list

| # | Change | Section | Gate |
|---|---|---|---|
| 1 | Add devDeps + sample HTMX + second brand TOML | 1.* | `pnpm install` clean |
| 2 | WCAG contrast helper | 2.* | self-test passes (black/white = 21.0) |
| 3 | `convert-htmx-react.mjs` script | 3.* | output passes `tsc --noEmit` standalone |
| 4 | `rebrand-artifact.mjs` script | 4.* | swap deltas non-empty + CSS regenerated |
| 5 | **End-to-end integration smoke** | 5.* | convert → scaffold → `pnpm build` succeeds |
| 6 | SKILL.md updates | 6.* | both updated, point at scripts |
| 7 | Acceptance gate sweep | 7.* | verify-app |

## Sequencing

- 1, 2 are parallel-safe (different files).
- 3 depends on 1 (needs sample HTMX), 2 (uses contrast helper for any default-contrast checks).
- 4 depends on 1 (needs second brand TOML), 2 (contrast report).
- **5 is the critical gate** — depends on 3 producing scaffolder-ready output.
- 6 depends on 3 + 4 being interface-stable.
- 7 depends on all.

## Risk register

| Risk | Mitigation in plan |
|---|---|
| Babel API churn between minor versions | Pin to current stable; record exact versions in package.json |
| parse5 tree shape requires walker iteration | Plan task 3.1 enumerates the transforms before writing the walker |
| HTMX `hx-*` permutations not all covered | Sidecar markdown documents the unhandled case; doesn't fail |
| Contrast computation false positives | `--ignore-contrast` flag; report not gate |
| Source TSX uses package imports beyond what scaffolder installs | Phase-2 has auto-`shadcn add`; broader npm imports surface as `pnpm build` errors with clear messages |
| Reverse-direction (React → HTMX) request | Documented as out-of-scope in SKILL.md; surfaces as a future phase |

## Estimated effort

One focused session, possibly two if `convert-htmx-react`'s walker needs iteration on real artifacts beyond the sample. Task 3.1 is the largest single piece.

## Reuse from phase-2

- `assets/templates/sample-app.tsx` — referenced by rebrand smoke
- `assets/library/brands/knowme.toml` — referenced as default `--from-brand`
- `scripts/scaffold-react-vite.sh` — integration target (no changes needed)
- `tools/template-forge-rs/templates/vite-shell-css.html` — invoked by rebrand for CSS regeneration
- `scripts/lib/kebab-case.sh` — invoked by both scripts for feature-name normalization

Net new code in this phase is just the two scripts + WCAG helper + sample HTMX + second brand TOML. The substrate is mostly in place.
