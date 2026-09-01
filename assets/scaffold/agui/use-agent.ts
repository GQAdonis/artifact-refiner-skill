/**
 * Hook layer for the AG-UI agent.
 *
 * Per `references/scaffolds/state-architecture.md`, hooks talk to stores and
 * nothing else. There is deliberately no `fetch`, no `EventSource`, and no
 * subscription setup here — that all lives in `agent-store.ts`. Attaching a
 * listener from this file would be the violation described at line 210.
 */

import { useEffect, useMemo } from 'react';
import { useAgentStore, type AgentMessage } from './agent-store';

export interface UseAgentResult {
  status: 'idle' | 'running' | 'error';
  /** Messages in arrival order. */
  messages: AgentMessage[];
  error: string | null;
  isRunning: boolean;
  runAgent: (prompt: string) => Promise<void>;
  abort: () => void;
}

export function useAgent(options?: { url?: string }): UseAgentResult {
  const status = useAgentStore((s) => s.status);
  const error = useAgentStore((s) => s.error);
  const messages = useAgentStore((s) => s.messages);
  const messageOrder = useAgentStore((s) => s.messageOrder);
  const runAgent = useAgentStore((s) => s.runAgent);
  const abort = useAgentStore((s) => s.abort);
  const initRealtime = useAgentStore((s) => s.initRealtime);

  // The single mount-time subscription hook-up. `initRealtime` is idempotent,
  // so a re-run under StrictMode double-invocation replaces rather than stacks.
  useEffect(() => {
    initRealtime(options);
  }, [initRealtime, options?.url]);

  const ordered = useMemo(
    () => messageOrder.map((id) => messages[id]).filter(Boolean),
    [messageOrder, messages],
  );

  return {
    status,
    messages: ordered,
    error,
    isRunning: status === 'running',
    runAgent,
    abort,
  };
}
