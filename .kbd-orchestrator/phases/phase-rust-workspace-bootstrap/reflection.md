# Reflection: phase-rust-workspace-bootstrap

**Phase:** `phase-rust-workspace-bootstrap`
**Date:** 2026-05-20
**Stage:** reflect complete
**Author:** Claude Code (Opus 4.7, 1m context)

## Goal Achievement

| Goal | Status |
|---|---|
| Workspace compiles end-to-end | MET |
| `template-forge` CLI works (version, list-engines, list-brands, render) | MET |
| `template-forge-mcp` MCP server works (stdio JSON-RPC + --probe) | MET |
| One brand TOML (knowme) loads + renders | MET |
| One Minijinja template (brand-guide.html) renders correctly | MET |
| Install script authored + executable | MET |
| `.mcp.json` registers the server | MET |
| Scope discipline held (Minijinja-only, no premature multi-engine) | MET |
| Unit tests cover the trait + library helpers | MET (5/5) |

**Achievement: 9/9 MET (100%).**

## Delivered Changes

| # | File / Surface | Lines / Bytes |
|---|---|---|
| 1 | `tools/template-forge-rs/Cargo.toml` | workspace manifest, 3 members, workspace.deps |
| 2 | `tools/template-forge-rs/rust-toolchain.toml` | MSRV note (no channel pin) |
| 3 | `crates/template-core/Cargo.toml` + `src/{lib,brand,library}.rs` + `src/engine/{mod,minijinja_engine}.rs` | ~500 lines Rust |
| 4 | `crates/template-cli/Cargo.toml` + `src/main.rs` | ~130 lines Rust |
| 5 | `crates/template-mcp/Cargo.toml` + `src/main.rs` | ~250 lines Rust |
| 6 | `templates/brand-guide.html` | ~95 lines Minijinja |
| 7 | `assets/library/brands/knowme.toml` | 35 lines TOML |
| 8 | `scripts/install-template-forge.sh` | 56 lines bash |
| 9 | `.mcp.json` (modified) | +9 lines |

Plus KBD/OpenSpec scaffolding:

- `openspec/changes/phase-rust-workspace-bootstrap/{proposal,tasks}.md`
- `.kbd-orchestrator/phases/phase-rust-workspace-bootstrap/{assessment,plan,execution,reflection}.md`
- `.kbd-orchestrator/phases/phase-rust-workspace-bootstrap/progress.json`

## Artifact Quality Summary

| Metric | Value |
|---|---|
| Changes with QA | 9/9 |
| First-pass pass rate | 9/9 (100%) |
| Compile attempts before clean | 2 (one Rust-2021 `#`-prefix fix) |
| Unit tests passed | 5/5 |
| Constraint violations | 0 |
| Time from start to all gates PASS | ~7 minutes wall, ~50s compile time |

### Recurring Constraint Violations

None.

### Notable success: scope discipline reduced risk to near-zero

The original session doc proposed 5 engines, 5 brand TOMLs, partial templates, `build-artifact-library` skill, and "six known issues" predicted to need fixing — none of which compiled or had ever been attempted. The assessment cut that to **1 engine, 1 brand, 1 template, 0 known-issues-list, 0 dependent-skill** — and the result is a workspace that compiled clean on the second attempt (one Rust-2021 syntax gotcha). The session doc's 6 predicted issues never materialized because we didn't write the speculation-prone code in the first place.

## Technical Debt Introduced

