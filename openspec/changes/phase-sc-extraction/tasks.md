# Tasks: phase-sc-extraction (wiring)

## 1. Add the submodule

- [ ] 1.1 Verify the remote is still reachable: `git ls-remote https://github.com/Know-Me-Tools/sycophancy-correction-skill | head -3`. If unreachable, halt and escalate.
- [ ] 1.2 Identify the pin target: prefer a release tag if one exists newer than the SHA `prometheus-skill-pack` uses. Default fallback: SHA `01150389c10169816fbd4cc4ef4145fbe052ad90` (matches prometheus-skill-pack on 2026-05-20).
- [ ] 1.3 `git submodule add https://github.com/Know-Me-Tools/sycophancy-correction-skill.git shared/sycophancy-correction`.
- [ ] 1.4 `cd shared/sycophancy-correction && git checkout <pin-target> && cd ../..`.
- [ ] 1.5 Verify `.gitmodules` now declares both `tools/rust-mcp-filesystem` and `shared/sycophancy-correction`.
- [ ] 1.6 `git submodule status` shows both entries.

## 2. Update `scripts/setup-submodules.sh`

- [ ] 2.1 Remove the "sycophancy-correction submodule is pending" warning block.
- [ ] 2.2 No replacement code needed — the existing `git submodule update --init --recursive` call now handles it.

## 3. Update `README.md`

- [ ] 3.1 In the "Submodules and vendored binaries" table, change the sycophancy-correction row: drop `*(pending)*` annotation; set Source to `Know-Me-Tools/sycophancy-correction-skill` with the pin.
- [ ] 3.2 Drop the explanatory sentence about phase-sc-extraction being pending.

## 4. Append ADR-0001 addendum

- [ ] 4.1 Append to `docs/decisions/0001-sycophancy-correction-extraction.md`:
  - Section: "## Addendum (2026-05-20) — Option A realization status"
  - Content: confirms the standalone repo exists at `Know-Me-Tools/sycophancy-correction-skill`, that `prometheus-skill-pack` already consumes it, and that `artifact-refiner` consumes it as of phase-sc-extraction.

## 5. Acceptance gates

- [ ] 5.1 `git submodule status` lists both submodules with clean SHAs.
- [ ] 5.2 `bash scripts/setup-submodules.sh` runs without the "pending" warning.
- [ ] 5.3 README does not mention `*(pending)*` for sycophancy-correction.
- [ ] 5.4 ADR-0001 has the addendum section.

## Out of scope

- Building / installing the sycophancy-correction binary.
- Wiring artifact-refiner PMPO loop to invoke the sycophancy MCP server.
- Forking the repo.

## Recommended agents

| Tasks | Agent |
|---|---|
| 1.* | direct shell |
| 2.*, 3.*, 4.* | direct edit |
| 5.* | verify-app |
