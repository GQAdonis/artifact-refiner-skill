# Scaffold Convention — State Architecture

Every React/Vite scaffold produced by this skill pack uses **zustand + immer** for shared state and follows a strict three-layer architecture. This is the contract.

## The dependency rule

```
Components  →  Hooks  →  Stores  →  Services / APIs / Realtime
            ↗            ↗            ↗
       (consume       (consume      (own all
        only hooks)    only stores)  I/O + side effects)
```

**No layer may skip a layer.** No exceptions for shared utilities, no shortcuts for "just this once".

| Layer | Owns | Forbidden imports |
|---|---|---|
| `**/components/**` | JSX, presentational logic | `**/stores/**`, `**/services/**`, `fetch`, `axios`, `ky` |
| `**/hooks/**` | State selection, effect orchestration, return-shape composition | `**/services/**`, `fetch`, `axios`, `ky`, any I/O primitive |
| `**/stores/**` | Application state, I/O, realtime subscriptions, persistence | `react`, anything React-coupled |

Stores are framework-agnostic. They could be consumed by Riverpod, AG-UI, or any other adapter — only the hook layer ties them to React.

## What counts as a "store" vs "local state"

The rule says "components → hooks → stores". A robotic reading would forbid `useState` for any state. That is wrong.

### `useState` is allowed for:

- **Ephemeral single-component UI state** — `isOpen` for a dropdown, `isHovered` for a card
- **Form drafts before submit** — input values, validation state
- **Animation / transition flags** — `isExiting`, `isLoaded`
- **Derived view state** — currently-selected tab, currently-highlighted row

### Use a zustand store when:

- The state is **shared across two or more components**
- The state triggers **I/O** (`fetch`, WebSocket, file system, native APIs)
- The state participates in **realtime updates** (Supabase realtime, SSE, WebSocket subscriptions)
- The state should **persist** (localStorage, IndexedDB)
- The state needs **time-travel debugging** or middleware (zustand devtools)
- The state belongs to a **domain object** (user, cart, session, feed)

If you're unsure, ask: "Does another component need this?" If yes → store. If no → `useState`.

## Store shape

Stores use zustand 5+ with the immer middleware so updates read like mutable code while remaining immutable underneath:

```ts
// src/features/cart/stores/cart-store.ts
import { create } from "zustand";
import { immer } from "zustand/middleware/immer";

interface CartItem {
  id: string;
  name: string;
  qty: number;
}

interface CartState {
  items: CartItem[];
  loading: boolean;

  // actions own I/O
  loadCart: (userId: string) => Promise<void>;
  addItem: (item: CartItem) => void;
  removeItem: (id: string) => void;

  // realtime lifecycle
  initRealtime: (userId: string) => () => void;
}

export const useCartStore = create<CartState>()(
  immer((set, get) => ({
    items: [],
    loading: false,

    loadCart: async (userId) => {
      set((s) => { s.loading = true; });
      const res = await fetch(`/api/cart/${userId}`);
      const items: CartItem[] = await res.json();
      set((s) => {
        s.items = items;
        s.loading = false;
      });
    },

    addItem: (item) => set((s) => { s.items.push(item); }),
    removeItem: (id) => set((s) => { s.items = s.items.filter((i) => i.id !== id); }),

    initRealtime: (userId) => {
      const ws = new WebSocket(`wss://example.com/cart/${userId}`);
      ws.addEventListener("message", (e) => {
        const update = JSON.parse(e.data);
        set((s) => {
          const i = s.items.find((it) => it.id === update.id);
          if (i) i.qty = update.qty;
        });
      });
      return () => ws.close();
    },
  })),
);
```

Notes:

- The store file does **not import React**. It's pure TypeScript.
- Actions return promises when async. Components/hooks await them through the hook layer if needed.
- Realtime registration returns an unsubscribe function. The caller (usually `<Providers>`) is responsible for cleanup.

## Hook shape

Hooks are the React adapter. They select from stores, compose `useEffect` for lifecycle, and expose tailored slices to components:

```ts
// src/features/cart/hooks/use-cart.ts
import { useEffect } from "react";
import { useCartStore } from "../stores/cart-store";

export function useCart(userId: string) {
  const items = useCartStore((s) => s.items);
  const loading = useCartStore((s) => s.loading);
  const loadCart = useCartStore((s) => s.loadCart);

  useEffect(() => {
    loadCart(userId);
  }, [userId, loadCart]);

  return { items, loading };
}

