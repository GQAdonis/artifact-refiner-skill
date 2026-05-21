# Proposal: phase-2-scaffold-react-vite (expanded scope per user directives)

## Why

This is the **headline phase** from the original ideation-to-app-pipeline assessment: refined React TSX artifact → buildable project on disk. User directives (2026-05-20) extended the scope to include:

1. **React 19 + Vite 8** as the target versions
2. **shadcn/ui on Base UI** (not Radix) as the UI base — `--base base` per the March 2026 shadcn CLI v4
3. **Kebab-case file naming** everywhere (`app.tsx`, `hero-section.tsx`, `use-theme.ts`, `auth-service.ts`)
4. **Feature-based clean architecture** — `src/features/<feature>/{components,hooks,services,types}/`, with `src/shared/` for cross-feature primitives
5. **Optional Rust + Axum wrapper** with `build.rs` that runs `vite build` and embeds `dist/` into the binary via `rust-embed`, producing a single self-contained executable

## Research-backed reality (Tavily web search, 2026-05-20)

Verified via the official shadcn changelog + CLI docs and Tailwind v4 docs:

- **`pnpm dlx shadcn@latest init --template vite --base base` is the canonical 2026 command** for a Vite + React + TS + Tailwind v4 + shadcn-on-Base-UI scaffold. We do NOT call `pnpm create vite` separately; shadcn CLI owns the entire bootstrap.
- **Base UI choice is independent of style.** `new-york` style supports both Radix and Base UI as of January 2026; we pass `--base base` to pick Base UI primitives, regardless of style.
- **Tailwind v4 is CSS-first** — no `tailwind.config.js`, no PostCSS, no autoprefixer. Just `@import "tailwindcss"` in `src/index.css` and the `@tailwindcss/vite` plugin in `vite.config.ts`. shadcn init does this for us.
- **React 19 is current stable** (19.2.6); Vite 8 is current (8.0.13). No special pinning required — shadcn CLI uses latest by default.
- **`rust-embed` + `axum` SPA serving** is a well-established pattern (`include_dir`, `rust-embed`, `spa-rs` wrapper, or `vite-rs-axum-0-8`). We use `rust-embed` directly for control + a SPA fallback handler so `/feature/sub-route` reloads serve `index.html`.

## What Changes

### Skill + orchestration

- **ADDED** `skills/scaffold-react-vite/SKILL.md` — quick-start dispatcher.
- **ADDED** `scripts/scaffold-react-vite.sh` — orchestration script (delegates to `shadcn init`, then patches).
- **ADDED** `scripts/scaffold-react-vite-axum.sh` — extension that also generates the Rust+Axum wrapper.
- **ADDED** `scripts/lib/kebab-case.sh` — small helper used by the patcher to rename files + import paths from PascalCase / camelCase to kebab-case.

### Brand-token integration

- **ADDED** `tools/template-forge-rs/templates/vite-shell-css.html` — Minijinja template producing the CSS-vars block that prepends `src/index.css` after `@import "tailwindcss"`. Renders the brand TOML's colors / typography as `--color-ember: #E04E28;` etc.

### Feature-based clean architecture conventions

- **ADDED** `references/scaffolds/clean-architecture.md` — the convention doc:
  - `src/features/<feature>/{components,hooks,services,types,index.ts}/`
  - `src/shared/{components,hooks,lib,types}/`
  - `src/app/` — top-level app shell (`app.tsx`, `router.tsx`, `providers.tsx`)
  - All file names kebab-case
  - Feature `index.ts` re-exports only the public surface
  - No cross-feature imports — features depend on `src/shared/`, never on each other

### Sample input

- **ADDED** `assets/templates/sample-app.tsx` — minimal TSX using `var(--color-ember)` + a shadcn Button so the smoke test exercises both the brand-token path and the Base UI primitive path.

### Optional Rust+Axum wrapper (deferred sub-feature)

When the user invokes `scaffold-react-vite-axum.sh` (or sets `--with-axum-wrapper`), in addition to the React app we generate:

- **`<target>/server/Cargo.toml`** — axum 0.8, tokio, rust-embed 8, tower-http 0.6, mime_guess
- **`<target>/server/build.rs`** — runs `pnpm install` + `pnpm build` against `<target>/` (the React app root) before compiling the Rust binary
- **`<target>/server/src/main.rs`** — axum server with:
  - `rust-embed` embedding `../dist/` at compile-time
  - Static file handler with mime detection
  - SPA fallback (any non-asset path → `index.html`)
  - Configurable port via env (`PORT`, default 3000)
