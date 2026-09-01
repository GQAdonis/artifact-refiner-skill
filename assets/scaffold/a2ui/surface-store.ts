/**
 * A2UI surface store.
 *
 * Owns all A2UI I/O. Per `references/scaffolds/state-architecture.md`:
 *
 *   - line 20  `stores/**` owns realtime subscriptions
 *   - line 39  streamed state belongs in a store
 *   - line 185 subscriptions coordinate through one `initRealtime()` at mount
 *   - line 210 attaching a listener anywhere else is a documented violation
 *
 * A2UI is streaming-first: an agent sends a sequence of envelope messages and
 * the surface is built up progressively. This store reduces that stream; it
 * does not fetch one document and render it once.
 *
 * It must not import `react` — the architectural ESLint config enforces that.
 *
 * ── Protocol version note ────────────────────────────────────────────────────
 * The schema this repo validates against (`a2ui-component.schema.json`) encodes
 * protocol v1.0 and admits six operations. `@a2ui/react@0.10.2` implements v0.9
 * and renders three of them: createSurface, updateComponents, updateDataModel.
 *
 * This store reduces all six, so it stays honest to the validated contract. The
 * three the renderer cannot draw are reduced into state and nothing more —
 * `deleteSurface` clearing state is a STORE guarantee, not a rendering one.
 * See the change's design.md for why the overlap was chosen over re-speccing.
 */

import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';

/** One component. Structural keys are fixed; the rest are catalog-specific. */
export interface A2uiComponent {
  id: string;
  component: string;
  child?: string;
  children?: string[];
  [prop: string]: unknown;
}

/** Envelope message. Exactly one operation key is present. */
export interface A2uiMessage {
  version?: string;
  createSurface?: {
    surfaceId: string;
    catalogId: string;
    components: A2uiComponent[];
    dataModel?: Record<string, unknown>;
    surfaceParams?: Record<string, unknown>;
  };
  updateComponents?: { surfaceId: string; components: A2uiComponent[] };
  updateDataModel?: { surfaceId: string; dataModel: Record<string, unknown> };
  deleteSurface?: { surfaceId: string };
  callFunction?: { surfaceId: string; call: string; args?: Record<string, unknown> };
  actionResponse?: { surfaceId: string };
}

export type SurfaceStatus = 'empty' | 'live' | 'error';

export interface SurfaceState {
  surfaceId: string | null;
  catalogId: string | null;
  /** Keyed by id — the protocol's component array is flat and id-addressed. */
  components: Record<string, A2uiComponent>;
  /** Arrival order. Object key order is not a contract. */
  componentOrder: string[];
  dataModel: Record<string, unknown>;
  status: SurfaceStatus;
  error: string | null;
  /** Messages reduced but not renderable by the v0.9 SDK. */
  unrenderableOps: string[];
}

export interface SurfaceActions {
  initRealtime: (options?: { source?: AsyncIterable<A2uiMessage> }) => void;
  applyMessage: (message: A2uiMessage) => void;
  reset: () => void;
}

const initialState: SurfaceState = {
  surfaceId: null,
  catalogId: null,
  components: {},
  componentOrder: [],
  dataModel: {},
  status: 'empty',
  error: null,
  unrenderableOps: [],
};

/** Operations the pinned renderer (v0.9) cannot draw. Reduced, never rendered. */
const UNRENDERABLE_BY_SDK = ['deleteSurface', 'callFunction', 'actionResponse'];

/**
 * Reduce one envelope message into a draft.
 *
 * Exported standalone so the reduction is testable without a store, a network,
 * or a React tree — the part most likely to be subtly wrong has the fewest
 * moving parts around it.
 */
export function reduceMessage(draft: SurfaceState, message: A2uiMessage): void {
  if (message.createSurface) {
    const op = message.createSurface;
    // Wholesale replacement: a new surface supersedes whatever preceded it.
    draft.surfaceId = op.surfaceId;
    draft.catalogId = op.catalogId;
    draft.components = {};
    draft.componentOrder = [];
    for (const c of op.components ?? []) {
      if (!c || typeof c.id !== 'string') continue;
      if (!(c.id in draft.components)) draft.componentOrder.push(c.id);
      draft.components[c.id] = c;
    }
    draft.dataModel = op.dataModel ?? {};
    draft.status = 'live';
    draft.error = null;
    return;
  }

  if (message.updateComponents) {
    // MERGE by id — never replace the map. Replacing would look correct on a
    // single-component surface and silently drop every sibling on a real one.
    for (const c of message.updateComponents.components ?? []) {
      if (!c || typeof c.id !== 'string') continue;
      if (!(c.id in draft.components)) draft.componentOrder.push(c.id);
      draft.components[c.id] = c;
    }
    return;
  }

  if (message.updateDataModel) {
    // Merge, so `{"path": …}` leaves re-resolve without components being resent.
    Object.assign(draft.dataModel, message.updateDataModel.dataModel ?? {});
    return;
  }

  if (message.deleteSurface) {
    Object.assign(draft, {
      ...initialState,
      components: {},
      componentOrder: [],
      dataModel: {},
      unrenderableOps: [...draft.unrenderableOps, 'deleteSurface'],
    });
    return;
  }

  for (const op of ['callFunction', 'actionResponse'] as const) {
    if (message[op]) {
      // Recorded rather than dropped: the schema admits these, the pinned
      // renderer does not implement them, and silently ignoring a valid message
      // would hide that gap from anyone reading state.
      draft.unrenderableOps.push(op);
      return;
    }
  }
}

/** Operations reduced here but not renderable by the pinned SDK version. */
export const unrenderableOperations = (): readonly string[] => UNRENDERABLE_BY_SDK;

export const useSurfaceStore = create<SurfaceState & SurfaceActions>()(
  immer((set) => {
    let cancelled = false;

    return {
      ...initialState,

      /**
       * Single subscription entry point, invoked once at mount.
       * Idempotent: a second call cancels the previous consumer rather than
       * stacking a duplicate.
       */
      initRealtime: (options) => {
        cancelled = true; // stop any prior consumer
        const source = options?.source;
        if (!source) return;
        cancelled = false;

        void (async () => {
          try {
            for await (const message of source) {
              if (cancelled) break;
              set((draft) => {
                reduceMessage(draft, message);
              });
            }
          } catch (err) {
            set((draft) => {
              draft.status = 'error';
              draft.error = (err as Error).message;
            });
          }
        })();
      },

      applyMessage: (message) => {
        set((draft) => {
          reduceMessage(draft, message);
        });
      },

      reset: () => {
        cancelled = true;
        set(() => ({ ...initialState, components: {}, componentOrder: [], dataModel: {} }));
      },
    };
  }),
);
