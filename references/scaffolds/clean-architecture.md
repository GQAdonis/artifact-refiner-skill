# Scaffold Convention — Feature-Based Clean Architecture

This is the directory and dependency convention all scaffolders in this skill pack produce. It is the contract every refined artifact lands into.

## Directory layout

```
src/
├── app/                            ◀── application shell
│   ├── app.tsx                     # root component
│   ├── providers.tsx               # theme, query client, etc.
│   └── router.tsx                  # placeholder; v1 has no routing wired
├── features/                       ◀── one folder per feature
│   └── <feature-name>/             # kebab-case
│       ├── components/
│       │   └── <component>.tsx     # kebab-case files; PascalCase components
│       ├── hooks/
│       │   └── use-<hook>.ts       # camelCase hook fn names, kebab-case files
│       ├── services/
│       │   └── <service>-service.ts
│       ├── types/
│       │   └── <name>.types.ts
│       └── index.ts                # public surface — re-exports only
├── shared/                         ◀── cross-feature primitives
│   ├── components/
│   │   └── ui/                     # shadcn-on-Base-UI components land here
│   ├── hooks/
│   ├── lib/
│   │   └── utils.ts                # `cn` helper, formatting utils
│   └── types/
├── index.css                       ◀── @import "tailwindcss" + brand tokens
└── main.tsx                        ◀── entry point — minimal
```

## Dependency rule (enforced by convention; lint optional)

```
shared/    →   (nothing)            shared cannot import from features or app
features/  →   shared/, app/        features can use shared + app, never other features
app/       →   shared/, features/   app composes features and shared
```

Violations:

- `features/auth/` imports from `features/billing/` → ❌ refactor: extract shared to `shared/`
- `shared/lib/cn.ts` imports from `features/dashboard/` → ❌ refactor: move logic to feature
- `app/providers.tsx` imports from `features/theme/` → ✅ allowed (app composes features)

## File naming

| Surface | Naming |
|---|---|
| File names | **kebab-case** always (`hero-section.tsx`, `use-toggle.ts`, `auth-service.ts`) |
| React component identifiers | **PascalCase** in source (`function HeroSection()`) |
| Hook function names | **camelCase** with `use*` prefix (`useToggle`) |
| Exported symbols (utils, types) | **camelCase** values, **PascalCase** types |
| Directory names | **kebab-case** |

The kebab-case rule applies to *files and directories*. It does NOT apply to identifiers inside files. See `kebab-case-rename.md` for the patcher details.

## Public surface via `index.ts`

Every feature exposes a `index.ts` that re-exports only the surface other code may consume:

```ts
// src/features/hero/index.ts
export { Hero } from "./components/hero";
export { useHeroState } from "./hooks/use-hero-state";
// internal sub-components, types, services NOT re-exported
```

Consumers import the feature, not its internals:

```ts
// ✅
import { Hero } from "@/features/hero";

// ❌
import { Hero } from "@/features/hero/components/hero";
```

## Path aliases (`tsconfig.json` + `components.json`)

```jsonc
{
  "compilerOptions": {
    "paths": {
      "@/app/*":      ["./src/app/*"],
      "@/features/*": ["./src/features/*"],
      "@/shared/*":   ["./src/shared/*"],
      "@/*":          ["./src/*"]
    }
  }
}
```

`components.json` aliases match:

```jsonc
{
  "aliases": {
    "components": "@/shared/components",
    "utils": "@/shared/lib/utils",
    "ui": "@/shared/components/ui",
    "lib": "@/shared/lib",
    "hooks": "@/shared/hooks"
  }
}
```

This makes `shadcn add <component>` land components in `src/shared/components/ui/`, not the default `src/components/ui/`.

## Why this layout

1. **Discoverable** — every concern has one home; `find . -name "use-*"` finds all hooks.
2. **Refactor-safe** — moving a feature is `mv src/features/<old> src/features/<new>` plus alias updates.
3. **AI-friendly** — agents (Claude Code, Cursor, etc.) can reason about feature boundaries without reading the whole tree.
4. **Reuses across scaffolders** — Tauri, Flutter, AG-UI scaffolders in later phases produce *the same* shape with platform-specific shells around `src/`.

## What this layout does NOT prescribe

- Routing library (React Router, TanStack Router, file-based, none) — feature index.ts can export route definitions if a router is added
- State management (Zustand, TanStack Query, Context, signals) — typically goes in `features/<f>/state/` or `features/<f>/store.ts` per feature
- Testing strategy (`*.test.tsx` next to source vs `__tests__/`) — convention left open; pick one and apply consistently per project
- CSS strategy beyond Tailwind v4 + brand-tokens — components may add CSS modules in their feature folder if desired

These are intentional non-decisions. The skeleton accommodates any of them.
