# Plan: phase-7-scaffold-ag-ui-host

**Backend:** OpenSpec (`openspec/changes/p7-*/`) — detected via
`project.json.change_backend: openspec` + existing `openspec/changes/`
**Changes:** 5 · **Tasks:** 91 · **Gates:** 16
**Evolver bridge:** none (`.evolver/` absent) — not an evolution cycle
**Inputs:** `assessment.md`, `library-candidates.json`, all three handoffs

---

## What this plan adds

Spec already fixed the **dependency edges**, and they form a strict chain, so
change *order* is not a plan decision — it is forced:

```
p7-01 → p7-02 → p7-03 → p7-04 → p7-05
                   └──────┴──→ (p7-05 needs both)
```

There is no reordering freedom to exercise and no parallelism to find: every
change depends on its predecessor. What plan contributes is therefore **session
batching, agent assignment, effort sizing, and where the risk actually sits** —
not a re-derivation of the order.

### On intra-change sequencing

The spec handoff named "sequencing within changes" as plan's remaining work.
Having read all 91 tasks, **that work is already done** — and I am stating that
rather than silently declining it.

Each `tasks.md` is already ordered by hard dependency, not by convenience:

| Change | Intra-change order is forced by |
|---|---|
| p7-01 | 1.x decision → 2.x/3.x branch → 4.x record → 5.x gate. The branch cannot precede the decision. |
| p7-02 | 1.x re-verify (with a HALT branch) → 2.x rename → 3.x add kinds → 4.x fixtures → 5.x gate. Editing before re-verifying is the failure mode task 1.2 exists to prevent. |
| p7-03 | 1.x dependency → 2.x mock agent → 3.x plugin (consumes the agent) → 4.x verify. |
| p7-04 | 1.x dependency → 2.x store → 3.x hook+component (consume the store) → 4.x verify. |
| p7-05 | 1.x scaffolder → 2.x skill registration → 3.x smoke on generated output. |

Two ordering constraints are worth restating because they are *not* obvious from
task numbering alone, and execute could violate them while following the numbers:

1. **p7-02 task 1.2 is a HALT, not a checkpoint.** On enum mismatch, stop and
   re-spec. Tasks 2.x/3.x hard-code a specific kind list; running them against a
   changed upstream writes a *new* wrong enum while appearing to succeed.
2. **p7-03 and p7-04 must not run in parallel worktrees.** They share
   `package.json`. The dependency edge is what makes the shared file safe.

Re-listing the 91 tasks in a different document would add no ordering
information and create a second copy to drift. The genuine remaining risk is
that execute follows numbering *past* a HALT — which is why it is called out
here rather than assumed.

---

## Ordered change list

| # | Change | Library | Effort | Agent | Gate |
|---|---|---|---|---|---|
| 1 | `p7-01-restore-phase-records` | — | small | **human-in-loop** | operator confirmation recorded (5.3) |
| 2 | `p7-02-fix-agui-event-enum` | — | small | pmpo-executor | negative-path example rejected (5.3) |
| 3 | `p7-03-agui-server-surface` | `@ag-ui/encoder@0.0.59` (ADOPT) | **medium-large** | pmpo-executor | streams ≥2 content frames (4.3) |
| 4 | `p7-04-agui-client-store` | `@ag-ui/client@0.0.59` (ADOPT) | medium | pmpo-executor | incremental render (4.5) |
| 5 | `p7-05-scaffold-agui-host` | — (consumes 3+4) | medium | pmpo-executor | **incremental render in a fresh scaffold (3.6)** |

Library annotations come from `library-candidates.json` per the Analyze-inputs
rule: changes 3 and 4 **reuse** adopted packages rather than rebuilding them.
Both pin **exact** `0.0.59` — pre-1.0, so a caret range could take a breaking
change in a patch bump.

---

## Session batching

| Session | Changes | Rationale |
|---|---|---|
| **A** | p7-01, p7-02 | Both small, both prerequisite-clearing, neither writes app code. Ends with the contract correct and records safe. |
| **B** | p7-03 | The phase's risk concentrates here — net-new SSE surface with no in-repo precedent. Give it a session alone. |
| **C** | p7-04, p7-05 | Client + scaffolder. p7-05 is thin once p7-04 exists, since it wires rather than invents. |

Three sessions, consistent with the assess estimate of 2–3. If p7-03 overruns,
it takes its own second session rather than compressing C — the acceptance
criterion that matters lives in C.

---

## Where the risk is

**p7-03 is the phase.** It is the only change with no substrate to lean on:

- No SSE precedent anywhere in the repo (`grep sse|event-stream` over the
  scaffolders returns only asset-serving code).
