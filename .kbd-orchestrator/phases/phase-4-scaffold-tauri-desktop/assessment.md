# Phase Assessment: Tauri Hybrid Scaffold + Architectural Standardization

**Phase:** `phase-4-scaffold-tauri-desktop` (effectively `phase-4-scaffold-hybrid`)
**Project:** `artifact-refiner`
**Date:** 2026-05-20
**Author:** Claude Code (Opus 4.7, 1m context)
**Mode:** Assessment only — no implementation
**Sycophancy correction:** applied aggressively

---

## 1. Goal Restatement

The user directives expand phase-4 in three dimensions and add a retroactive correction to phase-2:

### 1a. Forward goals (new for phase-4)

1. **Tauri 2 wrapper** added to scaffolded Vite/React projects. Any Vite/React app can be promoted to a Tauri app.
2. **Desktop + mobile form factors simultaneously**. Resizing to mobile viewport triggers a PWA-mobile UX. Tauri 2 mobile (iOS + Android) targets are also addressable from the same source.
3. **PWA behavior** for the web target — manifest, service worker, install prompt, offline cache, viewport meta.

### 1b. Retroactive corrections (apply to phase-2 + phase-3 outputs)

4. **Standardize on zustand + immer** for state management in all React/Vite code (web AND Tauri).
5. **Strict architectural rules**, applied without exception:
   - Components → hooks only (never direct to stores)
   - Hooks → stores only (never to APIs or network services)
   - Stores → APIs and external services; stores own all I/O
   - Stores own all realtime subscriptions (Supabase realtime, WebSocket, SSE, etc.); subscription coordination lives in stores
6. **TSX over JSX**, always. No `.jsx` files.

The retroactive items mean **phase-2's scaffolder must be updated** (sample-app.tsx, the patcher, the SKILL.md) and **phase-3's converter must be updated** (Alpine `x-data` → zustand store, not local `useState`). The current phase-2 and phase-3 outputs use plain `useState` which doesn't violate the rules per se (local UI state isn't a "store") but does NOT enforce the contract the user wants.

---

## 2. Sycophancy-Corrected Assessment

The user directives are correct in intent but inflate the phase if executed naively. Five corrections.

### Correction 1 — Rename the phase

The phase is no longer "tauri-desktop". Tauri 2 covers desktop + mobile natively. With PWA support added, the same source runs in:

- Web browser (desktop + mobile PWA)
- Tauri desktop (macOS, Windows, Linux)
- Tauri mobile (iOS, Android)

**Corrected name:** `phase-4-scaffold-hybrid`. The original `phase-5-scaffold-tauri-mobile` collapses into this phase because Tauri 2 doesn't separate desktop from mobile in the scaffold — they're build targets of the same project.

### Correction 2 — Architectural-rules enforcement is a separate concern from Tauri scaffolding

Mixing the architecture standardization with the Tauri shell scaffolding in one phase produces a scope monster. They share the same React/Vite substrate but address different layers.

**Corrected scoping:** split into **two sub-phases that execute together**:

- **phase-4a-architecture-standardization** — zustand+immer added to phase-2 scaffolder. Sample app rewritten to demonstrate stores/hooks/components separation. Convert-htmx-react Alpine `x-data` lift now emits a zustand store, not local `useState`. Retroactive — touches phase-2 and phase-3 outputs.
- **phase-4b-hybrid-shell** — Tauri 2 wrapper + PWA + responsive layout primitives. Adds new substrate. Forward-only.

Both ship in this phase; the split is for clarity, not separate executions.

### Correction 3 — "Mobile form factor" needs concrete responsive primitives, not just CSS @media

Telling the scaffolder "be responsive" is wish-list grade. **Concrete primitives:**

- `useBreakpoint` hook (in `src/shared/hooks/`) — reactive viewport classification (`mobile` / `tablet` / `desktop`)
- `useIsMobile()` convenience wrapping the above
- Tailwind v4 breakpoint preset matching the hook
- A `<ResponsiveShell>` component in `src/app/` that selects desktop layout vs mobile bottom-nav layout based on `useBreakpoint`
- Safe-area-inset CSS variables (`env(safe-area-inset-*)`) wired into `:root` for notch/home-bar clearance on Tauri mobile and PWA installs

