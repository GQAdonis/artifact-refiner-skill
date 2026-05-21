import { create } from "zustand";
import { immer } from "zustand/middleware/immer";
import { useEffect } from "react";
import { Button } from "@/shared/components/ui/button";

/**
 * Sample App — smoke target for the scaffold-react-vite pipeline.
 *
 * Demonstrates the state-architecture contract end-to-end:
 *
 *   Store (zustand + immer, no React import)
 *     │
 *     └─►  Hook (selects from store, exposes tailored slice)
 *            │
 *            └─►  Component (consumes only the hook)
 *
 * Three contract surfaces exercised:
 *
 * 1. Store layer — `useCounterStore` owns the count and increment action.
 *    The store file does NOT import React; it's pure zustand + immer.
 * 2. Hook layer — `useCounter` selects from the store and returns a clean
 *    `{ count, increment }` shape.
 * 3. Component layer — `App` consumes only `useCounter()`, never the store.
 *
 * After scaffolding, the patcher routes:
 *   - `useCounterStore` (named export, matches /^use[A-Z].*Store$/) → stores/counter-store.ts
 *   - `useCounter`      (hook, /^use[A-Z]/, not ending in "Store")    → hooks/use-counter.ts
 *   - `App`             (default export)                              → components/<feature>.tsx
 */

// ---------- Store (zustand + immer, framework-agnostic) ----------
// Type is inlined into create<...>() so the patcher's single-block extractor
// keeps the type with the store. For larger stores with shared types, declare
// the interface in a sibling `types.ts` and import it in the store file.

export const useCounterStore = create<{
  count: number;
  loading: boolean;
  increment: () => void;
  reset: () => void;
}>()(
  immer((set) => ({
    count: 0,
    loading: false,
    increment: () => set((s) => { s.count += 1; }),
    reset: () => set((s) => { s.count = 0; }),
  })),
);

// ---------- Hook (React adapter, selects from store) ----------

export function useCounter() {
  const count = useCounterStore((s) => s.count);
  const increment = useCounterStore((s) => s.increment);
  const reset = useCounterStore((s) => s.reset);

  // useEffect lifecycle composition is allowed in the hook layer.
  useEffect(() => {
    // Could fire-and-forget an analytics tick here via a store action.
  }, [count]);

  return { count, increment, reset };
}

// ---------- Component (consumes only the hook) ----------

export default function App() {
  const { count, increment, reset } = useCounter();

  return (
    <main
      style={{
        minHeight: "100dvh",
        background: "var(--color-bg)",
        color: "var(--color-ink)",
        fontFamily: "var(--font-body)",
        display: "grid",
        placeItems: "center",
        padding: "2rem",
      }}
    >
      <section
        style={{
          maxWidth: "32rem",
          textAlign: "center",
          padding: "2rem",
          background: "var(--color-surface)",
          border: "1px solid var(--color-border)",
          borderRadius: "1rem",
        }}
      >
        <h1
          style={{
            fontFamily: "var(--font-display)",
            fontSize: "clamp(2rem, 4vw, 3rem)",
            color: "var(--color-ember)",
            margin: 0,
          }}
        >
          Hello from the scaffolder
        </h1>
        <p style={{ marginTop: "1rem", color: "var(--color-muted)" }}>
          Brand tokens, shadcn UI on Base UI, and store-driven state in one tiny app.
        </p>
        <p style={{ marginTop: "1rem", color: "var(--color-muted)", fontFamily: "var(--font-mono)" }}>
          count: {count}
        </p>
        <div style={{ marginTop: "1.5rem", display: "flex", gap: "0.5rem", justifyContent: "center" }}>
          <Button onClick={increment} variant="default">
            Increment
          </Button>
          <Button onClick={reset} variant="outline">
            Reset
          </Button>
        </div>
      </section>
    </main>
  );
}
