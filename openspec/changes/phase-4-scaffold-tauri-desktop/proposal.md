# Proposal: phase-4-scaffold-tauri-desktop (effectively phase-4-scaffold-hybrid)

## Why

User directives expand the original "Tauri desktop" goal in three dimensions and add a retroactive correction to phase-2 + phase-3 outputs:

1. **Tauri 2 wrapper** is a thin add-on to any Vite/React project — both desktop and mobile (iOS + Android) targets are addressable from the same source. The originally-planned `phase-5-scaffold-tauri-mobile` collapses into this phase.
2. **PWA behavior** on the web target. Same source produces a desktop website, a mobile-installable PWA, a Tauri desktop binary, and Tauri iOS/Android apps.
3. **Responsive primitives** so the React app smoothly transitions between desktop and mobile form factors based on viewport, regardless of which shell hosts it.
4. **Architectural standardization** (retroactive): zustand + immer + strict component/hook/store separation, TSX always, applied to every React/Vite scaffold from phase-2 onward — including a rewrite of the phase-2 sample-app and a behavior change in the phase-3 converter.

These ship together because the architecture standardization is a *substrate* every subsequent scaffolder needs. Without it first, the responsive primitives and Tauri shell would be built on a non-conforming foundation.

## What Changes

### Block A — Architecture standardization (retroactive to phase-2 + phase-3)

- **ADDED** `references/scaffolds/state-architecture.md` — zustand+immer contract, dependency rule, store/hook/component separation, realtime ownership, lint examples.
- **REWRITTEN** `assets/templates/sample-app.tsx` — demonstrates a zustand+immer store, a hook that consumes it, a component that uses only the hook. Smoke target now exercises the architecture.
- **MODIFIED** `scripts/scaffold-react-vite.sh` — installs `zustand` + `immer`; creates `src/features/<f>/stores/` and `src/app/stores/`; generates `src/app/stores/app-store.ts` with theme slice; auto-routes detected `useXxxStore` named exports to `stores/`; updates the ESLint config (creates one if absent) with the no-cross-layer-import architectural rules.
- **MODIFIED** `scripts/convert-htmx-react.mjs` — Alpine `x-data` lift rule:
  - Single-boolean (`x-data="{ open: false }"`) stays as local `useState`.
  - Multi-field or non-boolean (`x-data="{ count: 0, items: [] }"`) lifts to a zustand+immer store + a hook that selects from it.
- **ADDED** `references/scaffolds/eslint-architecture.config.mjs` — copy-paste-ready flat ESLint config snippet documenting the architectural-rule overrides.
- **MODIFIED** `skills/scaffold-react-vite/SKILL.md` — adds an "Architectural baseline" section.

### Block B — Hybrid form-factor + PWA

- **ADDED** `references/scaffolds/responsive-architecture.md` — `useBreakpoint` + `useIsMobile` + `<ResponsiveShell>` + safe-area-inset contract.
- **MODIFIED** `tools/template-forge-rs/templates/vite-shell-css.html` — adds safe-area-inset CSS variables (`--safe-top`, `--safe-bottom`, etc.) and base mobile viewport rules.
- **ADDED** generated templates (emitted by the scaffolder into the scaffold target):
  - `src/shared/hooks/use-breakpoint.ts`
  - `src/shared/hooks/use-is-mobile.ts`
  - `src/app/responsive-shell.tsx`
- **MODIFIED** `scripts/scaffold-react-vite.sh` — installs `vite-plugin-pwa`; injects PWA config block into `vite.config.ts` with brand-resolved manifest fields; generates 192×192 + 512×512 PWA icon placeholders (SVG → PNG via existing `template-forge` machinery or hand-rolled).
- **ADDED** `tools/template-forge-rs/templates/pwa-icon.svg` — Minijinja-rendered SVG icon parameterized by brand TOML (ember color, "K" or first-letter wordmark).

### Block C — Tauri hybrid shell

- **ADDED** `scripts/scaffold-react-vite-tauri.sh` — wraps a scaffolded Vite project in Tauri 2; supports `--target desktop` (default) and `--target mobile` (adds iOS/Android init).
- **ADDED** `skills/scaffold-react-vite-tauri/SKILL.md` — frontmatter + procedure pointing at the script.
- **MODIFIED** `scripts/scaffold-react-vite.sh` — adds `--with-tauri-wrapper` flag chaining into the new Tauri script (alongside the existing `--with-axum-wrapper`).
- **MODIFIED** `.claude-plugin/plugin.json` — registers the new `scaffold-react-vite-tauri` skill.

## Impact

### Affected surfaces

- `scripts/`, `assets/templates/`, `references/scaffolds/`, `tools/template-forge-rs/templates/`, `skills/scaffold-react-vite{,-tauri}/`, `.claude-plugin/plugin.json`, `skills/convert-htmx-react/`

### Affected dependencies

New devDeps installed *by scaffolded projects* (not by artifact-refiner itself):

- `zustand` 5.x
- `immer` 11.x
- `vite-plugin-pwa` 1.x
- `@tauri-apps/cli` 2.x (devDep when `--with-tauri-wrapper`)
- `@tauri-apps/api` 2.x

artifact-refiner repo itself takes no new dependencies (scripts orchestrate shadcn/pnpm CLIs).

### Risk surface

- **High mitigation: retroactive correction** — block A changes scripts that already work. Smoke-test the convert→scaffold pipeline after block A to confirm no regression.
- **Medium**: Tauri 2 prerequisites (Rust toolchain present; Xcode for iOS; Android SDK for Android). Pre-flight check with clear install hints.
- **Low**: PWA manifest theme color must be a literal hex, but brand TOMLs may use OKLCH. Scaffolder reads the brand at scaffold-time and converts to hex via `culori` (already a devDep from phase-3).
- **Low**: ESLint architectural rules generate false-positives on unusual layouts. Config is starter, documented as customizable.

### Out of scope (deferred)

- iOS code signing / App Store submission (Tauri config provides hooks; user supplies credentials)
- Tauri plugin selection beyond defaults
- Multi-window Tauri configurations
- Migrating *existing* (already-scaffolded) projects to the new architecture
- AG-UI / A2UI / Flutter scaffolders (own phases)
- Tauri-specific UI shell (`tauri-plugin-shell` window controls, native menu bar) — defer to a polish phase

## Integration contract (preserved)

Every block remains backward-compatible with phase-2 inputs and phase-3 outputs:

- Scaffolder still accepts the same `--name --source --brand --target` interface.
- Converter still produces phase-2-scaffolder-ready output, just with zustand-backed stores when state is non-trivial.
- The axum wrapper from phase-2 still works on any scaffolded project regardless of whether the user added the Tauri wrapper.

The three wrapper flags can be combined or omitted independently:

```bash
bash scripts/scaffold-react-vite.sh --name foo --source x.tsx --brand knowme --target ./foo
bash scripts/scaffold-react-vite.sh ... --with-axum-wrapper        # + Rust axum server
bash scripts/scaffold-react-vite.sh ... --with-tauri-wrapper       # + Tauri hybrid shell
bash scripts/scaffold-react-vite.sh ... --with-axum-wrapper --with-tauri-wrapper  # both
```
