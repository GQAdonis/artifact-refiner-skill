# Plan: phase-sc-extraction (wiring)

**Backend:** OpenSpec (`openspec/changes/phase-sc-extraction/`)
**Tasks:** `openspec/changes/phase-sc-extraction/tasks.md`
**Proposal:** `openspec/changes/phase-sc-extraction/proposal.md`
**Scope:** 30 minutes wall-time — single submodule add + 3 doc edits + 1 acceptance pass.

## Ordered change list

| # | Change | Section | Effort |
|---|---|---|---|
| 1 | Add `shared/sycophancy-correction` submodule pinned to SHA | tasks 1.* | 5 min |
| 2 | Remove "pending" warning from setup-submodules.sh | tasks 2.* | 2 min |
| 3 | Update README "Submodules and vendored binaries" section | tasks 3.* | 3 min |
| 4 | Append ADR-0001 addendum recording realization | tasks 4.* | 5 min |
| 5 | Acceptance gates | tasks 5.* | 2 min |

## Sequencing

Strictly sequential. Each step is small enough that batching adds no value.

## Decisions baked in

- **Pin target:** SHA `01150389c10169816fbd4cc4ef4145fbe052ad90` (matches `prometheus-skill-pack`). Bumping is later in lockstep with the parent pack.
- **Submodule path:** `shared/sycophancy-correction/` — `shared` matches the conceptual role (skill consumed by the PMPO loop, not a separately-installable binary).
- **No branch tracking** in `.gitmodules` — explicit SHA pin is the contract.
- **HTTPS URL**, matching phase-1 precedent.

## Risk

Single low-likelihood risk: remote unreachable at execute time. Task 1.1 includes a pre-flight `ls-remote` check that halts cleanly if so.

## Acceptance criteria

1. `git submodule status` lists both `tools/rust-mcp-filesystem` and `shared/sycophancy-correction` with clean SHAs.
2. `bash scripts/setup-submodules.sh` runs without the "pending" warning.
3. README no longer says `*(pending)*` for sycophancy-correction.
4. ADR-0001 has an addendum section dated 2026-05-20 recording Option A realization.
