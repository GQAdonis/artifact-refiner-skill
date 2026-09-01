# Analysis — phase-7-scaffold-ag-ui-host

- **Phase:** `phase-7-scaffold-ag-ui-host`
- **Stage:** analyze
- **Date:** 2026-08-28
- **Mode:** stack-specified (React 19 + Vite + TS; server surface undecided at entry)
- **Input:** `handoffs/assess.json` — 4 open questions, 2 of them research questions

---

## Budget

| Tier | Used | Cap | Notes |
|---|---|---|---|
| T1 `gh search` | 2 | 8 | repo search + `gh repo view` |
| T2 Context7 | 3 | 8 | resolve + 2 doc queries |
| T3 registries | 6 | 8 | npm ×4, CopilotKit, crates.io |
| T4 firecrawl/tavily | 0 | 8 | **not needed** — T1–T3 decisive |

Within budget on every tier. No partial-confidence findings.

---

## Carried forward — G-6 remains BLOCKING and unaddressed

The assess handoff recorded G-6 as a **blocking precondition**: last session's
`prometheus kbd migrate --apply` overwrote every phase `progress.json` with
runtime-derived counters, replacing narrative records (`scope_note`,
`live_verification`, acceptance notes) with bare `N/N`. phase-1b went from 19
keys to counters.

**Analyze does not resolve it, and analyze cannot resolve it** — it is a record
restoration decision, not a research question. It is restated here because an
earlier draft of this document omitted it entirely, which would have let plan
proceed to code work with the precondition silently dropped.

Status, re-verified this session:

- **Still recoverable.** Nothing is committed; `git show HEAD:<path>` holds every
  original.
- **Still one command from permanent.** A `git add -A` makes the loss silent and
  irreversible.
- **Still required before phase-7 code work**, because every downstream phase
  reads these records — and this very analysis depended on phase-1b's recovered
  `scope_note` to disprove the "AG-UI surface already exists" claim.

**Plan stage requirement:** either restore the phase `progress.json` files from
git HEAD, or record an explicit decision that the runtime counters supersede the
narrative records. Do one or the other before the first phase-7 code change. Do
not let it lapse a third time.

Related but separate: G-7 (the runtime returns `committedLocally: true` for
writes that never reach the audit log) reproduced again during this phase's stage
recording. Not blocking for phase-7 work; blocking for trusting the runtime as
the record.

---

## Landscape

AG-UI is a real, actively-maintained protocol, not a speculative one:

| Signal | Value |
|---|---|
| Upstream repo | `ag-ui-protocol/ag-ui` |
| Stars | 15,595 |
| Last push | 2026-08-27 (**yesterday**) |
| npm releases | 74 |
| Latest publish | 2026-08-27 — same day as this analysis |
| First publish | 2025-04-30 |
| License | MIT (confirmed via npm **and** `gh api .../license`) |

The GitHub API initially reported `licenseInfo: null`, which would have been an
adopt blocker. It is an API artifact — the repo has an MIT `LICENSE` and every
package declares `"license": "MIT"`. Worth recording so the next reader does not
re-raise it.

T1 repo search surfaced only unrelated hobby projects (0 stars each). There is no
competing AG-UI host scaffolder to adopt or fork. This phase is genuinely
net-new work, confirming the assessment.

---

## Decision 1 — Client: **ADOPT `@ag-ui/client`**

The assessment framed this as roughly balanced: "SSE framing is ~10 lines; the
packages buy `RunAgentInput` Zod validation and protobuf negotiation."

**That framing was wrong, and T2 shows why.** The ~10 lines describes *encoding a
frame on the server*. The client side is a different problem:

> `POST` a `RunAgentInput` JSON body with `Accept: text/event-stream`
> — `sdks/typescript/packages/client/src/agent/http.ts`

**`EventSource` cannot issue a POST.** The browser SSE API is GET-only. A
hand-rolled client therefore needs `fetch` + `ReadableStream` + manual
`data: …\n\n` framing + partial-chunk buffering. That is not ten lines, and the
subtle part — a JSON frame split across two network chunks — is exactly what
`untruncate-json` (already a dependency of `@ag-ui/client`) exists to solve.

Adopting also brings run cancellation (`AbortController`) and the `RunAgentInput`
Zod schema, both of which a scaffolded app would otherwise fake.

**The real cost, stated plainly:** `@ag-ui/client` is **0.0.59** — pre-1.0, with
ten transitive dependencies including `rxjs@7.8.1` and protobuf tooling. Every
app this scaffolder emits inherits them. Pre-1.0 means breaking changes can land
in a patch bump, so the plan stage should pin exact versions rather than use a
caret range.

I am recommending adoption *despite* pre-1.0 status because the alternative is
reimplementing stream-framing edge cases, and the package is demonstrably alive
(published the same day as this analysis).

**`@copilotkit/react-core` (1.69.3, MIT, published 2026-08-27) — DEFER.** Far
more mature, and the reference AG-UI frontend. But it is a full agent-UI
framework with opinionated components that would collide with this repo's own
scaffolder conventions and `state-architecture.md`. Right answer if the phase
goal ever expands from *transport* to *complete chat UI*; wrong answer now.

