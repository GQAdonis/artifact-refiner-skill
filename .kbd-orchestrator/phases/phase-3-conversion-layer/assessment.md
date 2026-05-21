# Phase Assessment: Conversion Layer Execution

**Phase:** `phase-3-conversion-layer`
**Project:** `artifact-refiner`
**Date:** 2026-05-20
**Author:** Claude Code (Opus 4.7, 1m context)
**Mode:** Assessment only — no implementation
**Sycophancy correction:** applied

---

## 1. Goal Restatement

Close the gap between *ideation produces refined TSX* and *scaffolder consumes refined TSX*. Phase-0 authored five **spec-only** conversion skills; their procedures describe what to do but defer execution to "the PMPO loop with code-interpreter". When a user invokes `/convert-htmx-react ./hero.html`, today the skill explains the steps but doesn't actually run them.

Phase-3 ships the **execution layer** for the two conversions most directly feeding phase-2's scaffolder:

1. **`convert-htmx-react`** — HTMX/Alpine → React TSX (the input shape phase-2 expects)
2. **`rebrand-artifact`** — apply a different brand TOML to existing TSX (the brand-swap path phase-2 uses indirectly)

The other three (`convert-md-to-htmx`, `refine-moodboard`, `design-svg-logo`) are valuable but not on the critical path to the scaffolder. Defer them to a follow-on phase.

---

## 2. Sycophancy-Corrected Assessment

### Where the spec-only approach was correct

The phase-0 skills were intentionally light — at the time, there was no template-forge, no scaffolder, no brand registry, and committing to a particular execution mechanism would have been premature. The skills documented the *procedure* so future execution code knows what to do. That was the right call.

### Where it now needs correction

Phase-2 shipped. The scaffolder needs predictable input. "Ask the LLM in chat to convert HTMX to TSX" is not predictable. Two correction lenses:

#### Correction 1 — Don't try to AST-rewrite arbitrary HTMX in chat

The session doc and the phase-0 SKILL.md both gesture at "use code-interpreter with `htmlparser2`". In practice this is fragile: every HTMX artifact is different, the conversion rules are conditional on what HTMX/Alpine features are used, and chat-based conversion gives non-deterministic output. **A real execution layer needs a deterministic transform pipeline, not a prompt-driven one.**

**Corrected goal:** ship a small Node script (`scripts/convert-htmx-react.mjs`) that does the deterministic transforms (`class` → `className`, `for` → `htmlFor`, self-closing tags, etc.) and surfaces *only the semantically-ambiguous parts* (HTMX behaviors, Alpine controllers) for LLM judgment. Keep the mechanical work deterministic.

#### Correction 2 — `rebrand-artifact` is mostly a CSS-token swap, not a refinement loop

The phase-0 SKILL.md frames rebranding as a full PMPO loop with WCAG validation, brand TOML resolution, etc. In practice, ~95% of rebrand work is "swap these `var(--color-*)` values for these other values" or "rewrite hex literals in style props". That's a 50-line script, not a refinement loop.

**Corrected goal:** ship `scripts/rebrand-artifact.mjs` that does a fast deterministic swap based on a "from-brand TOML" and "to-brand TOML" diff. WCAG validation runs as a post-step against the swapped output; if it fails, the user gets a clear report and can choose to override or refine. Don't wrap a simple transform in a heavy loop.

#### Correction 3 — Both scripts should produce phase-2-ready output

Phase-2's scaffolder expects:
- Single `.tsx` file
- Default export = the component
- Optional named hooks (`useFoo`)
- Imports from `@/shared/components/ui/<name>` for shadcn primitives
- Brand consumption via `var(--color-*)` CSS variables

**Both** `convert-htmx-react` and `rebrand-artifact` should emit output that matches this shape so the scaffolder can pick it up directly. This is the integration contract.

#### Correction 4 — Three skills are out of scope

