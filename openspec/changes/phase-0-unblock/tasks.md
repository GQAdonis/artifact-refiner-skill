# Tasks: phase-0-unblock (re-scoped)

> Re-scoped 2026-05-20 after execute-time halt. template-forge-rs work removed; defers to its own future phase.

## 1. Author five new SKILL.md files

Canonical format reference: `skills/refine-logo/SKILL.md` (frontmatter: `name`, `description`; sections: Setup, User Input, Default Constraints). Each new skill must:

- Have valid YAML frontmatter (lines 1–N, opening and closing `---`)
- Reference `prompts/meta-controller.md` as the PMPO entry point
- Declare `artifact_type` and (where applicable) `content_type`
- List default constraints
- Stay under 100 lines (these are quick-start dispatchers, not full domain docs)

- [x] 1.1 Create `skills/convert-md-to-htmx/` directory.
- [x] 1.2 Author `skills/convert-md-to-htmx/SKILL.md`.
- [x] 1.3 Create `skills/convert-htmx-react/` directory.
- [x] 1.4 Author `skills/convert-htmx-react/SKILL.md`.
- [x] 1.5 Create `skills/rebrand-artifact/` directory.
- [x] 1.6 Author `skills/rebrand-artifact/SKILL.md`.
- [x] 1.7 Create `skills/refine-moodboard/` directory.
- [x] 1.8 Author `skills/refine-moodboard/SKILL.md`.
- [x] 1.9 Create `skills/design-svg-logo/` directory.
- [x] 1.10 Author `skills/design-svg-logo/SKILL.md`.
- [x] 1.11 Validate frontmatter: `for f in skills/{convert-md-to-htmx,convert-htmx-react,rebrand-artifact,refine-moodboard,design-svg-logo}/SKILL.md; do head -5 "$f" | grep -q "^---" && echo OK || echo MISSING; done`.

## 2. Register skills in `.claude-plugin/plugin.json`

- [x] 2.1 Read existing `.claude-plugin/plugin.json` to record current shape.
- [x] 2.2 Add five new paths to the `skills` array (alphabetical insertion preferred).

## 3. Write ADR-0001 — Sycophancy-correction extraction

- [x] 3.1 Create `docs/decisions/` directory.
- [x] 3.2 Author `docs/decisions/0001-sycophancy-correction-extraction.md`. Format: status (proposed), context, options (A/B/C), decision (deferred — user input required), consequences.

## 4. Phase-completion gate

- [x] 4.1 All section 1, 2, 3 tasks marked complete.
- [x] 4.2 Update progress.json — set `execute_complete: true`, `execute_status: COMPLETE`.
- [x] 4.3 Emit completion summary listing five SKILL.md files authored + ADR-0001 + plugin.json update.

## Out of scope (deferred phases)

- template-forge-rs Rust workspace
- assets/library/brands/*.toml
- scripts/install-template-forge.sh
- skills/build-artifact-library/SKILL.md (depends on template-forge)