---

## Decision 2 — Server surface: **BUILD, in Node, not Axum**

The assessment offered three homes. All three are evaluated below; evidence
narrows to one.

**Extending openai-proxy — reject.** This was the original plan of record
(`plan.md:65` says "openai-proxy AG-UI surface wiring"), so it deserves an
explicit verdict rather than silent omission:

1. **Out of repo.** openai-proxy is not vendored here — phase-1b's `scope_note`
   states "No openai-proxy vendoring." A phase that must modify a codebase this
   repo does not contain cannot verify its own acceptance criteria.
2. **The surface does not exist to extend.** All four AG-UI endpoint candidates
   404 against the running instance (assess F-1). This is net-new work wherever
   it lands, so "extend" was never the cheaper option it appeared to be.
3. **Wrong coupling for a scaffolder.** Every app the scaffolder emits would
   depend on a separately-deployed proxy at `localhost:8181`. A generated app
   should stand up on its own; requiring an external service to demo it makes
   the scaffolder's output non-self-contained.

Worth noting the proxy remains the right home for *inference* routing — it
already serves that role. It is the wrong home for a **protocol surface** the
scaffolded app must own.

**Rust/Axum — reject.** Two independent reasons:

1. `scaffold-react-vite-axum.sh` has **no SSE precedent**. Grepping
   `sse|event-stream|stream` returns only asset-serving and SPA-fallback code.
   Everything would be net-new Rust.
2. No viable Rust AG-UI crate exists. crates.io returns `ag-ui` (22 downloads),
   `ag-ui-rs` (108), `tirea-protocol-ag-ui` (399). Those numbers mean no
   production adoption and no maintenance guarantee — depending on one is a
   larger risk than writing the framing by hand.

**Node — recommend.** A Node route can use `@ag-ui/encoder`, whose `encodeSSE`
is exactly `` `data: ${JSON.stringify(event)}\n\n` `` and whose
`getContentType()` handles negotiation. This keeps a **single source of truth for
the event contract**: adopting the encoder server-side and the client
client-side means both ends track upstream together. Splitting TS client against
Rust server would fork that contract immediately.

The server itself is still BUILD — no candidate implements the route, only the
encoding.

---

## Decision 3 — G-4 severity upgrade: WARNING → **BLOCKING**

The assessment rated the event-enum drift a WARNING based on two missing kinds
(`STEP_STARTED`, `STEP_FINISHED`) and flagged the upstream claim as needing
re-confirmation. T2 re-confirmed it and found the problem is materially worse.

**Evidence is durable and locally reproducible.** Rather than rely on
documentation paths that do not resolve in this repo, the enum was extracted
from the **published npm tarball**:

```
npm pack @ag-ui/core@0.0.59
tar -xzf ag-ui-core-0.0.59.tgz
grep -oE '"(RUN|STEP|TEXT_MESSAGE|TOOL_CALL|REASONING_MESSAGE|STATE|MESSAGES|RAW|CUSTOM)[A-Z_]*"' \
  package/dist/index.js | tr -d '"' | sort -u
```

Anyone can re-run that offline against a pinned version. Artifact:
`@ag-ui/core@0.0.59`, npm `dist/index.js`.

**Ten kinds missing** (not eight — the tarball is authoritative where the docs
sample was partial): `RAW`, `REASONING_MESSAGE_START`,
`REASONING_MESSAGE_CONTENT`, `REASONING_MESSAGE_END`, `REASONING_MESSAGE_CHUNK`,
`STEP_STARTED`, `STEP_FINISHED`, `TOOL_CALL_ARGS`, `TOOL_CALL_CHUNK`,
`TOOL_CALL_RESULT`. (Local enum: 14. Shipped 0.0.59: 23.)

**And one is simply wrong.** We declare `TOOL_CALL_ARGS_DELTA`. Upstream is
`TOOL_CALL_ARGS`:

```typescript
export const ToolCallArgsEventSchema = BaseEventSchema.extend({
  type: z.literal(EventType.TOOL_CALL_ARGS),
  toolCallId: z.string(),
  delta: z.string(),
});
```

The field is named `delta`; the *event kind* is not. **A protocol-conformant
AG-UI spec using `TOOL_CALL_ARGS` is rejected by our validator today.** This is a
live correctness defect in already-shipped code, not a forward-looking gap — and
it is invisible because the only specs anyone has validated are our own two
examples, which use our own wrong name.

The wrong name appears in four places:

| File | Line |
|---|---|
| `references/schemas/ag-ui-spec.schema.json` | 76 |
| `references/domain/ag-ui-spike.md` | 16 |
| `references/domain/ag-ui.md` | 79 |
| `scripts/normalize-agui.mjs` | 35 |

This must be fixed **before** the host scaffolder is generated, or the generated
host inherits a wrong contract.

---

