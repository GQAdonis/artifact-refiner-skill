# Plan: phase-0-unblock

**Project:** artifact-refiner
**Phase:** phase-0-unblock
**Change backend:** OpenSpec (`openspec/changes/phase-0-unblock/`)
**Authoritative tasks:** `openspec/changes/phase-0-unblock/tasks.md`
**Design notes:** `openspec/changes/phase-0-unblock/design.md`
**Proposal:** `openspec/changes/phase-0-unblock/proposal.md`

## Goal

Clear the three concrete blockers identified in the phase-ideation-to-app-pipeline assessment so phase-1 (submodule topology), phase-1b (inference routing), and phase-2 (scaffold-react-vite) can land on a working foundation.

Blockers cleared by this phase:

1. `tools/template-forge-rs/` does not compile (six Priority-1 issues from `docs/session-2026-05-20-artifact-refiner-buildout.md`).
2. Five of six new sub-skill `SKILL.md` files are empty or partial.
3. `sycophancy-correction` import path will become a cycle once `artifact-refiner` is submoduled into `prometheus-skill-pack`. Decision must be recorded now via ADR.

## Ordered change list

| # | Change                                          | Backend artifact                                            | Recommended agent       | Blocks                  |
|---|-------------------------------------------------|-------------------------------------------------------------|-------------------------|-------------------------|
| 1 | Compile `template-forge-rs` workspace           | `openspec/changes/phase-0-unblock/` tasks 1.1–1.10          | `rust-build-resolver`   | all downstream rendering |
| 2 | Complete `convert-md-to-htmx/SKILL.md`          | tasks 2.1, 2.6, 2.7                                          | direct authoring        | phase-2 conversion       |
| 3 | Author `convert-htmx-react/SKILL.md`            | tasks 2.2, 2.6, 2.7                                          | direct authoring        | phase-2 conversion       |
| 4 | Author `rebrand-artifact/SKILL.md`              | tasks 2.3, 2.6, 2.7                                          | direct authoring        | phase-2 / phase-3        |
| 5 | Author `refine-moodboard/SKILL.md`              | tasks 2.4, 2.6, 2.7                                          | direct authoring        | none (additive)          |
| 6 | Author `design-svg-logo/SKILL.md`               | tasks 2.5, 2.6, 2.7                                          | direct authoring        | none (additive)          |
| 7 | Update `.claude-plugin/marketplace.json`        | tasks 3.1–3.3                                                | direct edit + verify-app | discoverability          |
| 8 | Write ADR-0001 (sycophancy-correction extraction) | task 4.1; output at `docs/decisions/0001-sycophancy-correction-extraction.md` | direct write | phase-1 submodule topology |
| 9 | Phase-completion gate                           | tasks 5.1–5.3                                                | `verify-app`, `code-reviewer` | phase-1                 |

## Execution order

```
[1 — workspace compile]   ◀── must finish first; no parallelism inside
        ▼
[2,3,4,5,6 — five SKILL.md files]   ◀── parallel-safe; independent files
        ▼
[7 — marketplace registration]      ◀── atomic; only after all five exist
        ▼
[8 — ADR write]                     ◀── independent of 1–7; can run any time but emits open question for user
        ▼
[9 — completion gate]
```

Step 1 must complete before any rendering smoke test runs. Steps 2–6 are independent files and parallel-safe (different paths, no shared state). Step 7 is atomic at the marketplace file. Step 8 can run anytime but produces an `open_question` the user must resolve before phase-1 can plan.

## Validation strategy

| Layer                | Check                                                          |
|----------------------|----------------------------------------------------------------|
| Rust workspace       | `cargo check --all-features` exits 0 on macOS                  |
| Rust workspace       | `cargo check --no-default-features` exits 0                    |
| Rust workspace       | All five `cargo check -p template-cli --features ...` combos pass |
| Install              | `bash scripts/install-template-forge.sh && template-forge --version` |
| Smoke render         | `template-forge render --brand knowme --template brand-guide --engine minijinja` produces non-empty HTML |
| SKILL.md frontmatter | `head -5 SKILL.md \| grep ^---` for each of five files          |
| Marketplace          | `bash scripts/validate-marketplace.sh`                          |
| ADR                  | File exists with status, context, options, decision, consequences sections |

## Open questions surfaced for the user

These do not block phase-0 execution but must be answered before `/kbd-plan phase-1-submodule-topology` produces a useful plan:

1. **Sycophancy-correction extraction choice** (ADR-0001 options A/B/C — recommendation A).
2. **rust-mcp-filesystem upstream or fork?** GQAdonis owns a fork at `git@github.com:GQAdonis/rust-mcp-filesystem.git`; upstream is `rust-mcp-stack/rust-mcp-filesystem`.
3. **`openai-proxy` wiring mode** (assessment §6a Option A vs B — recommendation B).

## Out of scope (deferred to later phases)

- Adding any submodule (phase-1).
- Wiring `openai-proxy` (phase-1b).
- Any new scaffold generator (phase-2 onward).
- Executing the sycophancy-correction extraction itself (separate phase after ADR decision).

## Risk register

| Risk                                           | Likelihood | Impact | Mitigation                                                |
|------------------------------------------------|------------|--------|-----------------------------------------------------------|
| Cascading compile errors from Issue 1 → 2 → 3  | Medium     | High   | Fix one engine at a time; default features first          |
| SKILL.md files diverge from canonical format   | Low        | Low    | Copy `refine-logo/SKILL.md` frontmatter verbatim          |
| Marketplace JSON shape changes break consumers | Low        | Medium | Read existing entries first; replicate shape exactly      |
| ADR decision blocks phase-1 indefinitely       | Medium     | Medium | Default to Option B (vendor snapshot) if no user input in 1 turn |

## Estimated session count

1–2 focused sessions. Step 1 dominates wall time; steps 2–6 are template authoring.
