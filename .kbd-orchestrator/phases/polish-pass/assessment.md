# Phase Assessment: Polish Pass

**Phase:** `polish-pass`
**Project:** `artifact-refiner`
**Date:** 2026-05-20
**Author:** Claude Code (Opus 4.7, 1m context)
**Mode:** Assessment only — no implementation
**Sycophancy correction:** applied (S-03 scope inflation actively resisted)
**Predecessors:** 11 phases shipped (phase-0 through phase-3b)

---

## 1. Goal Restatement

Audit + lift quality across what 11 phases shipped. No new capabilities. Targets explicitly listed by the "deferred follow-ups" lines in prior phase reflections, deduplicated and ranked.

A polish phase is **bounded by definition** — if the audit surfaces a new feature, it belongs in a new phase, not this one. The discipline of polish-pass is: *fix the known gaps, don't invent new ones.*

---

## 2. Sycophancy-Corrected Scope Discipline

Polish phases attract scope creep because everything could *use* a polish pass. Five corrections.

### Correction 1 — Only fix things that the prior reflections explicitly flagged

The prior reflections list "Known follow-ups" tables in §Technical Debt. Those tables are the **bounded source of truth** for this phase. Anything not in those tables is out of scope, even if it would be nice.

Audited follow-ups (from all 11 reflection.md files):

| Source phase | Follow-up | Severity |
|---|---|---|
| phase-3b | Moodboard template doesn't consume LLM `motifs`/`tone` arrays | Medium |
| phase-3b | WCAG contrast not wired into moodboard output | Low |
| phase-3b | refine-moodboard uses `node -e` for TOML parse (could be import) | Low |
| phase-3b | Wordmark/lockup PNG sizes filter (>= 128) is a heuristic | Low |
| phase-4 | Tauri menu bar / window-controls polish (not started) | Low |
| phase-4 | iOS/Android signing automation | Out of scope (user step) |
| phase-4 | Multi-window Tauri configs | Out of scope (per-project) |
| phase-4 | Vite 8 upgrade tracking | Out of artifact-refiner control |
| phase-4 | `theme-provider.tsx` from nova preset not moved by patcher | Low |
| phase-3 | Generator emits quoted-key style objects (cosmetic) | Low |
| phase-3 | Regex HTML walker (not AST) | Medium |
| phase-3 | `setCount` unused-destructure warning | Low |
| phase-3 | Multi-file source TSX in convert-htmx-react | Out of scope (own phase) |
| phase-3 | Reverse direction React → HTMX | Out of scope (own phase) |
| phase-prefer-endpoint | Streaming completions | Out of scope (v2) |
| phase-prefer-endpoint | Tool/function calling | Out of scope (v2) |
| phase-prefer-endpoint | Cost telemetry aggregation | Low (would be welcome) |
| phase-prefer-endpoint | Windows .bat wrapper for health-probe | Low |
| phase-1 | sycophancy-correction submodule pending (extracted in phase-sc-extraction) | RESOLVED |
| phase-rust-workspace-bootstrap | Multiple brand TOMLs beyond knowme + prometheus-ags | Resolved (3 brands now) |
| All phases | README + AGENTS.md don't reflect the 11-phase pipeline overview | Medium |
| Phase plugin manifest | Version still 1.1.0; reality is much further | Low (cosmetic) |

### Correction 2 — Polish ≠ feature work in disguise

Concretely banned from this phase even though tempting:

- AG-UI / Flutter / A2UI / MCP-UI scaffolders (own phases)
- Streaming chat completions
- Tool-calling
- Multi-file source TSX
- AST-based patcher rewrite
- Animated SVG generation

If the user wants any of these, they need their own assessment cycle.

### Correction 3 — Doc updates are real polish work

README + AGENTS.md don't reflect 11 phases of shipped work. New contributors / future LLM agents reading these files see the original v1.0.0-scope project. Updating docs to reflect actual capability is **the single highest-leverage polish item** — it improves discoverability across every future interaction.

### Correction 4 — Cosmetic-only items deferred to "as encountered"

Some flagged items are cosmetic and don't block anyone:

- Quoted-key JSON in generated TSX style props (works fine, just looks unusual)
- Wordmark PNG size heuristic (works fine, just an opinion)
- Plugin manifest version number (cosmetic)

These are documented as **deferred-to-as-encountered**. The first time they actually cause a problem, the affected phase is the place to fix them.