`convert-md-to-htmx`, `refine-moodboard`, `design-svg-logo` are useful skills but they don't feed the scaffolder. Adding them to phase-3 inflates scope. Defer to `phase-3b-aux-conversions` if/when they become priorities.

#### Correction 5 — `refine-ui` already has the browser-preview infrastructure

`scripts/compile-tsx-preview.mjs` and `scripts/render-preview.mjs` exist (esbuild + Playwright). Phase-3 should reuse them, not parallel-implement. Specifically: after conversion, render the output via these scripts and capture a screenshot for the artifact log.

---

## 3. Scope of This Phase

### In scope

1. **`scripts/convert-htmx-react.mjs`** — Node script using `parse5` (or `htmlparser2`) for deterministic HTML→JSX, with a clearly-marked "ambiguous regions" output for LLM judgment on Alpine/HTMX semantics.
2. **`scripts/rebrand-artifact.mjs`** — Node script that loads from-brand + to-brand TOMLs, computes the token delta, and rewrites the source.
3. **Both scripts produce phase-2-ready TSX output** — single-file default export + optional named hooks + brand-variable consumption.
4. **WCAG validation as a post-step** for `rebrand-artifact` — uses a small contrast computation (existing `culori` or `chroma-js` package or hand-rolled; pick one in plan).
5. **Update `skills/convert-htmx-react/SKILL.md`** — point at the script + describe the LLM's role for ambiguous regions only.
6. **Update `skills/rebrand-artifact/SKILL.md`** — same: point at the script + describe the contrast-fail escalation path.
7. **End-to-end smoke** — convert a sample HTMX artifact into TSX, then feed the result into `scaffold-react-vite.sh` to verify the integration contract.

### Out of scope (deferred)

- `convert-md-to-htmx` execution layer → `phase-3b-aux-conversions`
- `refine-moodboard` execution layer → `phase-3b-aux-conversions`
- `design-svg-logo` execution layer → `phase-3b-aux-conversions`
- AST-level React-to-HTMX (reverse direction) — `convert-htmx-react` v1 is HTMX→React only; reverse is a follow-on
- React → Flutter (`phase-6-scaffold-flutter` substrate)
- React → A2UI / AG-UI fragment (their own phases)
- TanStack Query / React Router scaffolding from HTMX `hx-*` patterns — punt to documentation, not auto-conversion

---

## 4. Current state inventory

| Surface | Status |
|---|---|
| `skills/convert-htmx-react/SKILL.md` | spec only |
| `skills/rebrand-artifact/SKILL.md` | spec only |
| `scripts/convert-htmx-react.mjs` | does not exist |
| `scripts/rebrand-artifact.mjs` | does not exist |
| `scripts/compile-tsx-preview.mjs` | exists (reuse for smoke render) |
| `scripts/render-preview.mjs` | exists (reuse for screenshot) |
| `assets/templates/sample-htmx.html` | does not exist |
| `assets/library/brands/knowme.toml` | exists |
| `assets/library/brands/<other>.toml` | only one brand today |

---

## 5. Architecture choices

### A. Node, not Rust

Both scripts work in JS/HTML AST land. Node has the best parsers (`parse5`, `acorn`, `swc-wasm`). Rewriting in Rust adds compile cost for no benefit — these are pure I/O scripts run once per conversion. Match the existing `compile-tsx-preview.mjs` / `render-preview.mjs` pattern.

### B. parse5 over htmlparser2

`parse5` produces a spec-conformant HTML5 tree; `htmlparser2` is faster but more liberal. For conversion correctness, spec-conformant wins. Both are well-maintained Node packages.

### C. Ambiguous-region annotation, not full LLM delegation

The script outputs deterministic JSX for the unambiguous 90%, and emits a sidecar `<artifact>.ambiguous.md` for the remaining 10%:

```
## Ambiguous regions in hero.html

### Region 1 (lines 23-29) — HTMX swap
Source:
  <button hx-post="/api/like" hx-target="#likes" hx-swap="innerHTML">Like</button>

Recommended translation:
  <Button onClick={async () => { const r = await fetch("/api/like", {method:"POST"}); setLikes(await r.text()); }}>Like</Button>

Reasoning: hx-post + hx-target + hx-swap → useState + fetch + setState pattern.
LLM review requested: is `setLikes` the right state setter? Source file has 3 candidates.
```

