# Proposal: p7-03 — AG-UI server surface (Node, mock agent)

**Change ID**: p7-03-agui-server-surface
**Phase**: phase-7-scaffold-ag-ui-host
**Status**: specified
**Origin**: assess G-1 (BLOCKING) · analyze Decision 2
**Depends on**: p7-02 (the event contract must be correct first)

## Summary

Build an AG-UI-conformant SSE endpoint in Node, backed by a mock agent, that the
scaffolded host connects to.

## Decisions this change makes

Analyze resolved *where* (Node, not Axum, not openai-proxy) but left two
questions open. This change closes both, because a spec that inherits them
unresolved cannot be executed.

**Q1 — mock agent vs real LLM: MOCK.** A mock emitter proves the transport and
satisfies every verification criterion. Wiring a real LLM converts this into an
inference-integration phase with its own credential handling, streaming
translation, and failure modes. Out of scope; revisit as a later phase.

**Q2 — Node hosting mechanism: Vite dev-server middleware plugin.** This was
carried as an *unresolved* WARNING out of analyze (revision cap reached), so it
is decided here with the reasoning stated:

| Option | Verdict |
|---|---|
| **Vite middleware plugin** | **Chosen** — no second process, no extra runtime dep, `pnpm dev` alone runs the whole demo |
| Standalone Express/Hono/Fastify | Rejected — adds a runtime dependency and a second process; the generated app stops being self-contained |
| Bare Node `http` handler | Rejected — needs its own port and lifecycle wiring, reintroducing the second-process problem |

The self-containment argument is the same one that disqualified openai-proxy in
analyze: a scaffolded app must stand up on its own.

**Consequence, stated honestly:** a Vite middleware plugin serves the dev server
only. A production deployment would need this route reimplemented behind the
app's real backend. That is acceptable because the phase goal is a *scaffolder
demonstrating the protocol*, not a production agent host — but the generated
README must say so plainly rather than implying production readiness.

## Contract

```
POST <route>
  Content-Type: application/json      body: RunAgentInput
  Accept: text/event-stream
→ 200
  Content-Type: text/event-stream
  Cache-Control: no-cache
  Connection: keep-alive
  body: `data: {…}\n\n` frames, one JSON BaseEvent each
```

Emission order, per upstream `ValidateSequence`:

```
RUN_STARTED → TEXT_MESSAGE_START → TEXT_MESSAGE_CONTENT×N
            → TEXT_MESSAGE_END → RUN_FINISHED
```

## Adopt

`@ag-ui/encoder@0.0.59` (MIT) — `encodeSSE` is exactly
`` `data: ${JSON.stringify(event)}\n\n` ``, and `getContentType()` handles
negotiation. Using it keeps client and server tracking the same upstream
contract. **Pin exact** (pre-1.0).

## Out of scope

Protobuf transport (`AGUI_MEDIA_TYPE`), authentication, multi-turn thread
persistence, real LLM backing, production hosting.
