# Plan: phase-8-scaffold-a2ui-host

**Backend:** OpenSpec (`openspec/changes/p8-*/`) — `change_backend: openspec` +
existing `openspec/changes/`
**Changes:** 5 · **Tasks:** 106 · **Evolver bridge:** none (`.evolver/` absent)

> **Task count note.** The spec handoff records 97 tasks (19/21/19/21/17); the
> current total is **106** (21/22/19/26/18). The delta is **+9**, added after
> that handoff was written:
>
> | Source | Tasks |
> |---|---|
> | Spec-stage adversarial review (Q3 rejection 3.3/3.4 + gate 5.8, p8-01 gate 4.7, p8-04 test rework) | +5 |
> | Plan-stage constraint audit (p8-01 4.8/4.9, p8-02 5.9, p8-04 5.7/5.8/5.9) | +2 net after counting |
> | Plan-stage round-2 review (p8-05 3.10 secrets-over-`scripts/`, 3.11 executable) | +2 |
>
> An earlier draft of this note said "seven", which did not reconcile with +9 —
> caught in review. The handoff is not wrong, it is earlier. **106** is the
> number to size against.
**Inputs:** `assessment.md`, `analysis.md`, `library-candidates.json`, three handoffs
**Unblocked by:** operator decision on G-8 → **align to upstream A2UI v1.0**

---

## Dependency shape — first phase with real parallelism

```
p8-01 ──► p8-02 ──┬──► p8-03 ──┐
                  │             ├──► p8-05
                  └──► p8-04 ──┘
```

Unlike phase-7's strict chain, **p8-03 and p8-04 are genuine siblings**: they
share no scope path, and neither reads the other's output. p8-03 rewrites data
(examples, references); p8-04 writes code (store, hook, component). Both need
the contract from p8-01/p8-02; both feed p8-05.

That is the one real ordering decision available, and it is what makes session
batching non-trivial here.

---

## Ordered change list

| # | Change | Library | Effort | Agent | Gate that matters |
|---|---|---|---|---|---|
| 1 | `p8-01-align-a2ui-schema` | — | medium | pmpo-executor | old dialect **rejected** (4.3) |
| 2 | `p8-02-rewrite-a2ui-normalizer` | — | **medium-large** | pmpo-executor | cycle detection survives the model change (5.2) |
| 3 | `p8-03-rewrite-a2ui-examples` | — | medium | pmpo-executor | old-dialect fixture rejected (4.3) |
| 4 | `p8-04-a2ui-render-host` | `@a2ui/react@0.10.2` (**ADOPT**) | medium | pmpo-executor | `updateComponents` merges, doesn't replace (5.1) |
| 5 | `p8-05-scaffold-a2ui-host` | — (consumes 3+4) | medium | pmpo-executor | **browser DOM via Playwright (3.6)** |

The library annotation comes from `library-candidates.json` per the Analyze-inputs
rule: p8-04 **reuses** `@a2ui/react` rather than rebuilding a renderer. Pinned
**exact** at `0.10.2` — pre-1.0, so a caret could take a breaking change in a
patch bump.

---

## Session batching

| Session | Changes | Rationale |
|---|---|---|
| **A** | p8-01, p8-02 | The contract and its validator. Ends with a schema that rejects the old dialect and a normalizer that enforces the new one — nothing downstream can be built against a wrong contract. |
| **B** | p8-03 **and** p8-04 | Parallelisable. If run sequentially, p8-04 first: it carries the adoption risk, and p8-03 is mechanical once the contract is fixed. |
| **C** | p8-05 | Scaffolder plus the browser-DOM gate that decides the phase. |

Three sessions, matching the analyze estimate for the alignment branch (2–3
sessions, 8–12 changes; this is 5 changes but 106 tasks).

**On parallelism:** p8-03 and p8-04 may run in separate worktrees — verified no
shared scope path. That is a genuine option here, unlike phase-7 where every
change shared `package.json` with its neighbour.

---

## Where the risk is

**p8-02 is the phase's hardest change.** It reworks a 350-line normalizer whose
every core assumption moves: recursive tree descent becomes flat-array indexing,
bindings-graph cycle detection becomes id-reference cycle detection, regex
vocabulary checking becomes catalog membership. Rewrites that preserve behaviour
while changing every internal model are where silent regressions live.

