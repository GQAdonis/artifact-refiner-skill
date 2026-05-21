# Design: phase-2-scaffold-react-vite

## Decisions baked in (from user directives + Tavily research 2026-05-20)

### Decision 1 — Delegate to `shadcn init --template vite --base base`, not `pnpm create vite`

Per the official shadcn CLI v4 docs (March 2026), `shadcn init --template vite` is the canonical 2026 command that scaffolds Vite + React 19 + TypeScript + Tailwind v4 + shadcn in one step.

**Why this and not `pnpm create vite` then `shadcn init`:**

- `shadcn init --template vite` already includes Tailwind v4 wiring (the `@tailwindcss/vite` plugin, `@import "tailwindcss"`, etc.) — wiring we'd otherwise have to add manually.
- Single CLI invocation, fewer moving parts.
- shadcn CLI owns the upgrade path; we follow.

### Decision 2 — `--base base` for Base UI primitives

Per the January 2026 shadcn changelog, `--base base` selects Base UI as the primitive library. The `new-york` style remains the default visual style and is compatible with both Radix and Base UI. User wanted Base UI; this is the flag.

**Why not `radix`:** Per user directive. Also per the late-2025 shadcn announcement, Base UI is the explicitly-recommended primitive library for new projects.

### Decision 3 — Kebab-case enforced via post-shadcn-init patcher

shadcn init produces a default layout with mixed naming (`App.tsx`, `main.tsx`, `lib/utils.ts`, etc.). The patcher (`scripts/scaffold-react-vite.sh` step e) renames files and rewrites imports to kebab-case in lockstep.

**What gets renamed:**

- File names: `App.tsx` → `app.tsx`, `MyComponent.tsx` → `my-component.tsx`, `useTheme.ts` → `use-theme.ts`
- Import paths: `from "@/App"` → `from "@/app/app"` (also reflects clean-architecture move)
- Directory names where applicable

**What does NOT get renamed:**

- React component identifiers (`function App()` stays `function App()` — only the *file* is `app.tsx`)
- Hook function names (`useTheme` stays `useTheme` — file is `use-theme.ts`)
- Exported symbol names

This matches React community conventions: kebab-case files, PascalCase components, camelCase hooks.

### Decision 4 — Feature-based clean architecture layout

```
src/
├── app/        # shell (app.tsx, providers.tsx, router.tsx)
├── features/   # one folder per feature; populated from source TSX
└── shared/     # cross-feature primitives (shadcn components, utils, hooks)
```

**Why this structure:**

- Aligns with the dependency rule from clean architecture: features depend on shared, never on each other.
- Mirrors the structure proven across React 19 + Vite app templates in 2025-2026 community usage.
- Easy for future scaffolders (Tauri, Flutter) to reuse the *concept* even if the implementation differs.

**Rules enforced by the patcher:**

- Features cannot import from other features (no `from "@/features/other"` in feature code).
- Features can import from `@/shared/*` and `@/app/*`.
- `@/shared/*` cannot import from `@/features/*`.

Enforcement is by convention (documented in `references/scaffolds/clean-architecture.md`) and by a lint rule if/when a follow-on phase adds one. v1 doesn't ship the lint rule; the convention doc is the contract.

### Decision 5 — Rust + Axum wrapper is opt-in via a flag

The `--with-axum-wrapper` flag (or chaining `scripts/scaffold-react-vite-axum.sh`) is the extension path. Reason: not every consumer wants a Rust binary. The default flow is React-only.

**Why one combined binary instead of separate React and server projects:**

- User directive ("self-contained Rust project that can build and serve the application").
- Aligns with the `template-forge-rs` + `rust-mcp-filesystem` pattern: a Rust binary that embeds its own assets.
- Single binary deploys cleanly to any container, edge runtime, or VM.

**Why `rust-embed` and not `include_dir`:**

Both work. `rust-embed` is more idiomatic for SPA serving (already battle-tested in 2026 axum SPA examples); it provides the runtime introspection (`Assets::get(path)`) we need for the SPA fallback handler. `include_dir` is more compile-time-static.

**Why not `spa-rs`:**

`spa-rs` is a higher-level wrapper that abstracts axum entirely. We want axum visible so consumers can add API routes alongside the SPA. The hand-rolled axum + rust-embed pattern is ~80 lines and gives us full control.

### Decision 6 — `build.rs` runs Vite before `cargo build`

`build.rs`:

1. Checks if `<target>/dist/` exists and is newer than `<target>/src/`.
2. If stale, runs `pnpm install` (only if `node_modules` is absent) then `pnpm build`.
3. Emits `cargo:rerun-if-changed=../src` and `cargo:rerun-if-changed=../package.json` so cargo correctly invalidates when frontend changes.

**Why mtime-based and not unconditional:**

Unconditional rebuild means every `cargo build` runs Vite. Even with Vite's caching that's 1-2 seconds of wasted time per Rust-only iteration. mtime check costs microseconds.

### Decision 7 — Brand-token CSS layered onto shadcn's CSS vars

shadcn v4 produces `src/index.css` with `--background`, `--foreground`, `--primary`, etc. — its own design-system tokens. Our `vite-shell-css.html` template **replaces** that file with one that:

1. `@import "tailwindcss"` (preserved from shadcn default)
2. Adds brand tokens: `--color-bg`, `--color-ember`, etc. (our naming, distinct from shadcn's)
3. **Does NOT touch shadcn's design tokens** — those are added back when the user runs `shadcn add <component>`, which re-populates `components.json`-driven CSS vars.

**Why two namespaces:**

shadcn's `--primary` etc. are component-driven (Button uses `--primary`). Our `--color-ember` etc. are brand-driven (custom JSX uses `var(--color-ember)`). Keeping them separate means changing brand doesn't break shadcn components, and changing shadcn theme doesn't break brand consumption.

## Non-decisions (explicitly out of scope)

- Choice of routing library (deferred — user adds React Router, TanStack Router, or none post-scaffold)
- Choice of state management (deferred)
- Authentication / session management
- API client generation
- Storybook / Ladle wiring
- Multi-feature scaffolding (v1 puts the entire source TSX into one feature folder)
- AST-based import rewriting (v1 uses regex + grep; AST follows when/if regex becomes brittle)

## Sycophancy check

S-03 (scope inflation) audit applied. The user directives expanded scope materially — from "Vite + React v1 walking skeleton" to "shadcn-on-Base-UI + kebab-case + clean architecture + optional Rust wrapper." The corrective lens is:

1. **Are these real user needs or wish-list items?** Real — the user is building real apps and has standards.
2. **Does each addition compound complexity or replace complexity?** Each addition either reuses an existing tool (`shadcn init` replaces hand-rolled Vite config; `rust-embed` replaces hand-rolled static serving) or codifies a convention the user would impose anyway (kebab-case, feature-based architecture). No scope is being added for its own sake.
3. **What is now out of scope that we'd be tempted to include?** Routing, state management, auth, API clients, Storybook, multi-feature scaffolding, AST rewriting. All deferred. The proposal explicitly lists them.

Scope is large but bounded. Plan stays at one focused session if shadcn CLI v4 behaves as documented. Two sessions if patcher needs iteration.
