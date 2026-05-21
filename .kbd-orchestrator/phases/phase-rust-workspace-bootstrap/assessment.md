# Phase Assessment: Rust Workspace Bootstrap

**Phase:** `phase-rust-workspace-bootstrap`
**Project:** `artifact-refiner`
**Date:** 2026-05-20
**Author:** Claude Code (Opus 4.7, 1m context)
**Mode:** Assessment only — no implementation
**Sycophancy correction:** applied
**Predecessor:** `phase-0-unblock` (complete)

---

## 1. Goal Restatement

Bootstrap a Rust workspace at `tools/template-forge-rs/` that provides
deterministic, branded artifact rendering for the skill pack. The session
doc `docs/session-2026-05-20-artifact-refiner-buildout.md` §5 describes a
*target* spec for this workspace that was never written to disk; this phase
treats that spec as a starting-point reference, not an authoritative state.

End-state of this phase:

- `tools/template-forge-rs/` workspace compiles on macOS and Linux.
- `template-forge` CLI binary installs into PATH via existing per-harness
  installer pattern (`scripts/installers/`).
- `template-forge-mcp` MCP server binary registers in `.mcp.json`.
- One brand TOML (`knowme.toml`) and one engine path (Minijinja) render an
  end-to-end smoke artifact.

Out of end-state explicitly:

- Full five-engine matrix (Askama + Tera + Handlebars + Mustache + Minijinja).
- All brand TOMLs from the session doc.
- `build-artifact-library` skill SKILL.md.
- Integration with the five new sub-skills authored in phase-0.

These are follow-on work; this phase delivers a *minimum walking skeleton*
that proves the workspace is real, not a v1.0 of the full session-doc design.

---

## 2. Sycophancy-Corrected Assessment of the Session-Doc Spec

The session doc proposes an ambitious workspace: 3 crates, 5 template
engines, a TemplateEngine trait abstraction, an MCP server, a CLI, a
shared brand-data schema, conditional Ramhorns derives, partial registration
across engine dirs. Treating the entire spec as a phase guarantees the phase
does not finish.

### Where the session-doc spec is correct

- **Workspace shape (3 crates: core / cli / mcp) is right.** Matches the
  proven `forge-rs` pattern from `prometheus-skill-pack`. Same dependency
  shape (axum, tokio, serde, clap), same `workspace.dependencies` discipline.
- **Askama-as-special-case is right.** Compile-time templating cannot
  cleanly implement a runtime `Box<dyn TemplateEngine>` trait. Keeping
  Askama as its own dispatch path while runtime engines share a trait is
  honest and clean.
- **Workspace-deps pattern is right.** Prometheus's forge-rs already proves
  it scales: dependencies declared once in `[workspace.dependencies]`, member
  crates reference via `crate-name.workspace = true`.

### Where the session-doc spec needs correction

#### Correction 1 — Five engines on day one is over-engineering

The session doc commits to Askama + Minijinja + Tera + Handlebars + Mustache
with feature flags. Reality: until a user requests a non-default engine, only
Minijinja matters. Building all five at once means debugging five sets of
template-loader quirks, five sets of feature-gating issues, five test surfaces.

**Corrected goal:** Phase ships **Minijinja only** as the runtime engine.
Askama support deferred until at least one real consumer needs compile-time
templates. Other engines deferred until requested. Trait abstraction designed
but lives in code with one implementor — its value is the shape, not the count.

#### Correction 2 — Brand TOML registry is a sub-phase, not a workspace concern

The session doc bundles brand TOMLs (`knowme.toml`, `prometheus-ags.toml`)
and `assets/library/brands/` registry into the same delivery as the Rust
workspace. They are conceptually independent: the workspace is the
*renderer*, the registry is *data*.

**Corrected goal:** Phase ships ONE example brand TOML (`knowme.toml`,
seeded from the BossGravity v2 work in the session doc) so the smoke render
actually has data to render. Additional brand TOMLs (Prometheus AGS, San Saba
Royalty, HotSeaters, TribeHealth) are deferred. The registry directory
structure (`assets/library/brands/`) is created but only contains the one
example.

#### Correction 3 — No `build-artifact-library` skill in this phase