The specific regression to watch: **cycle detection must survive.** The current
normalizer detects cycles in the bindings graph because JSON Schema cannot
express acyclicity. That requirement does not disappear under alignment — a flat
component array with id references describes cycles just as easily, and no schema
catches those either. Losing it would be invisible until a malformed spec hangs a
renderer.

**p8-05 gate 3.6 is the phase's acceptance test.** Rendered DOM asserted via
Playwright, by role and text rather than string-matching HTML. Phase-7 closed
with exactly one PARTIAL because "renders in the browser" was verified at store
level; a *rendering host* that never observes rendering would be verifying the
wrong thing twice.

**Q3 is security-relevant and its closure is a named gate.** Assess asked
whether to evaluate, sandbox, or reject arbitrary expression bindings and
recommended rejection for v1. The G-8 decision table originally called it moot
because the protocol defines `callFunction` — but p8-04 defers `callFunction`, so
nothing would have closed it. **p8-02 tasks 3.3/3.4, gated by 5.8**: an
expression-like `DynamicString` leaf is rejected with a named error, asserted by
matching the message rather than a non-zero exit, and the old dialect's
`{"kind": "expression"}` form is rejected explicitly so arbitrary JS cannot
survive the migration by omission. Execute must not treat 5.8 as optional.

**p8-03 carries the user-visible break.** Both shipped examples become invalid.
That is the accepted cost of the G-8 decision, not an accident — but it is the
change to review most carefully before it lands.

---

## Constraint compliance — all seven blocking constraints

Checked against `.kbd-orchestrator/constraints.md`. **Gaps found during planning
were closed by writing gates into the change tasks, not by documenting them.**
Phase-7's plan stage produced two CRITICALs for exactly that distinction: an
earlier draft there omitted three constraints, and the next draft described them
as gaps and deferred gate creation to execute. Both are planning work left undone.