- **`<target>/server/README.md`** — `cargo run --release` produces a single self-contained binary that serves the SPA

### Marketplace registration

- **MODIFIED** `.claude-plugin/plugin.json` — register the new `scaffold-react-vite` skill.

## Impact

### Affected surfaces

- `skills/scaffold-react-vite/`, `scripts/`, `tools/template-forge-rs/templates/`, `assets/templates/`, `references/scaffolds/`, `.claude-plugin/plugin.json`

### Affected dependencies

None at the artifact-refiner package level. The scaffolded projects bring their own:
- Frontend: React 19, Vite 8, Tailwind v4, shadcn-on-Base-UI (managed by `shadcn init`)
- Server (optional): axum 0.8, tokio 1, rust-embed 8, tower-http 0.6, mime_guess 2

### Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `shadcn init --template vite --base base` interactive prompts hang | Medium | High | Pass `--yes`; verify with `--help` during execute |
| Source TSX uses PascalCase imports referencing kebab-cased files | High | Medium | Patcher rewrites import paths in lockstep with file renames |
| Source TSX imports shadcn components that aren't installed by default | High | Medium | Patcher scans for `@/components/ui/<name>` imports and runs `shadcn add <name>` per match |
| Tailwind v4 CSS-vars collide with brand-token CSS-vars | Medium | Low | Brand vars use `--color-*` prefix; shadcn uses `--background`, `--foreground` etc. — different namespace |
| Rust+Axum `build.rs` rebuilds Vite on every `cargo build` | High | Low | `build.rs` checks `dist/` mtime vs `src/` mtime; skips if dist is newer |
| `pnpm` or `cargo` not installed | Medium | Medium | Pre-flight check with clear error messages |
| Vite 8 breaking change vs Vite 7 in `vite.config.ts` shape | Low | Medium | shadcn CLI generates the config; we don't hand-roll it |

No high-severity unmitigated risk.

### Out of scope (still deferred)

- Routing libraries (React Router, TanStack Router) — user adds post-scaffold if needed
- State management (Zustand, TanStack Query) — same
- Tauri / Flutter / AG-UI host scaffolders — their own phases
- Hot-reload between Rust server and Vite dev server — `cargo run` builds dist; iteration uses `pnpm dev` separately
- Multi-file source TSX (refined artifacts that span >1 file) — v1 accepts single .tsx; multi-file is a follow-on
- Updating an existing scaffold (idempotent re-run) — user deletes target first

## Conventions baked in (kebab-case + clean architecture)

Per user directive, the patcher enforces:

```
<target>/
├── src/
│   ├── app/                          # shell
│   │   ├── app.tsx
│   │   ├── providers.tsx             # theme, query-client, etc.
│   │   └── router.tsx                # placeholder for v1
│   ├── features/
│   │   └── <feature>/                # populated from the source TSX
│   │       ├── components/
│   │       │   └── <component>.tsx   # kebab-case
│   │       ├── hooks/
│   │       │   └── use-<hook>.ts
│   │       ├── services/
│   │       │   └── <service>-service.ts
│   │       ├── types/
│   │       │   └── <type>.types.ts
│   │       └── index.ts              # public surface
│   ├── shared/
│   │   ├── components/
│   │   │   └── ui/                   # shadcn components live here
│   │   ├── hooks/
│   │   ├── lib/
│   │   │   └── utils.ts              # cn helper
│   │   └── types/
│   ├── index.css                     # @import "tailwindcss" + brand vars
│   └── main.tsx                      # entry point — minimal
├── vite.config.ts
├── tsconfig.json
├── components.json                   # shadcn config (base: "base", style: "new-york")
├── package.json
└── README.md
```

The patcher detects the source TSX's exports and produces feature folders accordingly:

- Single default export → `src/features/<artifact-name>/components/<artifact-name>.tsx`
- Multiple named exports → each becomes a file under `src/features/<artifact-name>/components/`
- Hooks (functions starting with `use*`) → `hooks/use-*.ts`
- Pure utility functions → `lib/*.ts`
