# Proposal: phase-0-unblock (re-scoped)

> **Revision note (2026-05-20):** Original proposal was based on the session-doc file tree which never landed on disk. After execute-time reality check, scope was reduced to skills authoring + ADR + plugin registration. template-forge-rs deferred to its own future phase. See `execution.md` halt note.

## Why

The `phase-ideation-to-app-pipeline` assessment identified blockers in three areas. Two of them are addressable now without depending on a Rust workspace that does not yet exist:

1. **Five new sub-skill authoring targets exist only as names** in the session doc. They are referenced by the proposal for AG-UI / A2UI / scaffold work but have no `SKILL.md` files. Without them, downstream phases (especially phase-3 conversion layer) cannot describe what they consume.
2. **`sycophancy-correction` lives inside `prometheus-skill-pack` as an internal path.** Once `artifact-refiner` is submoduled into `prometheus-skill-pack`, the current import path becomes a cycle. The governance decision must be recorded now via ADR even if extraction itself happens later.

Deferred (was originally phase-0 scope, now its own phase):

- `tools/template-forge-rs/` Rust workspace creation. Treated as a substantial standalone effort needing its own assessment.

## What Changes

- **ADDED** `skills/convert-md-to-htmx/SKILL.md` — markdown → branded HTMX document. `direct:html`.
- **ADDED** `skills/convert-htmx-react/SKILL.md` — bidirectional HTMX ↔ React TSX conversion. `direct:react` or `direct:html`.
- **ADDED** `skills/rebrand-artifact/SKILL.md` — apply target brand guide to existing artifact. `direct:html` or `direct:react`.
- **ADDED** `skills/refine-moodboard/SKILL.md` — branded moodboard generator. `direct:html`.
- **ADDED** `skills/design-svg-logo/SKILL.md` — lightweight SVG logo creator (lighter than `refine-logo`). `direct:svg`.
- **ADDED** `docs/decisions/0001-sycophancy-correction-extraction.md` — ADR recording the governance decision. Options A/B/C with consequences and a recommendation.
- **MODIFIED** `.claude-plugin/plugin.json` — register the five new skill paths in the `skills` array.
- **ADDED** `.kbd-orchestrator/project.json` — already added; records `change_backend: openspec` and `model_policy`.

## Impact

### Affected surfaces

- `skills/` — five new directories, each with one `SKILL.md`.
- `.claude-plugin/plugin.json` — five new entries in the `skills` array.
- `docs/decisions/` — new directory + ADR file.

### Affected dependencies

None. No new Cargo dependencies, no submodules, no new MCP servers.

### Risk surface

- **Low** for SKILL.md authoring — additive, no behavior change to existing PMPO loop. The new skills reference existing infrastructure (`prompts/meta-controller.md`, `references/`, `assets/templates/`).
- **Zero** for ADR — documents a decision; does not move code.
- **Low** for plugin.json — additive entries only; existing entries unchanged.

### Out of scope (deferred to later phases)

- `tools/template-forge-rs/` Rust workspace — own phase, own assessment.
- `assets/library/brands/*.toml` brand registries — depends on template-forge.
- `scripts/install-template-forge.sh` — depends on template-forge.
- `skills/build-artifact-library/SKILL.md` — depends on template-forge.
- Adding `rust-mcp-filesystem` as a submodule → phase-1.
- Wiring `openai-proxy` → phase-1b.
- React/Vite scaffolder → phase-2.
- Actually extracting `sycophancy-correction` to a new repo — blocked on ADR decision.

## Rationale for the new skills (no Rust workspace required)

Each of the five new skills describes a workflow the user already runs by hand in Claude Desktop. The skill captures the procedure, the inputs, the outputs, and the constraints. When `template-forge-rs` eventually ships, the skills' rendering steps will accelerate via the binary — but the workflows themselves are valid using the existing PMPO loop and code-interpreter tool. The skills are not blocked on the Rust workspace; they merely use it opportunistically when available.
