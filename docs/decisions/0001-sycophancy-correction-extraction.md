# ADR-0001 — Sycophancy-correction extraction

- **Status:** Accepted — Option A (extract to own repo)
- **Decided by:** Travis James, 2026-05-20
- **Date:** 2026-05-20
- **Phase:** phase-0-unblock
- **Authors:** Claude Code on behalf of Travis James

## Context

`sycophancy-correction` is currently maintained inside
`prometheus-skill-pack/skills/imported/sycophancy-correction/`. It is imported
by `artifact-refiner` skills via a relative path that assumes
`prometheus-skill-pack` is a sibling checkout on disk (or that
`artifact-refiner` lives as a subdirectory inside it).

Plans for the `phase-ideation-to-app-pipeline` pipeline call for
`artifact-refiner` to be added as a submodule of `prometheus-skill-pack`.
Combined with the existing reverse relative path import, this produces a
cycle:

```
prometheus-skill-pack ──submodule──▶ artifact-refiner
artifact-refiner      ──relative path──▶ prometheus-skill-pack/skills/imported/sycophancy-correction
```

A cycle in a submodule graph is not resolvable at clone time without manual
`git submodule update` runs in a specific order, and is brittle under CI
that clones fresh.

The governance question is: **where does sycophancy-correction's source of
truth live, such that both packs can consume it without a cycle?**

## Decision

**Option A — Extract `sycophancy-correction` to its own GitHub repository.**

Authorized by Travis James on 2026-05-20. Phase-1-submodule-topology will
plan against this decision. A separate phase (`phase-sc-extraction`) tracks
the extraction work itself.

## Options

### Option A — Extract `sycophancy-correction` to its own GitHub repository

Move `sycophancy-correction` to a standalone repo (suggested name:
`sycophancy-correction-skill` under the same owner). Both
`prometheus-skill-pack` and `artifact-refiner` consume it as a submodule
pointed at the standalone repo.

```
sycophancy-correction (standalone repo)
        ▲                ▲
        │ submodule       │ submodule
        │                 │
prometheus-skill-pack  artifact-refiner
        ▲
        │ submodule
        │
(artifact-refiner if/when re-submoduled into prometheus pack — still a DAG)
```

**Pros:**
- Clean DAG; no cycle under any configuration.
- One source of truth; bug fixes land in one place and propagate by submodule bump.
- Standard pattern; CI clones reliably.
- Independent version tagging; downstream packs pin to specific releases.

**Cons:**
- One-time extraction cost: `git filter-repo` or fresh-init with curated commits.
- Two consumers must now bump submodule pointers on updates.
- New repo to maintain (CI, README, release process).
- If `sycophancy-correction` currently has any deep internal coupling to
  `prometheus-skill-pack` infrastructure (shared `shared/` lib, common scripts),
  that coupling must be either broken or vendored.

**Estimated cost:** half a session for extraction; one session for downstream
wiring updates.

### Option B — Vendor a snapshot into `artifact-refiner`

Copy current `sycophancy-correction` source into `artifact-refiner/shared/sycophancy-correction/`
and consume locally. `prometheus-skill-pack` remains the canonical home.

**Pros:**
- No new repo; trivial to land.
- No cycle.
- Per-pack snapshots can diverge intentionally if `artifact-refiner` needs a
  customized variant.

**Cons:**
- Two copies drift; updates are manual `cp -R`.
- Loss of canonical source of truth.
- Risk of one pack having a bug fix the other doesn't.
- Long-term maintenance is worse than Option A despite lower upfront cost.

**Estimated cost:** 30 minutes.

### Option C — Accept the cycle

Document the required clone order: clone `prometheus-skill-pack` first with
`--recurse-submodules`, then `artifact-refiner` resolves its relative path
into the existing sibling tree.

**Pros:**
- No code or repo changes.

**Cons:**
- CI fragility. Fresh clones in isolation fail.
- Other consumers cloning `artifact-refiner` alone have no `sycophancy-correction`.
- This is not a real fix; it just defers the pain.

**Estimated cost:** zero, but cost reappears every time someone clones the wrong order.

## Recommendation

**Option A** — extract to its own repo. The cost is bounded (≤2 sessions),
the resulting topology is a DAG, and every other approach has worse long-term
maintenance.

If the user is not ready to commit to Option A in the immediate term,
**Option B** is acceptable as a temporary measure with a tracking issue to
migrate to A within a defined window (suggested: before phase-1-submodule-topology
ships).

**Option C** is rejected as a permanent solution. It is acceptable only as a
documented gap while either A or B is being implemented.

## Consequences

### If Option A is chosen

- New repo created with current `sycophancy-correction` history (or fresh init if history is not worth preserving).
- `prometheus-skill-pack` and `artifact-refiner` both add it as a submodule (suggested path: `shared/sycophancy-correction/` in each).
- All existing relative-path imports in `artifact-refiner` and
  `prometheus-skill-pack` are updated to reference the submodule path.
- A separate KBD phase (`phase-sc-extraction`) tracks the extraction work.

### If Option B is chosen

- Snapshot copied to `artifact-refiner/shared/sycophancy-correction/`.
- Existing imports updated to the new local path.
- Tracking issue created to migrate to Option A.

### If Option C is chosen (not recommended)

- Document the required clone order in `README.md` and CI scripts.
- Continue with current relative paths.
- Re-open this ADR if cycle pain materializes.

## Open question for user

Which option (A / B / C)? Phase-1-submodule-topology cannot plan cleanly
without this decision.

> **Resolved:** Option A. Authorized by Travis James 2026-05-20.

---

## Addendum (2026-05-20) — Option A realization status

When phase-sc-extraction was assessed it was discovered that **Option A is
already realized**:

- The standalone repo exists at `https://github.com/Know-Me-Tools/sycophancy-correction-skill.git`.
- `prometheus-skill-pack` already consumes it as a submodule
  (path `skills/imported/sycophancy-correction/`, URL declared in its
  `.gitmodules`, pinned to SHA `01150389...` on `main`).
- The directory inside `prometheus-skill-pack` is a 68-byte gitlink, not an
  embedded copy.

Therefore the "extraction" portion of this ADR is **done by prior work**
(likely an earlier session). The remaining downstream consumption — adding
the standalone repo as a submodule of `artifact-refiner` — landed in
**phase-sc-extraction** on 2026-05-20:

- Submodule added at `shared/sycophancy-correction/`.
- Pinned to SHA `01150389c10169816fbd4cc4ef4145fbe052ad90` matching
  `prometheus-skill-pack`'s pin (lockstep alignment).
- `.gitmodules` updated; `scripts/setup-submodules.sh` now initializes it
  alongside `tools/rust-mcp-filesystem`.

The DAG is now complete:

```
Know-Me-Tools/sycophancy-correction-skill (standalone)
        ▲                     ▲
        │ submodule            │ submodule
        │                      │
prometheus-skill-pack      artifact-refiner
```

No cycle. Both consumers bump independently. Recommended cadence: align
bumps on each release of sycophancy-correction.
