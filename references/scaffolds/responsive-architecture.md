# Scaffold Convention — Responsive (Hybrid Form-Factor) Architecture

Every scaffolded React/Vite project supports **desktop + mobile form factors
simultaneously**. Resizing the viewport switches layout — the same source code
serves:

- Web browser (desktop + mobile PWA install)
- Tauri desktop window (resizable; mobile layout on narrow widths)
- Tauri mobile (iOS + Android, fixed viewport)

Form-factor detection is **viewport-based**, never runtime-based. A Tauri
desktop window dragged narrow switches to mobile layout. A PWA on a tablet
picks the tablet layout. The runtime shell (web / Tauri / PWA install) is
independent of the form factor.

## Breakpoint policy

| Class | Viewport width | Typical surface |
|---|---|---|
| `mobile` | < 768px | Phone, narrow Tauri window |
| `tablet` | 768–1023px | Tablet portrait, mid Tauri window |
| `desktop` | ≥ 1024px | Desktop browser, wide Tauri window |

These values match Tailwind v4's default `md` and `lg` breakpoints. The scaffolder's
brand CSS template (`vite-shell-css.html`) does NOT hardcode these breakpoints;
they live in the `useBreakpoint` hook.

## `useBreakpoint` hook

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
```

SSR-safe (returns `"desktop"` when `window` is undefined; corrects on hydration).

## `useIsMobile` convenience

```ts
import { useBreakpoint } from "./use-breakpoint";

export function useIsMobile(): boolean {
  return useBreakpoint() === "mobile";
}
```

## `<ResponsiveShell>` pattern

The scaffolder emits `src/app/responsive-shell.tsx`:

```tsx
import { useBreakpoint } from "@/shared/hooks/use-breakpoint";

export function ResponsiveShell({ children }: { children: React.ReactNode }) {
  const bp = useBreakpoint();
  const isMobile = bp === "mobile";

  if (isMobile) {
    return (
      <div style={{
        minHeight: "100dvh",
        display: "grid",
        gridTemplateRows: "1fr auto",
        paddingTop: "var(--safe-top, 0)",
      }}>
        <main style={{ overflowY: "auto" }}>{children}</main>
        <nav style={{
          padding: "0.5rem",
          background: "var(--color-surface)",
          borderTop: "1px solid var(--color-border)",
          paddingBottom: "calc(var(--safe-bottom, 0) + 0.5rem)",
        }}>
          {/* bottom nav */}
        </nav>
      </div>
    );
  }

  return (
    <div style={{
      minHeight: "100dvh",
      display: "grid",
      gridTemplateColumns: "auto 1fr",
    }}>
      <aside style={{
        width: "220px",
        background: "var(--color-surface)",
        borderRight: "1px solid var(--color-border)",
      }}>
        {/* sidebar */}
      </aside>
      <main style={{ overflowY: "auto" }}>{children}</main>
    </div>
  );
}
```

The starter is a placeholder; the user fills in nav items and content. The
structure (mobile bottom-nav vs desktop sidebar) is the convention.

## Safe-area-inset CSS variables

For notch / home-bar / status-bar clearance on Tauri mobile and PWA-installed
web, the brand CSS template adds:

```css
:root {
  --safe-top:    env(safe-area-inset-top, 0);
  --safe-bottom: env(safe-area-inset-bottom, 0);
  --safe-left:   env(safe-area-inset-left, 0);
  --safe-right:  env(safe-area-inset-right, 0);
}

/* Mobile-only padding (the rest of the layout doesn't need it) */
@media (max-width: 767px) {
  html { padding-top: var(--safe-top); }
}
```

`<ResponsiveShell>` consumes `var(--safe-top)` and `var(--safe-bottom)` in its
mobile layout. Desktop ignores them (the env values fall back to 0).

## Tauri-vs-web detection — used sparingly

For the rare case the code legitimately needs to know "am I in Tauri":

```ts
// src/shared/lib/runtime.ts
export function isTauri(): boolean {
  return typeof window !== "undefined" && "__TAURI_INTERNALS__" in window;
}
```

Use only when the answer changes behavior fundamentally:

- ✅ Show a native "Quit" menu item only inside Tauri
- ✅ Skip PWA install prompt inside Tauri (it'd be misleading)
- ❌ Choose mobile vs desktop layout (use `useBreakpoint` instead)
- ❌ Skip service worker registration (Tauri's WebView already ignores it)

## Form-factor invariants

These hold across all three shells (web/Tauri-desktop/Tauri-mobile):

1. Same source files, same `pnpm build`, three deploy targets
2. Same brand tokens via `var(--color-*)` and `var(--font-*)`
3. Same `<ResponsiveShell>` layout switching
4. Same `useBreakpoint` semantics
5. Same shadcn-on-Base-UI components

Per-shell differences live only in:

- `index.html` viewport meta (set by `vite-plugin-pwa` automatically)
- `manifest.webmanifest` (web/PWA only, ignored by Tauri)
- `src-tauri/tauri.conf.json` (Tauri only)
- Safe-area-inset values (`env()` resolves per platform; CSS handles it)

## Composability with state architecture

Responsive primitives sit at the **hook layer** of the state architecture:

- `useBreakpoint` is a hook (lives in `src/shared/hooks/`)
- `<ResponsiveShell>` is a component (lives in `src/app/`)
- Neither imports a store
- Neither performs I/O

Components consume `useBreakpoint` directly — it's a hook, layering rule preserved.
