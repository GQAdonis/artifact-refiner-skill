/**
 * MCP-UI resource store.
 *
 * Owns all MCP I/O. Per `references/scaffolds/state-architecture.md`:
 *
 *   - line 20  `stores/**` owns realtime subscriptions and network calls
 *   - line 39  fetched state belongs in a store
 *   - line 210 issuing a request anywhere else is a documented violation
 *
 * It must not import `react` — the architectural ESLint config enforces that.
 *
 * ── Why this store is small ──────────────────────────────────────────────────
 * AG-UI accumulates deltas; the A2UI web host reduces an envelope stream. MCP-UI
 * does neither: a tool call returns ONE embedded resource carrying its A2UI
 * messages complete. There is no sequence to fold, so this store tracks a
 * resource and a request status and nothing more.
 *
 * ── What this store is a peer of ─────────────────────────────────────────────
 * MCP-UI is an ENVELOPE for A2UI, not an alternative to it. The same A2UI
 * messages reach three surfaces:
 *
 *     A2UI ──┬── AG-UI transport   → the web host   (assets/scaffold/a2ui/)
 *            ├── MCP-UI resource   → this host
 *            └── a2ui_flutter      → the mobile host (planned)
 *
 * That is why the resource carries `a2ui` as a required field rather than just
 * HTML: it is what keeps the MCP surface identical to the other two.
 */

import { create } from 'zustand';
import { isUIResource } from '@mcp-ui/client';

/** Minimal shape of the embedded resource. Mirrors the repo schema. */
export interface McpUiResource {
  uri: string;
  mimeType: string;
  /** Generated host page with the A2UI messages inline. */
  text: string;
  /**
   * The A2UI messages this surface renders — the SHARED UI vocabulary.
   *
   * Required by the schema, not optional. MCP-UI is an ENVELOPE for A2UI: the
   * same messages reach an AG-UI web host and (planned) a Flutter host, so the
   * UI is identical whichever transport a client arrives over. A resource
   * without them would render something no other surface can reproduce.
   */
  a2ui: unknown[];
}

export interface EmbeddedResourceLike {
  type: string;
  resource?: Partial<McpUiResource>;
}

export type ResourceStatus = 'idle' | 'loading' | 'ready' | 'error';

/**
 * Discriminate an MCP-UI resource.
 *
 * TWO checks, deliberately. `isUIResource` from `@mcp-ui/client` narrows the
 * SHAPE (`type === 'resource'`) and says nothing about the URI scheme — read
 * `evidence/mcp-ui-client-7.1.1--isUIResource.d.ts`: its predicate is typed
 * against `EmbeddedResource` and tests `type` alone. Using it by itself would
 * accept `https://` resources as MCP-UI.
 *
 * The scheme check is what upstream's own host code does
 * (`mcpResource.resource.uri?.startsWith('ui://')`). Exported so the
 * discrimination gate can assert on the real predicate rather than a copy.
 */
export function isMcpUiResource(content: unknown): content is { type: 'resource'; resource: McpUiResource } {
  if (!content || typeof content !== 'object') return false;
  const c = content as EmbeddedResourceLike;
  if (!isUIResource(c)) return false;
  const uri = c.resource?.uri;
  return typeof uri === 'string' && uri.startsWith('ui://');
}

interface JsonRpcEnvelope {
  jsonrpc: '2.0';
  id: number;
  method: string;
  params?: Record<string, unknown>;
}

interface McpUiState {
  status: ResourceStatus;
  resource: McpUiResource | null;
  /** Set when a tool result arrived but carried nothing we can render. */
  rejectedReason: string | null;
  error: string | null;
  /** Every JSON-RPC method this client has issued — used by the method-set gate. */
  methodsCalled: string[];
  callTool: (opts?: { endpoint?: string; toolName?: string; fixture?: string }) => Promise<void>;
  reset: () => void;
}

let nextId = 1;

async function rpc(endpoint: string, method: string, params?: Record<string, unknown>): Promise<unknown> {
  const body: JsonRpcEnvelope = { jsonrpc: '2.0', id: nextId++, method, params };
  const res = await fetch(endpoint, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`${method}: HTTP ${res.status}`);
  const json = (await res.json()) as { result?: unknown; error?: { message?: string } };
  if (json.error) throw new Error(`${method}: ${json.error.message ?? 'JSON-RPC error'}`);
  return json.result;
}

export const useResourceStore = create<McpUiState>((set, get) => ({
  status: 'idle',
  resource: null,
  rejectedReason: null,
  error: null,
  methodsCalled: [],

  async callTool(opts) {
    const base = opts?.endpoint ?? '/api/mcp';
    const endpoint = opts?.fixture ? `${base}?fixture=${encodeURIComponent(opts.fixture)}` : base;
    const toolName = opts?.toolName ?? 'show_order_status';

    set({ status: 'loading', error: null, rejectedReason: null, resource: null });
    const track = (m: string) => set({ methodsCalled: [...get().methodsCalled, m] });

    try {
      track('initialize');
      await rpc(endpoint, 'initialize', {
        protocolVersion: '2025-06-18',
        capabilities: {},
        clientInfo: { name: 'mcp-ui-host', version: '0.0.0-dev' },
      });

      track('tools/call');
      const result = (await rpc(endpoint, 'tools/call', { name: toolName, arguments: {} })) as {
        content?: unknown[];
      };

      const embedded = (result.content ?? []).find(isMcpUiResource);
      if (!embedded) {
        // Loud, not silent. A tool result carrying a non-ui:// resource is a
        // real condition the discrimination gate drives deliberately.
        set({
          status: 'error',
          rejectedReason: 'No ui:// resource in tool result — not rendered as MCP-UI.',
        });
        return;
      }
      set({ status: 'ready', resource: embedded.resource });
    } catch (err) {
      set({ status: 'error', error: err instanceof Error ? err.message : String(err) });
    }
  },

  reset() {
    set({ status: 'idle', resource: null, rejectedReason: null, error: null, methodsCalled: [] });
  },
}));