export function useCartActions() {
  const addItem = useCartStore((s) => s.addItem);
  const removeItem = useCartStore((s) => s.removeItem);
  return { addItem, removeItem };
}
```

Notes:

- Hooks **never** call `fetch` directly. The store's `loadCart` action owns the network call.
- Hooks compose `useEffect` for lifecycle (mounting, dependency change).
- Selectors should be narrow — `(s) => s.items` not `(s) => s` — so re-renders are minimized.

## Component shape

Components consume only hooks:

```tsx
// src/features/cart/components/cart-list.tsx
import { useCart, useCartActions } from "../hooks/use-cart";

interface Props {
  userId: string;
}

export function CartList({ userId }: Props) {
  const { items, loading } = useCart(userId);
  const { removeItem } = useCartActions();

  if (loading) return <Spinner />;
  return (
    <ul>
      {items.map((item) => (
        <li key={item.id}>
          {item.name} × {item.qty}
          <button onClick={() => removeItem(item.id)}>Remove</button>
        </li>
      ))}
    </ul>
  );
}
```

Notes:

- The component never imports `useCartStore`.
- The component never imports `fetch` or any service module.
- Local UI state (e.g., "is delete-confirm dialog open") is fine via `useState` inside the component.

## Realtime ownership

All realtime subscriptions live in stores. Subscriptions are coordinated through a single `initRealtime()` action invoked once at app mount:

```tsx
// src/app/providers.tsx
import { useEffect } from "react";
import { useCartStore } from "@/features/cart/stores/cart-store";
import { useSessionStore } from "@/app/stores/session-store";

export function Providers({ children }: { children: React.ReactNode }) {
  const userId = useSessionStore((s) => s.userId);

  useEffect(() => {
    if (!userId) return;
    const teardown = useCartStore.getState().initRealtime(userId);
    return teardown;
  }, [userId]);

  return <>{children}</>;
}
```

Forbidden:

- `useEffect(() => { const sub = supabase.channel(...).subscribe(); return () => ...; }, [])` inside a component or hook
- WebSocket connections opened from `useEffect` inside a hook
- SSE listeners attached from anywhere except a store action

The reason: realtime subscriptions are expensive resources. Centralizing their lifecycle in stores means deduplication, reconnection logic, and teardown are all in one place.

## TSX over JSX, always

Every React source file uses `.tsx`. `.jsx` is forbidden. TypeScript types serve as the documentation, the contract, and the lint surface — losing them in a `.jsx` file is unacceptable.

The scaffolder enforces this: `pnpm dlx shadcn@latest init --template vite` produces `.tsx` by default, and the patcher does not rename `.tsx` to `.jsx` anywhere.

## ESLint enforcement

The scaffolder generates `eslint.config.mjs` with `no-restricted-imports` rules enforcing the layer rules. See `references/scaffolds/eslint-architecture.config.mjs` for the snippet.

Violations fail `pnpm lint`. The config is a *starter* — projects may customize per `eslint.config.mjs`'s override rules — but the default is the strict layering.

## File-naming reminder

State architecture lives alongside kebab-case file naming (see `kebab-case-rename.md`):

- Store files: `<feature>-store.ts` (e.g., `cart-store.ts`)
- Hook files: `use-<thing>.ts` (e.g., `use-cart.ts`)
- Component files: `<thing>.tsx` (e.g., `cart-list.tsx`)
- The folders are `stores/`, `hooks/`, `components/` (always)

## Realtime sources expected

The architecture accommodates these realtime mechanisms without case-by-case logic:

- **Supabase realtime** (`postgres_changes`, broadcast, presence)
- **WebSocket** (raw or wrapped via `socket.io-client`, `partysocket`)
- **Server-Sent Events** (SSE / EventSource)
- **AG-UI streaming** (consume the openai-proxy AG-UI surface via fetch streaming)

All of them connect inside store actions. Their subscriptions return unsubscribe functions. `<Providers>` coordinates lifecycle.

## When the rule bends

There are exactly two cases:

1. **Component-scoped ephemeral state** → `useState` (documented above)
2. **Refactoring legacy code** → temporary direct-store imports allowed during migration, but the file must include a `// TODO: lift to hook` comment and the migration must complete within the same change

There is no third case.
