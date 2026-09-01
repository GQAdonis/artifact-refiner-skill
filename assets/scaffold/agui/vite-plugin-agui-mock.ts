/**
 * Vite dev-server middleware exposing an AG-UI-conformant SSE endpoint.
 *
 * DEVELOPMENT ONLY. `configureServer` runs in the Vite dev server, not in a
 * production build. A deployed app needs this route reimplemented behind its
 * real backend. The generated README states this; do not infer from the shape
 * of the code that it is deployable.
 *
 * Transport contract (from the upstream AG-UI TypeScript client, `HttpAgent`):
 *
 *   POST <path>
 *     Content-Type: application/json      body: RunAgentInput
 *     Accept: text/event-stream
 *   → 200
 *     Content-Type: text/event-stream
 *     Cache-Control: no-cache
 *     Connection: keep-alive
 *     body: `data: {…}\n\n` frames, one JSON event each
 *
 * Frames are produced by `EventEncoder.encodeSSE` rather than hand-formatted,
 * so the wire format tracks upstream instead of drifting from it.
 */

import type { Connect, Plugin, ViteDevServer } from 'vite';
import type { IncomingMessage, ServerResponse } from 'node:http';
import { EventEncoder } from '@ag-ui/encoder';
import { runMockAgent, type AgUiEvent } from './mock-agent.ts';

/**
 * `encodeSSE` is typed against `@ag-ui/core`'s `BaseEvent`, whose `type` is the
 * `EventType` enum rather than `string`. The mock emits plain object literals so
 * it stays readable and testable without importing the SDK's enum — which this
 * package cannot import directly anyway, since only `@ag-ui/encoder` is a
 * declared dependency and pnpm does not guarantee `@ag-ui/core` is hoisted.
 *
 * The cast is narrowed to this one boundary. The wire format is identical: the
 * enum's values ARE the event-kind strings.
 */
const encodeEvent = (encoder: EventEncoder, event: AgUiEvent): string =>
  encoder.encodeSSE(event as unknown as Parameters<EventEncoder['encodeSSE']>[0]);

export interface AgUiMockOptions {
  /** Route the middleware answers on. */
  path?: string;
  /** Milliseconds between content deltas. */
  deltaDelayMs?: number;
}

const DEFAULT_PATH = '/api/agent/run';
const MAX_BODY_BYTES = 1_000_000;

function readJsonBody(req: IncomingMessage): Promise<unknown> {
  return new Promise((resolve, reject) => {
    let size = 0;
    const chunks: Buffer[] = [];
    req.on('data', (c: Buffer) => {
      size += c.length;
      // Bound the buffer: an unbounded read is a trivial memory exhaustion
      // vector even on a dev server.
      if (size > MAX_BODY_BYTES) {
        reject(new Error('request body exceeds 1MB'));
        req.destroy();
        return;
      }
      chunks.push(c);
    });
    req.on('error', reject);
    req.on('end', () => {
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString('utf8')));
      } catch (err) {
        reject(new Error(`body is not valid JSON: ${(err as Error).message}`));
      }
    });
  });
}

/**
 * Structural check for `RunAgentInput`.
 *
 * Deliberately not a Zod parse against `RunAgentInputSchema`: this package
 * declares only `@ag-ui/encoder`, and reaching into `@ag-ui/core` through it
 * would depend on a hoisting layout pnpm does not guarantee. The fields checked
 * here are the ones the mock actually consumes.
 */
function validateRunAgentInput(
  body: unknown,
): { ok: true; threadId?: string; runId?: string } | { ok: false; issues: string[] } {
  const issues: string[] = [];
  if (typeof body !== 'object' || body === null || Array.isArray(body)) {
    return { ok: false, issues: ['body must be a JSON object'] };
  }
  const input = body as Record<string, unknown>;
  if (!Array.isArray(input.messages)) {
    issues.push('messages: expected an array');
  }
  for (const key of ['threadId', 'runId'] as const) {
    if (input[key] !== undefined && typeof input[key] !== 'string') {
      issues.push(`${key}: expected a string when present`);
    }
  }
  if (issues.length > 0) return { ok: false, issues };
  return {
    ok: true,
    threadId: input.threadId as string | undefined,
    runId: input.runId as string | undefined,
  };
}

function sendJson(res: ServerResponse, status: number, payload: unknown): void {
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json');
  res.end(JSON.stringify(payload));
}

export function aguiMockPlugin(options: AgUiMockOptions = {}): Plugin {
  const path = options.path ?? DEFAULT_PATH;

  return {
    name: 'agui-mock-server',
    configureServer(server: ViteDevServer) {
      const handler: Connect.NextHandleFunction = (req, res, next) => {
        const url = (req.url ?? '').split('?')[0];
        if (url !== path) return next();
        if (req.method !== 'POST') return next();

        const contentType = req.headers['content-type'] ?? '';
        if (!contentType.toLowerCase().includes('application/json')) {
          sendJson(res, 415, {
            error: 'Unsupported Media Type: expected application/json',
          });
          return;
        }

        void (async () => {
          let parsed: unknown;
          try {
            parsed = await readJsonBody(req);
          } catch (err) {
            sendJson(res, 400, {
              error: 'Invalid RunAgentInput',
              issues: [(err as Error).message],
            });
            return;
          }

          const validated = validateRunAgentInput(parsed);
          if (!validated.ok) {
            sendJson(res, 400, { error: 'Invalid RunAgentInput', issues: validated.issues });
            return;
          }

          const encoder = new EventEncoder({ accept: 'text/event-stream' });
          res.statusCode = 200;
          res.setHeader('Content-Type', encoder.getContentType());
          res.setHeader('Cache-Control', 'no-cache');
          res.setHeader('Connection', 'keep-alive');
          res.flushHeaders?.();

          // A client that navigates away or aborts mid-run leaves the generator
          // running otherwise; each write would then throw on a dead socket.
          let closed = false;
          const markClosed = () => {
            closed = true;
          };
          res.on('close', markClosed);
          res.on('error', markClosed);

          try {
            for await (const event of runMockAgent({
              threadId: validated.threadId,
              runId: validated.runId,
              deltaDelayMs: options.deltaDelayMs,
            })) {
              if (closed || res.writableEnded) break;
              res.write(encodeEvent(encoder, event as AgUiEvent));
            }
          } catch (err) {
            if (!closed && !res.writableEnded) {
              // Surface failures in-band as RUN_ERROR: headers are already sent,
              // so an HTTP status can no longer carry the error.
              res.write(
                encodeEvent(encoder, {
                  type: 'RUN_ERROR',
                  message: (err as Error).message,
                }),
              );
            }
          } finally {
            if (!res.writableEnded) res.end();
          }
        })();
      };

      server.middlewares.use(handler);
    },
  };
}

export default aguiMockPlugin;
