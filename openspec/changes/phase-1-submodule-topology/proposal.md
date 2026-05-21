# Proposal: phase-1-submodule-topology

## Why

Phase-2 (scaffold-react-vite) and later scaffolders need:

1. **A reliable filesystem MCP surface** when the host harness doesn't provide one (e.g., Antigravity 2.0, Claude Desktop, arbitrary MCP clients). `rust-mcp-filesystem` already implements 24 file operations as a battle-tested Rust binary.
2. **A non-cyclic governance topology** for `sycophancy-correction`, which is imported by both `prometheus-skill-pack` and `artifact-refiner`. ADR-0001 was accepted on 2026-05-20 selecting **Option A** (extract to own repo).

This phase wires both submodule paths so phase-2 has the dependencies it needs at clone-time.

## What Changes

- **ADDED** `tools/rust-mcp-filesystem/` — git submodule pointing at upstream `git@github.com:rust-mcp-stack/rust-mcp-filesystem.git`. Per Q-002 decision: upstream, not fork.
- **ADDED** `shared/sycophancy-correction/` — git submodule pointing at the new standalone repo (to be created in `phase-sc-extraction`, a separate phase). Until that phase runs, this submodule path is documented in the plan but the actual `git submodule add` waits for the standalone repo to exist.
- **ADDED** `.gitmodules` — submodule registry (created/extended).
- **ADDED** `scripts/setup-submodules.sh` — one-shot init + update for fresh clones.
- **MODIFIED** `.mcp.json` — register the `rust-mcp-filesystem` server entry alongside the `template-forge` entry from `phase-rust-workspace-bootstrap`.
- **MODIFIED** `scripts/install-template-forge.sh` (or new `scripts/build-vendored-binaries.sh`) — build `rust-mcp-filesystem` as part of installation when not available via package manager.
- **MODIFIED** `AGENTS.md` — add submodule init step to the contributor checklist.
- **MODIFIED** `README.md` — add `git clone --recurse-submodules` instructions.
- **ADDED** `docs/decisions/0002-rust-mcp-filesystem-submodule.md` — short ADR recording the decision to consume upstream, not fork.

## Impact

### Affected surfaces

- `.gitmodules`, `tools/`, `shared/`, `scripts/`, `.mcp.json`, top-level docs.

### Affected dependencies

- One new git submodule (`rust-mcp-filesystem`).
- One planned submodule (`sycophancy-correction`) — added only after standalone repo exists.

### Risk surface

- **Low** for the rust-mcp-filesystem submodule — upstream is active and ships binaries; we can probe for installed binary first and only build from submodule if absent.
- **Medium** for the sycophancy-correction submodule — depends on extraction work in a separate phase. Phase-1 documents the path but does not execute the `submodule add` for it.
- **Low** for `.mcp.json` changes — additive.

### Out of scope (deferred)

- `phase-sc-extraction` — actually extracting `sycophancy-correction` to a standalone repo (separate phase, must run before this phase's sycophancy submodule line is executed).
- `phase-1b-inference-routing` — `openai-proxy` wiring (Q-003: external prerequisite). Separate phase.
- Submoduling `openai-proxy`, `artifact-refiner` itself into `prometheus-skill-pack`, or any other DAG nodes beyond the two named.

## Dependency on prior decisions

| Decision | Source | Applied |
|---|---|---|
| ADR-0001 Option A (sycophancy-correction → standalone repo) | `docs/decisions/0001-sycophancy-correction-extraction.md` | This phase consumes the to-be-extracted repo as a submodule |
| Q-002 upstream rust-mcp-filesystem | Q&A 2026-05-20 | This phase points at `rust-mcp-stack/rust-mcp-filesystem`, not the fork |