### Correction 5 — Bump plugin manifest version honestly

The plugin manifest still says version `1.1.0`. Eleven phases of substantial work have shipped since that was accurate. Set it to a version that reflects reality. **A version stuck at 1.1.0 when the code is at 11 phases makes downstream consumers (cowork, claude plugin marketplaces) display stale information.** Pick a number that means something — `1.3.0` for "major progress since last release tag," then document the changelog.

---

## 3. Scope of This Phase

### In scope (the bounded polish list)

1. **README.md update** — add "Pipeline Capabilities" section reflecting what's shipped across 11 phases. Specifically:
   - Conversion skills (convert-htmx-react, convert-md-to-htmx, refine-moodboard, design-svg-logo, rebrand-artifact)
   - Scaffolders (scaffold-react-vite with `--with-axum-wrapper` and `--with-tauri-wrapper`)
   - Inference routing (model_policy, openai-proxy integration)
   - The PMPO loop's place in this ecosystem
2. **AGENTS.md update** — add "Architecture Reference" section pointing at `references/scaffolds/{clean,state,responsive}-architecture.md` so contributors see them.
3. **Moodboard template consumes LLM-supplied `motifs` and `tone` arrays** — extend `moodboard.html` with `{% for m in brand.motifs %}` and `{% for t in brand.tone %}` blocks; keep fallback to static text when arrays absent.
4. **WCAG contrast wired into moodboard output** — call `culori`-based `wcagReport()` against the rendered palette pairs; embed the report in the HTML as a visible block.
5. **refine-moodboard TOML parse moves from `node -e` child-process to direct import** — `import { parse as parseToml } from "@iarna/toml"` at module level.
6. **Tauri default app menu** — when scaffolding a Tauri shell, write a minimal `src-tauri/src/menu.rs` with File/Edit/View/Window/Help structure and wire it in `main.rs`. Standard cross-platform menu; users customize.
7. **`theme-provider.tsx` patcher move** — extend `scaffold-react-vite.sh` reorganize step to also move `src/components/theme-provider.tsx` → `src/app/theme-provider.tsx` if present.
8. **Plugin manifest version bump** — `1.1.0` → `1.3.0`. CHANGELOG entry documenting the 11-phase span.
9. **Plain-text changelog entry** — `CHANGELOG.md` gets one new section: `## v1.3.0 (2026-05-20)` enumerating shipped phases.

### Out of scope (deferred, by name)

- AG-UI / Flutter / A2UI / MCP-UI scaffolders
- Streaming completions
- Tool/function calling
- Cost telemetry aggregation
- Windows .bat wrapper for shell scripts
- Multi-file source TSX
- AST-based patcher rewrite
- Animated SVG
- iOS/Android signing automation
- Multi-window Tauri configs
- Vite 8 upgrade (waits on shadcn upstream)
- Cosmetic items (quoted style keys, PNG size heuristics)

### Out of scope, but worth noting

- A cost-telemetry script that aggregates `.refiner/*/model-routing.log` could be a 50-line follow-on. Not this phase. Could be a small one-off later.

---

## 4. Acceptance criteria