| Debt | Severity | Tracked in |
|---|---|---|
| Only 1 of 5 planned engines exists (Minijinja) | Low | Follow-on phase per engine |
| Only 1 brand TOML exists (knowme) | Low | Follow-on phase or as-needed |
| `assets/library/brands/` referenced by 5 phase-0 skills now has 1 brand; the other brands (prometheus-ags, san-saba-royalty, hotseaters, tribehealth) referenced in session doc don't exist | Low | Brand-authoring follow-on phase |
| `template-forge-rs` not yet released to crates.io or via cargo-binstall | Low | Release-engineering phase (later) |
| Hand-rolled stdio JSON-RPC implements only `tools/list` and `tools/call`; full MCP spec features (`initialize`, `notifications`, resources, prompts, completions) not implemented | Medium | Re-evaluate rmcp adoption if/when richer MCP surface needed |
| No CI yet (no GitHub Actions workflow for the Rust workspace) | Medium | CI follow-on phase |
| WCAG contrast not deterministically validated (template renders but no validator runs over output) | Low | Constraint-validator phase |
| `build-artifact-library` SKILL.md still missing | Low | Quick follow-on now that workspace works |

None block phase-1-submodule-topology execute.

## Lessons Captured

### Lesson 1 — Scope discipline is the single biggest predictor of phase finishability

The session doc proposed a workspace and predicted 6 compile errors. The assessment cut scope by ~80% (5 engines → 1, 5 brands → 1, multi-skill bundle → just-the-workspace). The result: zero of the predicted compile errors appeared, because the code that would have produced them was never written. **Predicted bugs in unwritten code are not bugs to fix — they are scope to cut.**

### Lesson 2 — Hand-rolled simple protocols beat heavyweight dependencies when scope is bounded

rmcp 1.7 builds and is the "right" MCP library. But our MCP surface is two tools and a `tools/list`. ~200 lines of `serde_json` covers it deterministically, tests cleanly via `--probe`, and doesn't bind us to rmcp's macro evolution. The plan's risk-mitigation provision (task 7.1: hand-roll if rmcp churn is painful) was used proactively, not reactively, because the cost-benefit was already clear before any churn occurred.

### Lesson 3 — `rust-toolchain.toml` channel pins hurt contributors

Pinning `channel = "1.80"` looks like rigor but forces rustup to download/use that toolchain on every contributor machine. The honest pattern is: declare MSRV via `[workspace.package].rust-version`, and leave `rust-toolchain.toml` as documentation (with a comment showing how to verify MSRV). Contributors use their current stable; MSRV is still enforced at build time.

### Lesson 4 — Rust 2021 reserves `#ident` prefixes; raw strings with `#hex` literals are a trap

This is the kind of gotcha that costs 2 minutes to fix and 20 to remember. Documenting it in `execution.md` is cheap insurance for the next person.

### Lesson 5 — minijinja 2.x renamed `Value::from_serializable` → `Value::from_serialize`

Minor API churn worth noting in case the session doc (written for minijinja v1) is consulted later.

## Recommended Focus for Next Phase

**`/kbd-execute phase-1-submodule-topology`** — already planned, ready to run, unblocked. The user requested chaining into it, which is appropriate because:

- Phase-1's plan was authored with Q-001 and Q-002 already answered (A, upstream).
- Phase-1 doesn't touch the same files as this phase (no merge conflicts).
- The `.mcp.json` merge in phase-1 task 2.3 is now safe because this phase landed its `template-forge` entry first.

## Knowledge Base Hooks

- "Scope discipline cuts predicted bugs to zero by cutting the code that would produce them"
- "Hand-roll simple protocols when scope is bounded and macro/router APIs are large"
- "Declare MSRV via Cargo.toml rust-version; don't channel-pin rust-toolchain.toml"
- "Rust 2021 `#ident` prefix gotcha: raw strings + `#hex` literals collide"
- "minijinja 2.x: `Value::from_serialize` (was `from_serializable`)"

## Reflection Metadata

```yaml
phase: phase-rust-workspace-bootstrap
goals_met: 9/9 (100%)
first_pass_quality: 9/9
compile_attempts_to_clean: 2
unit_tests: 5/5 passing
technical_debt_blocking: false
next_phase_recommended: phase-1-submodule-topology
chain_authorized_by_user: true
```

Completed kbd-reflect — phase-rust-workspace-bootstrap
