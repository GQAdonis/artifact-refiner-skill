# Proposal: phase-sc-extraction (re-scoped to wiring)

## Why

ADR-0001 Option A (extract `sycophancy-correction` to a standalone GitHub repo and have both `prometheus-skill-pack` and `artifact-refiner` consume it as a submodule) was authorized by user on 2026-05-20.

At assessment time it was discovered that **the standalone repo already exists** at `https://github.com/Know-Me-Tools/sycophancy-correction-skill.git` and `prometheus-skill-pack` already consumes it as a submodule. Verified:

- `prometheus-skill-pack/.gitmodules` declares it
- Submodule SHA `01150389...` on `main` matches the remote HEAD
- `prometheus-skill-pack/skills/imported/sycophancy-correction/.git` is a 68-byte gitlink (submodule), not an embedded copy
- Repo URL responds HTTP 200 and `git ls-remote` succeeds

Phase therefore reduces to: **add the existing standalone repo as a submodule of `artifact-refiner`.** All extraction work is already done.

## What Changes

- **ADDED** `shared/sycophancy-correction/` — git submodule pointing at `https://github.com/Know-Me-Tools/sycophancy-correction-skill.git`, pinned to SHA `01150389c10169816fbd4cc4ef4145fbe052ad90` (matching `prometheus-skill-pack`'s current pin) or a newer release tag if one exists at execute time.
- **MODIFIED** `.gitmodules` — adds the new submodule entry alongside the existing `tools/rust-mcp-filesystem` entry.
- **MODIFIED** `scripts/setup-submodules.sh` — replace the "pending" warning block with normal status reporting now that the submodule is real.
- **MODIFIED** `README.md` — change the "Submodules and vendored binaries" table: drop `*(pending)*` annotation; update the explanatory paragraph.
- **MODIFIED** `docs/decisions/0001-sycophancy-correction-extraction.md` — append an addendum recording that Option A is now fully realized via the existing `Know-Me-Tools/sycophancy-correction-skill` repo.

## Impact

### Affected surfaces

`.gitmodules`, `shared/`, `scripts/setup-submodules.sh`, `README.md`, `docs/decisions/0001-*.md`.

### Affected dependencies

One additional git submodule pointing at a public repository.

### Risk surface

- **Low** — submodule add of a public, already-consumed repo with a known-good pin.
- **Zero** — for the doc/script updates.

### Out of scope

- Building or installing any sycophancy-correction binary (deferred — no current consumer needs it).
- Wiring `artifact-refiner` PMPO loop calls to the sycophancy-correction MCP server (separate consumption phase).
- Forking the standalone repo (no justification).
- Bumping `prometheus-skill-pack`'s pin (not our concern).
