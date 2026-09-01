# Assessment — phase-7-scaffold-ag-ui-host

- **Phase:** `phase-7-scaffold-ag-ui-host`
- **Stage:** assess
- **Date:** 2026-08-28
- **Origin:** Deferred since phase-2; listed as an alternate in four prior reflections
- **Model preflight:** `ok` — judge `k3`, critic `MiniMax-M3`, generator
  `kbd-frontier` (2 distinct dispatchable models)

---

## Phase Goal

Ship a scaffolder that emits a **running AG-UI host application** — a React app
that connects to an AG-UI agent backend over SSE and renders streamed events.

Definition of record (`.kbd-orchestrator/phases/phase-2-scaffold-react-vite/plan.md:65`):

> **phase-7-scaffold-ag-ui-host** — React scaffold + AG-UI client + openai-proxy
> AG-UI surface wiring.

Three components. Only the first exists.

---

## Method

Claims inherited from prior reflections were treated as hypotheses and tested,
because one of them turned out to be false (F-1). Protocol facts were taken from
the AG-UI upstream docs via Context7 rather than from memory, because the local
schema predates the current protocol (F-4).

---

## Findings

### F-1 — BLOCKING: the "openai-proxy AG-UI surface" does not exist

The phase-4 reflection (`.kbd-orchestrator/phases/phase-4-scaffold-tauri-desktop/reflection.md:144`) says
phase-7 can:

> "Leverage openai-proxy's AG-UI SSE surface (already running via phase-1b)"

**This is false.** Verified two ways:

1. **What phase-1b actually shipped.** Its original `progress.json` `scope_note`
   (recovered from `git show HEAD:` — see F-6) reads:

   > "Configuration-and-discovery layer only. No PMPO loop refactor. No
   > openai-proxy vendoring. Doc/schema/data triplet + health-probe +
   > integration doc."

   A health probe and an integration doc. No AG-UI surface was in scope.

2. **Live probe of the running proxy.** It is up (`/health` → `{"status":"ok"}`),
   and every AG-UI endpoint candidate 404s:

   | Path | Status |
   |---|---|
   | `/v1/agui` | 404 |
   | `/agui` | 404 |
   | `/v1/ag-ui` | 404 |
   | `/ag-ui` | 404 |

The proxy is a plain OpenAI-compatible chat endpoint. Phase-7 must **build** the
AG-UI server surface, not wire to an existing one. This is the single largest
scope item and it was invisible in every prior estimate.

### F-2 — The AG-UI *domain* already shipped and is a different thing

`direct:ag-ui` shipped via PR #2 (`references/domain/ag-ui.md`,
`ag-ui-spec.schema.json`, `scripts/normalize-agui.mjs`, two examples). That work
refines **static spec documents**. The spike was explicit about the boundary
(`references/domain/ag-ui-spike.md`):

> the refiner processes the *spec document* (a static authored artifact), not
> live event streams

Phase-7 is the *other half* — the runtime host that consumes live events. The
name similarity invites the assumption that phase-7 is mostly done. It is not:
no overlap in deliverables. The shipped schema is still useful as the **contract**
a generated host is scaffolded against.

### F-3 — The React substrate is genuinely ready (the one inherited claim that holds)

`scripts/scaffold-react-vite.sh` (1160 lines) already installs zustand+immer and
emits `src/app/stores/`. More importantly, the state architecture *already
mandates the exact shape an SSE host needs*
(`references/scaffolds/state-architecture.md`):

- line 20 — `stores/**` owns "realtime subscriptions"
- line 39 — state participating in "SSE, WebSocket subscriptions" belongs in a store
- line 185 — subscriptions coordinate through one `initRealtime()` at mount
- line 210 — "SSE listeners attached from anywhere except a store action" is a
  documented violation

**Precisely what this settles, and what it does not.** These four bullets are
*placement* rules: they say SSE subscriptions belong in a store action reached
via `initRealtime()`, and that attaching them anywhere else is a violation. That
is genuinely useful — it removes the "where does streaming live" question and
gives criterion 5 an objective test.

It does **not** answer the *semantic* design questions, which remain open for
plan:

- How a `TEXT_MESSAGE_CONTENT` delta stream reduces into store state (append to
  a buffer keyed by `messageId`? replace? how are out-of-order frames handled?)
- Whether `STATE_SNAPSHOT` / `STATE_DELTA` map onto the zustand store directly
  or into a separate agent-state slice
- Reconnection, backpressure, and partial-run recovery
- How an aborted run (`AbortController` in the upstream client) unwinds
  store state

So the phase-4 reflection's worry — "raises new design questions about how
stores integrate with streaming events" — is **partly** relieved, not answered.
Placement is settled; reduction semantics are not. This lowers phase-7 risk
somewhat, but the correction matters: an earlier draft of this assessment
claimed the question was fully answered, which would have let plan skip real
design work.

### F-3b — G-2 evidence: no AG-UI client of any kind exists

Reproducible, entirely local:

