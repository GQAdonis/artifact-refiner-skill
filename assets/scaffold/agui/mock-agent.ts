/**
 * Mock AG-UI agent — emits a scripted run as protocol events.
 *
 * Development only. This exists to prove the AG-UI transport end to end without
 * pulling in an LLM, credentials, or provider-specific streaming translation.
 * A real deployment replaces this with a backend that emits the same event
 * sequence.
 *
 * Emission order follows the AG-UI protocol's own sequencing rules (the
 * `ValidateSequence` contract in the upstream Go SDK):
 *
 *   RUN_STARTED
 *     → TEXT_MESSAGE_START
 *       → TEXT_MESSAGE_CONTENT × N
 *     → TEXT_MESSAGE_END
 *   → RUN_FINISHED
 *
 * Content arrives as *multiple* deltas on purpose. A single-delta response would
 * satisfy every check except the one that matters — that the UI renders text
 * incrementally rather than in one flush.
 */

/** Minimal structural type. The real shape is `BaseEvent` from `@ag-ui/core`. */
export interface AgUiEvent {
  type: string;
  [key: string]: unknown;
}

export interface MockAgentOptions {
  /** Thread the run belongs to. Echoed from RunAgentInput when present. */
  threadId?: string;
  /** Run identifier. Echoed from RunAgentInput when present. */
  runId?: string;
  /** Milliseconds between content deltas. 0 disables the delay (tests). */
  deltaDelayMs?: number;
  /** Overrides the canned reply. Chunked on word boundaries. */
  reply?: string;
}

const DEFAULT_REPLY =
  'This response arrives as a stream of deltas. Each fragment is a separate ' +
  'TEXT_MESSAGE_CONTENT event, so the interface can render text as it is ' +
  'produced instead of waiting for the whole message.';

const DEFAULT_DELTA_DELAY_MS = 40;

const sleep = (ms: number): Promise<void> =>
  ms > 0 ? new Promise((resolve) => setTimeout(resolve, ms)) : Promise.resolve();

/**
 * Split into chunks that keep whitespace attached to the preceding word, so
 * concatenating every delta reproduces the source string exactly. A naive
 * `split(' ')` loses the separators and silently corrupts the reassembled text.
 */
function chunk(text: string): string[] {
  return text.match(/\S+\s*/g) ?? [];
}

/**
 * Yield one scripted AG-UI run.
 *
 * Consumers must forward events in the order received; the sequence is only
 * protocol-valid as a whole.
 */
export async function* runMockAgent(
  options: MockAgentOptions = {},
): AsyncGenerator<AgUiEvent, void, undefined> {
  const threadId = options.threadId ?? `thread_${Date.now().toString(36)}`;
  const runId = options.runId ?? `run_${Date.now().toString(36)}`;
  const messageId = `msg_${Date.now().toString(36)}`;
  const delay = options.deltaDelayMs ?? DEFAULT_DELTA_DELAY_MS;

  yield { type: 'RUN_STARTED', threadId, runId };
  yield { type: 'TEXT_MESSAGE_START', messageId, role: 'assistant' };

  for (const delta of chunk(options.reply ?? DEFAULT_REPLY)) {
    await sleep(delay);
    yield { type: 'TEXT_MESSAGE_CONTENT', messageId, delta };
  }

  yield { type: 'TEXT_MESSAGE_END', messageId };
  yield { type: 'RUN_FINISHED', threadId, runId };
}
