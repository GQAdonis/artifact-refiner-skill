# Reflection: phase-1-submodule-topology

**Date:** 2026-05-20

## Goal Achievement

| Goal | Status |
|---|---|
| Add rust-mcp-filesystem submodule pointing at upstream | MET (v0.4.2, HTTPS URL) |
| Build/install probe script | MET (`scripts/build-vendored-binaries.sh`) |
| Setup script for fresh clones | MET (`scripts/setup-submodules.sh`) |
| `.mcp.json` lists rust-mcp-filesystem alongside template-forge | MET |
| ADR-0002 recording Q-002 = upstream | MET |
| README + AGENTS.md updated | MET |
| Sycophancy-correction submodule path documented (not executed) | MET — warning surfaces from setup script |

**Achievement: 7/7 MET (100%).**

## Delivered Changes

| Path | Status |
|---|---|
| `.gitmodules` | created |
| `tools/rust-mcp-filesystem/` | submodule at v0.4.2 |
| `scripts/build-vendored-binaries.sh` | created, executable |
| `scripts/setup-submodules.sh` | created, executable |
| `docs/decisions/0002-rust-mcp-filesystem-submodule.md` | created |
| `.mcp.json` | modified (additive; 3 servers total) |
| `README.md` | modified (new Submodules section) |
| `AGENTS.md` | modified (PR checklist line added) |

## Artifact Quality Summary

| Metric | Value |
|---|---|
| Changes with QA | 6/6 |
| First-pass pass rate | 6/6 (100%) |
| Acceptance gates | 6/6 PASS |
| Constraint violations | 0 |

### Recurring Constraint Violations

None.

## Technical Debt Introduced

| Debt | Severity |
|---|---|
| sycophancy-correction submodule line is stub-warned, not active. Phase-sc-extraction must ship before any consumer of artifact-refiner can rely on it being present. | Medium |
| Local system `rust-mcp-filesystem 0.3.8` wins over submodule-pinned `v0.4.2`. Acceptable per ADR-0002 rationale; documented in execution.md. | Low |
| No CI step yet validates `git submodule status` cleanliness on PRs. | Low |

None blocking.

## Lessons Captured

### Lesson 1 — Submodule pinning needs a parent-commit step to stick

`git checkout v0.4.2` inside the submodule sets the working tree but doesn't persist until the parent repo `git add tools/rust-mcp-filesystem && git commit`s the new SHA. `git submodule update --init` will reset the submodule back to whatever the parent recorded. This is well-known git behavior but easy to forget. Document the bump procedure in the ADR so future contributors don't trip on it.

### Lesson 2 — PATH-first install probes match real-world install state

We didn't have to build rust-mcp-filesystem from source because v0.3.8 was already on the box from an earlier `cargo install` / Homebrew install. The probe order (PATH → Homebrew tap → cargo-binstall → source) is correct: it matches how users actually install Rust binaries.

### Lesson 3 — HTTPS submodule URLs are friendlier than SSH

SSH URLs (`git@github.com:...`) require an SSH key configured for GitHub. HTTPS URLs (`https://github.com/...`) work for any consumer. Push privileges are handled via `git config --global url."git@github.com:".insteadOf "https://github.com/"` for maintainers who prefer SSH. Default to HTTPS in `.gitmodules`.

### Lesson 4 — Read-only-by-default is a security feature, not a missing feature

`.mcp.json` registers `rust-mcp-filesystem` without `-w`. Users opt into write access explicitly. Mirrors the upstream README's design intent and is the correct default for a tool that an LLM will invoke autonomously.

### Lesson 5 — Documenting a pending submodule (instead of skipping it) preserves intent

The sycophancy-correction submodule line in `setup-submodules.sh` doesn't fail and doesn't pretend to work — it prints a warning that the work is queued. This is better than either silently omitting it (loses the reminder) or hard-failing (breaks fresh clones).

## Recommended Focus for Next Phase

Per user chain request: `/kbd-assess phase-sc-extraction`.

Phase-sc-extraction is the next correctly-sequenced step:

- Unblocks the documented-but-not-executed sycophancy-correction submodule line from this phase.
- Is small in scope (extraction is a well-bounded git operation + ADR follow-through, not a feature build).
- Frees phase-2 from any indirect dependency on prometheus-skill-pack.

## Knowledge Base Hooks

- "Submodule pin requires parent commit to persist; `git submodule update --init` will reset working tree"
- "PATH-first install probes match how users actually install"
- "HTTPS for `.gitmodules`, SSH for push via insteadOf rewrites"
- "Read-only-by-default for autonomous-LLM-invoked filesystem tools"
- "Document pending submodule lines as warnings, not silent omissions"

Completed kbd-reflect — phase-1-submodule-topology
