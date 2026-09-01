# Proposal: p7-04 — AG-UI client store

**Change ID**: p7-04-agui-client-store
**Phase**: phase-7-scaffold-ag-ui-host
**Status**: specified
**Origin**: assess G-2 (BLOCKING) · analyze Decision 1 (ADOPT)
**Depends on**: p7-02 (contract), p7-03 (something to connect to)

## Summary

A zustand store that runs an AG-UI agent via `@ag-ui/client` and reduces the
streamed event Observable into renderable state.

## Adopt `@ag-ui/client@0.0.59` (MIT)

Analyze rejected hand-rolling on a concrete ground: **`EventSource` cannot
POST**, and AG-UI requires POSTing `RunAgentInput` with
`Accept: text/event-stream`. A hand-rolled client needs `fetch` +
`ReadableStream` + manual frame parsing + partial-JSON buffering — the last of
which is why `@ag-ui/client` already depends on `untruncate-json`.

**Cost, stated plainly:** 0.0.59 is pre-1.0 with ten transitive dependencies,
including `rxjs@7.8.2` and protobuf tooling. Every app this scaffolder emits
inherits them. **Pin exact.**

## Store placement is mandated, not chosen

`references/scaffolds/state-architecture.md` already settles this:

| Rule | Line |
|---|---|
| `stores/**` owns realtime subscriptions | 20 |
| SSE/WebSocket state belongs in a store | 39 |
| Subscriptions coordinate through one `initRealtime()` at mount | 185 |
| "SSE listeners attached from anywhere except a store action" is a violation | 210 |

Components talk to hooks; hooks talk to stores; stores own I/O. The generated
code must not attach the stream in a `useEffect`.

## Reduction semantics — decided here

Analyze left this open, noting only that `@ag-ui/client` returns an rxjs
`Observable<BaseEvent>`. Concretely:

| Event | Reduction |
|---|---|
| `RUN_STARTED` | set `status: 'running'`, record `runId` |
| `TEXT_MESSAGE_START` | create a message keyed by `messageId`, empty content |
| `TEXT_MESSAGE_CONTENT` | **append** `delta` to that message's content |
| `TEXT_MESSAGE_END` | mark the message complete |
| `RUN_FINISHED` | set `status: 'idle'` |
| `RUN_ERROR` | set `status: 'error'`, surface `message` |

Append, not replace — `delta` is an increment. Messages are keyed by
`messageId` so interleaved messages do not corrupt one another. Events for an
unknown `messageId` are dropped with a warning rather than silently creating a
message, so ordering violations surface instead of hiding.

## Out of scope

Tool-call rendering (`TOOL_CALL_*`), `STATE_SNAPSHOT`/`STATE_DELTA` reduction,
reconnection and backpressure, multi-turn history. Each is a real follow-up; all
are unnecessary to prove the transport.