### Correction 4 — Tauri + PWA in the same project requires deliberate config

Both can coexist but they overlap (service worker vs Tauri WebView, manifest vs Tauri config). **Concrete decisions:**

- **PWA assets are built into `dist/`** by `vite-plugin-pwa`. They serve correctly when deployed to web.
- **Tauri's WebView ignores the service worker** at runtime (Tauri bundles its own asset serving). The PWA manifest is harmless inside Tauri but unused.
- **No conditional builds** — one source tree, one `vite build`, three deployment targets (web, Tauri desktop, Tauri mobile).
- **Capacitor / Cordova are explicitly rejected.** Tauri 2 is the native shell. PWA is the web fallback.

### Correction 5 — Zustand+immer is correct; the rule set needs subtle interpretation

The user's rules are sound, but applying them robotically would forbid local UI state (toggle visibility, form input drafts, tab selections, etc.). The reasonable interpretation:

- **Stores** = zustand stores with immer middleware. Used for: anything shared across components, anything with side effects (I/O, realtime), anything persisted.
- **Local component state** = `useState` for ephemeral, single-component-scoped state (open/closed, hover, focus, draft form values before submit). This is NOT a "store" and is NOT forbidden.
- **The hook layer** is the only allowed bridge between components and stores. Even single-store consumers go through a hook (`useUserProfile()` selects from `useUserStore` and exposes a tailored slice).
- **Stores never import React.** Stores are framework-agnostic state containers; hooks are the React adapter.
- **Realtime subscription registration** happens in store init (`create((set) => { subscribeToSupabase(...); return { ... } })`) or in an explicit `initRealtime()` action invoked once from `<Providers>`.

**Corrected goal:** ship a `references/scaffolds/state-architecture.md` documenting these rules + boundaries + lint examples. The patcher enforces creation of `src/features/<f>/stores/` and `src/features/<f>/hooks/`; lint rules enforce the no-cross-layer-import contract.

---

## 3. Current state inventory

| Surface | Status |
|---|---|
| `scripts/scaffold-react-vite.sh` | exists, no zustand setup, no PWA, no Tauri |
| `scripts/scaffold-react-vite-axum.sh` | exists, web-only single-binary |
| `assets/templates/sample-app.tsx` | uses local `useState`, no store |
| `scripts/convert-htmx-react.mjs` | lifts Alpine `x-data` to local `useState` hook |
| `references/scaffolds/clean-architecture.md` | exists; has `src/features/<f>/` shape but no stores layer |
| `references/scaffolds/state-architecture.md` | **does not exist** |
| `references/scaffolds/responsive-architecture.md` | does not exist |
| `scripts/scaffold-react-vite-tauri.sh` | does not exist |
| `useBreakpoint` / `useIsMobile` hook templates | do not exist |
| `vite-plugin-pwa` integration | not wired |
| Tauri 2 prerequisites check | not implemented |

---

## 4. Scope of This Phase

### In scope

**Architectural standardization (retroactive):**

1. **`references/scaffolds/state-architecture.md`** — the zustand+immer contract, dependency rule, store/hook/component separation, realtime ownership.
2. **`assets/templates/sample-app.tsx` rewritten** — demonstrates a real zustand+immer store, a hook that consumes it, a component that uses only the hook. The smoke target now exercises the architecture.
3. **`scripts/scaffold-react-vite.sh` patcher updated** — installs `zustand` + `immer` automatically; creates `src/features/<f>/stores/` directory; generates a placeholder store template; updates the auto-detection to route `useXxxStore` exports to `stores/`, hook exports to `hooks/`, components to `components/`.
4. **`scripts/convert-htmx-react.mjs` updated** — when Alpine `x-data` has any non-trivial state (anything beyond a single boolean toggle), lift to a zustand store, NOT a local `useState` hook. Single-boolean state can stay as local `useState` (matches the "ephemeral component-scoped" rule).
5. **`skills/scaffold-react-vite/SKILL.md`** — updated to document the new architectural baseline.

**Hybrid form-factor + PWA (forward):**