## Bonus finding — protocol sequencing is specified and testable

The Go SDK ships a `ValidateSequence` function encoding the protocol's ordering
rules: `RUN_STARTED` precedes `RUN_FINISHED`; no duplicate starts; no restarting
a finished run; `TEXT_MESSAGE_START` precedes `CONTENT` and `END`;
`TOOL_CALL_START` precedes `ARGS` and `END`; state/snapshot/custom/raw events are
position-independent.

That is a ready-made specification for the host's own event-ordering tests, and a
stronger acceptance criterion than "events render." Recommend the plan stage
adopt it.

---

## Decision 4 — G-3 scaffolder: **BUILD from the in-repo pattern**

No external candidate applies. A T1 search for generic Vite/React scaffold
generators returned nothing usable, and adopting a third-party generator would
discard this repo's established conventions — brand-TOML injection, the
kebab-case rename pass, the import-rewrite pass, and the architectural ESLint
config.

The right model is the in-repo precedent:

| Scaffolder | Lines | Role |
|---|---|---|
| `scaffold-react-vite.sh` | 1160 | base |
| `scaffold-react-vite-axum.sh` | 431 | server-adjacent variant |
| `scaffold-react-vite-tauri.sh` | 230 | **thin wrapper — closest analogue** |

An AG-UI variant should follow the Tauri wrapper's shape: layer one concern onto
the base scaffolder rather than forking 1160 lines.

---

## Adversarial Review — 3 rounds, revision cap reached

Three dispatches, true cross-model isolation throughout
(`rest-gateway`, `cross_model_check: verified-distinct`, producer
`claude-opus-5` ≠ judge `kbd-judge`).

| Round | Verdict | Finding | Disposition |
|---|---|---|---|
| 1 | BLOCK | **G-6 dropped** — assess's blocking precondition (destroyed phase records) absent from both artifacts | **Fixed** — carried forward as a dedicated section + `blocking_prerequisites` |
| 1 | WARNING | Contradictory pinning guidance (recommended *and* listed as open) | **Fixed** — resolved, moved out of open questions |
| 1 | WARNING | G-4 evidence cited docs paths that do not resolve locally | **Fixed** — re-derived from the published npm tarball; count corrected 8 → 10 |
| 2 | BLOCK | **openai-proxy option dropped** — assess named three homes, only two evaluated | **Fixed** — explicit reject with three reasons |
| 3 | BLOCK | **G-3 dropped** from the gaps array | **Fixed** — Decision 4 above |
| 3 | WARNING | Node hosting mechanism unevaluated | **Unresolved** — see below |

Three of five rounds-1-to-3 CRITICALs were the *same class of error*: I carried
forward the gaps that had interesting research attached and silently dropped the
ones that did not. G-6, the openai-proxy option, and G-3 were each omitted
because analyze had "nothing to research" about them — which is precisely the
reasoning that loses a blocking precondition between stages. A gap with no
research still needs a recorded verdict.

## Unresolved review findings

Per the 2-round revision cap, one WARNING is accepted without a further
research round:

**Node hosting mechanism is unevaluated.** The analysis concludes "BUILD, in
Node" and settles the *encoder*, but does not evaluate *what runs the route*:
a Vite dev-server middleware plugin, a standalone Express/Hono/Fastify process,
or a Node `http` handler. These differ materially in dependency weight and in
whether the generated app needs a second process to demo.

The judge is right that this is unfinished. It is left for plan because it is an
implementation-shape decision constrained by the scaffolder's structure (Decision
4), not a build-vs-adopt question analyze can settle from registry evidence.
**Plan must decide it explicitly** rather than inheriting "Node" as if it were
fully specified.

---

## Open Questions Remaining

1. **Mock agent vs real LLM** — unchanged from assess. A scope decision, not a
   research question; the user or plan should settle it. Mock keeps the phase
   bounded and still satisfies every verification criterion.
2. **Store reduction semantics** — still a design question for plan, but now
   constrained: `@ag-ui/client` returns an **rxjs `Observable<BaseEvent>`**, so
   the store subscribes to a stream rather than registering callbacks. That
   shapes the `initRealtime()` action concretely.
3. ~~Version pinning~~ — **resolved, not open.** Pin exact (`0.0.59`, no caret)
   because pre-1.0 packages may ship breaking changes in a patch bump. The
   remaining plan task is to *implement and record* the pins, not to decide
   whether to pin.

---

## Skill-payload gap (process note)

`kbd-analyze` ships only `SKILL.md`. Both
`references/research-pipeline.md` (declared "the single source of truth" for
tiers, budgets, modes, and evidence format) and
`references/schemas/library-candidates.schema.json` are **absent** from the
installed skill and from the plugin cache.

I followed the tier structure and caps documented inline in `SKILL.md`, and
`library-candidates.json` follows the field set described there — but it is
**unvalidated against a schema that does not exist locally**. Anyone consuming it
programmatically should confirm the shape first. Same class of packaging gap as
the missing `handoff.schema.json` noted in phase-3c.
