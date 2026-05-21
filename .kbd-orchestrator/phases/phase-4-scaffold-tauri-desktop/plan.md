# Plan: phase-4-scaffold-tauri-desktop (hybrid)

**Backend:** OpenSpec (`openspec/changes/phase-4-scaffold-tauri-desktop/`)
**Tasks:** `openspec/changes/phase-4-scaffold-tauri-desktop/tasks.md`
**Design:** `openspec/changes/phase-4-scaffold-tauri-desktop/design.md`
**Proposal:** `openspec/changes/phase-4-scaffold-tauri-desktop/proposal.md`
**Effective name:** phase-4-scaffold-hybrid (Tauri 2 covers desktop + mobile; phase-5 collapses in)

## Decisions baked in

- **Order: Block A first**, then B + C. Block A is retroactive — failing to land it first means B/C inherit the broken architecture.
- **`useState` legal for ephemeral local state.** Threshold rule, not robotic enforcement.
- **Stores are framework-agnostic** — cannot import React. ESLint enforces.
- **Tauri 2 single source, multi-target.** Desktop default; `--mobile` flag adds iOS + Android.
- **PWA + Tauri coexist** without conditional builds — each platform reads only what it needs.
- **Responsive is viewport-based**, not Tauri-detection-based. Resizing a Tauri desktop window small switches to mobile layout.
- **PWA theme color resolved to hex at scaffold time** via culori; brand swaps require `rebrand-artifact.mjs` patch.
- **ESLint architectural config is starter**, customizable.
- **Alpine → store threshold: single-boolean local, else store.**

## Ordered change list

| # | Block | Change | Effort | Gate |
|---|---|---|---|---|
| 1 | A.1 | `state-architecture.md` convention doc | small | doc exists with required sections |
| 2 | A.2 | `eslint-architecture.config.mjs` snippet | small | file exists |
| 3 | A.3 | Rewrite `sample-app.tsx` to zustand+immer architecture | small | follows all 3 layering rules |
| 4 | A.4 | `scaffold-react-vite.sh` updates: zustand+immer install, stores/, app-store, ESLint config | medium | smoke: re-scaffold sample-app → `pnpm build` + `pnpm lint` pass |
| 5 | A.5 | `convert-htmx-react.mjs` threshold update + multi-field sample | medium | smoke: multi-field Alpine → zustand store; integration smoke still passes |
| 6 | A.6 | SKILL.md updates (scaffold-react-vite + convert-htmx-react) | small | new sections present |
| 7 | B.1 | `responsive-architecture.md` | small | doc exists |
| 8 | B.2 | Extend `vite-shell-css.html` with safe-area vars | small | render contains `--safe-top` |
| 9 | B.3 | Scaffolder emits `use-breakpoint.ts`, `use-is-mobile.ts`, `responsive-shell.tsx`, `runtime.ts` | small | files present after scaffold |
| 10 | B.4 | `vite-plugin-pwa` wiring + PWA icon generation | medium | `dist/manifest.webmanifest` + `dist/sw.js` after build |
| 11 | C.1 | `scaffold-react-vite-tauri.sh` | medium-large | `pnpm tauri info` exits 0 |
| 12 | C.2 | `skills/scaffold-react-vite-tauri/SKILL.md` | small | frontmatter valid |
| 13 | C.3 | `--with-tauri-wrapper` chain + `plugin.json` registration | small | chain works |
| 14 | C.4 | Tauri smoke: `cargo check src-tauri` exits 0 | medium | exit 0 |
| 15 | D | Acceptance gate sweep (8 gates) | small | all PASS |

## Sequencing

```
A.1 → A.2 → A.3 → A.4 → A.5 → A.6  (Block A: linear, A.4 includes re-smoke)
                              │
                              ▼
B.1 → B.2 → B.3 → B.4         (Block B: linear, B.4 includes smoke)
                              │
                              ▼
C.1 → C.2 → C.3 → C.4         (Block C: linear, C.4 includes smoke)
                              │
                              ▼
D                             (final sweep)
```

Within block A, A.1-A.3 are parallel-safe but A.4 depends on A.3 (sample-app must exist before scaffolder is smoke-tested against it).

## Risk register (carried forward from assessment + design)

| Risk | Mitigation in plan |
|---|---|
| Retroactive correction breaks existing scaffolder | A.4 re-runs full smoke after every change |
| Tauri prerequisites missing | C.1.2 pre-flight check with clear error messages |
| PWA manifest theme color must be literal hex | B.4.1 reads brand TOML, converts via culori |
| ESLint false-positives | Documented as starter config in A.1 |
| Tauri 2 `init --ci` non-interactivity | Pinned in C.1.3; alternate flag set if `--ci` fails |
| iOS/Android SDK absence | C.1.6 skips gracefully with warning |
| Converted multi-field HTMX requires store generation | A.5 explicitly enumerates the threshold |
| Brand-swap doesn't update PWA manifest | rebrand-artifact patched in C (or B.4 depending on ordering — see assessment) |

## Estimated effort

**Two focused sessions.** Block A alone is ~one session because the scaffolder script is large and the retroactive smoke needs network (`pnpm install` time). Blocks B + C share a session.

## Reuse from prior phases

| Reused | From | This phase's use |
|---|---|---|
| `scripts/lib/kebab-case.sh` | phase-2 | Tauri crate naming |
| `vite-shell-css.html` template | phase-2 (extended) | Safe-area vars + responsive CSS |
| `scaffold-react-vite.sh` step structure | phase-2 (extended) | Foundation for A/B blocks |
| `scaffold-react-vite-axum.sh` | phase-2 | Continues to work alongside Tauri |
| `convert-htmx-react.mjs` | phase-3 (modified) | Threshold rule update |
| `rebrand-artifact.mjs` | phase-3 (modified in B) | Patches vite.config.ts PWA manifest |
| `culori` (already devDep) | phase-3 | OKLCH → hex for PWA theme color |
| `assets/library/brands/{knowme,prometheus-ags}.toml` | phase-2/3 | Brand resolution for PWA manifest |