6. **Responsive primitives**: `useBreakpoint`, `useIsMobile` hook templates added to `src/shared/hooks/` during scaffolding.
7. **`<ResponsiveShell>` component template** in `src/app/responsive-shell.tsx` — switches desktop layout vs mobile bottom-nav.
8. **Tailwind v4 breakpoint preset** consistent with the hook.
9. **Safe-area-inset CSS variables** wired into `vite-shell-css.html` template.
10. **`vite-plugin-pwa` integration** — added to the scaffolder; produces `manifest.webmanifest`, service worker, offline cache.
11. **`references/scaffolds/responsive-architecture.md`** — the hybrid layout contract.

**Tauri shell (forward):**

12. **`scripts/scaffold-react-vite-tauri.sh`** — wraps a scaffolded Vite project in Tauri 2:
    - `src-tauri/` Rust project with desktop + mobile-target Cargo config
    - `tauri.conf.json` for desktop bundles + iOS/Android
    - `pnpm tauri dev` (desktop) and `pnpm tauri ios/android dev` flows documented
13. **`skills/scaffold-react-vite-tauri/SKILL.md`** — new skill (sibling to scaffold-react-vite).
14. **Plugin manifest update** — register new Tauri skill.

### Out of scope (deferred)

- iOS/Android signing / store submission (manual user step; doc reference only)
- Tauri plugin selection (storage, notifications, etc.) beyond the defaults
- Native widget integration (`tauri-plugin-widgets`)
- Multi-window Tauri configs
- Hot-reload between Tauri shell and Vite dev server beyond what `tauri dev` provides
- AG-UI / A2UI / Flutter — own phases
- Migrating *existing* (already-scaffolded) projects to the new architecture — phase-4 covers new scaffolds; existing scaffolds are a separate migration phase if/when needed

---

## 5. Architecture choices

### A. Zustand + immer pattern

Store shape:

```ts
// src/features/<feature>/stores/<feature>-store.ts
import { create } from "zustand";
import { immer } from "zustand/middleware/immer";

interface FeatureState {
  // state
  items: Item[];
  loading: boolean;

  // actions (stores own I/O)
  fetchItems: () => Promise<void>;
  addItem: (item: Item) => void;

  // realtime
  initRealtime: () => () => void;  // returns unsubscribe
}

export const useFeatureStore = create<FeatureState>()(
  immer((set, get) => ({
    items: [],
    loading: false,

    fetchItems: async () => {
      set((s) => { s.loading = true; });
      const res = await fetch("/api/items");
      const items = await res.json();
      set((s) => { s.items = items; s.loading = false; });
    },

    addItem: (item) => set((s) => { s.items.push(item); }),

    initRealtime: () => {
      const ws = new WebSocket("wss://...");
      ws.addEventListener("message", (e) => {
        const item = JSON.parse(e.data);
        set((s) => { s.items.push(item); });
      });
      return () => ws.close();
    },
  })),
);
```

Hook layer:

```ts
// src/features/<feature>/hooks/use-items.ts
import { useFeatureStore } from "../stores/feature-store";
import { useEffect } from "react";

export function useItems() {
  const items = useFeatureStore((s) => s.items);
  const loading = useFeatureStore((s) => s.loading);
  const fetchItems = useFeatureStore((s) => s.fetchItems);

  useEffect(() => {
    fetchItems();
  }, [fetchItems]);

  return { items, loading };
}
```

Component layer:

```tsx
// src/features/<feature>/components/items-list.tsx
import { useItems } from "../hooks/use-items";

export function ItemsList() {
  const { items, loading } = useItems();
  if (loading) return <Spinner />;
  return <ul>{items.map((i) => <li key={i.id}>{i.name}</li>)}</ul>;
}
```

The component never imports `useFeatureStore` directly. The hook never imports `fetch`. The store owns I/O and the boundary.

### B. Responsive primitives

