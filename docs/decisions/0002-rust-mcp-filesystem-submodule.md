# ADR-0002 — rust-mcp-filesystem source choice

- **Status:** Accepted
- **Date:** 2026-05-20
- **Phase:** phase-1-submodule-topology
- **Authors:** Claude Code on behalf of Travis James

## Context

`artifact-refiner` needs a reliable filesystem MCP surface for harnesses that do not provide one (Antigravity 2.0, Claude Desktop without `--add-dir`, arbitrary MCP clients). `rust-mcp-filesystem` already implements 24 tools as a battle-tested Rust binary. Two viable sources existed:

- **Upstream:** `https://github.com/rust-mcp-stack/rust-mcp-filesystem` — active maintainer, tagged releases (v0.4.2 at decision time), distributed via Homebrew tap, cargo-binstall, npm, Docker, and prebuilt binaries.
- **Fork:** `git@github.com:GQAdonis/rust-mcp-filesystem.git` — owned by the user.

## Decision

**Use upstream.** Submodule at `tools/rust-mcp-filesystem/` points at `https://github.com/rust-mcp-stack/rust-mcp-filesystem`, pinned to tag `v0.4.2`.

## Rationale

1. No patches are currently needed against upstream.
2. Upstream's release cadence is healthy and packaging is broad (Homebrew/npm/binstall/Docker). Consumers can install via package manager when available; submodule build is the reproducibility fallback.
3. Switching to fork later is a one-line URL change in `.gitmodules` if patches become necessary.
4. Maintaining a fork is non-trivial: rebase against upstream on each release, retest 24 tools. We avoid that cost until concrete benefit is identified.

## Consequences

- The `setup-submodules.sh` script does `git submodule update --init` then defers to `scripts/build-vendored-binaries.sh`.
- `scripts/build-vendored-binaries.sh` probes PATH first, then tries Homebrew (`brew install rust-mcp-stack/tap/rust-mcp-filesystem`), then cargo-binstall, then `cargo install --path` from the submodule as final fallback. This is intentional — package-manager installs are faster than building from source.
- The submodule pin (`v0.4.2`) protects against accidental drift; updating to a newer release is `cd tools/rust-mcp-filesystem && git checkout v0.5.x && cd ../.. && git add tools/rust-mcp-filesystem`.

## Revisit conditions

Promote to fork (or to an internal hard-fork) if any of:

- We need a tool the upstream does not provide (and a contribution PR is rejected).
- We need a tool to behave differently from upstream for a security or compliance reason.
- Upstream goes inactive (no releases in 6+ months).
