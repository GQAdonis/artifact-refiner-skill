# Proposal: p7-01 — Restore phase records destroyed by migrate --apply

**Change ID**: p7-01-restore-phase-records
**Phase**: phase-7-scaffold-ag-ui-host
**Status**: specified
**Origin**: assess G-6 (BLOCKING precondition), carried through analyze
**Depends on**: nothing — this is the gate for every other p7-* change

## Summary

`prometheus kbd migrate --apply` (2026-08-27) overwrote every phase
`progress.json` with runtime-derived counters, replacing narrative records with
bare `N/N`. Restore them from git, or record an explicit decision that the
counters supersede the narrative.

## Why this blocks the rest of the phase

This is not housekeeping. The phase-7 assessment depended on phase-1b's
`scope_note` to disprove the claim that an openai-proxy AG-UI surface already
existed — a claim inherited from the phase-4 reflection. Without that field the
assessment would have built on a false premise.

Every downstream phase reads these records for the same reason.

## Verified state

Both git HEAD and the working tree hold 19 keys for
`phase-1b-inference-routing/progress.json`, but they are **different** 19 keys —
a coincidence of count, not evidence of recovery:

| | Contains |
|---|---|
| git HEAD | `scope_note`, `live_verification`, `acceptance_gates_all_pass`, `port_correction`, `execution_path`, … |
| working tree | `schemaVersion`, `generatedBy`, `sourceRevision`, `frontier`, `migrationStatus`, counters |

`scope_note` and `live_verification` are absent from the working tree. Checking
key *count* is not a valid test; checking named fields is.

## Scope

- `.kbd-orchestrator/phases/*/progress.json` — 12 files
- `.kbd-orchestrator/phases/phase-7-scaffold-ag-ui-host/decision-log.md` —
  appended in the superseding branch, and in either branch to record the G-7
  deferral. Declared explicitly because the gate (`git diff --stat
  .kbd-orchestrator/phases/`) covers this path and would otherwise flag a
  legitimate write as unintended.

## Risk if deferred

Nothing is committed, so `git show HEAD:<path>` still holds every original. A
single `git add -A` makes the loss permanent and silent. That is one routine
command away, which is why this is ordered first.

## G-7 — deferred, but recorded rather than dropped

G-7: the runtime returns `committedLocally: true` for writes that never reach
the audit log. Reproduced three times — phase-3c, phase-7 assess, phase-7
analyze; `kbd audit` mentions phase-7 zero times.

**Fixing the write path is out of scope** — it is a runtime defect needing its
own investigation, and this phase cannot absorb it.

**But it must not simply vanish.** It was carried as a prerequisite through both
the assess and analyze handoffs with the requirement "treat the filesystem as
authoritative; do not trust the canonical runtime as the record." A prerequisite
that neither ships nor is explicitly deferred is a prerequisite that got dropped
— the exact failure that lost G-6 from the first analyze draft and cost three
adversarial-review rounds to catch.

So this change records the deferral as a decision (task 3.3), with the
filesystem-authoritative rule stated as an operating constraint for the
remainder of phase-7. The deferral is a choice on the record, not an omission.
