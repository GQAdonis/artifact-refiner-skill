# Reflection: phase-3b-aux-conversions

**Date:** 2026-05-20
**Status:** COMPLETE — 8/8 acceptance gates PASS, first LLM-primary script validated under live load

## Goal Achievement

| Goal | Status |
|---|---|
| `convert-md-to-htmx.mjs` deterministic markdown-it pipeline | MET |
| Brand CSS injection via existing template-forge | MET |
| Frontmatter support (gray-matter) overrides CLI flags | MET |
| `refine-moodboard.mjs` LLM-primary with placeholder fallback | MET |
| Structured JSON prompt + hand-rolled shape validator | MET |
| Prompt-injection marker rejection | MET (regex matchers) |
| `design-svg-logo.mjs` mode-switching (LLM + placeholder) | MET |
| Per-variant fallback on validation failure | MET |
| `scripts/lib/svg-validate.mjs` strict checks | MET (8/8 self-tests) |
| Two new Minijinja templates (`moodboard.html`, `logo-icon.html`) | MET |
| Three SKILL.md files updated to point at scripts | MET |
| Three new devDeps (markdown-it, markdown-it-anchor, gray-matter) | MET |
| End-to-end smoke (placeholder paths) | MET |
| LLM smoke (live proxy) | MET |

**Achievement: 14/14 MET (100%).**

## Delivered Changes

| Path | Type |
|---|---|
| `scripts/convert-md-to-htmx.mjs` | new, ~155 lines |
| `scripts/refine-moodboard.mjs` | new, ~215 lines |
| `scripts/design-svg-logo.mjs` | new, ~190 lines |
| `scripts/lib/svg-validate.mjs` | new, ~135 lines (8 self-tests) |
| `tools/template-forge-rs/templates/moodboard.html` | new Minijinja template, ~110 lines |
| `tools/template-forge-rs/templates/logo-icon.html` | new Minijinja template |
| `assets/templates/sample-md-document.md` | new smoke input |
| `skills/convert-md-to-htmx/SKILL.md` | rewritten |
| `skills/refine-moodboard/SKILL.md` | rewritten — documents LLM-primary pattern |
| `skills/design-svg-logo/SKILL.md` | rewritten — documents mode + validation |
| `package.json` | added markdown-it, markdown-it-anchor, gray-matter |

## Artifact Quality Summary

| Metric | Value |
|---|---|
| Changes with QA | 8/8 |
| First-pass pass rate | 8/8 (100%) |
| Changes requiring refinement | 0 |
| Total refinement iterations | 0 |
| Acceptance gates passed | 8/8 |
| Self-tests passed | 8/8 (svg-validate) |
| Live LLM smokes succeeded | 2/2 (moodboard + 3 logo variants) |

### Recurring Constraint Violations

None.

### Why this phase was clean

Like `phase-prefer-endpoint-consumption` before it, this phase was **net-new code with clean boundaries**:

- Three independent scripts, no shared mutable state
- Two new Minijinja templates, no existing-template modifications
- One self-contained helper (svg-validate) with its own tests
- SKILL.md updates were pure rewrites, no merging logic
- New devDeps installed cleanly

No refinement iterations. The pattern from phase-prefer-endpoint-consumption (also 0 iterations across 6 changes) replays cleanly here. **The retroactive-correction iteration cost is specific to retroactive correction; additive net-new work stays fast.**

## Technical Debt Introduced

| Debt | Severity | Notes |
|---|---|---|
| Moodboard template doesn't yet consume LLM-supplied `motifs`/`tone` arrays | Medium | LLM produces them in JSON; template currently renders hardcoded English text. Follow-up: extend Minijinja iteration over `brand.motifs` and `brand.tone` when populated |
| Wordmark/lockup PNG export skips small sizes | Low | Heuristic: sizes >= 128 for text-containing variants. Refine if real-world inputs surface needs |
| `refine-moodboard` calls `node -e` to parse TOML | Low | Synchronous child_process spawn; minor latency. Could import `@iarna/toml` directly if it works in ESM context |
| LLM may produce SVG without primary color | Low | Validation accepts; designer reviews |
| No WCAG contrast in moodboard output | Low | culori is available; not wired yet |
| Syntax highlighting in convert-md-to-htmx | Low (out-of-scope) | Users add Prism/Shiki post-build |
| Heading anchor link style | Low (out-of-scope) | markdown-it-anchor defaults; users customize |

