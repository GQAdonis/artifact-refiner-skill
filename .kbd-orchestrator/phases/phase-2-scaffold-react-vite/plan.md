# Plan: phase-2-scaffold-react-vite

**Backend:** OpenSpec (`openspec/changes/phase-2-scaffold-react-vite/`)
**Tasks:** `openspec/changes/phase-2-scaffold-react-vite/tasks.md`
**Design:** `openspec/changes/phase-2-scaffold-react-vite/design.md`
**Proposal:** `openspec/changes/phase-2-scaffold-react-vite/proposal.md`
**Headline phase:** yes
**User directives applied:** React 19 + Vite 8, shadcn-on-Base-UI, kebab-case, feature-based clean architecture, optional Rust+Axum wrapper

## Research-backed decisions (Tavily 2026-05-20)

- Canonical command: `pnpm dlx shadcn@latest init --template vite --base base --name <kebab> --yes`
- `--base base` = Base UI primitives (per January 2026 shadcn changelog)
- Tailwind v4 wiring done automatically by shadcn init (no PostCSS, no autoprefixer, CSS-first config)
- React 19.2.6 + Vite 8.0.13 + shadcn CLI 4.7.0 all current stable

## Ordered change list

| # | Change | Section | Gate |
|---|---|---|---|
| 1 | Author clean-architecture + kebab-case convention docs | 1.* | docs exist |
| 2 | Author `vite-shell-css.html` Minijinja template + render test | 2.* | render produces `@import "tailwindcss"` + `--color-ember` |
| 3 | Author `scripts/lib/kebab-case.sh` helper | 3.* | smoke test passes |
| 4 | Author `assets/templates/sample-app.tsx` (uses brand var + shadcn Button + hook) | 4.* | file exists |
| 5 | Author `scripts/scaffold-react-vite.sh` (delegate + patch) | 5.* | smoke `pnpm build` succeeds |
| 6 | Author `scripts/scaffold-react-vite-axum.sh` + axum binary scaffold | 6.* | `cargo check` succeeds |
| 7 | Author `skills/scaffold-react-vite/SKILL.md` | 7.* | frontmatter validates |
| 8 | Register skill in `plugin.json` | 8.* | JSON valid |
| 9 | Acceptance gate sweep | 9.* | verify-app |

## Sequencing

- 1–4 are parallel-safe (different files, independent).
- 5 depends on 2, 3, 4.
- 6 depends on 5 (axum wrapper consumes the React scaffold).
- 7 depends on 5 (SKILL.md references the script).
- 8 depends on 7.
- 9 depends on all.

## Estimated effort

One focused session if `shadcn init --template vite --base base` works first try. Two sessions if the patcher needs iteration on:

- Source TSX edge cases (named exports, hooks, utils detection)
- Cross-file import rewriting
- `pnpm build` regressions caused by clean-architecture moves

## Risk register (carried forward from proposal + design)

| Risk | Mitigation in plan |
|---|---|
| shadcn init hangs on interactive prompts | `--yes` flag; plan task 5.1 step c |
| Source TSX imports kebab-incompatible paths | Patcher rewrites import paths in step f |
| Missing shadcn components imported by source | Plan task 5.1 step g — auto `shadcn add` per detected import |
| Tailwind v4 / shadcn CSS-var collision | Different namespaces (`--color-*` vs `--background` etc.) per design Decision 7 |
| `build.rs` rebuilds Vite every cargo build | mtime check in task 6.1 step d |
| Vite 8 breaking change in `vite.config.ts` | shadcn CLI owns config generation |

## Reuse opportunities for follow-on phases

The patcher infrastructure built here is the template for:

- **phase-4-scaffold-tauri-desktop** — same React scaffold + Tauri shell crate.
- **phase-5-scaffold-tauri-mobile** — Tauri 2 mobile target on top of phase-4.
- **phase-7-scaffold-ag-ui-host** — React scaffold + AG-UI client + openai-proxy AG-UI surface wiring.
- **phase-9-scaffold-mcp-ui** — React scaffold + MCP-UI primitives (when MCP-UI standard solidifies).

The shared substrate is:

- `vite-shell-css.html` template (brand-vars injection)
- `kebab-case.sh` helper (file renaming)
- Patcher logic (move shadcn defaults into clean-architecture)
- Source-TSX import scanning (auto-`shadcn add`)

Reuse these in later phases; don't re-implement.