```ts
// src/shared/hooks/use-breakpoint.ts
import { useEffect, useState } from "react";

export type Breakpoint = "mobile" | "tablet" | "desktop";

const BREAKPOINTS = { mobile: 0, tablet: 768, desktop: 1024 } as const;

function classify(width: number): Breakpoint {
  if (width >= BREAKPOINTS.desktop) return "desktop";
  if (width >= BREAKPOINTS.tablet) return "tablet";
  return "mobile";
}

export function useBreakpoint(): Breakpoint {
  const [bp, setBp] = useState<Breakpoint>(() =>
    typeof window === "undefined" ? "desktop" : classify(window.innerWidth)
  );
  useEffect(() => {
    const onResize = () => setBp(classify(window.innerWidth));
    window.addEventListener("resize", onResize, { passive: true });
    return () => window.removeEventListener("resize", onResize);
  }, []);
  return bp;
}

export function useIsMobile(): boolean {
  return useBreakpoint() === "mobile";
}
```

### C. Tauri 2 directory shape

```
<target>/
├── src/                          ◀ React/Vite/Tailwind (unchanged)
├── public/
├── src-tauri/                    ◀ new
│   ├── Cargo.toml
│   ├── tauri.conf.json
│   ├── capabilities/
│   ├── icons/
│   └── src/
│       ├── main.rs
│       └── lib.rs
├── server/                       ◀ optional (from phase-2 axum wrapper)
└── package.json                  ◀ `tauri` scripts added
```

**Tauri config decisions:**

- `bundle.targets`: `["app", "dmg", "deb", "rpm", "appimage", "msi", "nsis"]` (desktop) + `["aab", "apk", "ipa"]` (mobile, opt-in via subcommand)
- `app.windows[0].width = 1200`, `height = 800` for desktop; mobile inherits viewport
- `app.security.csp` set to a strict policy with `connect-src` for the user's API
- `tauri.conf.json` `app.withGlobalTauri = false` (use `@tauri-apps/api` imports)
- `frontendDist = "../dist"` so `tauri dev` and `tauri build` see Vite output
- `devUrl = "http://localhost:5173"` for dev mode

### D. PWA wiring

`vite-plugin-pwa` configured in `vite.config.ts`:

```ts
import { VitePWA } from "vite-plugin-pwa";

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
    VitePWA({
      registerType: "autoUpdate",
      manifest: {
        name: "<feature-name>",
        short_name: "<feature-name>",
        theme_color: "var(--color-ember)",  // resolved at build
        background_color: "var(--color-bg)",
        display: "standalone",
        start_url: "/",
        icons: [{ src: "/icons/icon-192.png", sizes: "192x192", type: "image/png" }],
      },
      workbox: { globPatterns: ["**/*.{js,css,html,svg,png,ico,woff2}"] },
    }),
  ],
});
```

Theme/background colors are scaffolder-injected from the brand TOML at scaffold time (not at build time — vite-plugin-pwa needs literal values in its config).

### E. Conditional Tauri detection at runtime

For the rare case the React code wants to know "am I in Tauri":

```ts
// src/shared/lib/runtime.ts
export function isTauri(): boolean {
  return typeof window !== "undefined" && "__TAURI_INTERNALS__" in window;
}
```

Used sparingly. Most code should be runtime-agnostic.

### F. Lint enforcement (optional but recommended)

ESLint rules to enforce the architecture:

```js
// eslint.config.js
{
  rules: {
    "no-restricted-imports": ["error", {
      patterns: [
        { group: ["**/stores/*"], message: "Components/hooks may not import stores directly. Use a hook." },
        // Within hooks/ only, the restriction is relaxed
      ],
    }],
  },
  overrides: [
    { files: ["**/hooks/**"], rules: { "no-restricted-imports": ["error", { patterns: [
      { group: ["**/services/*", "axios", "ky"], message: "Hooks may not perform I/O. Move to a store." },
    ]}] } },
    { files: ["**/components/**"], rules: { "no-restricted-imports": ["error", { patterns: [
      { group: ["**/stores/*"], message: "Components must consume via hooks." },
      { group: ["**/services/*"], message: "Components must not import services directly." },
    ]}] } },
  ],
}
```

Phase-4 generates this config. Future violations fail the build.

---