None blocking.

## Lessons Captured

### Lesson 1 — The net-new-code clean-pass pattern holds across three phases now

| Phase | First-pass quality | Refinement iterations |
|---|---|---|
| phase-4 Block A (retroactive correction) | 5/9 | 5 |
| phase-prefer-endpoint-consumption (net-new) | 6/6 | 0 |
| phase-3b-aux-conversions (net-new) | 8/8 | 0 |

The lesson from phase-prefer-endpoint-consumption replays: **net-new code with clean boundaries is fast and clean; retroactive correction is iteration-heavy.** Worth treating as a design heuristic — when there's a choice between extending an existing script and adding a new one, the new file is faster *and* lower-risk.

### Lesson 2 — LLM-primary scripts establish a reusable pattern

`refine-moodboard.mjs` introduces the "LLM is the engine" pattern:

```
1. Structured prompt requests JSON with exact shape
2. chat(phaseKey, ...) calls openai-proxy via model-routing
3. Strip markdown fences from response
4. Reject prompt-injection markers
5. Validate JSON shape (hand-rolled validator, not Zod — keep deps light)
6. Fall back to placeholder on any failure
7. Deterministic renderer produces final output
```

Future generative skills (image-prompt synthesis, code-generation scaffolds, content templates) reuse this scaffold. **The pattern is now documented by code, not just spec.**

### Lesson 3 — Strict SVG validation is cheap insurance

`svg-validate.mjs` is ~135 lines including 8 self-tests. The validator's strict-but-helpful approach (parse-then-walk-for-script via parse5; regex pre-check for `on*=` and `javascript:` URLs) catches both syntactic disasters (truncated SVG) AND security issues (XSS vectors). **When asking an LLM for SVG, this validator is the gate that turns "trust the LLM" into "verify and fall back."**

### Lesson 4 — Synthetic brand TOML in a temp directory beats adding a `--data` flag to template-forge

The moodboard path needed to feed LLM-synthesized brand spec into template-forge, but template-forge only accepts brand TOMLs from `<library>/brands/`. Two options:

A. Add a `--data <json-file>` flag to template-forge (requires Rust change + cargo rebuild)
B. Write the spec as a synthetic TOML to a temp directory; point template-forge at the temp library

Picked B. Cost: ~10 lines of Node TOML-emission. Benefit: no Rust change, no rebuild. **The "shape it to look like the existing input format" trick avoids adding general-purpose flags before they're needed.**

### Lesson 5 — Markdown frontmatter as authoritative override

Where the same value (e.g., `document-type`) could come from CLI flags OR frontmatter, frontmatter wins. This means a `convert-md-to-htmx.mjs --document-type article` run on a file with `document-type: brief` frontmatter respects the frontmatter. **The document's own metadata is more authoritative than the invocation's flags.** Frontmatter is configuration-as-source-of-truth.

### Lesson 6 — Per-variant fallback beats per-run fallback

`design-svg-logo.mjs` doesn't fall back as a unit. If the LLM produces a valid icon and an invalid wordmark, the icon stays LLM-generated and only the wordmark falls back. **The unit of failure should match the unit of value.** Each variant is independently valuable; each variant's validation is independent.

### Lesson 7 — Subscription-priced inference makes "ask the LLM" the natural first move

The LLM smoke for design-svg-logo made 3 separate model calls. The moodboard smoke made 1. At per-token pricing this would prompt deliberation. At subscription pricing it's invisible. **Future generative skills can lean on the LLM for every step that benefits**, with the safety net that each call is logged + cost-routed + fallback-protected via `chat()`.

