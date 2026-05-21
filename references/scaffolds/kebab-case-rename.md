# Scaffold Convention — Kebab-Case Rename Heuristic

The patcher renames files and imports from the source TSX into kebab-case as it lands them into the clean-architecture layout. This doc specifies what gets renamed and what doesn't.

## What gets renamed

### File names

```
HeroSection.tsx        → hero-section.tsx
useDarkMode.ts         → use-dark-mode.ts
AuthService.ts         → auth-service.ts
UserProfile.types.ts   → user-profile.types.ts
```

### Directory names

```
src/Components/         → src/components/
src/UserAuth/           → src/user-auth/
```

### Import paths inside files

When a file is renamed `HeroSection.tsx → hero-section.tsx`, every import referencing it gets rewritten:

```ts
// before
import HeroSection from "@/components/HeroSection";

// after
import { HeroSection } from "@/features/hero/components/hero-section";
```

The patcher updates **path strings** in `import`, `export from`, and `require()` calls.

## What does NOT get renamed

### React component identifiers

```tsx
// ✅ Component identifier stays PascalCase — only the file name changes
// File: hero-section.tsx
export function HeroSection() {
  return <div />;
}
```

JSX usage stays as-is:

```tsx
<HeroSection />  // ✅ PascalCase in JSX
```

### Hook function names

```ts
// File: use-dark-mode.ts
export function useDarkMode() { ... }  // ✅ camelCase + use* prefix
```

### Exported symbol names (utilities, types, constants)

```ts
// File: format-currency.ts
export function formatCurrency(amount: number): string { ... }
export type CurrencyCode = "USD" | "EUR" | "JPY";
export const DEFAULT_LOCALE = "en-US";
```

### Object property names, function parameters, local variables

These are pure code identifiers, never touched.

## Renaming algorithm (regex-based for v1)

The patcher uses these heuristics in order. AST-based rewriting is deferred to a follow-on phase if regex becomes brittle.

```
1. PascalCase → kebab-case
   HeroSection → hero-section
   Step:  match /([A-Z][a-z]+)([A-Z])/g, insert "-" between groups, then lowercase

2. camelCase → kebab-case
   useDarkMode → use-dark-mode
   Step:  match /([a-z])([A-Z])/g, insert "-" between groups, then lowercase

3. Consecutive uppercase (acronyms) collapse to lowercase
   APIClient    → api-client
   useURLState  → use-url-state
   Step:  match /([A-Z]+)([A-Z][a-z])/g, insert "-" between groups

4. Preserve trailing extension (.ts, .tsx, .types.ts, .test.tsx)
   UserProfile.types.ts → user-profile.types.ts (suffix preserved verbatim)

5. Numbers
   OAuth2Client     → o-auth-2-client (numeric digits treated as word boundaries)
   Component2       → component-2
```

## File type routing (where a source export lands)

Given a source TSX with multiple exports, the patcher routes each to a target path:

| Export kind | Detection regex | Target path |
|---|---|---|
| Default React component | `export default function [A-Z][A-Za-z]*` or `export default [A-Z][A-Za-z]*` | `features/<feature>/components/<feature-kebab>.tsx` |
| Named React component | `export (function|const) ([A-Z][A-Za-z]*)\b` | `features/<feature>/components/<name-kebab>.tsx` |
| Hook | `export (function|const) (use[A-Z][A-Za-z]*)\b` | `features/<feature>/hooks/use-<name-kebab>.ts` |
| Type / interface | `export (type|interface) [A-Z][A-Za-z]*` | `features/<feature>/types/<feature>.types.ts` (consolidated) |
| Constant | `export const [A-Z_]+\b` | `features/<feature>/lib/constants.ts` |
| Plain function | `export (function|const) [a-z][A-Za-z]*` | `features/<feature>/lib/<name-kebab>.ts` |
| Class | `export class [A-Z][A-Za-z]*` | `features/<feature>/services/<name-kebab>-service.ts` |

When the source has only a single default export, the patcher uses the simplified path: `features/<feature>/components/<feature>.tsx`.

## When the patcher refuses to rename

The patcher leaves a file untouched and logs a warning if:

- The file name contains characters outside `[A-Za-z0-9_.-]` (special handling needed)
- The file name is already kebab-cased (no change needed; idempotent)
- The file is in `node_modules/`, `dist/`, `.git/`, or any directory matching `tsconfig.json`'s `exclude`

## Tests the patcher must pass (for the v1 smoke source)

Given input `App` (default export, with `useToggle` hook), the patcher produces:

```
src/features/app/
├── components/
│   └── app.tsx           # default export with `function App()`
├── hooks/
│   └── use-toggle.ts     # exports `useToggle`
└── index.ts              # re-exports `App` (default) and `useToggle`
```

Imports in `src/main.tsx` are updated:

```tsx
import { App } from "@/features/app";
```