## 6. Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Tauri 2 CLI prerequisites missing on user's machine (Rust + platform SDKs) | High | Medium | Pre-flight check with clear install hints (rustup, Xcode for iOS, Android Studio for Android) |
| iOS code signing requires Apple Developer account | High | Low | Document; phase generates the project, user supplies credentials |
| `vite-plugin-pwa` interacts oddly with Tauri's WebView | Medium | Low | Tauri ignores SW; manifest is harmless. Verify on smoke |
| Brand theme color must be a literal in PWA manifest, but brand TOML supplies a CSS var | Medium | Low | Scaffolder reads the brand TOML at scaffold-time, injects the literal value into `vite.config.ts`. Re-running on a brand swap requires regen |
| Existing scaffolded projects (from phase-2) won't have the new architecture | High | Low | Out of scope; phase-4 only covers new scaffolds. Existing scaffolds keep working |
| Convert-htmx-react Alpine→zustand path complicates simple toggles | Medium | Low | Threshold rule: single-boolean state stays local; anything more lifts to a store |
| ESLint architectural rules false-positive on legit cross-cuts | Medium | Low | Config is starter; users can customize. Document override path |
| Mobile bottom-nav layout clashes with Tauri desktop window chrome | Low | Low | `<ResponsiveShell>` uses `useBreakpoint`, not `useIsTauri` — purely viewport-based. Tauri windows resize freely |

No high-severity unmitigated risk.

---

## 7. Acceptance criteria

1. `references/scaffolds/state-architecture.md` exists; documents zustand+immer + dependency rule.
2. `references/scaffolds/responsive-architecture.md` exists; documents `useBreakpoint` + `<ResponsiveShell>` + safe-area pattern.
3. `assets/templates/sample-app.tsx` rewritten — uses a zustand+immer store via a hook (the smoke target exercises the architecture).
4. `scripts/scaffold-react-vite.sh` installs `zustand` + `immer`, creates `stores/` directory, generates `useBreakpoint` + `useIsMobile` + `<ResponsiveShell>` templates.
5. End-to-end smoke: re-scaffold sample-app → `pnpm build` succeeds with the new architecture in place.
6. `scripts/convert-htmx-react.mjs` updated — Alpine `x-data` with >1 field or non-boolean field lifts to a zustand store + a hook consuming it; single-boolean stays local.
7. `vite-plugin-pwa` configured by the scaffolder; build produces `manifest.webmanifest` + service worker.
8. `scripts/scaffold-react-vite-tauri.sh` wraps a scaffolded Vite project in Tauri 2; `pnpm tauri build --target desktop` produces a desktop binary.
9. Tauri smoke: `cd <target> && pnpm tauri info` succeeds (proves Tauri config is valid).
10. `skills/scaffold-react-vite-tauri/SKILL.md` exists with valid frontmatter; registered in `plugin.json`.
11. ESLint config generated; `pnpm lint` produces architectural-rule errors on intentional violations.

11 gates. Some require platform SDKs (Tauri iOS/Android need Xcode/Android Studio) — those gates degrade gracefully to "Tauri config is valid" rather than "full mobile build" if SDKs absent.

---

## 8. Phase decomposition

### Block A — Architecture standardization (retroactive)

| # | Sub-change | Effort |
|---|---|---|
| A1 | Author `references/scaffolds/state-architecture.md` | small |
| A2 | Rewrite `assets/templates/sample-app.tsx` with zustand+immer store + hook + component pattern | small |
| A3 | Update `scripts/scaffold-react-vite.sh` to install `zustand` + `immer`, create `stores/` dir, generate `useBreakpoint`+`useIsMobile`+`<ResponsiveShell>` templates | medium |
| A4 | Update `scripts/convert-htmx-react.mjs` to lift Alpine `x-data` to zustand store for non-trivial state | medium |
| A5 | Update `skills/scaffold-react-vite/SKILL.md` to document the architectural baseline | small |
| A6 | Generate ESLint config with architectural rules | small |

### Block B — Hybrid form-factor + PWA

| # | Sub-change | Effort |
|---|---|---|
| B1 | Author `references/scaffolds/responsive-architecture.md` | small |
| B2 | Add safe-area-inset block to `vite-shell-css.html` template | small |
| B3 | Wire `vite-plugin-pwa` in scaffolder; inject brand-resolved manifest at scaffold time | medium |
| B4 | Smoke: re-scaffold sample-app → verify `dist/manifest.webmanifest` + `dist/sw.js` present | small |

### Block C — Tauri shell

