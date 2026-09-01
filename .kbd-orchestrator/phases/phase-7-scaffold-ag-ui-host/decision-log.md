# Decision Log — phase-7-scaffold-ag-ui-host

## D-001 · Adopt `@ag-ui/client` rather than hand-rolling the SSE client [analyze · 2026-08-28]

**TL;DR** — Adopt, despite pre-1.0 (0.0.59) and ten transitive deps.

**Why** — The hand-roll option rested on a false premise. `EventSource` is
GET-only, and the AG-UI transport requires POSTing a `RunAgentInput` body with
`Accept: text/event-stream`. A hand-rolled client needs `fetch` +
`ReadableStream` + manual frame parsing + partial-JSON buffering — the last of
which is why `@ag-ui/client` already depends on `untruncate-json`. Maintenance
signal is strong: 15.6k stars, pushed 2026-08-27, 74 releases, latest published
the same day as this analysis.

**Alternatives** — Hand-rolled `EventSource` client (**rejected**: cannot POST).
`@copilotkit/react-core` 1.69.3 (**deferred**: mature and MIT, but a full
agent-UI framework that collides with this repo's scaffolder conventions;
revisit if scope expands from transport to chat UI).

**Cost accepted** — rxjs 7.8.2 + protobuf tooling enter every scaffolded app.
Pre-1.0 means breaking changes can arrive in a patch bump, so pin exact versions.

**Provenance** — research (Context7 `/ag-ui-protocol/ag-ui`, npm registry).

**Learn more** — `sdks/typescript/packages/client/src/agent/http.ts` (upstream).

---

## D-002 · Server surface lives in Node, not Axum [analyze · 2026-08-28]

**TL;DR** — BUILD the route; host it in Node so `@ag-ui/encoder` can be reused.

**Why** — Two independent disqualifiers for Rust. (1) `scaffold-react-vite-axum.sh`
has no SSE precedent — grep for `sse|event-stream|stream` returns only
asset-serving and SPA-fallback code, so everything would be net-new. (2) No
viable Rust AG-UI crate: `ag-ui` 22 downloads, `ag-ui-rs` 108,
`tirea-protocol-ag-ui` 399 — no production adoption, no maintenance guarantee.
Node lets both ends share one event contract via `@ag-ui/encoder`.

**Alternatives** — Axum route (**rejected**, above). Extending openai-proxy
(**rejected**: out-of-repo, and phase-3c showed that surface does not exist).

**Provenance** — research (crates.io API, local grep).

---

## D-003 · G-4 upgraded WARNING → BLOCKING; contains a live defect [analyze · 2026-08-28]

**TL;DR** — Our event enum is missing 8 kinds **and** declares one wrong name.
Fix before generating the host.

**Why** — Assess rated this WARNING on 2 missing kinds, correctly flagging the
upstream claim as unconfirmed. Confirming it revealed the drift is larger: 14
local kinds vs 21 upstream. Worse, we declare `TOOL_CALL_ARGS_DELTA` where
upstream is `TOOL_CALL_ARGS` — so a protocol-conformant spec is **rejected by our
validator today**. That is a correctness bug in shipped code, invisible because
the only validated specs are our own two examples using our own wrong name.

**Blast radius** — 4 files: `ag-ui-spec.schema.json:76`, `ag-ui-spike.md:16`,
`ag-ui.md:79`, `normalize-agui.mjs:35`.

**Provenance** — research (Context7 `sdks/typescript/packages/core/src/events.ts`)
cross-checked against local grep.

---

## D-004 · Adopt upstream `ValidateSequence` rules as acceptance criteria [analyze · 2026-08-28]

**TL;DR** — Use the Go SDK's documented ordering rules as the host's event tests.

**Why** — Upstream specifies sequencing precisely (RUN_STARTED before
RUN_FINISHED, no duplicate starts, no restarting a finished run,
TEXT_MESSAGE_START before CONTENT/END, TOOL_CALL_START before ARGS/END; state and
snapshot events position-independent). This is a stronger, testable acceptance
criterion than "events render."

