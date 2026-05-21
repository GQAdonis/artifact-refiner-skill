# Tasks: phase-4-scaffold-tauri-desktop (hybrid)

Three blocks (A/B/C) plus an acceptance sweep. Execute strictly in order: Block A must complete and re-smoke phase-2/phase-3 cleanly before Block B starts, so B and C build on the corrected substrate.

## Block A — Architecture standardization (retroactive)

### A.1 Convention doc

- [ ] A.1.1 Author `references/scaffolds/state-architecture.md`. Required sections:
  - **Layering** — Components → Hooks → Stores → I/O
  - **Local state exception** — `useState` allowed for ephemeral single-component state (toggles, drafts, hover); anything shared, persisted, or with side effects → store
  - **Store rules** — stores never import React; stores use zustand+immer; stores own all I/O and realtime subscriptions; stores expose plain interfaces
  - **Hook rules** — hooks consume stores via selectors; hooks may compose useEffect for lifecycle; hooks do not perform I/O directly
  - **Component rules** — components consume only hooks; components do not import services; components do not import store files directly
  - **Realtime ownership** — Supabase/WebSocket/SSE registrations live in store init or `initRealtime()` actions invoked once from `<Providers>`
  - **TSX over JSX** — every React source file uses `.tsx` extension; `.jsx` is forbidden
  - **ESLint config example** — flat-config snippet showing the `no-restricted-imports` rules

### A.2 ESLint architectural config

- [ ] A.2.1 Author `references/scaffolds/eslint-architecture.config.mjs` — flat-config snippet with per-directory `no-restricted-imports` overrides:
  - `**/components/**` cannot import from `**/stores/**` or `**/services/**`
  - `**/hooks/**` cannot import from `**/services/**`, `axios`, `ky`, `fetch` wrappers
  - `**/stores/**` cannot import from `react` (stores are framework-agnostic)

### A.3 Sample app rewrite

- [ ] A.3.1 Rewrite `assets/templates/sample-app.tsx` to demonstrate the architecture:
  - One zustand+immer store exported (`useAppStore`) with state + actions
  - One hook (`useCounter`) that selects from the store and exposes a tailored slice
  - One default-exported `App` component that uses only the hook
  - JSX still consumes brand vars via `var(--color-*)`
  - Still imports a shadcn Button to exercise that path
- [ ] A.3.2 Sample must be valid TSX and follow all three layering rules.

### A.4 Scaffolder updates for the new architecture

- [ ] A.4.1 Update `scripts/scaffold-react-vite.sh`:
  - Install `zustand` + `immer` via `pnpm add` after shadcn init
  - Create `src/features/<f>/stores/` and `src/app/stores/` directories during reorganize step
  - Generate `src/app/stores/app-store.ts` — empty zustand+immer store with theme slice as a starter
  - Auto-detect source TSX named exports matching `^use[A-Z][A-Za-z]*Store$` → route to `stores/<kebab>.ts`
  - Generate `eslint.config.mjs` (or extend existing) with the architectural-rule overrides from A.2
- [ ] A.4.2 Re-run end-to-end smoke against the rewritten sample-app: `pnpm build` succeeds and `pnpm lint` exits clean.

### A.5 Converter update

- [ ] A.5.1 Update `scripts/convert-htmx-react.mjs`:
  - Add threshold: count fields in Alpine `x-data`; if 1 boolean → local `useState` (current behavior); if >1 field OR any non-boolean → emit a zustand+immer store + a hook
  - Store goes to `stores/<feature>-store.ts` (the patcher then moves it to `src/features/<f>/stores/`)
  - Hook in `hooks/use-<feature>-state.ts` selects from store
- [ ] A.5.2 Re-run conversion smoke (sample-htmx.html) — verify the multi-field state (count + a future "items" example) now lifts to a store, not local `useState`. (Current sample-htmx only has `count`; either extend the sample to exercise both branches OR ship a second `assets/templates/sample-htmx-multi.html`.)
- [ ] A.5.3 Re-run convert → scaffold → `pnpm build` integration smoke; verify lint passes.

### A.6 SKILL.md updates

- [ ] A.6.1 Update `skills/scaffold-react-vite/SKILL.md`:
  - Add "Architectural Baseline" section pointing at `state-architecture.md`
  - Document the `--with-tauri-wrapper` flag (forward reference to Block C)