The session doc treats the workspace and the `build-artifact-library`
SKILL.md as one delivery. They aren't. The skill is a user-facing
PMPO-loop dispatcher; the workspace is a binary. The skill should be
authored after the workspace is provably working, because the skill's
"how to use the binary" docs depend on the binary's actual CLI surface.

**Corrected goal:** `build-artifact-library/SKILL.md` is deferred to a
follow-on phase after this one ships. The skill's directory is not even
created in this phase.

#### Correction 4 — The six "Priority 1" issues from the session doc are speculative

The session doc lists six known compile issues. Those were predicted bugs
based on writing the code without compiling it. Some will probably appear,
others may not. A few may appear in different shapes than predicted.

**Corrected approach:** Implement clean. When `cargo check` fails, debug
the *actual* errors. Use the session doc's prediction list as a hint for
where to look first, not as a fact-list to "fix."

#### Correction 5 — Template format duplication is acceptable for now

The session doc creates `templates/`, `templates/jinja/`, `templates/handlebars/`,
`templates/mustache/` with the same template files repeated in each engine's
syntax. With only Minijinja shipping in this phase, the duplication doesn't
exist yet. **Don't create the empty directories** — they invite
sync-divergence with no benefit. Create them when their engines ship.

---

## 3. Current State (Code Inventory)

### What exists in `artifact-refiner/` today

| Surface                                  | Status                              |
|------------------------------------------|-------------------------------------|
| `tools/` directory                        | **does not exist**                  |
| `assets/library/`                         | **does not exist**                  |
| `assets/templates/`                       | exists (3 templates in repo)        |
| `assets/vendor/`                          | exists                              |
| `scripts/installers/` (13 harnesses)      | exists, proven pattern              |
| `.mcp.json`                               | needs to be read to see current shape |
| `Cargo.toml` at repo root                 | **does not exist** (the workspace is its own root) |
| Per-language Rust toolchain config        | none in repo                        |

### What exists as a reference pattern

`prometheus-skill-pack/tools/forge-rs/` — 6-crate workspace, axum 0.8, tokio
full, clap derive, tera 1, walkdir, zip, tracing, jemallocator, release
profile with strip+lto. This is the template to follow.

### What exists as a spec to mine

`docs/session-2026-05-20-artifact-refiner-buildout.md` §5 has:

- Module layout for `template-core` (`brand.rs`, `engine/{askama,minijinja,tera,handlebars,mustache}_engine.rs`, `lib.rs`, `library.rs`, `render.rs`).
- `BrandData` struct shape (meta, colors, typography, logo, contact).
- `TemplateEngine` trait signature with `Send + Sync` bound.
- `EngineSelection` enum.
- Template directory convention by engine.
- MCP tool names (`template_forge_list_brands`, `template_forge_render`, `template_forge_library_status`, `template_forge_list_engines`).
- `.mcp.json` registration shape.

Treat all of this as **specifications worth mining**, not facts.

---

## 4. Scope of This Phase (Minimum Walking Skeleton)

### In scope

1. **Workspace skeleton:**
   - `tools/template-forge-rs/Cargo.toml` (workspace manifest)
   - `tools/template-forge-rs/crates/template-core/`
   - `tools/template-forge-rs/crates/template-cli/`
   - `tools/template-forge-rs/crates/template-mcp/`
   - `rust-toolchain.toml` pinning MSRV (1.80 per session doc)

2. **template-core crate** with:
   - `BrandData` struct + TOML deserialization
   - `TemplateEngine` trait (Send + Sync)
   - **One** implementor: `MinijinjaEngine` (path_loader rooted at `templates/`)
   - Library status helpers (list brands, list templates)

3. **template-cli crate** (binary: `template-forge`):
   - `template-forge --version`
   - `template-forge list-engines` → returns `["minijinja"]`
   - `template-forge list-brands --library <path>`
   - `template-forge render --brand <name> --template <name> --engine minijinja --library <path> --templates-base <path>`

4. **template-mcp crate** (binary: `template-forge-mcp`):
   - Stdio JSON-RPC 2.0 MCP server
   - One tool: `template_forge_list_engines`
   - One tool: `template_forge_render` (delegating to template-core)
   - Health probe endpoint (or equivalent introspection tool)

5. **One example brand:** `assets/library/brands/knowme.toml`. Seeded with the
   KnowMe tokens described in session doc §3.

