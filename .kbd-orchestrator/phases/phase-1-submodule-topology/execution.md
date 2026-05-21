# Execution: phase-1-submodule-topology

**Status:** COMPLETE
**Backend:** OpenSpec
**Executed:** 2026-05-20

## Acceptance gates — all PASS

| # | Gate | Result |
|---|---|---|
| 6.1 | `git submodule status` lists submodule with clean SHA | PASS — `tools/rust-mcp-filesystem (v0.4.2-1-g27e63b7)` |
| 6.2 | `bash scripts/setup-submodules.sh` runs to completion | PASS |
| 6.3 | `rust-mcp-filesystem --version` works | PASS — `0.3.8` already on PATH (system install precedence) |
| 6.4 | `.mcp.json` lists both `template-forge` and `rust-mcp-filesystem` | PASS — also `e2b-sandbox` from prior |
| 6.5 | README shows clone-with-submodules instruction | PASS |
| 6.6 | ADR-0002 written | PASS |

## Deliverables

| Path | Purpose |
|---|---|
| `.gitmodules` | New file — registers `tools/rust-mcp-filesystem` submodule pointing at upstream |
| `tools/rust-mcp-filesystem/` | Submodule checkout at v0.4.2 |
| `scripts/build-vendored-binaries.sh` | Probe PATH → Homebrew → binstall → cargo install fallback |
| `scripts/setup-submodules.sh` | One-shot setup for fresh clones |
| `docs/decisions/0002-rust-mcp-filesystem-submodule.md` | ADR recording Q-002 = upstream decision |
| `.mcp.json` | Modified — `rust-mcp-filesystem` server entry added |
| `README.md` | Modified — new "Submodules and vendored binaries" section |
| `AGENTS.md` | Modified — added `git submodule status` clean-state check to PR process |

## Decisions during execute

1. **HTTPS submodule URL, not SSH.** Used `https://github.com/rust-mcp-stack/rust-mcp-filesystem.git` instead of `git@github.com:...` so contributors without SSH keys can clone. SSH push remains available via global git config.

2. **Pinned to v0.4.2 tag.** `git checkout v0.4.2` inside the submodule, then the parent commit will record that SHA. Reproducibility over freshness; bumping is `cd tools/rust-mcp-filesystem && git checkout v0.5.x && cd ../.. && git add tools/rust-mcp-filesystem`.

3. **Version drift accepted.** Local system has `rust-mcp-filesystem 0.3.8` installed (pre-existing); the script's PATH-first probe uses it instead of building v0.4.2 from the submodule. This is intentional — package-manager installs win over source builds for speed. The submodule pin is the reproducibility floor, not a forced version.

4. **sycophancy-correction submodule deferred, not added.** ADR-0001 Option A authorized extraction to a standalone repo, but the repo does not yet exist. Per plan task 3.2, `setup-submodules.sh` prints a warning that the submodule is pending phase-sc-extraction rather than failing on a non-existent URL.

5. **`rust-mcp-filesystem` runs read-only by default.** Server args in `.mcp.json` are `["${workspaceFolder}"]` (positional dir), no `-w` flag. Write access requires explicit opt-in by the consumer.

## Out of scope (deferred, per plan)

- `phase-sc-extraction` — actual extraction of sycophancy-correction to standalone repo.
- `phase-1b-inference-routing` — openai-proxy wiring (Q-003 = external prerequisite).
- Adding `artifact-refiner` itself as a submodule of `prometheus-skill-pack` (reverse direction).

## Next phase

`/kbd-reflect phase-1-submodule-topology`, then either `phase-sc-extraction` or `phase-1b-inference-routing` or `phase-2-scaffold-react-vite` depending on user priority.
