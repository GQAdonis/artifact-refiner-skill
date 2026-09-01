# Reflection — phase-7-scaffold-ag-ui-host

- **Status:** COMPLETE (5/5 changes; 5/6 acceptance criteria MET, 1 PARTIAL)
- **Date:** 2026-08-28
- **Backend:** OpenSpec — all five changes verified and archived
- **Sessions:** 1 (plan estimated 2–3)

---

## 1. Goal Achievement

**Phase goal:** ship a scaffolder that emits a *running* AG-UI host application —
a React app that connects to an AG-UI agent backend over SSE and renders
streamed events.

| # | Acceptance criterion | Verdict | Evidence |
|---|---|---|---|
| 1 | Scaffolded app's `pnpm build` exits 0 | **MET** | p7-05 gate 3.2 on a fresh scaffold |
| 2 | Server answers POST + `Accept: text/event-stream` with `text/event-stream` | **MET** | p7-05 gate 3.5 against live `pnpm dev` |
| 3 | Run emits `RUN_STARTED` … `RUN_FINISHED` as `data: {…}\n\n` frames | **MET** | 36 frames, correct bracketing |
| 4 | `TEXT_MESSAGE_CONTENT` deltas render incrementally **in the browser** | **PARTIAL** | see below |
| 5 | SSE subscription lives in a store action, not a hook or component | **MET** | architectural ESLint now enforces it (see §3) |
| 6 | `pnpm lint` passes, including the architectural ESLint config | **MET** | p7-05 gate 3.3, after fixing why it never ran |

**5/6 MET · 1 PARTIAL.**

### Criterion 4 — why PARTIAL, not MET

Incremental accumulation is proven: 32 snapshots, 31 growing, monotonic prefix
growth, sampled from the real store reducer fed by the real dev-server stream.
A non-streaming implementation yields one snapshot.

What is **not** proven is the words "in the browser". The scaffolder emits
`AgentPanel` but does not mount it — `scaffold-react-vite-agui.sh:221` tells the
user to "render `<AgentPanel />` from your app". No DOM was ever rendered and no
browser was driven. The reduction is verified; the paint is inferred from React
re-rendering on store updates.

Calling this MET would overstate the evidence. The honest gap: nobody has watched
this text appear on screen.

---

## 2. Delivered Changes

| Change | Tasks | What shipped |
|---|---|---|
| `p7-01-restore-phase-records` | 12 + 2 N/A | 187 narrative fields restored across 11 phases |
| `p7-02-fix-agui-event-enum` | 20 | Renamed a wrong event kind, added 10 missing ones, closed a corpus blind spot |
| `p7-03-agui-server-surface` | 20 | Vite middleware + mock agent emitting conformant SSE |
| `p7-04-agui-client-store` | 19 | zustand store, hook, panel; append-not-replace reduction |
| `p7-05-scaffold-agui-host` | 16 + 2 N/A | `scaffold-react-vite-agui.sh` + skill definition |

87 tasks completed, 4 recorded N/A with reasons, **0 left open**.

Four spec capabilities synced to `openspec/specs/`, which was **empty** at phase
start: `ag-ui-spec-validation`, `agui-server-surface`, `agui-client-store`,
`agui-host-scaffolder`.

---

## 3. Defects Found in Pre-Existing Code

This phase's largest value was not the feature. Building it exercised paths that
had never been exercised end to end, and three shipped defects surfaced.

### D-1 — The architectural ESLint config had never run (most serious)

`scaffold-react-vite.sh` wrote its layering rules to `eslint.config.mjs`, but
shadcn had already written `eslint.config.js`. ESLint loads exactly one flat
config and prefers `.js`. **Every app ever produced by this scaffolder had
unenforced architectural rules.**

Proven, not inferred: a component importing a store directly — the explicit
violation the config forbids — linted clean with exit 0. After the fix, the same
probe errors correctly.

This is the defect class the whole `state-architecture.md` convention exists to
prevent, and the enforcement mechanism was silently inert.