1. README.md has a "Pipeline Capabilities" section listing the 5 conversion skills + 2 scaffolders + inference routing.
2. AGENTS.md has an "Architecture Reference" section pointing at the three scaffolds/*.md files.
3. `moodboard.html` template has `{% for m in brand.motifs %}` and `{% for t in brand.tone %}` blocks; falls back to static if arrays absent.
4. `refine-moodboard.mjs` LLM-mode output renders LLM-supplied motifs and tone visibly in the HTML (smoke verifies).
5. `moodboard.html` rendered HTML contains a WCAG contrast report block listing each text-on-bg pair with ratio + level.
6. `refine-moodboard.mjs` imports `@iarna/toml` directly (no more `node -e` subprocess).
7. `scaffold-react-vite-tauri.sh` generates a default menu file (or main.rs has the menu inlined).
8. `scaffold-react-vite.sh` reorganize step moves `theme-provider.tsx` from `src/components/` to `src/app/` if present.
9. `.claude-plugin/plugin.json` version bumped to `1.3.0`.
10. `CHANGELOG.md` has a `## v1.3.0` entry listing the 11 shipped phases.
11. End-to-end smoke: re-scaffold sample-app → `pnpm build` passes (verifies the polish didn't break anything).

11 acceptance gates. All deterministically checkable. No gate requires new features.

---

## 5. Phase decomposition

| # | Sub-change | Effort |
|---|---|---|
| 1 | Update README.md with Pipeline Capabilities section | medium |
| 2 | Update AGENTS.md with Architecture Reference section | small |
| 3 | Extend `moodboard.html` template for motifs/tone arrays | small |
| 4 | Verify LLM moodboard JSON shape includes motifs/tone (update refine-moodboard prompt + validator if needed) | small |
| 5 | Wire culori-based WCAG report into refine-moodboard output | small |
| 6 | Replace `node -e` TOML parse in refine-moodboard with import | small |
| 7 | Generate default Tauri menu file in scaffold-react-vite-tauri.sh | medium |
| 8 | Extend scaffold-react-vite.sh reorganize step for theme-provider | small |
| 9 | Bump plugin.json version 1.1.0 → 1.3.0 | trivial |
| 10 | Author CHANGELOG.md v1.3.0 entry | small |
| 11 | Regression smoke: re-scaffold sample-app | medium (network) |
| 12 | Acceptance gate sweep | small |

Total: one focused session expected.

---

## 6. Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| README rewrite drifts from current behavior | Low | Low | Cite explicit files/scripts; verify each claim |
| Moodboard template iteration syntax mismatch in Minijinja | Medium | Low | Smoke render against a knowme TOML with optional motifs array |
| LLM-supplied motifs in non-list form break iteration | Medium | Low | Validator already enforces shape; just extend it to require array of `{name, description}` |
| Tauri menu DSL Rust syntax wrong | Medium | Medium | Test via `cargo check src-tauri/` smoke; Tauri 2 menu API is documented + stable |
| Plugin version bump breaks downstream consumers | Low | Low | Semver-style minor bump; CHANGELOG provides migration story |
| Direct import of @iarna/toml in ESM doesn't work | Low | Low | It's already a devDep + already used in scaffold-react-vite.sh's PWA section; pattern is proven |

No high-severity risk.

---

## 7. Open questions

1. **Plugin version: `1.2.0` or `1.3.0`?** `1.2.0` was the version when AG-UI domain was added (git tag). Eleven phases since then is a substantial bump. Recommendation: `1.3.0`. If a release tag pattern exists, follow it; otherwise `1.3.0` is the safe minor bump.
2. **Should the WCAG report appear inline in moodboard HTML or as a sidecar JSON?** Recommendation: inline in HTML as a visible "Accessibility Report" section. Users want to see it; tucking it in JSON wastes the rendering opportunity.
3. **Tauri menu: native menu via `tauri-plugin-menu` or hand-built via `tauri::Menu` API?** Recommendation: Tauri 2's built-in `Menu` API directly (no extra plugin). Standard cross-platform structure (File, Edit, View, Window, Help).
4. **`theme-provider.tsx` patcher move: rewrite path imports too?** It's a free-floating component file from the nova preset; nothing in our scaffolded code references it yet. Recommendation: move it; if there are imports referencing `@/components/theme-provider`, the existing import-rewrite block already handles those.
5. **Should the CHANGELOG enumerate all 11 phases or just the high-water marks?** Recommendation: list phases with one-line summaries. Honest history; future contributors trace progress.

---

## 8. Honest verdict

This phase has clear scope and explicit boundaries. The work is mechanical (doc edits + small script extensions). No new architecture. The biggest item is the README pipeline-capabilities section because it must accurately describe 11 phases of behavior without inventing capabilities.

**Recommendation:** proceed to `/kbd-plan polish-pass`. One focused session. The regression smoke at the end is the critical gate — polish should not break anything.

---

## 9. Assessment metadata

```yaml
assessment_complete: true
phase: polish-pass
type: quality_lift
prerequisites_met:
  all_11_predecessor_phases: complete
scope_discipline_applied:
  - bounded by prior reflections' explicit follow-up lists
  - feature_work_actively_rejected (AG-UI, Flutter, streaming, tool-calling)
  - cosmetic items deferred to as-encountered
recommendation: |
  Proceed to /kbd-plan polish-pass. One focused session. Doc-heavy with
  small script extensions; regression smoke as the closing gate.
next_command: /kbd-plan polish-pass
```

Completed kbd-assess — polish-pass