```
grep -rniE "ag-?ui|EventSource|text/event-stream|RUN_STARTED|RunAgentInput" \
  scripts/scaffold-react-vite.sh scripts/scaffold-react-vite-tauri.sh \
  scripts/scaffold-react-vite-axum.sh assets/templates/sample-app.tsx
```

Returns **no matches**. `grep -rn "EventSource" assets/ scripts/` likewise
returns nothing. The pattern set deliberately covers a hand-rolled client
(`EventSource`, raw `text/event-stream`, event-kind literals) as well as the
`@ag-ui` packages, so G-2 is not merely "no dependency declared" — no client
implementation exists in any form.

### F-4 — WARNING: the local event-kind enum is behind the current protocol

`ag-ui-spec.schema.json` `/definitions/agEventKind` declares 14 kinds
(local, verifiable): `RUN_STARTED`, `RUN_FINISHED`, `RUN_ERROR`,
`TEXT_MESSAGE_START/CONTENT/END/CHUNK`, `TOOL_CALL_START/ARGS_DELTA/END`,
`STATE_SNAPSHOT`, `STATE_DELTA`, `MESSAGES_SNAPSHOT`, `CUSTOM`.

The upstream AWS Strands integration endpoint lists `STEP_STARTED` and
`STEP_FINISHED` among supported types. **That upstream claim carries the same
external provenance as F-5** — it comes from Context7
(`/ag-ui-protocol/ag-ui`), not from any file in this repo, and is not
verifiable from the packet alone. Re-verify by re-querying Context7 before
acting on it.

What *is* locally verifiable: the two kinds are absent from our schema —
`grep -c "STEP_STARTED\|STEP_FINISHED" references/schemas/ag-ui-spec.schema.json`
returns **0**.

A host scaffolded strictly against the local enum would reject valid upstream
events. This is a small fix but must land *before* the host is generated, not
after.

### F-5 — The transport contract is now known and is narrow

**Provenance — these paths are NOT in this repository.** They are files in the
upstream `ag-ui-protocol/ag-ui` GitHub repository, retrieved this session via the
Context7 documentation MCP (library id `/ag-ui-protocol/ag-ui`). They will not
resolve against this repo's file tree and are not expected to. They are cited as
*external protocol authority*, not as local evidence. Anyone re-verifying should
re-query Context7 or fetch the upstream repo directly:

- `sdks/typescript/packages/client/src/agent/http.ts` — `HttpAgent.requestInit`
- `sdks/typescript/packages/encoder/src/encoder.ts` — `EventEncoder.encodeSSE`
- `integrations/aws-strands/typescript/src/endpoint.ts` — canonical server route
- `sdks/community/c++/tests/mock_server/README.md` — worked SSE frame example

I used upstream rather than my own knowledge because this protocol is young and
moving; F-4 below is a case where the local artifact had already fallen behind.

With that provenance stated, the server contract a generated host must satisfy:

- `POST` a `RunAgentInput` JSON body
- request carries `Accept: text/event-stream`
- response sets `Content-Type: text/event-stream`, `Cache-Control: no-cache`,
  `Connection: keep-alive`
- body is `data: {...}\n\n` frames, one JSON `BaseEvent` per frame
- a run is bracketed `RUN_STARTED` … `RUN_FINISHED`

This is implementable without adopting `@ag-ui/*` packages (none are currently
dependencies — grep found no `@ag-ui` in `package.json`). Whether to adopt them
is a real build-vs-adopt decision and belongs to the analyze/plan stage, not here.

### F-6 — BLOCKING (process, not code): the migration destroyed phase records

Last session's `prometheus kbd migrate --apply` **overwrote** every phase
`progress.json` with runtime-derived counters. Compare phase-1b:

| | Keys |
|---|---|
| Before (`git show HEAD:`) | 19, incl. `scope_note`, `live_verification`, `acceptance_gates_all_pass`, `port_correction` |
| After (working tree) | bare counters + `migrationStatus: legacy-read-only` |

The narrative record — what each phase actually did and verified — was replaced
by `6/6`. I needed `scope_note` to disprove F-1 and had to recover it from git.

**Not yet lost.** Nothing was committed, so `git show HEAD:<path>` holds every
original. But a `git add -A` would make the loss permanent and silent.

Related: the runtime never registered phase-3c despite returning
`committedLocally: true` for seven commands (`kbd audit` mentions it 0 times),
and `position.json` is stale — its cursor points at `phase-0-unblock › probe`, a
throwaway stage. **Do not trust the canonical runtime as the record for this
phase** until that is understood.

---

## Gap Report

| ID | Gap | Severity | Evidence |
|---|---|---|---|
| G-1 | No AG-UI server surface exists; must be built | BLOCKING | F-1, 4×404 |
| G-2 | No AG-UI client in the scaffolder — packaged **or** hand-rolled | BLOCKING | see command below |
| G-3 | No `scaffold-react-vite-agui.sh` | BLOCKING | only 3 scaffolders exist |
| G-4 | Event-kind enum missing `STEP_STARTED`/`STEP_FINISHED` | WARNING | F-4, grep 0 |
| G-5 | Build-vs-adopt for `@ag-ui/*` undecided | WARNING | F-5 |
| G-6 | Phase records replaced by counters; recoverable only from git | BLOCKING (process) | F-6 |
| G-7 | Runtime silently drops writes; phase-3c absent from audit | WARNING (process) | F-6 |

