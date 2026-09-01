/**
 * Mock A2UI message source.
 *
 * Development only. Emits a scripted envelope sequence so the host can be
 * exercised without an agent, credentials, or a transport.
 *
 * The sequence is deliberately three messages rather than one `createSurface`:
 *
 *   createSurface     → an empty surface exists
 *   updateDataModel   → data arrives BEFORE the components that reference it
 *   updateComponents  → components resolve `{path: …}` against that data
 *
 * A single `createSurface` carrying everything would satisfy "the surface
 * renders" while proving nothing about progressive application. Ordering the
 * data model first is the stricter case: it only works if `updateDataModel`
 * merges into state rather than being applied to components that already exist.
 */

import type { A2uiMessage } from './surface-store';

export interface MockSourceOptions {
  /** Milliseconds between messages. 0 disables the delay (tests). */
  stepDelayMs?: number;
  surfaceId?: string;
  catalogId?: string;
}

const DEFAULT_STEP_DELAY_MS = 120;
const DEFAULT_SURFACE_ID = 'demo-surface';
const DEFAULT_CATALOG_ID = 'https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json';

const sleep = (ms: number): Promise<void> =>
  ms > 0 ? new Promise((resolve) => setTimeout(resolve, ms)) : Promise.resolve();

/** The scripted sequence, as plain data so tests can assert on it directly. */
export function mockMessages(options: MockSourceOptions = {}): A2uiMessage[] {
  const surfaceId = options.surfaceId ?? DEFAULT_SURFACE_ID;
  const catalogId = options.catalogId ?? DEFAULT_CATALOG_ID;

  return [
    {
      version: 'v1.0',
      createSurface: { surfaceId, catalogId, components: [], dataModel: {} },
    },
    {
      version: 'v1.0',
      updateDataModel: {
        surfaceId,
        dataModel: {
          title: 'Agent-rendered surface',
          body: 'These components arrived after the data they reference.',
          ctaLabel: 'Acknowledge',
        },
      },
    },
    {
      version: 'v1.0',
      updateComponents: {
        surfaceId,
        components: [
          { id: 'root', component: 'Column', children: ['heading', 'body', 'cta'] },
          // Button renders as a semantic <button>, so a DOM assertion can query
          // by ROLE rather than by text. A surface built only from Text renders
          // as styled <div>s — indistinguishable, to an accessibility tree, from
          // no UI at all.
          //
          // The basic catalog ships 18 components: AudioPlayer, Button, Card,
          // CheckBox, ChoicePicker, Column, DateTimeInput, Divider, Icon, Image,
          // List, Modal, Row, Slider, Tabs, Text, TextField, Video. There is no
          // `Heading` — an earlier draft used one and the renderer correctly
          // reported "Unknown component: Heading" rather than degrading silently.
          { id: 'heading', component: 'Text', text: { path: '/title' } },
          { id: 'body', component: 'Text', text: { path: '/body' } },
          {
            id: 'cta',
            component: 'Button',
            child: 'cta-label',
            action: { event: { name: 'acknowledge' } },
          },
          { id: 'cta-label', component: 'Text', text: { path: '/ctaLabel' } },
        ],
      },
    },
  ];
}

/** Yield the scripted sequence, optionally paced so streaming is observable. */
export async function* runMockSurfaceSource(
  options: MockSourceOptions = {},
): AsyncGenerator<A2uiMessage, void, undefined> {
  const delay = options.stepDelayMs ?? DEFAULT_STEP_DELAY_MS;
  for (const message of mockMessages(options)) {
    await sleep(delay);
    yield message;
  }
}