6. **One example template:** `tools/template-forge-rs/templates/brand-guide.html`
   (Minijinja syntax — `{{ brand.meta.name }}` etc).

7. **Install script:** `scripts/install-template-forge.sh`. cargo-binstall
   probe + cargo install fallback.

8. **`.mcp.json` registration** of `template-forge-mcp` server.

9. **Smoke test** documented in README or assessment: `template-forge render
   --brand knowme --template brand-guide --engine minijinja` produces an
   HTML file that opens cleanly in a browser.

### Out of scope (deferred to follow-on phases)

- Askama engine (deferred — needs compile-time test infrastructure).
- Tera engine (Minijinja covers same template files; opt-in later).
- Handlebars engine (logic-less templating; opt-in later).
- Mustache / Ramhorns engine (proc-macro derive cost; opt-in later).
- Additional brand TOMLs beyond KnowMe.
- Additional templates beyond `brand-guide.html`.
- `build-artifact-library` SKILL.md (own follow-on phase).
- Integration with the five phase-0 SKILL.md files (own follow-on phase).
- Partial templates (`partials/nav.html`, `partials/footer.html`) — when Minijinja's only template needs them.
- All the engine-specific template directories (`templates/handlebars/`, `templates/mustache/`).

### Decision: trait shape now or later?

Recommendation: **define the trait now** with `MinijinjaEngine` as its
only implementor. The trait is one tiny file; it documents the shape so
later engine additions slot in cleanly. The cost of defining it now is
zero; the cost of refactoring single-engine code into a trait later is
non-zero.

---

## 5. Risk Analysis

| Risk                                                           | Likelihood | Impact | Mitigation                                                       |
|----------------------------------------------------------------|------------|--------|------------------------------------------------------------------|
| Minijinja `path_loader` finds nothing                          | Low        | High   | First test renders one template by name from a known absolute path |
| `BrandData` TOML deser fails on real KnowMe tokens             | Medium     | Medium | Build BrandData by reverse-engineering knowme.toml shape first, not the other way around |
| MCP stdio JSON-RPC server hard to test without an MCP client   | Medium     | Medium | Add a `--probe` flag to the binary that exercises the same code path without going through stdio |
| Workspace deps version drift from forge-rs                     | Low        | Low    | Use the same versions as forge-rs explicitly                     |
| `cargo install --path` fails on macOS due to ARM cross-compile | Low        | Medium | Test install on both ARM and x86 if available; otherwise just ARM |
| jemallocator crashes on macOS (known historical issue)         | Low        | Medium | Match forge-rs config; tikv-jemallocator 0.6+ is fine on recent macOS |

No risk in this list is high-severity. The biggest unknown is MCP server
testing surface; mitigated by the `--probe` flag idea.

---

## 6. Acceptance Criteria

This phase is done when **all of** the following hold:

1. `cd tools/template-forge-rs && cargo check --all-targets` exits 0 on macOS.
2. `cd tools/template-forge-rs && cargo build --release` produces both binaries.
3. `template-forge --version` prints a sane version string.
4. `template-forge list-engines` prints `minijinja`.
5. `template-forge list-brands --library assets/library` lists `knowme`.
6. `template-forge render --brand knowme --template brand-guide --engine minijinja --library assets/library --templates-base tools/template-forge-rs/templates` produces a non-empty HTML file.
7. `template-forge-mcp` starts and responds to a `tools/list` JSON-RPC request listing `template_forge_list_engines` and `template_forge_render`.
8. `bash scripts/install-template-forge.sh` installs `template-forge` and `template-forge-mcp` into PATH on the local machine.
9. `.mcp.json` includes the `template-forge` server entry.

No other goal is acceptance-critical for this phase.

---

## 7. Phase Decomposition (for the upcoming Plan)

| Order | Sub-change                                  | Estimated effort |
|-------|---------------------------------------------|------------------|
| 1     | Workspace + 3 crate skeletons with empty modules  | small (clean cargo check)  |
| 2     | `BrandData` + TOML deser + first knowme.toml     | small                       |
| 3     | `TemplateEngine` trait + `MinijinjaEngine`       | small                       |
| 4     | `template-cli` with `--version`, `list-engines`, `list-brands`, `render` | medium |
| 5     | One Minijinja template `brand-guide.html`        | small                       |
| 6     | End-to-end smoke render via CLI                  | small                       |
| 7     | `template-mcp` minimal server (stdio JSON-RPC, two tools) | medium             |
| 8     | Install script + `.mcp.json` registration        | small                       |
| 9     | Acceptance checks 1–9                            | small                       |