**Provenance** — research (`sdks/community/go/pkg/core/events/events.go`).

---

## Operator confirmation — p7-01 restore-vs-supersede [apply · 2026-08-28]

**Decision: RESTORE (merge).** Confirmed by the operator in session, in response
to an explicit `AskUserQuestion` prompt presenting all three options. Not
inferred, not assumed from silence.

**Chosen branch:** restore the git HEAD narrative fields into each phase's
`progress.json` **while keeping** every runtime field the migration added
(`completion`, `schemaVersion`, `phaseId`, `migrationStatus`, `frontier`,
`sourceRevision`, …).

**Why merge rather than `git checkout`:** a plain checkout would discard the
canonical `completion` object the migration correctly produced. Task 2.2
prohibits it for that reason, and the third option offered to the operator named
this tradeoff explicitly.

**Verified safe before asking:** a field-level diff across all 12 files found
**zero conflicts** — no key exists in both versions with differing values. The
merge is purely additive, so nothing either side produced is lost.

**Scope of what is being restored:** 11 phases lost 14–23 fields each, including
`execute_status`, `acceptance_gates_passed` / `acceptance_gates_all_pass`,
`live_verification`, `scope_summary` / `scope_note`, `reflection_path`,
`assessment_path`, and `next_command`. `phase-ideation-to-app-pipeline` lost
nothing; `phase-3c-brand-data-extend` post-dates the migration and has no HEAD
version.

**Why this mattered enough to gate the phase:** the phase-7 assessment relied on
phase-1b's `scope_note` to disprove an inherited claim that an openai-proxy
AG-UI surface already existed. Without that field the assessment would have
built on a false premise.

---

## D-005 · G-7 deferred — runtime silently drops writes [apply · 2026-08-28]

**TL;DR** — Fixing the runtime write path is deferred to its own investigation.
**The filesystem is authoritative for phase-7 records.** Recorded so the
deferral is a decision, not an omission.

**The defect.** `prometheus kbd` returns `committedLocally: true` for commands
whose events never reach the audit log. Reproduced across five command types:
`phase create`, `phase activate`, `stage enter`, `stage transition`,
`completion set`. `kbd audit | grep -c phase-7-scaffold-ag-ui-host` returns
**0** despite every phase-7 stage being recorded through the CLI.

**It is not cosmetic — it caused data corruption this session.** Because
`phase activate` for phase-7 silently no-op'd, the runtime's `activePhaseId`
stayed at `polish-pass`. The `kbd-apply` driver then resolved the active phase
from the runtime and wrote `p7-01-restore-phase-records` — a phase-7 change —
into `polish-pass/progress.json`, incrementing `changes_total` 11 → 12 and
flipping a completed phase from `COMPLETE` to `IN_PROGRESS`.

Detected only because task 2.1's conflict scan flagged `changes_total` as the
single field differing between git HEAD and the worktree. An earlier scan that
skipped one phase reported zero conflicts — the narrower check would have missed
it and the merge would have written the corrupted total back.

**Repair applied:** `polish-pass` restored to 11/11 `COMPLETE`, misattributed
change stripped, `_repair_note` recorded in the file.

**Operating rule for the rest of phase-7:** the filesystem is authoritative.
Do not use `kbd-apply`'s driver subcommands until the runtime's active phase can
be set reliably — they write progress to whatever phase the runtime believes is
active, which is currently wrong. Drive tasks with direct edits and verify
against the filesystem.

**Why deferred rather than fixed here:** the write path lives in the
`prometheus` binary, outside this repository. Diagnosing it is its own phase.

**Provenance** — reproduced in-session; corruption verified by field-level diff.

**Operator acceptance (task 4.2):** confirmed in session via explicit
`AskUserQuestion` — deferral accepted, phase-7 proceeds with the filesystem as
the authoritative record. Not inferred from silence.
