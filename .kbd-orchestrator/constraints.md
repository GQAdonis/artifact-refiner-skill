# KBD Constraint Configuration — artifact-refiner

Project-specific constraint rules for KBD. Derived from the Code Review Checklist
in `AGENTS.md` and the Testing section of `CLAUDE.md`.

This repository is a **skill pack** — Markdown skill definitions, shell scripts,
JSON schemas, and prompt controllers. It has no `src/` tree and no root-level
compiled toolchain, so the generic source-code constraints from the KBD template
do not apply. They are retained, commented out, at the bottom of this file in case
a `src/` tree is added later.

Rust lives in two distinct places, and the distinction matters because it decides
what is editable here:

- **Submodules — parent-owned pins, not edited from this repo.** Exactly two, per
  `.gitmodules` and `git submodule status`: `shared/sycophancy-correction` and
  `tools/rust-mcp-filesystem`.
- **First-party, in-tree — editable.** `tools/template-forge-rs` is a normal
  tracked directory of this repository (17 tracked blobs, no gitlink, no nested
  `.git`), containing the `template-core`, `template-cli`, and `template-mcp`
  crates. Phase-3c edited `template-core/src/brand.rs` directly.

The `AGENT_RULES.md` single-writer `CARGO_TARGET_DIR` policy applies to any cargo
build in this tree; no constraint or trigger in this file invokes `cargo`.

> Corrected 2026-08-30. This paragraph previously listed `tools/template-forge-rs`
> as a submodule. That was wrong, and it was load-bearing: phase-9's assess-stage
> adversarial review raised a CRITICAL against a correct finding because this file
> contradicted it. Verify with `git submodule status`, not by directory location.

---

## Blocking Constraints (prevent archiving until resolved)

```yaml
constraints:
  - id: marketplace-validates
    severity: blocking
    description: 'Marketplace and plugin manifests must validate'
    command: 'bash scripts/validate-marketplace.sh'

  - id: skill-frontmatter-present
    severity: blocking
    description: 'Every SKILL.md and agent definition has YAML frontmatter'
    check: "for f in skills/*/SKILL.md agents/*.md; do head -5 \"$f\" | grep -q '^---' || echo \"missing frontmatter: $f\"; done"

  - id: references-resolve
    severity: blocking
    description: 'All references/ paths cited in prompts/ resolve to real files'
    check: "grep -roh 'references/[a-zA-Z0-9/_.-]*' prompts/ | sort -u | while read f; do [ -e \"$f\" ] || echo \"broken reference: $f\"; done"

  - id: schemas-parse
    severity: blocking
    description: 'All JSON schemas under references/schemas/ are valid JSON'
    check: "for f in references/schemas/*.json; do python3 -c \"import json,sys; json.load(open(sys.argv[1]))\" \"$f\" || echo \"invalid JSON: $f\"; done"

  - id: no-brand-leakage
    severity: blocking
    description: 'No legacy sediment:// brand references remain in documentation'
    note: 'Scoped to shipped content. Excluded: CLAUDE.md, this file, and docs/audit/ — each cites the pattern to describe the check rather than leaking it.'
    check: "grep -rn 'sediment://' prompts/ skills/ agents/ references/ assets/ README.md SKILL.md --include='*.md'"

  - id: no-hardcoded-secrets
    severity: blocking
    description: 'No hardcoded API keys, tokens, or passwords'
    check: "grep -rn 'sk-\\|api_key\\|API_KEY\\|secret.*=.*[\"\\x27][A-Za-z0-9]' scripts/ prompts/ references/"

  - id: submodules-clean
    severity: blocking
    description: 'git submodule status shows no unintended +/- prefixes'
    check: "git submodule status | grep -E '^[+-]' && echo 'dirty submodule pointer'"
```

---

## Warning Constraints (acknowledge before archiving)

```yaml
constraints:
  - id: hook-scripts-executable
    severity: warning
    description: 'Hook scripts referenced by hooks/hooks.json are executable'
    check: "for f in scripts/*.sh; do [ -x \"$f\" ] || echo \"not executable: $f\"; done"

  - id: no-stub-comments
    severity: warning
    description: 'No TODO/FIXME/STUB/HACK comments in committed skill or script content'
    check: "grep -rn 'TODO\\|FIXME\\|STUB\\|HACK' prompts/ scripts/ skills/ agents/"

  - id: examples-updated
    severity: warning
    description: 'Examples updated when phase controller behavior changed'
    note: 'Manual review required — see AGENTS.md Code Review Checklist'

  - id: no-duplicated-docs
    severity: warning
    description: 'No duplicated content across README.md, CLAUDE.md, and SKILL.md'
    note: 'Manual review required — see AGENTS.md Code Review Checklist'

  - id: plugin-manifest-current
    severity: warning
    description: 'plugin.json updated when new skills or agents were added'
    note: 'Manual review required — see AGENTS.md Code Review Checklist'
```

---

## Workflow Triggers

```yaml
workflow_triggers:
  - event: on_iteration_complete
    action:
      type: command
      target: 'bash scripts/validate-marketplace.sh'

  - event: on_change_complete
    action:
      type: command
      target: 'bash scripts/validate-marketplace.sh'
```

Note: no `on_refinement_complete` auto-commit trigger is configured. Commits in
this repository follow the Conventional Commits + feature-branch process defined
in `AGENTS.md`; auto-committing would bypass that review gate.

---

## Retained Generic Constraints (INACTIVE)

The KBD template ships the constraints below, all of which check a `src/`
directory. This repository has no `src/` tree, so these would pass vacuously —
appearing to enforce while enforcing nothing. They are retained here, inactive,
for reuse if a `src/` tree is ever added.

To activate: move a block into the sections above and verify the path exists.

```yaml
# INACTIVE — requires a src/ tree that does not exist in this repository.
#
# - id: no-console-log-in-commits
#   severity: blocking
#   description: 'No console.log statements in committed TypeScript/JavaScript'
#   check: "grep -r 'console\\.log' src/ --include='*.ts' --include='*.tsx' --include='*.js'"
#
# - id: no-any-type
#   severity: blocking
#   description: 'No `any` type usage in TypeScript source'
#   check: "grep -rn ': any' src/ --include='*.ts' --include='*.tsx'"
#
# - id: no-unused-imports
#   severity: blocking
#   description: 'No unused imports (varies by language)'
#   note: 'Enforce via lint command in project.json'
#
# - id: tests-for-new-features
#   severity: warning
#   description: 'Tests exist for all new features added in this change'
#
# - id: accessibility-basics
#   severity: warning
#   description: 'New UI components have aria-label or semantic HTML'
#   note: 'Manual review required'
```
