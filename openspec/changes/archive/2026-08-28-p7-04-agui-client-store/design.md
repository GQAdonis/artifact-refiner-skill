# Design: p7-04 — AG-UI client store

## Dependency pin and its real cost

| Package | Version | Range | License |
|---|---|---|---|
| `@ag-ui/client` | `0.0.59` | **exact — no caret** | MIT |

Every app this scaffolder emits inherits the full transitive set:

| Dependency | Declared |
|---|---|
| `rxjs` | `7.8.1` |
| `zod` | `^3.22.4` |
| `uuid` | `^11.1.0` |
| `@types/uuid` | `^10.0.0` |
| `fast-json-patch` | `^3.1.1` |
| `untruncate-json` | `^0.0.1` |
| `compare-versions` | `^6.1.1` |
| `@ag-ui/core` · `@ag-ui/proto` · `@ag-ui/encoder` | `0.0.59` |

**Correction to the analyze stage:** it recorded `rxjs@7.8.2`. The package
declares **`7.8.1`** (exact, no caret). Immaterial to the decision, but the
number in `analysis.md` is wrong and this is the accurate one.

Two things worth noting for whoever revisits the adopt decision:

- `@types/uuid` is a **runtime** dependency, not a devDependency. That is a
  packaging mistake upstream; it ships types into production installs.
- `untruncate-json` is the concrete justification for adopting rather than
  hand-rolling: it repairs JSON split across network chunks, which is the
  failure mode a naive SSE reader hits intermittently and then only under load.

## API: the spec's assumption vs. the shipped surface

The spec described `runAgent(input)` constructing `HttpAgent` and subscribing to
"the returned rxjs Observable". The shipped `HttpAgent` exposes **both**:

| Method | Shape |
|---|---|
| `run(input)` | `Observable<BaseEvent>` — low level |
| `subscribe(subscriber)` + `runAgent()` | callback-based, `{ unsubscribe }` |

This store uses **`subscribe({ onEvent })` + `runAgent()`**, because it matches
the `initRealtime()` contract in `state-architecture.md:185`: one subscription
established at mount, runs dispatched against it afterwards. Subscribing per run
would create and tear down a subscription on every send — the pattern line 210
warns against.

The behaviour is identical; only the attachment point differs.

## Reduction semantics

Analyze left these open; they are decided here and unit-tested.

| Event | Reduction |
|---|---|
| `RUN_STARTED` | `status: 'running'`, clear error, record ids |
| `TEXT_MESSAGE_START` | create message keyed by `messageId`, empty content |
| `TEXT_MESSAGE_CONTENT` | **append** `delta` to that message |
| `TEXT_MESSAGE_END` | mark complete |
| `RUN_FINISHED` | `status: 'idle'` |
| `RUN_ERROR` | `status: 'error'`, surface `message` |
| everything else | ignored — valid protocol events this store does not render yet |

**Append, not replace.** `delta` is an increment. Replacing renders only the
final fragment while still producing plausible-looking output, so a test that
only checks the final text would pass. The unit suite asserts
`content === 'first second' && content !== 'second'` specifically to catch that.

**Unknown `messageId` is dropped, not synthesised.** Creating a message on
demand would hide a protocol ordering violation (content before its START)
behind output that looks fine. The store counts drops and warns instead.

`reduceEvent` is exported as a standalone pure function so it can be tested
without a store, a network, or a React tree.

## Verification note

`pnpm lint` (gate 4.6) has no harness here — this repo has no lint script and no
ESLint config, because the architectural config ships to *scaffolded apps*. The
properties those rules encode were verified directly instead: no `react` import
in the store, no `fetch`/`EventSource` in the hook or component, `new HttpAgent`
only in the store. The ESLint run happens in p7-05 gate 3.3.

Gate 4.5 — the phase's decisive criterion — ran the **real** store reducer
against the **real** p7-03 server: 35 render snapshots, 32 of which grew, with
monotonic prefix growth. A non-streaming implementation produces one snapshot.

## Path contract

`assets/scaffold/agui/{agent-store.ts,use-agent.ts,agent-panel.tsx}` are read by
name by p7-05 task 1.4. Renaming breaks p7-05 with no gate catching it.
