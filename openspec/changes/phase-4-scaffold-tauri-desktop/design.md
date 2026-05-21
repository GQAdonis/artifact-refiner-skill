# Design: phase-4-scaffold-tauri-desktop (hybrid)

## Key decisions baked in

### Decision 1 — Three blocks ship together, but block A executes first

Block A (architecture standardization) is retroactive to phase-2/phase-3. If B and C execute on the pre-standardized substrate, they inherit the gap (local `useState` everywhere, no store layer). Strict ordering: A completes, smoke passes, **then** B and C.

### Decision 2 — `useState` stays legal for ephemeral local state

The user's architectural rules say "components → hooks → stores". Robotically applied this forbids local `useState` for things like "is dropdown open" or "form draft". Real-world React with that rule would force every UI toggle into a global store. Wrong.

**Threshold rule** documented in `state-architecture.md`:

| State shape | Mechanism |
|---|---|
| Single boolean, single component | `useState` is fine |
| Form drafts before submit | `useState` |
| Shared across 2+ components | zustand store |
| Triggers I/O or realtime | zustand store (always) |
| Persisted to disk / localStorage | zustand store with persist middleware |

This isn't a softening of the rule; it's the rule applied with judgment. Stores exist for *coordination*, not for every variable.

### Decision 3 — Stores are framework-agnostic

Zustand stores in `**/stores/**` cannot `import React from "react"`. They're plain TypeScript with framework-independent shape. The React adapter lives in hooks. This is enforceable via ESLint `no-restricted-imports`.

Rationale: when phase-6 (Flutter) or phase-7 (AG-UI) lands, the stores conceptually translate to Riverpod providers or AG-UI state contracts. If they're React-coupled, that translation costs more.

### Decision 4 — Tauri 2 desktop + mobile from same source

Tauri 2 is one project that builds to multiple targets:

- `pnpm tauri build` → desktop (current host platform)
- `pnpm tauri build --target x86_64-pc-windows-msvc` → Windows from non-Windows host (when toolchain available)
- `pnpm tauri ios build` → iOS app (requires macOS + Xcode)
- `pnpm tauri android build` → Android app (requires Android SDK)

The `--mobile` flag in `scaffold-react-vite-tauri.sh` controls whether `tauri ios init` and `tauri android init` are run, which adds the iOS/Android-specific scaffolding to `src-tauri/`. Without it, the project is desktop-only.

### Decision 5 — PWA service worker coexists with Tauri without conditional builds

`vite-plugin-pwa` generates `manifest.webmanifest`, `sw.js`, and `registerSW.js` into `dist/`. They serve correctly when deployed to a static host. Inside Tauri's WebView, the service worker registration runs but is harmless (Tauri serves assets via its own protocol; SW intercepts won't matter). Tauri ignores the manifest.

The user gets the right behavior on each platform without conditional builds, because each platform reads only what it cares about.

### Decision 6 — Responsive primitives are runtime-viewport-based, not Tauri-detection-based

`useBreakpoint()` reads `window.innerWidth` and emits `mobile` / `tablet` / `desktop`. `<ResponsiveShell>` reads `useBreakpoint()` and picks a layout. **Neither calls `isTauri()`.**

This is intentional: a Tauri desktop window resized small should switch to the mobile layout. A PWA on a tablet should pick the tablet layout. The runtime shell (web vs Tauri vs PWA) is independent of the form factor (mobile vs tablet vs desktop).

`isTauri()` exists in `src/shared/lib/runtime.ts` for the rare case code legitimately needs to know (e.g., showing a native "Quit" menu item). Used sparingly.

### Decision 7 — PWA theme color must be a literal hex

`vite-plugin-pwa`'s manifest config takes literal values. The brand TOML's `colors.dark.ember` is the source. If it's already hex (`#E04E28`), inject directly. If it's OKLCH or another color space, convert to hex via `culori` at scaffold time.

The scaffolder reads the brand TOML once at scaffold time. Subsequent brand swaps require regenerating both the CSS (current rebrand-artifact behavior) and the `vite.config.ts` manifest block (new). `rebrand-artifact.mjs` is extended in this phase to also patch `vite.config.ts` if it exists in the target.

### Decision 8 — ESLint enforcement is starter, not gospel

The architectural-rule ESLint config in scaffolded projects is a *starting point*. Users can override per project — that's normal ESLint usage. We document the override path; we don't try to lock it down.

False-positive likelihood: medium. Real-world projects have legitimate cross-cuts (a feature exposing a hook to another feature's components; a shared store consumed across features). The lint rules catch the most common violations and the user customizes the rest.

### Decision 9 — Convert-htmx-react Alpine→store rule has a single threshold

Single-boolean: `useState`. Anything else: zustand store. No middle ground in v1.

The threshold could be more nuanced (e.g., "single-number that's used in only one component is also local"). v1 keeps it simple. Refine when real-world inputs reveal ambiguity.

### Decision 10 — Realtime registration in store init

```ts
export const useFeedStore = create<FeedState>()(
  immer((set) => ({
    items: [],
    initRealtime: () => {
      const sub = supabase.channel("feed").on("postgres_changes", { ... }, (payload) => {
        set((s) => { s.items.push(payload.new); });
      }).subscribe();
      return () => supabase.removeChannel(sub);
    },
  })),
);
```

Apps invoke `useFeedStore.getState().initRealtime()` once from a `<Providers>` component at mount. The returned unsubscribe is captured for cleanup.

`<Providers>` (in `src/app/providers.tsx`) is the single place realtime is wired. **Not in components, not in hooks.**

### Decision 11 — Reuse phase-2 + phase-3 + phase-rust-workspace substrate

This phase adds substrate, doesn't replace. The reuse map:

| Reused | Source phase | This phase's use |
|---|---|---|
| `scripts/lib/kebab-case.sh` | phase-2 | Tauri scaffolder uses for crate naming |
| `tools/template-forge-rs/templates/vite-shell-css.html` | phase-2 (extended in this phase) | Brand CSS + safe-area vars |
| `scripts/scaffold-react-vite.sh` | phase-2 (modified) | Foundation; A/B blocks extend it |
| `scripts/scaffold-react-vite-axum.sh` | phase-2 | Still works alongside Tauri wrapper |
| `scripts/convert-htmx-react.mjs` | phase-3 (modified) | Alpine→store threshold update |
| `scripts/rebrand-artifact.mjs` | phase-3 (modified in C) | Patches vite.config.ts manifest too |
| `assets/library/brands/*.toml` | phase-2/3 | Source for PWA manifest colors |

## Non-decisions (explicitly out of scope)

- Tauri plugin selection (defer until concrete need)
- iOS/Android signing automation (defer to deployment phase)
- Multi-window Tauri configs
- Existing-project migration to new architecture
- Tauri-specific native menu bar / window-controls polish
- State persistence beyond zustand's `persist` middleware default (defer for advanced features)