The LLM (in the calling skill) reviews the sidecar and either accepts the recommendation or proposes alternatives. **Deterministic work is deterministic; LLM judgment is bounded to genuinely ambiguous regions.**

### D. Brand-token swap is structural, not regex-on-hex

`rebrand-artifact.mjs` doesn't grep for hex strings. It:

1. Loads both brand TOMLs (from-brand, to-brand).
2. Computes the token map: `from.colors.dark.ember (#A1B2C3) → to.colors.dark.ember (#E04E28)`.
3. Walks the source TSX AST (via `acorn`) for two cases:
   - String literals that exactly match a from-brand hex value → swap.
   - `var(--color-*)` references → no swap needed; just inject the new tokens into the CSS file.
4. Outputs the rewritten TSX + a separate updated `index.css`.

Hex literals that don't match a from-brand value are left alone (user-injected colors are preserved).

### E. Output destination convention

Conversion / rebrand outputs land in `.refiner/artifacts/<artifact_name>/converted.tsx` (and `<artifact_name>/converted.css` for rebrand). The user / scaffolder picks them up from there.

---

## 6. Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| HTMX/Alpine has constructs we don't know about | High | Medium | Sidecar markdown for ambiguous regions; don't fail, document |
| `parse5` produces a tree shape that doesn't map cleanly to JSX | Low | Medium | parse5 is the de-facto standard; existing converters in the wild use it successfully |
| Brand TOML lookups for a "from-brand" that doesn't exist | Medium | Low | Two paths: (a) auto-detect by scanning the source for hex values matching known brands, (b) ask user to specify with `--from-brand` |
| WCAG validation false positives blocking acceptable output | Medium | Low | Validation is a *report*, not a *gate*; user can `--ignore-contrast` to override |
| Reverse direction (React → HTMX) expectations | Medium | Low | v1 is HTMX → React only; doc the asymmetry clearly in SKILL.md |

No high-severity unmitigated risks.

---

## 7. Acceptance criteria

1. `scripts/convert-htmx-react.mjs` exists, executable via `node`, accepts `--source <html> --output <tsx>`.
2. `scripts/rebrand-artifact.mjs` exists, accepts `--source <tsx> --from-brand <name> --to-brand <name> --output <tsx>`.
3. `assets/templates/sample-htmx.html` exists — small but realistic HTMX/Alpine artifact for smoke testing.
4. Running `node scripts/convert-htmx-react.mjs --source assets/templates/sample-htmx.html --output /tmp/converted.tsx` produces a valid `.tsx` file that parses cleanly via `tsc --noEmit /tmp/converted.tsx` (or with a tsconfig override).
5. End-to-end integration: converted TSX → `scripts/scaffold-react-vite.sh --source /tmp/converted.tsx ...` → `pnpm build` succeeds.
6. `scripts/rebrand-artifact.mjs` swaps tokens correctly when from-brand and to-brand TOMLs differ; produces both a rewritten TSX and an updated CSS.
7. `skills/convert-htmx-react/SKILL.md` and `skills/rebrand-artifact/SKILL.md` updated to point at scripts.
8. Sidecar ambiguous-region markdown is produced when HTMX/Alpine constructs are detected.

8 gates. All deterministically checkable.

---

## 8. Phase decomposition

