/**
 * Vite dev-server middleware exposing a minimal MCP server over JSON-RPC 2.0.
 *
 * DEVELOPMENT ONLY. `configureServer` runs in the Vite dev server, not in a
 * production build. A deployed app needs a real MCP server behind this route.
 * The generated README states this; do not infer from the shape of the code
 * that it is deployable.
 *
 * Transport contract:
 *
 *   POST <path>
 *     Content-Type: application/json      body: JSON-RPC 2.0 request
 *   → 200
 *     Content-Type: application/json
 *     body: JSON-RPC 2.0 response
 *
 * WHY ONLY THREE METHODS. The `ui://` resource travels INSIDE the tool-call
 * result's `content` array as an EmbeddedResource — it is not fetched with
 * `resources/read`. Evidence: `@mcp-ui/client`'s own `isUIResource` predicate is
 * typed against `EmbeddedResource` from the MCP SDK, a content-array element
 * type. So `initialize` + `tools/list` + `tools/call` is a complete surface for
 * a host that is handed pre-fetched HTML.
 *
 * That holds only for a host configured with pre-fetched `html`. `AppRenderer`
 * fetches the resource itself when `html` is omitted, and would then call
 * `resources/read`. Every unhandled method is LOGGED and answered with a proper
 * JSON-RPC error rather than silently dropped, so a configuration that needs
 * more surfaces loudly instead of hanging.
 */

import type { Plugin, ViteDevServer } from 'vite';
import type { IncomingMessage, ServerResponse } from 'node:http';
import { readFileSync, existsSync } from 'node:fs';
import { join, basename } from 'node:path';

export interface McpMockOptions {
  /** Route the middleware answers. */
  path?: string;
  /** Directory holding the fixture corpus. */
  fixturesDir: string;
  /**
   * Pre-built A2UI guest page. Its `__A2UI_MESSAGES__` placeholder is replaced
   * with the fixture's `a2ui` array, producing a self-contained surface that
   * renders under `connect-src: none`. Build it with guest/build-guest.mjs.
   */
  guestTemplatePath?: string;
  /** Fixture served when the request names none. */
  defaultFixture?: string;
  /** Tool name advertised by `tools/list` and accepted by `tools/call`. */
  toolName?: string;
}

/** Methods this mock implements. Anything else is a logged JSON-RPC error. */
const IMPLEMENTED = ['initialize', 'notifications/initialized', 'tools/list', 'tools/call'] as const;

const PROTOCOL_VERSION = '2025-06-18';

interface JsonRpcRequest {
  jsonrpc?: string;
  id?: string | number | null;
  method?: string;
  params?: Record<string, unknown>;
}

function readBody(req: IncomingMessage): Promise<string> {
  return new Promise((resolve, reject) => {
    let data = '';
    req.on('data', (c) => (data += c));
    req.on('end', () => resolve(data));
    req.on('error', reject);
  });
}

function send(res: ServerResponse, status: number, payload: unknown): void {
  const body = JSON.stringify(payload);
  res.statusCode = status;
  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Content-Length', Buffer.byteLength(body));
  res.end(body);
}

const result = (id: JsonRpcRequest['id'], value: unknown) => ({ jsonrpc: '2.0', id: id ?? null, result: value });
const error = (id: JsonRpcRequest['id'], code: number, message: string) => ({
  jsonrpc: '2.0',
  id: id ?? null,
  error: { code, message },
});

/**
 * Resolve a fixture by BASENAME ONLY, inside the configured directory.
 * A dev-only mock is still not a file-read primitive: `../` must not escape.
 */
interface EmbeddedFixture {
  type: string;
  resource: { uri: string; mimeType: string; text: string; a2ui?: unknown[] };
}

function loadFixture(dir: string, name: string): EmbeddedFixture {
  const safe = basename(name);
  const path = join(dir, safe.endsWith('.json') ? safe : `${safe}.json`);
  if (!existsSync(path)) throw new Error(`fixture not found: ${safe}`);
  return JSON.parse(readFileSync(path, 'utf8')) as EmbeddedFixture;
}

export function mcpMockPlugin(options: McpMockOptions): Plugin {
  const route = options.path ?? '/api/mcp';
  const defaultFixture = options.defaultFixture ?? 'rawhtml-resource.json';
  const toolName = options.toolName ?? 'show_order_status';
  const seen = new Set<string>();

  return {
    name: 'mcp-ui-mock',
    configureServer(server: ViteDevServer) {
      server.middlewares.use(route, async (req, res, next) => {
        if (req.method !== 'POST') return next();

        let rpc: JsonRpcRequest;
        try {
          rpc = JSON.parse(await readBody(req));
        } catch {
          return send(res, 400, error(null, -32700, 'Parse error'));
        }

        if (rpc.jsonrpc !== '2.0') {
          return send(res, 400, error(rpc.id, -32600, 'jsonrpc must be "2.0"'));
        }

        const method = rpc.method ?? '';
        // Method log — this is what makes the empirical discovery step possible.
        if (!seen.has(method)) {
          seen.add(method);
          server.config.logger.info(
            `[mcp-mock] method: ${method}${(IMPLEMENTED as readonly string[]).includes(method) ? '' : '  <-- UNIMPLEMENTED'}`,
          );
        }

        // Fixture selection, so a host can be driven with a non-conformant
        // resource to prove the discrimination path.
        const url = new URL(req.url ?? '/', 'http://localhost');
        const fixture = url.searchParams.get('fixture') ?? process.env.MCP_UI_FIXTURE ?? defaultFixture;

        switch (method) {
          case 'initialize':
            return send(res, 200, result(rpc.id, {
              protocolVersion: PROTOCOL_VERSION,
              capabilities: { tools: {} },
              serverInfo: { name: 'mcp-ui-mock', version: '0.0.0-dev' },
            }));

          case 'notifications/initialized':
            return send(res, 200, result(rpc.id, {}));

          case 'tools/list':
            return send(res, 200, result(rpc.id, {
              tools: [{
                name: toolName,
                description: 'Development mock. Returns a ui:// resource embedded in the tool result.',
                inputSchema: { type: 'object', properties: {} },
              }],
            }));

          case 'tools/call': {
            let embedded: EmbeddedFixture;
            try {
              embedded = loadFixture(options.fixturesDir, fixture);
            } catch (err) {
              return send(res, 200, error(rpc.id, -32603, String(err)));
            }

            // Substitute the A2UI messages into the pre-built guest page, so the
            // resource carries a renderer AND its data with no network access.
            // A real server does the same substitution; the fixture's `text` is
            // only a placeholder for local development.
            if (options.guestTemplatePath && embedded?.resource?.a2ui) {
              try {
                const tpl = readFileSync(options.guestTemplatePath, 'utf8');
                embedded = {
                  ...embedded,
                  resource: {
                    ...embedded.resource,
                    text: tpl.replace(
                      '__A2UI_MESSAGES__',
                      JSON.stringify(embedded.resource.a2ui),
                    ),
                  },
                };
              } catch (err) {
                return send(res, 200, error(rpc.id, -32603,
                  `guest template unreadable: ${String(err)}`));
              }
            }
            // The ui:// resource rides in the content array alongside text.
            return send(res, 200, result(rpc.id, {
              content: [
                { type: 'text', text: 'Order status' },
                embedded,
              ],
            }));
          }

          default:
            return send(res, 200, error(rpc.id, -32601, `unknown method '${method}'`));
        }
      });
    },
  };
}

export default mcpMockPlugin;