## Pipeline Maturity Assessment

```
Ideation → refined artifact          (LLM-driven via phase-0 skill specs)
       ↓
Conversions:
  HTMX → React                       (phase-3, with --llm-judgment)
  Markdown → branded HTML            (this phase, deterministic)
  Brief → branded moodboard          (this phase, LLM-primary)
  Brief → SVG logo set               (this phase, LLM with fallback)
  Rebrand artifact                   (phase-3)
       ↓
Scaffolds:
  React/Vite                         (phase-2)
  + Tailwind v4 + shadcn-on-Base-UI
  + zustand+immer architecture       (phase-4 A)
  + responsive primitives + PWA      (phase-4 B)
  + Rust+axum self-binary            (phase-2 --with-axum-wrapper)
  + Tauri 2 hybrid                   (phase-4 C, --with-tauri-wrapper)

Inference routing config             (phase-1b)
Inference routing runtime            (phase-prefer-endpoint-consumption)
```

**The phase-0 conversion-skill commitment is now fully realized.** All five originally-named conversion skills (convert-htmx-react, rebrand-artifact, convert-md-to-htmx, refine-moodboard, design-svg-logo) have shipped execution layers.

## Recommended Focus for Next Phase

Three candidates remain in the original phase pipeline. Ranked by strategic value:

### Option A — `polish-pass` (recommended)

Audit + lift quality across what's already shipped. Specifically:
- Moodboard template consumes LLM-supplied motifs/tone (debt from this phase)
- WCAG contrast wired into moodboard rendered output
- Tauri menu bar customization
- Vite 8 upgrade tracking when shadcn upstream bumps
- README + AGENTS.md update with the 11-phase pipeline overview

No new capabilities; quality lift across 11 phases of work. Self-contained, completable in one session.

### Option B — `phase-7-scaffold-ag-ui-host`

Leverage openai-proxy's AG-UI SSE surface + scaffolder substrate. Builds agent-backed app host. More ambitious — raises new design questions about how stores integrate with streaming events from AG-UI SSE.

### Option C — `phase-6-scaffold-flutter`

Largest architectural divergence (Dart + Riverpod/Bloc + Flutter widgets). Substantial concept reuse from phase-4 substrate, fresh implementation. Two-to-three session phase.

**Recommendation: A.** After three new-feature phases in a row, polish addresses accumulated debt. Phases B and C are net-new headline work that benefit from a quality-stable foundation.

## Knowledge Base Hooks

- "Net-new code with clean boundaries: 0 iterations. Retroactive correction: 5+ iterations. Choose new files when both options are architecturally clean."
- "LLM-primary script pattern: structured-prompt → chat() → strip-fences → reject-injection → validate-shape → fallback-or-render"
- "Strict SVG validation (parse5 + regex pre-checks) is cheap insurance against LLM hallucination + XSS"
- "Synthetic config in a temp directory beats adding general-purpose data flags to renderers"
- "Frontmatter is authoritative — document metadata wins over invocation flags"
- "Per-variant fallback beats per-run fallback when each variant is independently valuable"
- "Subscription-priced inference makes 'ask the LLM' the natural first move for generative work"

## Reflection Metadata

```yaml
phase: phase-3b-aux-conversions
goals_met: 14/14 (100%)
acceptance_gates_passed: 8/8
first_pass_quality: 8/8 (100%)
refinement_iterations: 0
end_to_end_integration: PASS (both placeholder + LLM modes for all 3 scripts)
technical_debt_blocking: false
new_capability_now_available: convert-md-to-htmx + refine-moodboard + design-svg-logo
first_llm_primary_script_in_repo: refine-moodboard.mjs
pipeline_maturity: phase-0 conversion-skill commitment fully realized
next_phase_recommended: polish-pass
alternates: [phase-7-scaffold-ag-ui-host, phase-6-scaffold-flutter]
```

Completed kbd-reflect — phase-3b-aux-conversions