| # | Sub-change | Effort |
|---|---|---|
| C1 | Author `scripts/scaffold-react-vite-tauri.sh` | medium-large |
| C2 | Author `skills/scaffold-react-vite-tauri/SKILL.md` | small |
| C3 | Register in `plugin.json` | trivial |
| C4 | Smoke: `pnpm tauri info` succeeds; if Rust toolchain + macOS frontmost, `pnpm tauri build` attempt | medium |

### Block D — Acceptance sweep

| # | Sub-change | Effort |
|---|---|---|
| D1 | Run all 11 acceptance gates | small |

Total: one focused session if Tauri prerequisites are present; two if Tauri config debugging is needed.

---

## 9. Open questions

1. **Tauri 2 vs Tauri 1?** Recommendation: Tauri 2 (current stable, mobile support). Tauri 1 is legacy.
2. **PWA service worker strategy:** `registerType: "autoUpdate"` (most user-friendly) or `"prompt"` (user-controlled)? Recommendation: `autoUpdate`. Power users override.
3. **Where does state-architecture lint config live:** `eslint.config.js` (modern flat config) or `.eslintrc.json` (legacy)? Recommendation: flat `eslint.config.js` per ESLint 9+.
4. **Should Alpine `x-data` single-boolean threshold actually be the line?** Recommendation: yes for v1. Refine if real-world inputs surface ambiguity.
5. **Should the patcher create a default `useAppStore` global store** for app-level concerns (theme, auth, locale), or leave it to users? Recommendation: yes — create an empty `src/app/stores/app-store.ts` with theme slice as a starter; user expands.
6. **PWA icons:** scaffolder generates placeholders or user supplies? Recommendation: generate 192/512 placeholders from the brand TOML (use `template-forge` with a new SVG template); user replaces.
7. **Should Tauri scaffolder support being chained from `scaffold-react-vite.sh --with-tauri-wrapper`** like the axum case, or only as a separate post-step? Recommendation: both — `--with-tauri-wrapper` chains; standalone usage also works.

---

## 10. Honest verdict

This phase is materially larger than phase-2 or phase-3, because it does three things at once:

1. **Retroactive correction** to phase-2 and phase-3 outputs (architecture standardization)
2. **Net-new substrate** (responsive primitives + PWA wiring)
3. **Net-new scaffolder target** (Tauri 2 hybrid)

The temptation is to scope-cut by deferring one of these. **But the user's directive is explicit that the architecture rules apply retroactively** — phase-4 *must* update phase-2 outputs. So the scope is what it is.

Realistic execution estimate: **two focused sessions**. Block A is invasive (touches three existing scripts + one converter + a skill). Block C is genuinely new code. Blocks B and D are small.

**Recommendation:** proceed to `/kbd-plan phase-4-scaffold-tauri-desktop`. Treat the architecture standardization as the first work item — without it, phases B and C produce code that violates the architecture by inheritance.

---

## 11. Assessment metadata

```yaml
assessment_complete: true
phase: phase-4-scaffold-tauri-desktop
effective_name: phase-4-scaffold-hybrid
user_directives_applied:
  - tauri_2_wrapper
  - hybrid_desktop_mobile_form_factor
  - pwa_behavior_on_web
  - zustand_immer_state_management
  - strict_component_hook_store_architecture
  - tsx_over_jsx
  - retroactive_correction_to_phase_2_and_phase_3
scope_discipline_applied:
  - Three sub-phases (A: architecture, B: hybrid, C: Tauri) shipped together but logically separate
  - Defer iOS signing, Tauri plugins beyond defaults, multi-window configs, existing-project migration
prerequisites_met:
  phase-2-scaffold-react-vite: complete (target of retroactive correction)
  phase-3-conversion-layer: complete (target of retroactive correction)
  phase-rust-workspace-bootstrap: complete (template-forge reused for PWA icons + brand-CSS)
risk_summary: no high-severity unmitigated risks
recommendation: |
  Proceed to /kbd-plan phase-4-scaffold-tauri-desktop. Expected two focused
  sessions. Execute Block A first (architecture standardization) so blocks B
  and C build on the corrected substrate.
next_command: /kbd-plan phase-4-scaffold-tauri-desktop
```

Completed kbd-assess — phase-4-scaffold-tauri-desktop
