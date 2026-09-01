/**
 * A2UI surface renderer.
 *
 * Renders through `@a2ui/react` rather than a hand-written component switch.
 * That choice is the point of this change: the repository's previous A2UI
 * renderer was a ~30-line `switch` handling three lowercase component names
 * that could never match its own schema, and it shipped for a whole phase
 * without ever rendering a conformant spec. Upstream ships and maintains the
 * component set; reimplementing it is how that failure recurs.
 *
 * Presentational: talks to the `useSurface` hook and nothing else.
 *
 * ── Protocol version ─────────────────────────────────────────────────────────
 * `@a2ui/react@0.10.2` implements protocol **v0.9** and exposes its renderer at
 * the `/v0_9` subpath. `MessageProcessor` lives in `@a2ui/web_core/v0_9`, which
 * is a transitive dependency of `@a2ui/react` and NOT re-exported by it — a
 * scaffolded app must declare `@a2ui/web_core` explicitly (see p8-05).
 *
 * The store reduces all six operations the validated schema admits; only
 * createSurface / updateComponents / updateDataModel reach this renderer,
 * because they are the three the pinned SDK implements.
 */

import { useEffect, useMemo, useState, type ReactElement } from 'react';
import {
  MessageProcessor,
  type A2uiMessage as SdkMessage,
  type ComponentApi,
} from '@a2ui/web_core/v0_9';
import { A2uiSurface as UpstreamSurface, basicCatalog } from '@a2ui/react/v0_9';
import { useSurface, type A2uiMessage } from '../hooks/use-surface';

/** Operations the pinned v0.9 renderer does not implement. */
const RENDERABLE_OPS = ['createSurface', 'updateComponents', 'updateDataModel'] as const;

/**
 * Translate store state into the message sequence the SDK's processor expects.
 *
 * Two shape differences between the validated schema (v1.0) and the SDK (v0.9)
 * are handled here, at the single boundary where they matter:
 *
 *   1. `version` — the schema declares "v1.0"; the SDK expects "v0.9".
 *   2. `updateDataModel` — the schema carries `{surfaceId, dataModel}`; the SDK
 *      expects `{surfaceId, path, value}`.
 *
 * Doing this in one function keeps the divergence visible instead of smeared
 * through the store, which stays faithful to the contract p8-02 validates.
 */
// `MessageProcessor<T extends ComponentApi>` is generic over the catalog's
// component implementation, and its `processMessages` takes `A2uiMessage[]` —
// the SDK's v0.9 shape, not our v1.0 store shape. Both are exported by name
// from the v0_9 entrypoint, so no structural inference is needed.
type Processor = MessageProcessor<ComponentApi>;

function toSdkMessages(
  surfaceId: string,
  catalogId: string,
  components: unknown[],
  dataModel: Record<string, unknown>,
): SdkMessage[] {
  // `version` is the SDK's literal union ("v0.9" | "v0.9.1"), not our schema's
  // "v1.0". Deriving the parameter type from processMessages itself means a
  // future SDK version change surfaces here as a type error rather than as a
  // runtime message the processor silently ignores.
  return [
    { version: 'v0.9', createSurface: { surfaceId, catalogId } },
    { version: 'v0.9', updateComponents: { surfaceId, components } },
    { version: 'v0.9', updateDataModel: { surfaceId, path: '/', value: dataModel } },
  ] as unknown as SdkMessage[];
}

export function A2uiSurface(props?: {
  source?: AsyncIterable<A2uiMessage>;
}): ReactElement {
  const { surfaceId, components, dataModel, status, error, unrenderableOps } =
    useSurface({ source: props?.source });

  const [processor] = useState<Processor>(
    () => new MessageProcessor([basicCatalog]) as Processor,
  );
  const [surfaces, setSurfaces] = useState<unknown[]>([]);

  // Feed the processor whenever the reduced surface changes. The processor owns
  // catalog validation, so an unknown component raises the renderer's own error
  // rather than degrading to a JSON dump — the failure mode of the old switch.
  useEffect(() => {
    if (!surfaceId || components.length === 0) return;
    processor.processMessages(
      toSdkMessages(surfaceId, basicCatalog.id, components, dataModel),
    );
    setSurfaces(Array.from(processor.model.surfacesMap.values()));
  }, [processor, surfaceId, components, dataModel]);

  useEffect(() => {
    const sync = () => setSurfaces(Array.from(processor.model.surfacesMap.values()));
    const created = processor.onSurfaceCreated(sync);
    const deleted = processor.onSurfaceDeleted(sync);
    return () => {
      created.unsubscribe();
      deleted.unsubscribe();
    };
  }, [processor]);

  const skipped = useMemo(
    () => unrenderableOps.filter((op) => !RENDERABLE_OPS.includes(op as never)),
    [unrenderableOps],
  );

  return (
    <section className="a2ui-surface" aria-label="Agent surface">
      {status === 'error' && error ? (
        <p className="a2ui-surface__error" role="alert">
          {error}
        </p>
      ) : null}

      {surfaces.length === 0 ? (
        <p className="a2ui-surface__waiting">Waiting for agent…</p>
      ) : (
        surfaces.map((surface, i) => (
          <UpstreamSurface key={String(i)} surface={surface as never} />
        ))
      )}

      {skipped.length > 0 ? (
        <p className="a2ui-surface__note" role="status">
          {skipped.length} message(s) reduced but not rendered: {skipped.join(', ')}.
          The pinned renderer implements protocol v0.9 and does not support these
          operations.
        </p>
      ) : null}
    </section>
  );
}

export default A2uiSurface;