### D-2 — `pnpm build` was broken for every user

`scaffold-react-vite.sh:711` set `compilerOptions.baseUrl`. TypeScript 6.0.3
hard-errors on it (TS5101); it was merely deprecated when phase-4 last verified
this green. Removed rather than silenced — the `paths` entries are already
tsconfig-relative, so resolution is unchanged, and `baseUrl` disappears entirely
in TS 7.

### D-3 — `pnpm lint` failed on shadcn's own generated file

`react-refresh/only-export-components` errored on `button.tsx`, which co-exports
a component and its `cva` variants. Fixed by registering the plugin in the merged
config with an exemption for vendored `ui/**`.

### D-4 — Live protocol defect in shipped code (p7-02)

Our schema declared `TOOL_CALL_ARGS_DELTA`; `@ag-ui/core@0.0.59` declares
`TOOL_CALL_ARGS`. A protocol-conformant spec was **rejected by our validator**.
It survived review because no example exercised the tool-call path at all —
`grep TOOL_CALL_ARGS examples/` returned nothing. The enum was also missing 10
kinds (14 local vs 23 shipped).

---

## 4. Artifact Quality Summary

No `artifact-refiner` logs exist for this phase: that gate applies to *refined
artifacts*, and every p7 change is code or state. **Adversarial review was the QA
gate**, run at every stage.

| Metric | Value |
|---|---|
| Stages vetted | 4/4 (assess, analyze, spec, plan) |
| Review rounds | 9 total (assess 2, analyze 3, spec 2, plan 2) |
| Findings raised | 24 |
| CRITICAL | 7 |
| WARNING | 17 |
| Findings verified correct | **24/24** |
| Findings applied | 24 (1 accepted at revision cap with rationale) |

Isolation was true cross-model (`rest-gateway`, `verified-distinct`) for
analyze and plan. Assess ran degraded (tier-2 subagent, HTTP 401 on the gateway);
spec ran degraded for a different reason — the packet builder supports only the
native-kbd layout, so the packet was assembled by hand.

### Recurring finding pattern

**Dropped carry-forward items — 3 CRITICALs, one root cause.** Across three
separate rounds the judge caught the same error: gaps with no interesting
research attached were silently omitted rather than given a verdict.

- analyze R1: **G-6** (the blocking record-restoration precondition) vanished
- analyze R2: the **openai-proxy** option went unevaluated
- analyze R3: **G-3** (the scaffolder gap) dropped from the gaps array

Every one was a gap where the honest answer was "nothing to research" — and that
is precisely the reasoning that loses a blocking precondition between stages.
**A gap with no research still needs a recorded verdict.**

**Second pattern — describing coverage instead of enforcing it.** Both plan-stage
CRITICALs were this: the first draft omitted three blocking constraints from the
compliance table; the second documented them as gaps and deferred gate creation
to execute. Deferring gate creation is planning work left undone. Five gates were
written into the change tasks as runnable commands as a result.

---

## 5. Where Verification Actually Caught Things

Every defect above was found by *running* something, never by reading it:

| Defect | Found by |
|---|---|
| Producer TOML ordering (phase-3c) | round-trip test failing on an identically-wrong fixture |
| `EventType` vs `string` | `pnpm build` on a scaffolded app — harness bundling skipped typecheck |
| `JSX.Element` unresolvable | same build |
| ESLint config inert | probe file that *should* have errored |
| `baseUrl` / TS 6 | first real scaffold run |

Harness testing proved the middleware logic but could not prove the Vite wiring;
p7-03 gate 5.1 was recorded PARTIAL for exactly that reason, and p7-05 gate 3.4
closed it. That deferral was correct.

---

## 6. Technical Debt

