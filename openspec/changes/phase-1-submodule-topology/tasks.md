# Tasks: phase-1-submodule-topology

## 1. Add `rust-mcp-filesystem` upstream submodule

- [ ] 1.1 `git submodule add git@github.com:rust-mcp-stack/rust-mcp-filesystem.git tools/rust-mcp-filesystem`.
- [ ] 1.2 Pin to latest tagged release (probe with `git -C tools/rust-mcp-filesystem describe --tags --abbrev=0`).
- [ ] 1.3 Verify `.gitmodules` updated correctly.
- [ ] 1.4 Commit the submodule addition.

## 2. Build / install wiring for `rust-mcp-filesystem`

- [ ] 2.1 Author `scripts/build-vendored-binaries.sh`:
  - Probe for `rust-mcp-filesystem` already on PATH (e.g., installed via `brew install rust-mcp-stack/tap/rust-mcp-filesystem` or `cargo install`). If present, skip build.
  - Else build from submodule: `cargo install --path tools/rust-mcp-filesystem`.
  - Probe again to confirm binary is on PATH.
- [ ] 2.2 `chmod +x scripts/build-vendored-binaries.sh`.
- [ ] 2.3 Register `rust-mcp-filesystem` server in `.mcp.json`:
  ```json
  {
    "mcpServers": {
      "rust-mcp-filesystem": {
        "command": "rust-mcp-filesystem",
        "args": ["--allowed-dirs", "."],
        "transport": "stdio"
      }
    }
  }
  ```
  (Merged alongside existing `template-forge` entry from phase-rust-workspace-bootstrap. Do not overwrite.)
- [ ] 2.4 Validate `.mcp.json` parses.

## 3. Document the sycophancy-correction submodule path (without executing)

ADR-0001 Option A authorizes extraction to a standalone repo. That extraction is a separate phase (`phase-sc-extraction`) that has not yet run. This phase documents the eventual submodule wiring but does not execute `submodule add` until the standalone repo exists.

- [ ] 3.1 Write `docs/decisions/0002-rust-mcp-filesystem-submodule.md` recording Q-002 = upstream decision. Short ADR.
- [ ] 3.2 In `scripts/setup-submodules.sh` (created in task 4): include a stub line for `sycophancy-correction` that prints a clear message: "sycophancy-correction submodule will be added by phase-sc-extraction. Currently pending." Do not error.

## 4. Setup script for fresh clones

- [ ] 4.1 Author `scripts/setup-submodules.sh`:
  - Run `git submodule update --init --recursive`.
  - Invoke `scripts/build-vendored-binaries.sh`.
  - Print final status: which submodules initialized, which binaries are on PATH.
- [ ] 4.2 `chmod +x scripts/setup-submodules.sh`.

## 5. Documentation updates

- [ ] 5.1 Update `README.md` clone instructions:
  ```
  git clone --recurse-submodules <repo-url>
  cd artifact-refiner
  bash scripts/setup-submodules.sh
  ```
- [ ] 5.2 Update `AGENTS.md` Pull Request Process: add "Ensure `git submodule status` shows clean state".
- [ ] 5.3 In `README.md`, add a short section explaining the topology: rust-mcp-filesystem (upstream) provides file ops; sycophancy-correction (own repo) is pending extraction.

## 6. Acceptance gates

- [ ] 6.1 `git submodule status` lists `tools/rust-mcp-filesystem` with a clean SHA.
- [ ] 6.2 `bash scripts/setup-submodules.sh` runs to completion on a fresh clone.
- [ ] 6.3 `rust-mcp-filesystem --version` works after setup.
- [ ] 6.4 `.mcp.json` lists both `template-forge` (from prior phase) and `rust-mcp-filesystem` servers.
- [ ] 6.5 README shows the clone-with-submodules instruction.
- [ ] 6.6 ADR-0002 written.

## Out of scope (separate phases)

- `phase-sc-extraction` — actually move `sycophancy-correction` to a standalone repo and add its submodule.
- `phase-1b-inference-routing` — openai-proxy wiring (Q-003 = external prerequisite).
- Adding `artifact-refiner` itself as a submodule of `prometheus-skill-pack` (reverse direction; not this phase's concern).

## Recommended agents

| Tasks | Agent |
|---|---|
| 1.*, 2.* | direct shell + edit |
| 4.*, 5.* | direct edit |
| 6.* | `verify-app` |
