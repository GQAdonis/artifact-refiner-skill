# Tasks: p7-01-restore-phase-records

**scope**:
- `.kbd-orchestrator/phases/*/progress.json` (12 files)
- `.kbd-orchestrator/phases/phase-7-scaffold-ag-ui-host/decision-log.md`
  (appended — G-7 deferral in both branches; supersession decision in branch 3)

## Decision

- [x] 1.1 Confirm with the operator: restore narrative records from git HEAD, **or**
      record an explicit decision that runtime counters supersede them.
      Do not choose silently — this determines whether phase history survives.
- [x] 1.2 Record the answer as a timestamped `## Operator confirmation` entry in
      `.kbd-orchestrator/phases/phase-7-scaffold-ag-ui-host/decision-log.md`,
      naming the chosen branch. "Operator" = whoever is driving this session;
      an unanswered prompt is **not** consent, and every task below that says
      "confirm the operator" means this recorded entry, not an inferred
      agreement. Without the entry, gate 5.3 fails and the phase stays blocked —
      which is the intended behaviour when nobody has actually decided.

## If restoring (default)

- [x] 2.1 For each of the 12 `.kbd-orchestrator/phases/*/progress.json`, diff the
      git HEAD version against the working tree and list which named fields
      (`scope_note`, `live_verification`, `acceptance_gates_all_pass`,
      `execution_path`, `port_correction`, …) exist only in HEAD.
- [x] 2.2 Merge: restore the HEAD narrative fields **while keeping** the runtime
      fields the migration added (`completion`, `schemaVersion`, `phaseId`,
      `migrationStatus`). Do not simply `git checkout` the files — that would
      discard the canonical `completion` object the migration correctly produced.
- [x] 2.3 Verify every merged file is valid JSON.
- [x] 2.4 Verify by named field, never by key count: assert `scope_note` is
      present in `phase-1b-inference-routing/progress.json`. Key counts collide
      (both versions have 19 keys) and would give a false pass.

## If superseding (branch 3 — only when 1.1 chose supersede)

- [~] 3.1 (N/A — restore branch chosen) Write the decision, its rationale, and what is being given up to
      `.kbd-orchestrator/phases/phase-7-scaffold-ag-ui-host/decision-log.md`.
- [~] 3.2 (N/A — restore branch chosen) Confirm the operator accepts that phase narrative history is
      unrecoverable once committed.

## Record the G-7 deferral (ALWAYS — runs in both branches)

- [x] 4.1 Append a G-7 entry to
      `.kbd-orchestrator/phases/phase-7-scaffold-ag-ui-host/decision-log.md`:
      the runtime reports `committedLocally: true` for writes absent from the
      audit log (reproduced 3×); fixing the write path is deferred to its own
      investigation; **the filesystem is authoritative for phase-7 records**.
      Recording the deferral is what keeps it from silently disappearing the way
      G-6 did between analyze drafts.
- [x] 4.2 Confirm the operator accepts the deferral rather than assuming it.

## Gate

- [x] 5.1 `git diff --stat .kbd-orchestrator/phases/` shows exactly the declared
      scope: the 12 `progress.json` files plus the `decision-log.md` append —
      and nothing else.
- [x] 5.2 `decision-log.md` contains a G-7 entry (assert by grep, not by eye).
- [x] 5.3 `decision-log.md` contains an `## Operator confirmation` entry naming
      the chosen branch (assert by grep). This is the only machine-checkable
      proof that a human made the call rather than the agent assuming it.
- [x] 5.4 No other p7-* change starts until this one is complete.