| # | Constraint | Gated in | Status |
|---|---|---|---|
| 1 | `marketplace-validates` | p8-01 4.6 · p8-02 5.7 · p8-04 5.8 · p8-05 3.7 | ✅ |
| 2 | `skill-frontmatter-present` | p8-05 3.7 | ✅ |
| 3 | `references-resolve` | p8-01 4.9 · p8-03 4.5 | ✅ **added during planning** |
| 4 | `schemas-parse` | p8-01 4.8 · p8-02 5.9 · p8-03 4.6 | ✅ **added during planning** |
| 5 | `no-brand-leakage` | p8-03 4.7 · p8-05 3.8 | ✅ |
| 6 | `no-hardcoded-secrets` | p8-04 5.7 *(assets only)* · **p8-05 3.10 (the constraint's own paths)** | ✅ **both added during planning** |
| 7 | `submodules-clean` | p8-05 3.9 | ✅ **added during planning** |

All five warning constraints, acknowledged rather than sampled:

| Warning constraint | Disposition |
|---|---|
| `hook-scripts-executable` | p8-05 **3.11** — asserts `chmod +x` from task 1.2 took effect |
| `no-stub-comments` | p8-04 5.9 · p8-05 3.7 |
| `examples-updated` | p8-03 is *entirely* example rewriting; gates 4.1–4.3 verify them |
| `no-duplicated-docs` | manual review — p8-01 rewrites `references/domain/a2ui.md`; watch for overlap with `references/content-types.md`, which p8-03 also edits |
| `plugin-manifest-current` | **not applicable**, see below |

### Gates added during planning

| Constraint | Where | Why it was missing |
|---|---|---|
| `schemas-parse` | p8-01 **4.8**, p8-02 **5.9** | p8-01 hand-edits a JSON schema and only checked *that* file; the constraint is directory-wide. p8-02 reads the schema at runtime, where a malformed one surfaces as a confusing runtime error rather than a parse failure. |
| `references-resolve` | p8-01 **4.9** | p8-01 rewrites `references/domain/a2ui.md`, which `prompts/` cites. |
| `no-hardcoded-secrets` | p8-04 **5.7** | p8-04 was the only change adding new source files with no repo-constraint gate at all. |
| `no-hardcoded-secrets` *(scan-path coverage)* | p8-05 **3.10** | **Round-2 review catch.** p8-04's gate greps only `assets/scaffold/a2ui/`, but the constraint scans `scripts/ prompts/ references/` — and p8-05 creates `scripts/scaffold-react-vite-a2ui.sh`. Gating a constraint over a path it does not cover is not gating it. p8-05 3.10 now runs the constraint's own command over its own paths. |
| `hook-scripts-executable` | p8-05 **3.11** | p8-05 task 1.2 runs `chmod +x`; nothing verified it took effect. |
| `submodules-clean` | p8-05 **3.9** | No p8 change touches `shared/` or `tools/`, so this is trivially clean — asserted rather than assumed. |

### On `plugin-manifest-current`

**Not applicable, and this is deliberate.** `.claude-plugin/plugin.json` has no
`skills` key and lists no existing skill, including `scaffold-react-vite-tauri`
and `scaffold-react-vite-agui`. `CLAUDE.md:31` states component paths are
auto-discovered. `CLAUDE.md:54` says the opposite and is stale — it cost a detour
in p7-05, and p8-05's tasks carry an explicit note not to repeat it.

---

## Deferred, recorded

- **G-7** — five unpinned `unpkg@latest` loads in
  `a2ui-preview-template.html`. Owned as a tracked deferral in p8-05's
  Out-of-scope: under alignment the preview template may be superseded entirely
  by the runtime renderer, so pinning a file that may be deleted is likely wasted
  work. Revisit when its fate is decided.
- **`callFunction` / `actionResponse` round-tripping**, multi-surface management,
  custom catalog authoring — all out of scope for v1 (p8-04 proposal).
- **G-7's sibling risk:** because the preview template is out of this path, the
  p8-05 DOM test is deterministic — the scaffolded app bundles `@a2ui/react`
  through Vite rather than loading `@latest` from a CDN.

---

## Carry into execute

1. **p8-01 task 1.2 is a HALT.** If the re-verified upstream protocol differs
   from what the proposal records, stop and re-spec. Tasks 2.x hard-code the
   envelope key set; running them against a changed protocol writes a *new* wrong
   schema that looks authoritative — the exact failure this phase corrects.
2. **p8-02 must derive its vocabulary from the schema**, not duplicate it. A
   hand-maintained second copy is how `TOOL_CALL_ARGS_DELTA` lived in two places
   at once through an entire phase.
3. **Both spec-stage CRITICALs were cross-change assertions outrunning the
   declared graph** — prose claiming an ordering the `depends_on` edges did not
   enforce. Execute should trust the edges, not the prose.

---

## Adversarial Review — 2 rounds, revision cap reached

True cross-model isolation both rounds (`rest-gateway`, `verified-distinct`,
producer `claude-opus-5` ≠ judge `kbd-judge`). Both BLOCK; all six findings
verified correct and applied.

**Round 1 — 1 CRITICAL, 3 WARNING**

| Finding | Disposition |
|---|---|
| `no-hardcoded-secrets` claimed covered while p8-05 adds script surface the constraint scans | **Fixed** — p8-05 gate 3.10 |
| Only 2 of 5 warning constraints acknowledged | **Fixed** — all five now have a disposition, including `hook-scripts-executable` → p8-05 3.11 |
| Task count contradicted the spec handoff | **Fixed** — reconciled with a provenance table |
| Q3's security-relevant closure not surfaced as an execution gate | **Fixed** — p8-02 gate 5.8 called out explicitly in *Where the risk is* |

**Round 2 — 1 CRITICAL, 1 WARNING**

| Finding | Disposition |
|---|---|
| Same constraint *still* ungated in the plan's table | **Fixed — and the repeat was the real lesson.** Round 1 added the task to `p8-05/tasks.md` but left the plan's compliance table crediting p8-04 alone. The gate existed; the plan's own record of it did not. Fixing the artifact without fixing its index leaves the next reader with the wrong picture. |
| Arithmetic said "seven" where the delta was +9 | **Fixed** — provenance table now reconciles to +9 |

Both CRITICALs were the same underlying error, and it is the third phase running:
**claiming constraint coverage that the gate's actual scan path does not provide.**
p8-04's gate greps `assets/scaffold/a2ui/`; the constraint greps
`scripts/ prompts/ references/`. Gating a constraint over a path it does not
cover is not gating it.

## Exact next command

```
/kbd-apply p8-01-align-a2ui-schema
```

Nothing else may start first: every other change builds on the contract p8-01
defines, and p8-02 through p8-05 would all encode a wrong document model if it
were skipped.
