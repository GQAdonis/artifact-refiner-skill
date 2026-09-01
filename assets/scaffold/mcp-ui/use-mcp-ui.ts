/**
 * Hook layer for the MCP-UI surface.
 *
 * Per `references/scaffolds/state-architecture.md`, hooks talk to stores and
 * nothing else. There is deliberately no `fetch` here — that lives in
 * `resource-store.ts`. Issuing a request from this file would be the violation
 * described at line 210.
 *
 * This file also RE-EXPORTS the types and predicates the surface needs. A
 * component importing them from `stores/` violates the architectural ESLint
 * rule — phase-8 hit exactly that and `pnpm lint` caught it.
 */

import { useCallback, useMemo } from 'react';
import {
  useResourceStore,
  isMcpUiResource,
  type McpUiResource,
  type ResourceStatus,
} from '../stores/resource-store';

export type { McpUiResource, ResourceStatus };
export { isMcpUiResource };

/**
 * Sender validation for guest messages.
 *
 * ORIGIN ALONE IS NOT ENOUGH. The sandbox drops `allow-same-origin`, which
 * makes the framed document opaque: its messages arrive with `origin: "null"`,
 * a value ANY opaque frame can present. So the origin check is paired with a
 * source check against the frame we actually mounted — that is the half which
 * distinguishes our guest from a forged sender.
 *
 * Exported so the trust-boundary tests can call it directly rather than
 * driving a browser.
 */
export function isTrustedGuestMessage(
  event: Pick<MessageEvent, 'origin' | 'source'>,
  expected: { origin: string; source: unknown },
): boolean {
  if (event.origin !== expected.origin) return false;
  if (!expected.source) return false;
  return event.source === expected.source;
}

/**
 * Link-scheme validation for `onOpenLink`.
 *
 * Allow `http(s)` only. `javascript:`, `data:`, and `file:` are refused —
 * the guest is server-supplied content, and an unchecked scheme here is script
 * execution in the host's context.
 */
export function isSafeLink(url: string): boolean {
  let parsed: URL;
  try {
    parsed = new URL(url);
  } catch {
    return false;
  }
  return parsed.protocol === 'http:' || parsed.protocol === 'https:';
}

export interface UseMcpUiResult {
  status: ResourceStatus;
  resource: McpUiResource | null;
  /** Set when a tool result carried no `ui://` resource. */
  rejectedReason: string | null;
  error: string | null;
  methodsCalled: string[];
  /** HTML to hand the sandbox, or null when nothing renderable has arrived. */
  html: string | null;
  callTool: (opts?: { endpoint?: string; toolName?: string; fixture?: string }) => Promise<void>;
  reset: () => void;
}

export function useMcpUi(): UseMcpUiResult {
  const status = useResourceStore((s) => s.status);
  const resource = useResourceStore((s) => s.resource);
  const rejectedReason = useResourceStore((s) => s.rejectedReason);
  const error = useResourceStore((s) => s.error);
  const methodsCalled = useResourceStore((s) => s.methodsCalled);
  const storeCallTool = useResourceStore((s) => s.callTool);
  const storeReset = useResourceStore((s) => s.reset);

  const callTool = useCallback<UseMcpUiResult['callTool']>((opts) => storeCallTool(opts), [storeCallTool]);
  const reset = useCallback(() => storeReset(), [storeReset]);
  const html = useMemo(() => resource?.text ?? null, [resource]);

  return { status, resource, rejectedReason, error, methodsCalled, html, callTool, reset };
}