- [ ] A.6.2 Update `skills/convert-htmx-react/SKILL.md`:
  - Add "State lift threshold" subsection documenting the single-boolean vs multi-field rule

## Block B — Hybrid form-factor + PWA

### B.1 Responsive architecture doc

- [ ] B.1.1 Author `references/scaffolds/responsive-architecture.md`:
  - **Breakpoint policy** — mobile (<768), tablet (768-1023), desktop (≥1024)
  - **`useBreakpoint` contract** — reactive viewport classifier
  - **`useIsMobile` convenience** — derived `useBreakpoint() === "mobile"`
  - **`<ResponsiveShell>` pattern** — selects desktop layout vs mobile bottom-nav at runtime
  - **Safe-area-inset CSS variables** — `--safe-top`, `--safe-bottom`, `--safe-left`, `--safe-right`; used by `<ResponsiveShell>` for notch / home-bar clearance on Tauri mobile + PWA installs
  - **Tailwind v4 breakpoint preset** matching the hook
  - **Tauri-vs-web detection** — `isTauri()` helper in `src/shared/lib/runtime.ts`, used sparingly

### B.2 Safe-area + responsive CSS in brand template

- [ ] B.2.1 Update `tools/template-forge-rs/templates/vite-shell-css.html`:
  - Add `--safe-top`, `--safe-bottom`, `--safe-left`, `--safe-right` to `:root`
  - Map them to `env(safe-area-inset-*)`
  - Add `html { padding-top: var(--safe-top); }` mobile rule guarded by `@media (max-width: 767px)`
  - Add `meta name="viewport"` recommendation comment for `vite-plugin-pwa` to inject
- [ ] B.2.2 Re-render against knowme brand; verify the new CSS vars are present.

### B.3 Generated templates (emitted by scaffolder into target)

- [ ] B.3.1 In the scaffolder, generate `src/shared/hooks/use-breakpoint.ts` with the contract from assessment §5B.
- [ ] B.3.2 Generate `src/shared/hooks/use-is-mobile.ts` (one-line wrapper).
- [ ] B.3.3 Generate `src/app/responsive-shell.tsx` with a placeholder desktop sidebar layout + mobile bottom-nav layout selected by `useBreakpoint()`.
- [ ] B.3.4 Generate `src/shared/lib/runtime.ts` exporting `isTauri()`.

### B.4 PWA wiring

- [ ] B.4.1 Update `scripts/scaffold-react-vite.sh`:
  - Install `vite-plugin-pwa` via `pnpm add -D`
  - Inject `VitePWA({ ... })` plugin into `vite.config.ts` with brand-resolved manifest:
    - `name`, `short_name` from `--name`
    - `theme_color` from brand TOML's `colors.dark.ember` (or light if user chose), converted to hex via culori
    - `background_color` from brand TOML's `colors.dark.bg` (hex)
    - `start_url: "/"`, `display: "standalone"`, `registerType: "autoUpdate"`
    - Icons reference `/icons/icon-192.png` and `/icons/icon-512.png`
- [ ] B.4.2 Generate PWA icon placeholders:
  - Author `tools/template-forge-rs/templates/pwa-icon.svg` — Minijinja template rendering a 512×512 SVG with brand ember background and the first character of `brand.meta.name` in white (display font)
  - Scaffolder renders it via `template-forge`, writes to `<target>/public/icons/icon-512.png` (rasterize via `node-sharp` or skip rasterization if package not present and emit SVG only with a clear warning)
- [ ] B.4.3 Re-run end-to-end smoke: build produces `dist/manifest.webmanifest` and `dist/sw.js` (or `dist/registerSW.js`).

## Block C — Tauri hybrid shell

### C.1 Tauri scaffolder script

- [ ] C.1.1 Author `scripts/scaffold-react-vite-tauri.sh`. Inputs:
  - `--target <path>` (required) — the React project root (already scaffolded by phase-2)
  - `--mobile` (optional flag) — also init iOS + Android targets
  - `--bundle-id <reverse-dns>` (default: `com.example.<kebab-name>`)
