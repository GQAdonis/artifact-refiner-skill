# Plan: phase-3b-aux-conversions

**Backend:** OpenSpec (`openspec/changes/phase-3b-aux-conversions/`)
**Tasks:** `openspec/changes/phase-3b-aux-conversions/tasks.md`
**Proposal:** `openspec/changes/phase-3b-aux-conversions/proposal.md`

## Decisions baked in

- **convert-md-to-htmx is fully deterministic** — no LLM calls in v1
- **refine-moodboard is LLM-primary** — first script where `chat()` is the engine, not a sidecar
- **design-svg-logo is mode-switching** — `--mode llm` (with validation + fallback) or `--mode placeholder`
- **SVG validation is strict** — reject `<script>`, `on*=`, `javascript:` URLs; fall back to placeholder
- **Moodboard prompt routes to `refiner-evaluate` (medium tier)** — creative synthesis needs more capability than mechanical iteration
- **Logo prompt routes to `refiner-iterate` (small tier)** — each variant is a small request; multiple calls is fine at subscription pricing
- **Single-file HTML outputs** — no external CSS/JS for md-to-htmx or moodboard
- **PNG rasterization uses rsvg-convert when available**, copies SVG to `.png` as fallback (same pattern as phase-4 B.4)
- **No template-forge `--data` flag in this phase** — shape moodboard spec as brand-data extension

## Ordered change list

| # | Change | Section | Gate |
|---|---|---|---|
| 1 | Install devDeps + author sample inputs | 1.* | `pnpm install` clean |
| 2 | Author `moodboard.html` + `logo-icon.svg` Minijinja templates | 2.* | render via template-forge succeeds for both |
| 3 | Author `scripts/lib/svg-validate.mjs` + self-test | 3.* | 4/4 validator tests pass |
| 4 | Author `scripts/convert-md-to-htmx.mjs` | 4.* | sample MD → branded HTML smoke passes |
| 5 | Author `scripts/refine-moodboard.mjs` (placeholder + LLM modes) | 5.* | both smoke paths produce HTML |
| 6 | Author `scripts/design-svg-logo.mjs` (placeholder + LLM modes) | 6.* | 3 SVG + 18 PNG output |
| 7 | Update three SKILL.md files | 7.* | dispatch lines present + frontmatter valid |
| 8 | Acceptance gate sweep | 8.* | 8/8 PASS |

## Sequencing

```
1 (deps + samples) → 2 (templates) ── 3 (validator)
                                     │
                                     ▼
                                    4 (md-to-htmx) ── (independent, no LLM)
                                     │
                                     ▼
                                    5 (moodboard, uses #2 template + chat())
                                     │
                                     ▼
                                    6 (svg-logo, uses #2 template + #3 validator + chat())
                                     │
                                     ▼
                                    7 (SKILL.md docs) → 8 (acceptance)
```

4 is parallel-safe with 5 and 6 (different files, different concerns). Doing them strictly sequential is the lower-risk order for one focused session.

## Risk register

| Risk | Mitigation |
|---|---|
| LLM SVG invalid / has `<script>` | `isValidSvg()` strict check → fallback |
| LLM moodboard JSON malformed | Hand-rolled validator → fallback |
| markdown-it edge cases | Pin version; document quirks; defer to user's plugins |
| template-forge can't render moodboard non-brand input | Shape spec as brand-data; write temp TOML for synthetic moodboards |
| LLM prompt-injection in moodboard | Reject responses containing `SYSTEM:`, `IGNORE PREVIOUS`, etc. |
| rsvg-convert absent | Copy SVG to `.png` filename + warn (existing pattern) |

## Estimated effort

One focused session if `template-forge` doesn't need extension (and it doesn't — we shape moodboard input as brand-data). Two sessions if real-world MD edge cases surface in convert-md-to-htmx.

## Strategic value

Modest. Completes the phase-0 conversion-skill commitment. Pressure-tests the chat() routing layer under genuine generative load (moodboard) and validation-required load (SVG).

The **interesting work** is in `refine-moodboard.mjs`: it's the first script where the LLM is the engine, not a sidecar. The pattern it establishes (LLM produces structured JSON → deterministic renderer produces HTML) is the template for future generative skills.

## Reuse from prior phases

| Reused | Source phase | Use |
|---|---|---|
| `scripts/lib/openai-client.mjs` `chat()` | phase-prefer-endpoint-consumption | LLM calls in moodboard + svg-logo |
| `tools/template-forge-rs` Minijinja engine | phase-rust-workspace-bootstrap | Render moodboard + logo-icon |
| `vite-shell-css.html` brand CSS | phase-2 | Brand styling for md-to-htmx |
| `assets/library/brands/*.toml` | phase-2 | Brand data source |
| `culori` | phase-3 | WCAG ratios in moodboard |
| `parse5` | phase-3 | SVG validation in svg-validate |
| PWA icon SVG pattern | phase-4 B.4 | logo-icon.svg template structure |

Net new: ~700 lines (3 scripts + 2 templates + 1 helper + 3 SKILL.md edits + sample inputs).