| Item | Severity | Note |
|---|---|---|
| **G-7 — runtime silently drops writes** | HIGH | 5 command types return `committedLocally: true` while `kbd audit` shows 0 phase-7 events. **Caused real corruption**: `polish-pass` flipped 11/11 COMPLETE → 11/12 IN_PROGRESS when the apply driver attributed a phase-7 change to it. Repaired; deferral accepted by the operator. |
| No `progress.json` for phase-7 | MEDIUM | The apply driver was disabled under the G-7 rule, so it wrote none. The archived changes are the record. |
| Criterion 4 unproven in a DOM | MEDIUM | No browser-level test exists. `AgentPanel` is emitted but never mounted. |
| `@ag-ui/*` pre-1.0 | MEDIUM | Pinned exact at `0.0.59`. `@types/uuid` is a *runtime* dep upstream — a packaging bug shipped into every scaffolded app. |
| CLAUDE.md:54 contradicts CLAUDE.md:31 | LOW | Line 54 says add skills to `plugin.json`; line 31 says paths are auto-discovered. No skill is listed there. Line 54 is stale. |
| Tooling gaps | LOW | `kbd-analyze` ships without `research-pipeline.md` or `library-candidates.schema.json`; `adversarial-review`'s packet builder handles only the native-kbd spec layout. |
| 14 unarchived OpenSpec changes | LOW | Predate this phase; task boxes stale. |

---

## 7. Lessons

- **An enforcement mechanism nobody has seen fail is not known to work.** The
  ESLint config looked correct in source for the entire life of the scaffolder.
  One probe file that *should* error settled it in seconds.
- **A gap with no research still needs a recorded verdict.** Three CRITICALs,
  one habit: omitting the boring items because there was nothing interesting to
  say about them.
- **"Verified via the fallback path" verifies the fallback.** Inherited from
  phase-3c, and it recurred here in a new form: harness testing verified the
  handler, not the wiring.
- **Key-count comparison is not field comparison.** Both the pre- and
  post-migration `phase-1b/progress.json` had 19 keys — entirely different ones.
  The count check gave a false pass; the named-field check caught it.
- **Corpus blind spots hide protocol bugs.** The wrong event name survived review
  because no example exercised the tool-call path. Coverage of the *contract*
  matters more than coverage of the code.
- **Building a feature is a good way to audit a pipeline.** Three pre-existing
  defects surfaced because the phase forced an end-to-end run nobody had done.

---

## 8. Advancing the Waypoint

Deferred phases remaining: `phase-6-scaffold-flutter`,
`phase-8-scaffold-a2ui-host`, `phase-9-scaffold-mcp-ui`.

**Recommended next: `phase-8-scaffold-a2ui-host`.** The A2UI domain already
shipped (PR #1), and phase-7 established the whole substrate a host scaffolder
needs — the wrapper pattern, the dev-middleware approach, the store layering, and
now-working ESLint enforcement. It is the cheapest phase that exercises the new
substrate a second time, which is also how the substrate gets validated as
reusable rather than bespoke.

Two smaller items worth doing first, both cheap:

1. **A browser-level test for criterion 4** — mount `AgentPanel` in the
   scaffolded app and assert text growth in a real DOM. Closes the phase's only
   PARTIAL and needs the Playwright already in `devDependencies`.
2. **Fix CLAUDE.md:54** — a one-line doc correction that would have saved a
   detour this phase.

**Not recommended next: G-7.** It is real and it corrupted data, but it lives in
the `prometheus` binary outside this repo. The operator accepted the deferral;
it needs its own phase, not a corner of this one.

```yaml
phase: phase-7-scaffold-ag-ui-host
goals_met: 5/6 (83%; 1 partial with stated evidence gap)
changes: 5/5
tasks: 87 done, 4 N/A, 0 open
adversarial_review: 9 rounds, 24 findings, 24/24 verified correct
preexisting_defects_fixed: 3
technical_debt_blocking: false
sessions_used: 1 (estimated 2-3)
next_phase_recommended: phase-8-scaffold-a2ui-host
alternates: [phase-6-scaffold-flutter, phase-9-scaffold-mcp-ui]
```