- [ ] C.1.2 Pre-flight: check `cargo`, `rustup`, `pnpm`. If `--mobile`, also check for `xcrun` (macOS) and a `JAVA_HOME` (Android).
- [ ] C.1.3 In `<target>`, run `pnpm tauri init --ci --app-name <basename> --window-title <basename> --frontend-dist ../dist --dev-url http://localhost:5173`. (Tauri v2 `init` is non-interactive with `--ci`.)
- [ ] C.1.4 Customize `src-tauri/tauri.conf.json`:
  - `app.security.csp` set to brand-aware policy
  - `bundle.targets` set per platform defaults
  - `app.withGlobalTauri = false`
- [ ] C.1.5 Add `tauri` script to `<target>/package.json` (via node JSON edit, alongside existing `dev`/`build`).
- [ ] C.1.6 If `--mobile`: run `pnpm tauri ios init` and `pnpm tauri android init` (gracefully skip with a warning if SDKs absent).
- [ ] C.1.7 Verify by running `pnpm tauri info` and capturing exit code 0.

### C.2 Tauri SKILL.md

- [ ] C.2.1 Author `skills/scaffold-react-vite-tauri/SKILL.md`:
  - Frontmatter: `name: scaffold-react-vite-tauri`
  - Setup, User Input, Procedure (dispatches to the script), Default Constraints, Output Contract
  - Prerequisites section listing Rust + platform SDKs
  - "Why this and not Capacitor?" rationale

### C.3 Chaining + registration

- [ ] C.3.1 Add `--with-tauri-wrapper` flag to `scripts/scaffold-react-vite.sh` that chains into `scaffold-react-vite-tauri.sh` after build.
- [ ] C.3.2 Update `.claude-plugin/plugin.json` to register `./skills/scaffold-react-vite-tauri` (alphabetical: between `scaffold-react-vite` and existing entries).

### C.4 Tauri smoke

- [ ] C.4.1 Run `bash scripts/scaffold-react-vite.sh --name smoke-tauri --source assets/templates/sample-app.tsx --brand knowme --target /tmp/smoke-tauri --with-tauri-wrapper`.
- [ ] C.4.2 Verify `/tmp/smoke-tauri/src-tauri/Cargo.toml` exists.
- [ ] C.4.3 `cd /tmp/smoke-tauri && pnpm tauri info` exits 0.
- [ ] C.4.4 If Rust toolchain + macOS available: `pnpm tauri build --debug` succeeds OR (acceptable fallback) `cargo check --manifest-path src-tauri/Cargo.toml` exits 0.

## Block D — Acceptance gate sweep

- [ ] D.1 All A.* tasks complete; phase-2 sample-app and phase-3 converter smoke tests still pass with new architecture.
- [ ] D.2 All B.* tasks complete; `dist/manifest.webmanifest` + `dist/sw.js` present after build.
- [ ] D.3 All C.* tasks complete; Tauri smoke gates pass.
- [ ] D.4 `references/scaffolds/{state-architecture,responsive-architecture}.md` both exist with required sections.
- [ ] D.5 `plugin.json` lists `scaffold-react-vite-tauri`.
- [ ] D.6 `eslint.config.mjs` is generated in scaffolded projects and `pnpm lint` exits clean on the rewritten sample-app.
- [ ] D.7 `scripts/scaffold-react-vite.sh --help` documents `--with-tauri-wrapper`.
- [ ] D.8 Final integration: re-scaffold sample-app with `--with-tauri-wrapper --with-axum-wrapper`; verify both `server/` and `src-tauri/` coexist cleanly.

## Out of scope (deferred)

- iOS code signing / App Store / Google Play submission
- Tauri plugin selection beyond defaults (storage, notifications, deep-link, etc.)
- Multi-window Tauri configurations
- Migrating existing scaffolded projects
- Native menu bar / window-controls polish
- AG-UI / A2UI / Flutter scaffolders

## Recommended agents

| Tasks | Agent |
|---|---|
| A.1-A.3, A.6, B.1, C.2 | direct authoring |
| A.4, A.5, B.3, B.4, C.1, C.3 | direct scripting + verify-app for each smoke |
| A.4.2, A.5.3, B.4.3, C.4 | verify-app |
| D.* | verify-app |
| Post-execute review | code-reviewer + typescript-reviewer |
