# Proposal: polish-pass

## Why

Eleven phases of shipped work have accumulated bounded follow-up items in their reflections. Three new-feature phases in a row (phase-prefer-endpoint-consumption, phase-4 hybrid, phase-3b) added capability without addressing the documentation drift, small script gaps, and version-staleness that built up alongside.

This phase **fixes only what prior reflections explicitly flagged** as deferred. It introduces zero new capabilities. The discipline is: *fix the known gaps, don't invent new ones.*

## What Changes

- **MODIFIED** `README.md` — adds a "Pipeline Capabilities" section describing the 5 conversion skills + 2 scaffolders + inference routing shipped across 11 phases. The current README reflects v1.0.0-scope project state.
- **MODIFIED** `AGENTS.md` — adds an "Architecture Reference" section pointing at `references/scaffolds/{clean-architecture,state-architecture,responsive-architecture,kebab-case-rename}.md` so new contributors and future LLM agents discover them.
- **MODIFIED** `tools/template-forge-rs/templates/moodboard.html` — extends with `{% for m in brand.motifs %}` and `{% for t in brand.tone %}` iteration blocks; falls back to existing static text when those arrays are absent.
- **MODIFIED** `scripts/refine-moodboard.mjs` — replaces `node -e` subprocess TOML parse with direct `import { parse as parseToml } from "@iarna/toml"`; wires `culori`-based WCAG contrast report into the rendered HTML; ensures the LLM-supplied `motifs` and `tone` arrays land in the synthetic brand TOML so the template iterates over them.
- **MODIFIED** `scripts/scaffold-react-vite-tauri.sh` — generates a default cross-platform Tauri 2 menu (File / Edit / View / Window / Help) wired in `src-tauri/src/main.rs`. Standard structure; users customize per project.
- **MODIFIED** `scripts/scaffold-react-vite.sh` — extends the clean-architecture reorganize step to move `src/components/theme-provider.tsx` (from the shadcn nova preset) to `src/app/theme-provider.tsx` if present; rewrites import paths in lockstep.
- **MODIFIED** `.claude-plugin/plugin.json` — version `1.1.0` → `1.3.0` (semver minor bump reflecting 11-phase delta since last accurate version).
- **MODIFIED** `marketplace.json` — same version bump (1.1.0 → 1.3.0).
- **ADDED** (or modified if present) `CHANGELOG.md` — adds a `## v1.3.0 (2026-05-20)` section listing the 11 shipped phases with one-line summaries each.

## Impact

### Affected surfaces

`README.md`, `AGENTS.md`, `CHANGELOG.md`, `tools/template-forge-rs/templates/moodboard.html`, `scripts/refine-moodboard.mjs`, `scripts/scaffold-react-vite-tauri.sh`, `scripts/scaffold-react-vite.sh`, `.claude-plugin/plugin.json`, `marketplace.json`.

### Affected dependencies

None new. The `culori` and `@iarna/toml` modules are already devDeps.

### Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| README drifts from current behavior | Low | Low | Cite explicit file paths; verify each claim against grep |
| Moodboard template iteration syntax (Minijinja) wrong | Medium | Low | Render against knowme TOML with optional motifs array; smoke |
| LLM-supplied motifs in non-array form break iteration | Medium | Low | Validator in refine-moodboard.mjs gates shape before render |
| Tauri menu Rust syntax wrong | Medium | Medium | `cargo check src-tauri/` smoke after scaffold; Tauri 2 menu API is stable |
| Plugin version bump breaks downstream consumers | Low | Low | Semver minor bump; CHANGELOG provides context |
| theme-provider move breaks an existing scaffold's imports | Low | Low | Existing import-rewrite block (`@/components/theme-provider` → `@/app/theme-provider`) handles it |

No high-severity risk.

### Out of scope (deferred, explicitly)

All items already enumerated in the assessment §3 "Out of scope" list — AG-UI/Flutter/streaming/tool-calling/multi-file TSX/AST patcher/animated SVG/iOS signing/multi-window Tauri/Vite 8/cosmetic-only items. Each remains tracked but not addressed here.

## Integration contract preserved

- All scaffolders, converters, and the chat() helper continue to work unchanged from a consumer's perspective.
- Existing scaffolded projects are unaffected (this phase only changes the scaffolder's *output for new runs*).
- The PMPO loop is untouched.
- No new dependencies; the substrate stays the same.
- The regression smoke (gate #11) verifies the polish didn't break the existing pipeline.
