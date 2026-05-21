# Tasks: phase-2-scaffold-react-vite

Sequenced. The early tasks establish conventions; later tasks consume them.

## 1. Convention docs

- [ ] 1.1 Author `references/scaffolds/clean-architecture.md` — directory layout, kebab-case naming rules, feature-boundary rules (no cross-feature imports), `index.ts` re-export discipline.
- [ ] 1.2 Author `references/scaffolds/kebab-case-rename.md` — heuristic for renaming PascalCase / camelCase identifiers to kebab-case file paths; what gets renamed (files, import paths) vs what doesn't (component identifiers in JSX, exported symbol names).

## 2. Brand-token CSS template

- [ ] 2.1 Author `tools/template-forge-rs/templates/vite-shell-css.html` — Minijinja template producing `:root { --color-bg: ...; --color-ember: ...; }` etc. with brand TOML data. First line: `@import "tailwindcss";` so the file replaces `src/index.css` cleanly.
- [ ] 2.2 Render test: `template-forge render --brand knowme --template vite-shell-css --library assets/library --templates-base tools/template-forge-rs/templates`. Expected: contains `@import "tailwindcss"` and `--color-ember: #E04E28`.

## 3. Helper scripts

- [ ] 3.1 Author `scripts/lib/kebab-case.sh` — pure-bash helper exposing functions `to_kebab <name>` and `rename_file_kebab <path>`. Handles PascalCase → kebab (`HeroSection` → `hero-section`) and camelCase → kebab (`useTheme` → `use-theme`). Pure shell, no Node.
- [ ] 3.2 Smoke test: `to_kebab MyComponent` → `my-component`; `to_kebab useDarkMode` → `use-dark-mode`.

## 4. Sample input artifact

- [ ] 4.1 Author `assets/templates/sample-app.tsx` — minimal TSX that:
  - Uses `var(--color-ember)` in inline styles (exercises brand-token consumption)
  - Imports a shadcn `Button` from `@/shared/components/ui/button` (exercises shadcn-on-Base-UI path)
  - Has one named hook `useToggle` (exercises hook routing to `hooks/use-toggle.ts`)
  - Single default export `App`

## 5. Core scaffolder script

- [ ] 5.1 Author `scripts/scaffold-react-vite.sh`:

  Inputs (flags):
    --name <artifact-name>       (required, used as feature folder name)
    --source <path-to-tsx>       (required)
    --brand <brand-name>         (required, e.g. knowme)
    --target <path>              (required)
    --with-axum-wrapper          (optional flag; chains into the axum generator)

  Steps:
    a) Pre-flight: check `pnpm`, `node`, `curl`, `template-forge` on PATH. Fail-fast with hints.
    b) Validate inputs: source TSX exists, target dir does not (no overwrite v1), brand TOML resolvable.
    c) Run `pnpm dlx shadcn@latest init --template vite --base base --name <kebab-target-name> --yes` in the parent of `<target>`. shadcn CLI creates the project tree under `<target>`.
    d) Render `vite-shell-css.html` → `<target>/src/index.css` via template-forge (overwriting shadcn's default index.css; shadcn's CSS variables are preserved via shadcn's components.json mechanism and re-emitted by shadcn add).
    e) Reorganize default tree into clean-architecture layout:
       - Move `src/components/ui/` → `src/shared/components/ui/`
       - Create `src/app/`, `src/features/`, `src/shared/{hooks,lib,types}/`
       - Move existing `src/lib/utils.ts` → `src/shared/lib/utils.ts`
       - Update `components.json` aliases: `"components": "@/shared/components"`, `"utils": "@/shared/lib/utils"`, etc.
       - Update `tsconfig.json` path aliases to match
    f) Patch source TSX into `src/features/<name>/`:
       - Detect default export → write to `components/<name>.tsx` (kebab-cased)
       - Detect named hooks (functions matching `^use[A-Z]`) → write to `hooks/use-<kebab>.ts`
       - Detect named components → write to `components/<kebab>.tsx`
       - Generate `index.ts` re-exporting only the default + hooks
       - Rewrite import paths inside the moved files to match new layout
    g) Scan all generated TSX for `@/shared/components/ui/<name>` imports; run `pnpm dlx shadcn@latest add <name> --yes --base base` for each missing component.
    h) Update `src/main.tsx` to `import App from "@/features/<name>"` and render `<App />`. (Rename to `src/main.tsx` even if shadcn produced `main.tsx`; shadcn's default is already kebab-compatible.)
    i) Write `<target>/README.md` recording: artifact_name, brand, source path, run commands.
    j) Run `pnpm install --silent` (already done by shadcn init usually; verify).
    k) Run `pnpm build` to verify the tree compiles.
    l) Print success summary with path + run commands.
    m) If `--with-axum-wrapper`, dispatch to `scripts/scaffold-react-vite-axum.sh --target <target>`.

- [ ] 5.2 `chmod +x scripts/scaffold-react-vite.sh`.
- [ ] 5.3 Smoke test: `bash scripts/scaffold-react-vite.sh --name smoke --source assets/templates/sample-app.tsx --brand knowme --target /tmp/smoke-vite` — verify `pnpm build` succeeds.

