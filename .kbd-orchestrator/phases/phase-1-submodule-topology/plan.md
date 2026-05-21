# Plan: phase-1-submodule-topology

**Backend:** OpenSpec (`openspec/changes/phase-1-submodule-topology/`)
**Tasks:** `openspec/changes/phase-1-submodule-topology/tasks.md`
**Design:** `openspec/changes/phase-1-submodule-topology/design.md`
**Proposal:** `openspec/changes/phase-1-submodule-topology/proposal.md`

## Decisions applied (from user authorization 2026-05-20)

- **Q-001 = A:** sycophancy-correction extracted to standalone repo. Submodule path documented here; actual `submodule add` happens in `phase-sc-extraction`.
- **Q-002 = upstream:** `rust-mcp-filesystem` submodule points at `rust-mcp-stack/rust-mcp-filesystem`, not the GQAdonis fork.

## Ordered change list

| # | Change | Section | Gate |
|---|---|---|---|
| 1 | Add rust-mcp-filesystem submodule (upstream) | 1 | `git submodule status` clean |
| 2 | Build/install probe + .mcp.json merge | 2 | binary on PATH + JSON valid |
| 3 | Document sycophancy submodule path (no add) | 3 | ADR-0002 written |
| 4 | setup-submodules.sh entry script | 4 | runs to completion on fresh clone |
| 5 | README / AGENTS.md doc updates | 5 | clone instructions present |
| 6 | Acceptance gates | 6 | verify-app |

## Sequencing

Strictly ordered. Sections 1 → 2 → 3 → 4 → 5 → 6.

## Estimated effort

One focused session.

## Dependency on prior phases

This phase can run in parallel with `phase-rust-workspace-bootstrap` because they touch different surfaces (this phase: `tools/rust-mcp-filesystem/`, `shared/`, `.gitmodules`, `scripts/setup-submodules.sh`, `scripts/build-vendored-binaries.sh`; prior phase: `tools/template-forge-rs/`, `assets/library/`, `scripts/install-template-forge.sh`).

The `.mcp.json` edit in task 2.3 must be ordered after the prior phase's `.mcp.json` edit OR both edits must be aware of each other. Recommendation: run phase-rust-workspace-bootstrap to completion first so its `.mcp.json` entry exists when this phase merges.

## Risk register

| Risk | Mitigation |
|---|---|
| Upstream rust-mcp-filesystem API drifts | Pin to a specific tag in `git submodule add`, not `main` |
| Build from submodule fails on fresh clone | Probe binary on PATH first; submodule build is the fallback |
| `.mcp.json` clobbered by parallel phase | Plan task 2.3 reads existing JSON first |
| Sycophancy submodule URL changes after extraction | The submodule line is documented here but not executed; phase-sc-extraction will land the actual `submodule add` with the final URL |
