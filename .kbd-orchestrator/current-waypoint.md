# Current Waypoint

**Active phases (both planned):** `phase-rust-workspace-bootstrap`, `phase-1-submodule-topology`
**Stage:** both planned — ready to execute
**Recommended next command:** `/kbd-execute phase-rust-workspace-bootstrap`

## Decisions recorded

- **Q-001 = A** (sycophancy-correction → standalone repo). ADR-0001 status now **Accepted**.
- **Q-002 = upstream** (`rust-mcp-stack/rust-mcp-filesystem`, not fork).
- **Q-003 = B** (openai-proxy as external prerequisite). Applies to phase-1b.

## Sequencing

Run bootstrap first so its `.mcp.json` entry exists when phase-1 merges its rust-mcp-filesystem entry. The two phases are otherwise parallel-safe (different surfaces).

```
phase-rust-workspace-bootstrap  ▶ /kbd-execute  (do this first)
phase-1-submodule-topology      ▶ /kbd-execute  (immediately after)
```

## Phase scopes (compressed)

### phase-rust-workspace-bootstrap

Minijinja-only walking skeleton. 9 acceptance gates:

1. `cargo check --all-targets` exits 0
2. `cargo build --release` produces both binaries
3. `template-forge --version`
4. `template-forge list-engines` → `minijinja`
5. `template-forge list-brands` → `knowme`
6. Smoke render produces HTML containing `#E04E28`
7. `template-forge-mcp --probe` works
8. Install script installs both binaries
9. `.mcp.json` registers `template-forge`

### phase-1-submodule-topology

rust-mcp-filesystem (upstream) submodule + setup script + docs. 6 acceptance gates:

1. `git submodule status` clean
2. `setup-submodules.sh` runs to completion
3. `rust-mcp-filesystem --version` works
4. `.mcp.json` lists both servers
5. README shows clone-with-submodules instruction
6. ADR-0002 written

## Deferred phases (not planned yet)

- **phase-sc-extraction** — actually move sycophancy-correction to a standalone repo per ADR-0001 Option A. Phase-1 documents the submodule path but does not execute it.
- **phase-1b-inference-routing** — openai-proxy wiring per Q-003 = B.
- **phase-2-scaffold-react-vite** — first real scaffolder.

## Where we are in the pipeline

```
[phase-0-unblock]                                 ✅ complete
[phase-rust-workspace-bootstrap plan]             ✅
[phase-1-submodule-topology plan]                 ✅  ◀── here
[phase-rust-workspace-bootstrap execute]          ⏳ next
[phase-1-submodule-topology execute]
[phase-sc-extraction]                             deferred
[phase-1b-inference-routing]                      deferred
[phase-2-scaffold-react-vite]                     deferred
```