## 6. Axum wrapper generator

- [ ] 6.1 Author `scripts/scaffold-react-vite-axum.sh`:

  Inputs:
    --target <path>  (the React project root)

  Steps:
    a) Validate `<target>/package.json` exists.
    b) Create `<target>/server/` directory.
    c) Write `<target>/server/Cargo.toml`:
       - axum 0.8 (features = ["macros"])
       - tokio 1 (features = ["full"])
       - tower-http 0.6 (features = ["fs", "trace", "cors"])
       - rust-embed 8 (features = ["debug-embed"] for dev, plain for release)
       - mime_guess 2
       - anyhow 1, thiserror 2, tracing 0.1, tracing-subscriber 0.3
       - clap 4 (features = ["derive", "env"])
    d) Write `<target>/server/build.rs`:
       - Compare mtime of `<target>/dist/` and `<target>/src/`
       - If dist absent or stale, run `pnpm install` (only if `node_modules` absent) then `pnpm build`
       - Re-run on changes to `package.json` or `src/` via `cargo:rerun-if-changed=`
    e) Write `<target>/server/src/main.rs`:
       - `#[derive(RustEmbed)] #[folder = "../dist"] struct Assets;`
       - Axum router: GET `/*path` → `static_handler`
       - `static_handler` looks up the path in Assets; on miss, falls back to `index.html` (SPA semantics) — except for paths matching `\.(js|css|svg|png|jpg|woff|woff2|ico)$` which return 404
       - mime via `mime_guess::from_path`
       - PORT env var (default 3000), bind to `0.0.0.0:$PORT`
       - tracing-subscriber init
    f) Write `<target>/server/README.md`:
       - `cargo run --release` builds Vite + compiles binary + serves
       - `cargo build --release` produces a self-contained binary at `target/release/server`
       - The binary is single-file; ship that, no node_modules needed at runtime
    g) Run `cargo check --manifest-path <target>/server/Cargo.toml` to verify it compiles.

- [ ] 6.2 `chmod +x scripts/scaffold-react-vite-axum.sh`.

## 7. Skill definition

- [ ] 7.1 Author `skills/scaffold-react-vite/SKILL.md`:

  Frontmatter:
    name: scaffold-react-vite
    description: Convert a refined React TSX artifact into a buildable Vite + React 19 + TypeScript + shadcn-on-Base-UI project with kebab-case feature-based clean architecture. Optionally wrap in a Rust + Axum binary that embeds the dist via rust-embed and serves the SPA.

  Sections:
    - Setup (artifact_type, content_type, domain adapter, PMPO entry)
    - User Input (arguments + flags)
    - Default Constraints
    - Procedure (delegates to scripts/scaffold-react-vite.sh)
    - Output Contract
    - When to Use the Axum Wrapper
    - References (clean-architecture.md, kebab-case-rename.md, the proposal)

- [ ] 7.2 Validate frontmatter: `head -5 skills/scaffold-react-vite/SKILL.md | grep -q "^---"`.

## 8. Plugin manifest registration

- [ ] 8.1 Read `.claude-plugin/plugin.json`.
- [ ] 8.2 Insert `./skills/scaffold-react-vite` in the `skills` array (alphabetical position).
- [ ] 8.3 Validate JSON.

## 9. Acceptance gate sweep

- [ ] 9.1 `skills/scaffold-react-vite/SKILL.md` exists with valid frontmatter.
- [ ] 9.2 `scripts/scaffold-react-vite.sh` exists, is executable.
- [ ] 9.3 `scripts/scaffold-react-vite-axum.sh` exists, is executable.
- [ ] 9.4 `tools/template-forge-rs/templates/vite-shell-css.html` exists.
- [ ] 9.5 `template-forge render --brand knowme --template vite-shell-css ...` produces output containing `@import "tailwindcss"` and `--color-ember: #E04E28`.
- [ ] 9.6 `assets/templates/sample-app.tsx` exists.
- [ ] 9.7 `references/scaffolds/clean-architecture.md` exists.
- [ ] 9.8 `references/scaffolds/kebab-case-rename.md` exists.
- [ ] 9.9 End-to-end smoke: `bash scripts/scaffold-react-vite.sh --name smoke --source assets/templates/sample-app.tsx --brand knowme --target /tmp/smoke-vite` produces a directory where `pnpm build` succeeds.
- [ ] 9.10 End-to-end axum: re-run with `--with-axum-wrapper`; `cargo check --manifest-path /tmp/smoke-vite/server/Cargo.toml` succeeds.
- [ ] 9.11 `plugin.json` lists the new skill.

## Out of scope (deferred)

- React Router / TanStack Router setup
- State management opinionation
- Tauri / Flutter / AG-UI / A2UI / MCP-UI scaffolders (own phases)
- Hot-reload between cargo and Vite dev server
- Multi-file source TSX
- Idempotent re-run on existing scaffolds

## Recommended agents

| Tasks | Agent |
|---|---|
| 1.*, 2.*, 7.* | direct authoring |
| 3.*, 5.*, 6.* | direct shell + verify-app for smoke |
| 8.* | direct edit |
| 9.* | verify-app |
| Post-execute review | code-reviewer + typescript-reviewer |