Total: one focused session, possibly two.

---

## 8. Open Questions for the Plan

These do not block writing the plan, but the plan should pick one answer for each:

1. **Workspace location:** `tools/template-forge-rs/` (matches forge-rs) vs `tools/template-forge/` (drop the `-rs` suffix since context is unambiguous). Recommendation: `tools/template-forge-rs/` to mirror forge-rs convention.
2. **MSRV:** 1.80 (per session doc) vs current stable. Recommendation: 1.80 — matches forge-rs and gives room for users with older toolchains.
3. **jemallocator on macOS:** include or skip. Recommendation: include behind a `#[cfg(not(target_env = "msvc"))]` guard, matching forge-rs.
4. **MCP transport for v1:** stdio only, or stdio + Streamable HTTP? Recommendation: stdio only (`rmcp` or `mcp-server-rust` crate). Streamable HTTP can land later if a consumer needs it.
5. **Brand TOML format authority:** is there an existing brand TOML schema in `prometheus-skill-pack`, or do we define ours fresh? Recommendation: check forge-rs/forge-skills for a brand schema; if absent, define minimal one (meta/colors/typography/logo/contact) per session doc §5.
6. **Template render output destination:** stdout, file path arg, or both? Recommendation: both — `--output -` writes to stdout, `--output <path>` writes to file, default = stdout.

---

## 9. Honest Verdict

This phase is a clean, finishable bootstrap if it stays at "Minijinja-only walking skeleton" scope. It becomes a multi-week effort if it tries to ship the full five-engine matrix from the session doc.

The session doc is valuable as a **specification of the eventual full system**. It is dangerous as a **definition of phase scope**. Treat it as the former.

**Recommendation:** proceed to `/kbd-plan phase-rust-workspace-bootstrap`. Stay disciplined on the "Minijinja-only" scope. Promote additional engines to their own phases as concrete consumers request them.

---

## 10. Note on the Chained Command

The user requested chaining into `/kbd-plan phase-1-submodule-topology` after this assessment. **That command remains blocked** on the same open questions as before this phase started:

- **Q-001** — sycophancy-correction extraction (A/B/C). No user answer recorded.
- **Q-002** — rust-mcp-filesystem upstream vs fork. No user answer recorded.

Proceeding to `phase-1-submodule-topology` planning without those answers will produce a plan with placeholder decisions that have to be re-planned once the user answers. Phase-1 is small (just submodule wiring) and benefits from being planned *with* answers in hand.

**Recommendation on chained command:**

- Run `/kbd-plan phase-rust-workspace-bootstrap` now — fully unblocked.
- Defer `/kbd-plan phase-1-submodule-topology` until Q-001 and Q-002 are answered. The right next prompt to the user is "Please answer Q-001 and Q-002 before I plan phase-1," not "I'll plan phase-1 against placeholders."

This is sycophancy-corrected behavior. Chaining without preconditions met would be S-01 deference.

---

## 11. Assessment Metadata

```yaml
assessment_complete: true
phase: phase-rust-workspace-bootstrap
inputs_reviewed:
  - docs/session-2026-05-20-artifact-refiner-buildout.md §5
  - prometheus-skill-pack/tools/forge-rs/ (Cargo.toml, crate layout)
  - .kbd-orchestrator/phases/phase-0-unblock/reflection.md
  - existing scripts/installers/ pattern
scope_discipline_applied:
  - Five engines reduced to one (Minijinja)
  - Brand registry reduced to one TOML (knowme)
  - build-artifact-library skill deferred
  - Engine-specific template dirs deferred
recommendation: |
  Proceed to /kbd-plan phase-rust-workspace-bootstrap now.
  Defer /kbd-plan phase-1-submodule-topology until user answers
  Q-001 (ADR extraction option) and Q-002 (mcp-filesystem upstream vs fork).
next_command: /kbd-plan phase-rust-workspace-bootstrap
```

Completed kbd-assess — phase-rust-workspace-bootstrap
