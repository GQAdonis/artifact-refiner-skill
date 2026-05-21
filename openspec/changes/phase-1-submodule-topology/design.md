# Design: phase-1-submodule-topology

## Submodule topology (final state after this phase + phase-sc-extraction)

```
artifact-refiner/
├── tools/
│   ├── template-forge-rs/          ◀── owned (from phase-rust-workspace-bootstrap)
│   └── rust-mcp-filesystem/        ◀── submodule (upstream rust-mcp-stack)
├── shared/
│   └── sycophancy-correction/      ◀── submodule (standalone repo, after phase-sc-extraction)
└── ...
```

DAG (no cycles):

```
sycophancy-correction ◀── consumed by ──── artifact-refiner
                       ◀── consumed by ──── prometheus-skill-pack

rust-mcp-filesystem   ◀── consumed by ──── artifact-refiner
```

## Decision 1 — Upstream rust-mcp-filesystem, not the fork

Authorized by user 2026-05-20 (Q-002 = upstream).

**Rationale:** No known patches needed. Upstream ships binaries via brew, cargo-binstall, npm, Docker, and prebuilt releases. Switching to fork later is a one-line `.gitmodules` URL change if patches become necessary.

## Decision 2 — Sycophancy-correction submodule path documented but not executed

The submodule wiring for `shared/sycophancy-correction/` is documented in this phase but the actual `git submodule add` waits for `phase-sc-extraction` to create the standalone repo. Why split:

- This phase ships independently of when the extraction work happens.
- Phase-2 (scaffold-react-vite) does not depend on sycophancy-correction; it depends on rust-mcp-filesystem.
- Trying to add a submodule pointing at a non-existent repo would fail and stall this phase.

## Decision 3 — Vendored-binaries install model

`rust-mcp-filesystem` upstream provides multiple install paths. Our script probes in order:

1. Binary already on PATH (any source). Use it.
2. `brew install rust-mcp-stack/tap/rust-mcp-filesystem` if Homebrew is present.
3. `cargo install --path tools/rust-mcp-filesystem` from the submodule.

We do NOT force users to build from source if a package-manager install is faster. Submodule existence is a fallback / reproducibility guarantee, not the primary install path.

## Decision 4 — `.mcp.json` is additive, not replaced

This phase merges its server entry with whatever is already in `.mcp.json` (likely the `template-forge` entry from phase-rust-workspace-bootstrap). Plan task 2.3 explicitly requires reading the file first to avoid clobbering existing entries.

## Non-decisions (out of scope)

- Whether to ship our own filesystem MCP tools beyond what rust-mcp-filesystem provides (deferred until a concrete gap surfaces).
- Whether to vendor `openai-proxy` (Q-003 = external prerequisite; phase-1b).
- Whether `artifact-refiner` becomes a submodule of `prometheus-skill-pack` (separate, reverse-direction concern).
