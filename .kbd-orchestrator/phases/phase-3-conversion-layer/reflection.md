# Reflection: phase-3-conversion-layer

**Date:** 2026-05-20
**Status:** ideation-to-app loop closed end-to-end, 10/10 acceptance gates PASS

## Goal Achievement

| Goal | Status |
|---|---|
| Convert HTMX/Alpine HTML → React TSX deterministically | MET |
| Lift Alpine `x-data` → `useState` named hook | MET |
| Convert `@click` / `x-text` / inline style → JSX equivalents | MET |
| Surface HTMX `hx-*` to ambiguous-region sidecar | MET |
| Rebrand: swap brand TOML tokens via AST walk | MET |
| Regenerate brand-vars CSS via template-forge | MET |
| WCAG contrast as report not gate | MET (with `--ignore-contrast` override) |
| Both scripts produce phase-2-scaffolder-ready output | MET |
| End-to-end integration: convert → scaffold → `pnpm build` | **MET — critical gate** |
| Update SKILL.md files to point at scripts | MET |

**Achievement: 10/10 MET (100%). Critical end-to-end gate passed on first integration run.**

## Delivered Changes

| Path | Status |
|---|---|
| `scripts/convert-htmx-react.mjs` | created (~400 lines) |
| `scripts/rebrand-artifact.mjs` | created (~160 lines) |
| `scripts/lib/wcag-contrast.mjs` | created with 4/4 self-tests passing |
| `assets/templates/sample-htmx.html` | created |
| `assets/library/brands/prometheus-ags.toml` | created (second brand in registry) |
| `skills/convert-htmx-react/SKILL.md` | rewritten — points at script + ambiguous-region review |
| `skills/rebrand-artifact/SKILL.md` | rewritten — points at script + contrast override path |
| `package.json` devDeps | added: parse5, @babel/{parser,generator,traverse,types}, culori, @iarna/toml |

## Artifact Quality Summary

| Metric | Value |
|---|---|
| Changes with QA | 7/7 |
| First-pass pass rate | 5/7 (71%) |
| Changes requiring refinement | 2 (convert-htmx-react walker, ambiguous-region detector) |
| Total refinement iterations | 1 (bare-identifier passthrough) |
| Acceptance gates passed | 10/10 |
| Unit tests (wcag-contrast self-test) | 4/4 |
| End-to-end build | PASSED (775ms, 31 modules) |

### Refinement iterations during execute

1. **`x-text="count"` flagged as ambiguous** — initial `transformAlpineExpr` only matched assign/increment; bare-identifier expressions fell to fallback. Added a third regex branch returning the identifier verbatim. One iteration, ~2 minutes.

### Recurring Constraint Violations

None — both scripts produced valid output on first compile-check.

## Technical Debt Introduced

| Debt | Severity | Notes |
|---|---|---|
| Generator emits `style={{ "background": "..." }}` with quoted keys | Low | Cosmetic; JSON.stringify on object keys. Bare `background:` would be cleaner. Could add a prettifier pass. |
| `setCount` destructured but unused → TS warning at strict build | Low | The hook returns both `count` and `setCount`; consumer only uses `setCount` through the `@click` rewrite. Scaffolder strips unused *imports* but not unused *destructured* vars. Follow-up. |
| Regex-based HTML walker (not AST) | Medium | parse5 produces an AST but our walker is still string-emitting. Acceptable for simple HTMX; promote to AST emission if real-world artifacts surface escape-sequence edge cases. |
| HTMX `hx-*` is sidecar-only (no auto-translation) | Medium | By design — `hx-post` + `hx-target` + `hx-swap` has too many semantic interpretations. The sidecar gives the LLM bounded judgment scope. Revisit if patterns emerge. |
| `x-show` / `x-model` are sidecar-only too | Low | Same reasoning. Could add deterministic translation for `x-show="boolExpr"` → conditional render in v2. |
| Reverse direction (React → HTMX) not shipped | Low | Documented out-of-scope in SKILL.md. Future phase. |
| Multi-file source TSX in convert-htmx-react | Low | v1 single-file only. |
| `rebrand-artifact` doesn't update brand-specific copy (company name, taglines) | Low | TOML doesn't expose copy fields; if added, AST walk could match string literals. |

None blocking. Each item has a clear retirement path or is explicitly out of scope.

## Lessons Captured

### Lesson 1 — Bounded LLM judgment beats unbounded delegation

The ambiguous-region sidecar pattern is the right shape for this kind of work: scripts do the deterministic 90%, surface the residual 10% with a concrete recommendation, and let the LLM (or human) review *only* the genuinely ambiguous parts. This is more reliable than "ask the LLM to convert HTMX to React" and faster than "specify every transform rule in the spec".

### Lesson 2 — End-to-end integration smoke is the only meaningful gate

Acceptance gates 1-7 verify individual deliverables. Gate 8 (convert → scaffold → `pnpm build`) verifies they compose. Without that gate, every individual gate could pass while the composition fails. **The integration smoke is what made phase-3 trustworthy** — not the unit checks.

### Lesson 3 — Self-test inside the helper file is cheap insurance

`scripts/lib/wcag-contrast.mjs` runs its own self-test when invoked directly. That caught a sRGB-vs-linear-RGB ambiguity in culori's API on first run — without the self-test, the bug would have surfaced as confusing rebrand warnings later. **Helper files that ship without a runnable self-test are a smell.**