- No viable Rust alternative (crates.io AG-UI packages: 22–399 downloads).
- The mock agent must chunk deliberately — a single-flush response satisfies
  every check except the one that matters.

**p7-05 gate 3.6 is the phase's real acceptance test.** *Incremental rendering* —
asserting the rendered text **grows across frames**, not merely that the final
text is correct. Every other criterion in this plan passes against a
non-streaming stub. If only one gate is enforced honestly, it is this one.

**p7-01 is the only change that can block on a human.** Tasks 1.1, 3.2, and 4.2
require operator confirmation. Gate 5.3 makes that machine-checkable by grepping
`decision-log.md` for an `## Operator confirmation` entry, so "nobody answered"
fails loudly instead of being read as consent.

---

## Constraint compliance

Checked against `.kbd-orchestrator/constraints.md`. **All seven blocking
constraints**, not a subset — an earlier draft listed only four of them plus two
warnings, which would have let `schemas-parse` and `references-resolve` go
unenforced on the exact change that edits a JSON schema and two
`references/domain/` files.

| # | Blocking constraint | Applies to | Where satisfied |
|---|---|---|---|
| 1 | `marketplace-validates` | p7-02, p7-05 | p7-02 gate 5.4, p7-05 gate 3.7 |
| 2 | `skill-frontmatter-present` | p7-05 | p7-05 task 2.1 |
| 3 | `references-resolve` | p7-02 | p7-02 gate 5.6 |
| 4 | `schemas-parse` | p7-02 | p7-02 gate 5.5 |
| 5 | `no-brand-leakage` | p7-02, p7-05 | p7-02 gate 5.7, p7-05 gate 3.8 |
| 6 | `no-hardcoded-secrets` | all | mock agent needs no credentials — a reason MOCK was chosen |
| 7 | `submodules-clean` | none | no change enters `shared/` or `tools/` |

Warning constraints also tracked: `hook-scripts-executable` (p7-05 task 1.2,
`chmod +x`), `no-stub-comments` (p7-05 gate 3.7), and `plugin-manifest-current`
(p7-05 gate 3.9 — this change adds a new skill, which is exactly the case the
constraint exists for).

### Gates added during planning

Three blocking constraints had no gate when this plan was first drafted. An
earlier draft *documented the gaps and deferred them to execute* — which is
planning work left undone, not planning work completed. They are now written
into the change tasks as executable commands:

| Constraint | Gate added | Command |
|---|---|---|
| `schemas-parse` | p7-02 **5.5** | `for f in references/schemas/*.json; do python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f" \|\| exit 1; done` |
| `references-resolve` | p7-02 **5.6** | `grep -roh 'references/[a-zA-Z0-9/_.-]*' prompts/ \| sort -u \| while read f; do [ -e "$f" ] \|\| exit 1; done` |
| `no-brand-leakage` | p7-02 **5.7**, p7-05 **3.8** | `grep -rn 'sediment://' prompts/ skills/ agents/ references/ assets/ README.md SKILL.md --include='*.md'` returns no matches |
| `plugin-manifest-current` (warning) | p7-05 **3.9** | `.claude-plugin/plugin.json` lists the new skill (grep) |

Each is a runnable command with a defined pass condition, not a prose
instruction. `schemas-parse` matters most: p7-02 hand-edits a JSON enum, and a
trailing comma would ship a broken schema that every other gate in that change
tolerates.

---

## Deferred, recorded

- **G-7** — runtime reports `committedLocally: true` for writes absent from the
  audit log (reproduced 4× including this phase's own stage records). Deferred
  to its own investigation; p7-01 task 4.1 records the deferral so it cannot
  vanish the way G-6 nearly did.
- **Tool-call rendering, `STATE_*` reduction, reconnection/backpressure,
  multi-turn history** — real follow-ups, none required to prove the transport.
- **Production hosting** — the Vite middleware is dev-only. p7-05 task 1.6
  requires the README to say so rather than letting production-shaped output
  imply otherwise.

---

## Exact next command

```
/kbd-apply p7-01-restore-phase-records
```

Nothing else may start first. Two distinct p7-01 gates are involved and are
easily conflated:

- **Gate 5.3** — `decision-log.md` contains an `## Operator confirmation` entry.
  Proves a human chose restore-vs-supersede.
- **Gate 5.4** — no other p7-* change starts until p7-01 is complete. The
  blocking rule itself.

5.3 is the human checkpoint; 5.4 is the ordering constraint. Both must hold. The
urgency is that p7-01's subject matter — recoverable-but-unrestored phase
records — degrades with any `git add -A`.
