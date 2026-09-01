/**
 * A2UI guest — the page that runs INSIDE the MCP-UI sandbox iframe.
 *
 * ── Why this is a separate bundle ────────────────────────────────────────────
 * The guest renders under `connect-src: none` in an opaque-origin iframe loaded
 * via `srcdoc`. It cannot fetch anything — not a script, not a stylesheet. So
 * the renderer must be INLINED into the page the MCP server returns.
 *
 * That forces a build step: this file is bundled to a single self-contained
 * IIFE, and the scaffolder injects it into the `text` field of a ui:// resource
 * alongside the A2UI messages.
 *
 * ── Why React, when the sandbox makes it expensive ───────────────────────────
 * `@a2ui/web_core` is explicitly "building blocks for building web-based A2UI
 * renderers" — message processing, data model, catalog. It does NOT render DOM
 * (verified: nothing under src/ touches `document` outside a stylesheet
 * constant). `@a2ui/react` is the renderer. There is no lighter option that
 * still guarantees the SAME output as the AG-UI web host, and identical output
 * is the whole point of routing MCP-UI through A2UI.
 *
 * ── Parity ───────────────────────────────────────────────────────────────────
 * This uses the same `MessageProcessor` + `basicCatalog` + `A2uiSurface` triple
 * as `assets/scaffold/a2ui/a2ui-surface.tsx`. Changing the renderer on one
 * surface without the other reintroduces exactly the drift this design removes.
 */

import { StrictMode, useEffect, useState } from 'react';
import { createRoot } from 'react-dom/client';
import { MessageProcessor } from '@a2ui/web_core/v0_9';
import { A2uiSurface as UpstreamSurface, basicCatalog } from '@a2ui/react/v0_9';

type Processor = InstanceType<typeof MessageProcessor>;

/** The host injects the A2UI messages into this script tag. */
function readMessages(): unknown[] {
  const el = document.getElementById('a2ui-messages');
  if (!el?.textContent) return [];
  try {
    const parsed: unknown = JSON.parse(el.textContent);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

interface V1CreateSurface {
  surfaceId: string;
  catalogId?: string;
  components?: unknown[];
  dataModel?: unknown;
}

/**
 * Translate our validated **v1.0** documents into what `@a2ui/react@0.10.2`
 * (protocol **v0.9**) actually accepts. Two differences, both structural:
 *
 *   1. CATALOG ID — v1.0 documents name the v1.0 catalog URL; the renderer
 *      registers only its own v0.9 catalog and raises "Catalog not found" for
 *      anything else. Retarget to `basicCatalog.id`.
 *
 *   2. MESSAGE SPLIT — v1.0 carries `components` and `dataModel` INSIDE
 *      `createSurface`. v0.9 expects three separate messages. Without the
 *      split the surface is created but never populated, and the renderer sits
 *      at "[Loading root...]" forever — a silent-looking failure that is really
 *      a protocol mismatch.
 *
 * This mirrors `toSdkMessages()` in the AG-UI web host
 * (assets/scaffold/a2ui/a2ui-surface.tsx) deliberately. Both surfaces translate
 * at ONE boundary, the same way, so the same v1.0 document renders identically
 * on both. Diverging here is precisely how the surfaces drift apart.
 */
function toV09Messages(messages: unknown[]): unknown[] {
  const out: unknown[] = [];
  for (const m of messages) {
    const msg = m as { version?: string; createSurface?: V1CreateSurface };
    if (!msg?.createSurface) {
      out.push(m);
      continue;
    }
    const { surfaceId, components, dataModel } = msg.createSurface;
    out.push({ version: 'v0.9', createSurface: { surfaceId, catalogId: basicCatalog.id } });
    if (Array.isArray(components) && components.length > 0) {
      out.push({ version: 'v0.9', updateComponents: { surfaceId, components } });
    }
    if (dataModel !== undefined) {
      out.push({ version: 'v0.9', updateDataModel: { surfaceId, path: '/', value: dataModel } });
    }
  }
  return out;
}

function Guest() {
  const [processor] = useState<Processor>(
    () => new MessageProcessor([basicCatalog]) as Processor,
  );
  const [surfaces, setSurfaces] = useState<unknown[]>([]);
  const [failure, setFailure] = useState<string | null>(null);

  useEffect(() => {
    const messages = readMessages();
    if (messages.length === 0) {
      setFailure('No A2UI messages were embedded in this resource.');
      return;
    }
    try {
      // The renderer is FED messages rather than fetching them. That is what
      // lets an A2UI surface run under `connect-src: none`.
      //
      // v1.0 → v0.9 translation happens in toV09Messages(); see its docstring.
      processor.processMessages(
        toV09Messages(messages) as unknown as Parameters<Processor['processMessages']>[0],
      );
      setSurfaces(Array.from(processor.model.surfacesMap.values()));
    } catch (err) {
      // Loud, in the DOM. A silent failure inside a sandboxed frame is
      // effectively invisible — the host cannot see the guest's console.
      setFailure(err instanceof Error ? err.message : String(err));
    }
  }, [processor]);

  useEffect(() => {
    const sync = () => setSurfaces(Array.from(processor.model.surfacesMap.values()));
    const created = processor.onSurfaceCreated(sync);
    const deleted = processor.onSurfaceDeleted(sync);
    return () => {
      created.unsubscribe();
      deleted.unsubscribe();
    };
  }, [processor]);

  useEffect(() => {
    // Lifecycle handshake — the host waits on this.
    window.parent.postMessage({ type: 'ui-lifecycle-iframe-ready' }, '*');
  }, []);

  if (failure) {
    return (
      <section role="alert">
        <h2>A2UI surface failed to render</h2>
        <p>{failure}</p>
      </section>
    );
  }

  return (
    <section aria-label="Agent surface">
      {surfaces.map((surface, i) => (
        <UpstreamSurface
          key={i}
          surface={surface as Parameters<typeof UpstreamSurface>[0]['surface']}
        />
      ))}
    </section>
  );
}

// This file is a standalone ENTRY POINT bundled into a self-contained page —
// it is never imported by the host app, so Fast Refresh does not apply.
// eslint-disable-next-line react-refresh/only-export-components
const root = document.getElementById('a2ui-root');
if (root) createRoot(root).render(<StrictMode><Guest /></StrictMode>);