### Lesson 4 — Babel ESM interop is consistently weird

`_traverse.default ?? _traverse` is the standard pattern across the Babel ecosystem under Node ESM. It would be nice if Babel just shipped pure ESM, but the CJS/ESM dual-publish reality means every consumer paper-cuts on this. Document it once, apply it consistently.

### Lesson 5 — Brand-vars in TSX as `var(--color-*)` is the right contract

The rebrand smoke reported "0 hex swaps" against `sample-app.tsx` — and that's the *correct* result, because the TSX consumes everything via `var(--color-*)`. Rebrand only needed to regenerate the CSS. **When the consumer follows the contract, the rebrand path is essentially free.** This validates phase-2's design decision to inject brand tokens as CSS vars, not inline hex.

### Lesson 6 — WCAG-as-report (not gate) catches real problems without blocking

Prometheus AGS `#E96A12` against light bg scored at "A" level — a genuine contrast issue with the orange brand color. The rebrand still produced output; the user got a clear warning. This is the right tradeoff: don't block on subjective tradeoffs, but make them visible.

## Pipeline Maturity Assessment

The original ideation-to-app gap is now closed end-to-end. Visualized:

```
HTMX/Alpine artifact         (input — ideation output)
        ↓
convert-htmx-react.mjs       (phase-3)
        ↓
Scaffolder-ready TSX
        ↓
scaffold-react-vite.sh       (phase-2)
        ↓
Vite + React 19 + Base UI + Tailwind v4 project
        ↓
pnpm build                   (deployed dist)

Alternate paths now also work:
  - TSX → rebrand-artifact (phase-3) → different-branded TSX → scaffolder
  - Scaffolder + --with-axum-wrapper → single-binary axum 0.8.9 server (phase-2)
```

This is functional for the original goal. Pipeline maturity:

| Stage | Status |
|---|---|
| Ideation → refined artifact | Phase-0 skill specs guide this; LLM-driven |
| Conversion (HTMX→React) | **Shipped (phase-3)** |
| Rebranding | **Shipped (phase-3)** |
| Scaffolding (React/Vite) | **Shipped (phase-2)** |
| Single-binary deployment (axum) | **Shipped (phase-2 with `--with-axum-wrapper`)** |
| Cost-routing for inference | Config shipped (phase-1b); runtime hookup deferred |
| Alternate scaffolders (Tauri/Flutter/AG-UI/A2UI/MCP-UI) | All deferred (own phases) |
| Aux conversions (md-to-htmx, moodboard, svg-logo) | Deferred (phase-3b) |

## Recommended Focus for Next Phase

Four candidates, ranked by strategic value:

### Option A — `phase-4-scaffold-tauri-desktop` (recommended)

Apply the phase-2 substrate to Tauri 2 desktop. This is the second visible win demonstrating that the reuse strategy works. Tauri's frontend is just a Vite project — phase-2's scaffolder produces exactly that. Tauri adds a `src-tauri/` Rust shell alongside. Externally most demoable.

### Option B — `phase-3b-aux-conversions`

Complete `convert-md-to-htmx`, `refine-moodboard`, `design-svg-logo` execution layers. Smaller and more self-contained than Tauri. Internally rounds out the phase-0 promise but doesn't ship a new headline capability.

### Option C — `phase-prefer-endpoint-consumption`

Wire PMPO loop to honor `prefer_endpoint` at runtime. Cost-routing benefit accrues immediately. Internal-only value; no new user-visible capability.

### Option D — `phase-7-scaffold-ag-ui-host`

The most ambitious next phase. Leverages openai-proxy's AG-UI SSE surface (phase-1b) + the scaffolder substrate. Builds the agent-backed app host. Big, high-value, but raises new design questions.

**Recommendation: A.** Tauri desktop demonstrates the reuse strategy convincingly without the design weight of D. After A, the substrate is proven across 3 scaffold targets (web/Tauri-desktop with reuse), making D or further targets lower-risk.

## Knowledge Base Hooks

- "Bounded LLM judgment beats unbounded delegation — script the 90%, surface the 10%"
- "End-to-end integration smoke is the only meaningful gate — unit checks can all pass while composition fails"
- "Helper files that ship without a runnable self-test are a smell"
- "Babel ESM interop: `_default ?? _module` pattern — apply consistently"
- "Brand-vars as CSS vars (not inline hex) make rebrands essentially free"
- "WCAG-as-report (not gate) catches real problems without blocking subjective tradeoffs"

## Reflection Metadata

```yaml
phase: phase-3-conversion-layer
goals_met: 10/10 (100%)
acceptance_gates_passed: 10/10
first_pass_quality: 5/7 (1 refinement iteration during execute)
end_to_end_integration: PASSED (convert → scaffold → pnpm build)
technical_debt_blocking: false
unit_tests: 4/4 (wcag-contrast)
next_phase_recommended: phase-4-scaffold-tauri-desktop
alternates: [phase-3b-aux-conversions, phase-prefer-endpoint-consumption, phase-7-scaffold-ag-ui-host]
pipeline_maturity: ideation-to-app loop closed end-to-end
```

Completed kbd-reflect — phase-3-conversion-layer
