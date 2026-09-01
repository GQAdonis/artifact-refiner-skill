/**
 * AG-UI agent store.
 *
 * Owns all agent I/O. Per `references/scaffolds/state-architecture.md`:
 *
 *   - line 20  `stores/**` owns realtime subscriptions
 *   - line 39  SSE/WebSocket state belongs in a store
 *   - line 185 subscriptions coordinate through one `initRealtime()` at mount
 *   - line 210 "SSE listeners attached from anywhere except a store action"
 *              is a documented violation
 *
 * Components talk to hooks; hooks talk to this store; only this store talks to
 * the network. It must not import `react` — the architectural ESLint config
 * enforces that.
 */

import { create } from 'zustand';
import { immer } from 'zustand/middleware/immer';
import { HttpAgent } from '@ag-ui/client';

/** Structural event type — the wire shape, independent of SDK internals. */
export interface AgUiEvent {
  type: string;
  [key: string]: unknown;
}

export interface AgentMessage {
  id: string;
  role: string;
  /** Accumulated text. Deltas are appended, never replaced. */
  content: string;
  complete: boolean;
}

export type AgentStatus = 'idle' | 'running' | 'error';

export interface AgentState {
  status: AgentStatus;
  runId: string | null;
  threadId: string | null;
  /** Keyed by messageId so interleaved messages cannot corrupt one another. */
  messages: Record<string, AgentMessage>;
  /** Arrival order — object key order is not a contract. */
  messageOrder: string[];
  error: string | null;
  /** Events dropped because their messageId had no open message. */
  droppedEvents: number;
}

export interface AgentActions {
  initRealtime: (options?: { url?: string }) => void;
  runAgent: (prompt: string) => Promise<void>;
  abort: () => void;
  /** Exported for tests: applies one event to state. Pure w.r.t. the network. */
  applyEvent: (event: AgUiEvent) => void;
  reset: () => void;
}

const DEFAULT_URL = '/api/agent/run';

const initialState: AgentState = {
  status: 'idle',
  runId: null,
  threadId: null,
  messages: {},
  messageOrder: [],
  error: null,
  droppedEvents: 0,
};

/**
 * Reduce one event into a draft.
 *
 * Exported standalone so the reduction can be tested without a store, a
 * network, or a React tree — the logic most likely to be subtly wrong is the
 * part with the fewest moving parts around it.
 */
export function reduceEvent(draft: AgentState, event: AgUiEvent): void {
  switch (event.type) {
    case 'RUN_STARTED': {
      draft.status = 'running';
      draft.error = null;
      draft.runId = (event.runId as string) ?? null;
      draft.threadId = (event.threadId as string) ?? null;
      break;
    }

    case 'TEXT_MESSAGE_START': {
      const id = event.messageId as string;
      if (!id) return;
      draft.messages[id] = {
        id,
        role: (event.role as string) ?? 'assistant',
        content: '',
        complete: false,
      };
      draft.messageOrder.push(id);
      break;
    }

    case 'TEXT_MESSAGE_CONTENT': {
      const id = event.messageId as string;
      const target = draft.messages[id];
      if (!target) {
        // Do not synthesise a message: that would hide a protocol ordering
        // violation (content before its START) behind plausible output.
        draft.droppedEvents += 1;
        console.warn(
          `[agent-store] dropped TEXT_MESSAGE_CONTENT for unknown messageId "${id}"`,
        );
        return;
      }
      // Append — `delta` is an increment. Replacing renders only the final
      // fragment while still looking like working output.
      target.content += (event.delta as string) ?? '';
      break;
    }

    case 'TEXT_MESSAGE_END': {
      const id = event.messageId as string;
      const target = draft.messages[id];
      if (!target) {
        draft.droppedEvents += 1;
        console.warn(
          `[agent-store] dropped TEXT_MESSAGE_END for unknown messageId "${id}"`,
        );
        return;
      }
      target.complete = true;
      break;
    }

    case 'RUN_FINISHED': {
      draft.status = 'idle';
      break;
    }

    case 'RUN_ERROR': {
      draft.status = 'error';
      draft.error = (event.message as string) ?? 'agent run failed';
      break;
    }

    default:
      // Tool-call, state, reasoning, and step events are out of scope for this
      // change (see the proposal). Ignored rather than dropped-with-warning:
      // they are valid protocol events this store simply does not render yet.
      break;
  }
}

export const useAgentStore = create<AgentState & AgentActions>()(
  immer((set, get) => {
    let agent: HttpAgent | null = null;
    let unsubscribe: (() => void) | null = null;

    return {
      ...initialState,

      /**
       * Single subscription entry point, invoked once at app mount.
       * Idempotent — a second call replaces the previous subscription rather
       * than stacking a duplicate.
       */
      initRealtime: (options) => {
        unsubscribe?.();
        agent = new HttpAgent({ url: options?.url ?? DEFAULT_URL });
        const sub = agent.subscribe({
          onEvent: ({ event }) => {
            set((draft) => {
              reduceEvent(draft, event as unknown as AgUiEvent);
            });
          },
        });
        unsubscribe = () => sub.unsubscribe();
      },

      runAgent: async (prompt) => {
        if (!agent) get().initRealtime();
        if (!agent) return;
        agent.addMessage({
          id: `usr_${Date.now().toString(36)}`,
          role: 'user',
          content: prompt,
        });
        try {
          await agent.runAgent();
        } catch (err) {
          set((draft) => {
            draft.status = 'error';
            draft.error = (err as Error).message;
          });
        }
      },

      abort: () => {
        agent?.abortRun();
        set((draft) => {
          draft.status = 'idle';
          // Close any message left mid-stream so the UI does not show a
          // permanently "still typing" bubble.
          for (const id of draft.messageOrder) {
            const m = draft.messages[id];
            if (m && !m.complete) m.complete = true;
          }
        });
      },

      applyEvent: (event) => {
        set((draft) => {
          reduceEvent(draft, event);
        });
      },

      reset: () => {
        unsubscribe?.();
        unsubscribe = null;
        agent = null;
        set(() => ({ ...initialState, messages: {}, messageOrder: [] }));
      },
    };
  }),
);