---

## Scope Recommendation

**Do G-6 first, before any phase-7 code.** Restore the phase `progress.json`
files from git, or explicitly decide the counters supersede them. Every
subsequent phase reads these records; losing them costs more than this phase is
worth, and the loss becomes permanent on the next `git add -A`.

**Then, in scope for phase-7:**

- G-4 — extend the event-kind enum (small; must precede host generation)
- G-1 — an AG-UI server surface implementing the F-5 contract
- G-2 — client-side SSE consumption in a zustand store per
  `state-architecture.md:185` (`initRealtime()` shape)
- G-3 — `scaffold-react-vite-agui.sh` following the established scaffolder pattern

**Out of scope:**

- G-7 (runtime write reliability) — its own investigation; do not fold in
- Changes to the shipped `direct:ag-ui` refiner domain — F-2 shows no overlap
- Protobuf transport (`AGUI_MEDIA_TYPE`) — SSE only for v1

---

## Open Questions for analyze/plan

1. **Adopt `@ag-ui/client` + `@ag-ui/encoder`, or hand-roll?** The SSE framing is
   ~10 lines; the value of the packages is `RunAgentInput` Zod validation and
   protobuf negotiation. Adopting adds dependencies to every scaffolded app.
   This is the phase's main build-vs-adopt decision — analyze should evaluate it,
   not assume it.
2. **Where does the server surface live?** Options: extend openai-proxy (outside
   this repo), a new Axum route in `scaffold-react-vite-axum.sh` (431 lines,
   already exists), or a Node dev-server route. The Axum scaffolder is the
   closest existing home.
3. **What agent backs it?** A mock event emitter is enough to prove the transport
   and keeps the phase bounded. Wiring a real LLM turns this into an
   inference-integration phase.

---

## Verification Criteria (for the plan stage)

- [ ] `scaffold-react-vite-agui.sh <name>` produces an app where `pnpm build` exits 0
- [ ] The generated server responds to `POST` + `Accept: text/event-stream` with
      `Content-Type: text/event-stream`
- [ ] A run emits `RUN_STARTED` … `RUN_FINISHED` as `data: {...}\n\n` frames
- [ ] Streamed `TEXT_MESSAGE_CONTENT` deltas render incrementally in the browser
- [ ] SSE subscription lives in a store action, not a hook or component
      (`state-architecture.md:210`)
- [ ] `pnpm lint` passes, including the architectural ESLint config

Criterion 4 is the one that actually proves the phase: everything else can pass
against a non-streaming stub.

---

## Adversarial Review

Two rounds, true cross-model isolation both times
(`rest-gateway:http://localhost:8181/v1`, `cross_model_check: verified-distinct`,
producer `claude-opus-5` ≠ judge `kbd-judge`). The gateway credential that
returned 401 during phase-3c is working again, so this review is a stronger
guarantee than that one.

**Round 1 — BLOCK** (1 CRITICAL, 3 WARNING). The CRITICAL was correct: F-5
cited upstream file paths as if they were local evidence, and `cited_paths`
reported them MISSING. A reader could not tell whether I had invented the
contract. Fixed by stating provenance explicitly (Context7,
`/ag-ui-protocol/ag-ui`) and marking the paths as external-not-local.

Round 1 also corrected two real overstatements:

| Finding | Disposition |
|---|---|
| F-3 claimed the state architecture "already answers" streaming design | **Fixed** — it settles *placement* only; reduction semantics, reconnection, and abort handling remain open. The original wording would have let plan skip real design work. |
| G-2 evidence ruled out only `@ag-ui` packages, not a hand-rolled client | **Fixed** — F-3b adds a grep covering `EventSource`, `text/event-stream`, and event-kind literals. Still zero matches, so the gap holds on stronger evidence. |

**Round 2 — PASS** (0 CRITICAL, 2 WARNING). Both remaining warnings carried
into the handoff:

- Phase-record paths lacked the `.kbd-orchestrator/` prefix — **fixed** after
  round 2.
- G-4 promotes an externally-sourced protocol delta into a local gap. **Accepted
  as-is with the caveat stated in F-4.** The local half (our enum lacks both
  kinds) is verifiable; the upstream half must be re-confirmed via Context7 at
  plan time before any schema edit. Flagged rather than silently trusted.

## Estimate

**Not a one-session phase.** Prior reflections called it "more ambitious"
without sizing it; F-1 is why. Rough shape:

| Item | Size |
|---|---|
| G-6 record restoration | small |
| G-4 enum extension | small |
| G-1 server surface | **medium-large** — net-new, no substrate |
| G-2 client store | medium |
| G-3 scaffolder | medium |

Comparable phases (phase-4 at 15 changes, phase-2 at 9) are the right reference
class. Expect **8–14 changes across 2–3 sessions**, with G-1 carrying the risk.
