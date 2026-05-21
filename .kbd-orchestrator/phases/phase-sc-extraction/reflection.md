# Reflection: phase-sc-extraction

**Date:** 2026-05-20
**Scope outcome:** Wiring (not extraction — extraction was already done by prior work)

## Goal Achievement

| Goal | Status |
|---|---|
| Add `shared/sycophancy-correction` submodule | MET |
| Pin to SHA matching `prometheus-skill-pack` | MET (`01150389`) |
| Remove "pending" warning from setup-submodules.sh | MET |
| Update README to drop `*(pending)*` annotation | MET |
| Append ADR-0001 addendum recording Option A realization | MET |
| Acceptance gates pass | MET (4/4) |

**Achievement: 6/6 MET (100%).**

## Delivered Changes

| Path | Change |
|---|---|
| `.gitmodules` | added submodule entry |
| `shared/sycophancy-correction/` | submodule at SHA `01150389` |
| `scripts/setup-submodules.sh` | removed pending warning |
| `README.md` | submodule table row updated |
| `docs/decisions/0001-sycophancy-correction-extraction.md` | resolved + addendum section |

## Artifact Quality Summary

| Metric | Value |
|---|---|
| Changes with QA | 5/5 |
| First-pass pass rate | 5/5 (100%) |
| Acceptance gates | 4/4 PASS |
| Constraint violations | 0 |
| Wall time | ~10 minutes |

### Recurring Constraint Violations

None.

## Technical Debt Introduced

| Debt | Severity |
|---|---|
| `scripts/build-vendored-binaries.sh` still only handles `rust-mcp-filesystem` — does not build/install the sycophancy-correction MCP binary | Low |
| `artifact-refiner` PMPO loop does not yet invoke the sycophancy MCP server (consumption wiring deferred) | Low |
| No release tags on `Know-Me-Tools/sycophancy-correction-skill` — pin must be SHA-based until first tag | Low |

None blocking.

## Lessons Captured

### Lesson 1 — Verify reality before planning every phase

The original ADR-0001 framed phase-sc-extraction as 1.5 sessions of extraction + wiring. The assessment, done by checking actual filesystem state (`prometheus-skill-pack/.gitmodules`, the `.git` file inside the submodule directory, `git ls-remote` on the standalone repo URL), discovered extraction was already done. Phase reduced to **10 minutes**. The cost of this verification: <2 minutes. The savings: ~80% of phase effort.

**Generalized rule:** before planning, spend a few minutes verifying that the phase's premise still holds. Premises rot.

### Lesson 2 — Pre-existing work is data, not failure

Discovering that someone (likely the user) had already extracted sycophancy-correction was not a "we missed it" event — it's normal evolution of a project across sessions. The correction is to **incorporate** it, not regret missing it. Treating prior work as a free win speeds the next phase; treating it as a planning failure slows everything.

### Lesson 3 — Preserve resolved-but-historical content in ADRs

ADR-0001's "Open question" section could have been deleted once resolved. Keeping it (with a "Resolved: Option A" quote) preserves the reasoning trail. Future contributors reading the ADR understand both the framing and the outcome.

### Lesson 4 — SHA pinning matches lockstep alignment

Both `prometheus-skill-pack` and `artifact-refiner` now pin sycophancy-correction at SHA `01150389`. When the upstream cuts a release tag, recommend both consumers bump together. This keeps the two skill packs functionally equivalent on this dependency.

## Recommended Focus for Next Phase

Per user chain request: `/kbd-assess phase-1b-inference-routing`.

This is now correctly sequenced:

- Q-003 = B (external prerequisite) is already authorized.
- `openai-proxy` is a single-purpose change (wire it as an external endpoint into the model-routing reference and `.kbd-orchestrator/project.json`).
- It does not depend on phase-2 (scaffold-react-vite); scaffold-react-vite *benefits from* it but does not require it.

## Knowledge Base Hooks

- "Verify reality before planning every phase; premises rot"
- "Pre-existing work is data, not failure"
- "Preserve resolved-but-historical content in ADRs as reasoning trail"
- "SHA pin shared consumers in lockstep; bump together on upstream releases"

Completed kbd-reflect — phase-sc-extraction
