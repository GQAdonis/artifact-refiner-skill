/**
 * MCP-UI surface.
 *
 * Reads the hook; never the store directly. Types and predicates come from
 * `use-mcp-ui.ts`, which re-exports them — importing from `stores/` violates
 * the architectural ESLint rule.
 *
 * ── Why AppRenderer, and why pre-fetched html ────────────────────────────────
 * `@mcp-ui/client@7.1.1` exports `AppRenderer` and `AppFrame`. It does NOT
 * export `UIResourceRenderer`, which upstream documentation still shows for
 * "legacy hosts" — see the vendored `index.d.ts`. Code written from those docs
 * fails at the import.
 *
 * `html` is passed explicitly. `AppRenderer` fetches the resource itself when
 * `html` is omitted, which would make `resources/read` part of the server's
 * required surface; the store already holds the resource from the tool result,
 * so handing it over keeps the mock at three JSON-RPC methods.
 *
 * ── Sandbox posture ──────────────────────────────────────────────────────────
 * The library default is `allow-scripts allow-same-origin allow-forms`. That
 * pairing lets framed content reach out of the sandbox, and upstream is only
 * safe because its proxy is a SEPARATE ORIGIN. This scaffold serves the proxy
 * same-origin to avoid a second process, so it must drop `allow-same-origin`
 * instead. Keeping the default here would be strictly less safe than upstream.
 */

import { useEffect, useRef } from 'react';
import { AppRenderer } from '@mcp-ui/client';
import { useMcpUi, isSafeLink } from '../hooks/use-mcp-ui';

/** Where the scaffolder places the sandbox proxy. Served by Vite from `public/`. */
const SANDBOX_PROXY_PATH = '/mcp-ui-sandbox-proxy.html';

/**
 * `allow-same-origin` is deliberately absent. See the posture note above.
 * `allow-forms` is kept so ordinary form controls in guest content work.
 */
const SANDBOX_PERMISSIONS = 'allow-scripts allow-forms';

export interface McpUiSurfaceProps {
  endpoint?: string;
  toolName?: string;
  /** Overrides which fixture the dev mock serves. Development only. */
  fixture?: string;
  autoLoad?: boolean;
}

export function McpUiSurface({
  endpoint = '/api/mcp',
  toolName = 'show_order_status',
  fixture,
  autoLoad = true,
}: McpUiSurfaceProps) {
  const { status, html, rejectedReason, error, callTool } = useMcpUi();
  const started = useRef(false);

  useEffect(() => {
    if (!autoLoad || started.current) return;
    started.current = true;
    void callTool({ endpoint, toolName, fixture });
  }, [autoLoad, callTool, endpoint, toolName, fixture]);

  if (status === 'loading' || status === 'idle') {
    return (
      <section aria-busy="true" className="p-6">
        <p>Loading MCP-UI resource…</p>
      </section>
    );
  }

  // Errors render in the DOM, not only the console: a browser gate asserting on
  // rendered text cannot see a console message, and a silent failure is the
  // one outcome worse than a loud one.
  if (status === 'error' || !html) {
    return (
      <section role="alert" className="p-6">
        <h2>MCP-UI resource not rendered</h2>
        <p>{rejectedReason ?? error ?? 'No renderable resource.'}</p>
      </section>
    );
  }

  return (
    <section className="p-6">
      <AppRenderer
        toolName={toolName}
        html={html}
        sandbox={{
          url: new URL(SANDBOX_PROXY_PATH, window.location.origin),
          permissions: SANDBOX_PERMISSIONS,
          // `McpUiResourceCsp` is a DOMAIN ALLOWLIST, not raw CSP directives:
          // connectDomains → connect-src, resourceDomains → img/script/style/
          // font/media-src, frameDomains → frame-src. Per its own docs, each
          // omitted field is the SECURE DEFAULT (no network, no nested frames).
          // An empty object is therefore the most restrictive posture, and
          // saying so beats leaving the prop off and letting a reader wonder.
          csp: {},
        }}
        onOpenLink={async ({ url }) => {
          if (!isSafeLink(url)) {
            // Refused, and said so. Dropping it silently would leave a guest
            // unable to distinguish "blocked" from "broken".
            console.warn(`[mcp-ui] refused link with unsupported scheme: ${url}`);
            return { isError: true };
          }
          window.open(url, '_blank', 'noopener,noreferrer');
          return { isError: false };
        }}
        onMessage={async () => ({ isError: false })}
        onError={(err) => {
          console.error('[mcp-ui] renderer error', err);
        }}
      />
    </section>
  );
}

export default McpUiSurface;