| # | Sub-change | Effort |
|---|---|---|
| 1 | Decide parser (`parse5` vs `htmlparser2`) and brand token swap library (`culori` etc.) | small |
| 2 | Author `assets/templates/sample-htmx.html` — small HTMX/Alpine artifact | small |
| 3 | Author `scripts/convert-htmx-react.mjs` (parser → JSX walker → emitter → ambiguous-region sidecar) | medium-large |
| 4 | Smoke test: convert sample-htmx → /tmp/converted.tsx, verify `tsc --noEmit` passes | small |
| 5 | Add second brand TOML (e.g. `prometheus-ags.toml`) so rebrand has a non-trivial swap | small |
| 6 | Author `scripts/rebrand-artifact.mjs` (AST walk, token map, hex swap, CSS update) | medium |
| 7 | Smoke test: rebrand sample TSX from knowme → prometheus-ags, verify deltas | small |
| 8 | End-to-end integration: converted TSX + brand → `scaffold-react-vite.sh` → `pnpm build` succeeds | small (network-bounded) |
| 9 | Update SKILL.md files to point at scripts | small |
| 10 | WCAG contrast validator post-step + `--ignore-contrast` flag | small |
| 11 | Acceptance gate sweep | small |

Total: one focused session, possibly two if the ambiguous-region detector wants iteration.

---

## 9. Open questions

1. **Parser choice:** `parse5` (recommended, spec-conformant) or `htmlparser2` (faster, more permissive)? Recommendation: `parse5`.
2. **AST library for TSX:** `acorn`-with-JSX-plugin, `@babel/parser`, or `swc-wasm`? Recommendation: `@babel/parser` — most mature, best-tested for JSX, and we don't need swc's speed for one-shot conversion.
3. **Color science library:** `culori` (modern, OKLCH-aware), `chroma-js` (battle-tested), or hand-rolled WCAG? Recommendation: `culori` — handles the OKLCH literals in modern brand TOMLs natively.
4. **Brand TOML #2:** Use `prometheus-ags` (referenced in session doc) or create something simpler for the smoke test? Recommendation: ship `prometheus-ags.toml` with the brand tokens from the session doc — kills two birds.
5. **Should the smoke compile the converted TSX standalone, or always through `scaffold-react-vite.sh`?** Recommendation: both — `tsc --noEmit` for fast syntax-only validation, full scaffold for integration check.
6. **Should rebrand also update the brand-vars CSS, or only the TSX?** Recommendation: both. The CSS holds the canonical brand vars; the TSX consumes them via `var(--color-*)`. A rebrand updates both atomically.

---

## 10. Honest verdict

This phase ships the second-most-important piece after phase-2. Without it, users hand-edit refined TSX to match the scaffolder's expected shape, or call the LLM in chat for each conversion. Both are friction.

The work is genuinely small — two Node scripts, one sample HTMX, one second brand TOML, two SKILL.md updates. The architectural decisions (parse5 + babel + culori, ambiguous-region sidecar, both scripts produce phase-2-ready output) are clean and conventional.

**Recommendation:** proceed to `/kbd-plan phase-3-conversion-layer`. One focused session of execute expected. Phase-2 substrate (kebab-case helper, vite-shell-css template) is reused unchanged.

---

## 11. Assessment metadata

```yaml
assessment_complete: true
phase: phase-3-conversion-layer
prerequisites_met:
  phase-2-scaffold-react-vite: complete (integration target)
  phase-rust-workspace-bootstrap: complete (template-forge reused)
  phase-0-unblock: complete (skill specs provide the procedure baseline)
scope_discipline_applied:
  - Two scripts (convert-htmx-react + rebrand-artifact), not five
  - Deterministic transforms with bounded LLM judgment for ambiguous regions
  - Reuse phase-2 substrate (no new kebab-case logic, no new brand-CSS rendering)
  - Out: convert-md-to-htmx, refine-moodboard, design-svg-logo executions
out_of_scope_deferred:
  - phase-3b-aux-conversions for the three deferred skills
  - React → HTMX reverse direction
  - React → Flutter / A2UI / AG-UI conversion paths (own phases)
recommendation: |
  Proceed to /kbd-plan phase-3-conversion-layer. One focused session.
  Integration target is phase-2's scaffolder; verify end-to-end on smoke.
next_command: /kbd-plan phase-3-conversion-layer
```

Completed kbd-assess — phase-3-conversion-layer
