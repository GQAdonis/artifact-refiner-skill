# Execution: phase-sc-extraction

**Status:** COMPLETE
**Backend:** OpenSpec
**Executed:** 2026-05-20 (~10 minutes wall)
**Scope:** Wiring only (extraction was already done by prior work)

## Acceptance gates — all PASS

| # | Gate | Result |
|---|---|---|
| 5.1 | Both submodules clean SHAs | PASS — `shared/sycophancy-correction (01150389)` + `tools/rust-mcp-filesystem (v0.4.2-1-g27e63b7)` |
| 5.2 | `setup-submodules.sh` no "pending" mention | PASS (0 occurrences) |
| 5.3 | README drops `*(pending)*` for sycophancy | PASS |
| 5.4 | ADR-0001 has addendum | PASS |

Bonus verification: `setup-submodules.sh` ran end-to-end with no warnings.

## Deliverables

| Path | Change |
|---|---|
| `.gitmodules` | added `shared/sycophancy-correction` entry |
| `shared/sycophancy-correction/` | submodule checkout at SHA `01150389` (matches `prometheus-skill-pack` pin) |
| `scripts/setup-submodules.sh` | removed "pending" warning block |
| `README.md` | submodule table row updated; explanatory paragraph removed |
| `docs/decisions/0001-sycophancy-correction-extraction.md` | "Decided by" line resolved + new "Addendum (2026-05-20)" section recording Option A realization |

## Decisions during execute

1. **No release tags exist** on the standalone repo — pinned to SHA `01150389` as planned. When the repo cuts its first tag, recommend bumping both consumers simultaneously.
2. **Branch context recorded.** Submodule HEAD reports `heads/main` so contributors can `cd shared/sycophancy-correction && git pull origin main` cleanly. Pin is still SHA-based; `main` tracking is a convenience for fetches, not the contract.
3. **ADR-0001 "Open question" section retained**, not deleted. Marked as resolved with a quote, preserving the historical artifact (someone reading the ADR later sees how the question was framed and resolved).

## Out of scope (deferred)

- Building / installing sycophancy-correction binary (`scripts/build-vendored-binaries.sh` only handles `rust-mcp-filesystem` right now; extend when a consumer needs the sycophancy MCP server).
- Wiring `artifact-refiner` PMPO loop to invoke the sycophancy MCP server (consumption phase, separate).
- Bumping `prometheus-skill-pack`'s pin (not our concern).

## Next phase

`/kbd-reflect phase-sc-extraction`.
