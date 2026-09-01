/**
 * Hook layer for the A2UI surface.
 *
 * Per `references/scaffolds/state-architecture.md`, hooks talk to stores and
 * nothing else. There is deliberately no `fetch`, no `EventSource`, and no
 * subscription setup here — that lives in `surface-store.ts`. Attaching a
 * listener from this file would be the violation described at line 210.
 */

import { useEffect, useMemo } from 'react';
import {
  useSurfaceStore,
  type A2uiComponent,
  type A2uiMessage,
  type SurfaceStatus,
} from '../stores/surface-store';

export interface UseSurfaceResult {
  surfaceId: string | null;
  catalogId: string | null;
  /** Components in arrival order. */
  components: A2uiComponent[];
  /** Keyed by id, for resolving `child` / `children` references. */
  componentsById: Record<string, A2uiComponent>;
  dataModel: Record<string, unknown>;
  status: SurfaceStatus;
  error: string | null;
  isLive: boolean;
  /** Operations reduced into state that the pinned renderer cannot draw. */
  unrenderableOps: string[];
  applyMessage: (message: A2uiMessage) => void;
}

export function useSurface(options?: {
  source?: AsyncIterable<A2uiMessage>;
}): UseSurfaceResult {
  const surfaceId = useSurfaceStore((s) => s.surfaceId);
  const catalogId = useSurfaceStore((s) => s.catalogId);
  const components = useSurfaceStore((s) => s.components);
  const componentOrder = useSurfaceStore((s) => s.componentOrder);
  const dataModel = useSurfaceStore((s) => s.dataModel);
  const status = useSurfaceStore((s) => s.status);
  const error = useSurfaceStore((s) => s.error);
  const unrenderableOps = useSurfaceStore((s) => s.unrenderableOps);
  const applyMessage = useSurfaceStore((s) => s.applyMessage);
  const initRealtime = useSurfaceStore((s) => s.initRealtime);

  // The single mount-time subscription hook-up. `initRealtime` is idempotent,
  // so a StrictMode double-invocation replaces rather than stacks.
  useEffect(() => {
    initRealtime(options);
  }, [initRealtime, options?.source]);

  const ordered = useMemo(
    () => componentOrder.map((id) => components[id]).filter(Boolean),
    [componentOrder, components],
  );

  return {
    surfaceId,
    catalogId,
    components: ordered,
    componentsById: components,
    dataModel,
    status,
    error,
    isLive: status === 'live',
    unrenderableOps,
    applyMessage,
  };
}

// Re-exported so components can name the message type without importing from
// `stores/` — the architectural ESLint rule forbids that path, and the hook is
// the layer components are meant to talk to.
export type { A2uiMessage };
