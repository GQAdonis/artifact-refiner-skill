# Design: phase-0-unblock

## Context

This is a pure unblock phase. No new architecture is introduced. The design notes here document the **decisions made while resolving existing issues** so future contributors can understand why each Priority-1 issue was resolved a particular way.

## Decision 1 — Askama template dir resolution (Issue 1)

**Options considered:**

- A. `build.rs` in `template-core` sets `ASKAMA_TEMPLATE_DIR` env var to `../../templates`.
- B. Move Askama-consumed templates into `crates/template-core/templates/`.

**Chosen: B.**

**Reasoning:** Askama's compile-time invariant is that templates are part of the crate they are derived in. Pointing Askama at a directory two levels up via env vars works but leaks build-time geometry into runtime concerns. The runtime engines (Jinja, Handlebars, Mustache) genuinely need to share `tools/template-forge-rs/templates/{jinja,handlebars,mustache}/` because they load by path at runtime. Askama does not. Keeping its sources next to the derive macros keeps the constraint local.

**Cost:** Templates are now duplicated at two locations (Askama in `crates/template-core/templates/`, runtime in `tools/template-forge-rs/templates/`). Mitigation: a `tools/template-forge-rs/scripts/sync-templates.sh` keeps them aligned if hand-editing diverges them. Acceptable for v1; revisit if drift becomes a maintenance issue.

## Decision 2 — Mustache root context (Issue 2)

**Options considered:**

- A. Implement `ramhorns::Content` manually on `BrandContext` to wrap `BrandData` under a `brand` key (keeps template path consistency: `{{brand.meta.name}}` everywhere).
- B. Pass `BrandData` directly; mustache templates use `{{meta.name}}` instead of `{{brand.meta.name}}`.

**Chosen: B.**

**Reasoning:** Option A's manual `Content` impl is invasive and the session doc already flags it as buggy. The whole point of the engine trait abstraction is that template directories are engine-specific (`templates/mustache/` vs `templates/jinja/`). Inconsistent context paths across engines are acceptable *as long as* templates inside each engine directory are internally consistent.

**Cost:** Documented inconsistency. Recorded in `engine/mustache_engine.rs` module docs and in `references/template-engines.md` (to be added if not present).

## Decision 3 — Feature-flag default set

**Confirmed (no change from session doc):** `engine-minijinja` + `engine-handlebars` remain the defaults. `engine-tera` and `engine-mustache` opt-in.

**Reasoning:** Minijinja covers Jinja2-style needs with the most mature crate. Handlebars covers logic-less template discipline for brand docs. Tera is redundant with Minijinja for the same template files. Mustache adds proc-macro derive cost that only pays off if someone actually needs Mustache. Asking install-time users to opt into uncommon engines is correct.

## Decision 4 — Sycophancy-correction extraction (ADR)

**Status:** Deferred. ADR `docs/decisions/0001-sycophancy-correction-extraction.md` will record three options:

- **A. Extract to its own GitHub repo.** Submodule from both `prometheus-skill-pack` and `artifact-refiner`. Clean DAG. Highest cost. Recommended long-term.
- **B. Vendor a snapshot.** Copy current sycophancy-correction into `artifact-refiner/shared/sycophancy-correction/` and consume locally. No cycle. Costs: snapshots drift; updates are manual.
- **C. Accept the cycle.** Use submodule-of-submodule (`prometheus-skill-pack/skills/imported/artifact-refiner/shared/sycophancy-correction`). Works at clone time only if git submodule update is run twice. Brittle.

User input required before phase-1 closes. Phase-0 produces the ADR but does not execute on it.

## Decision 5 — Marketplace registration ordering

Register marketplace entries **last** in phase-0, only after each skill's `SKILL.md` is complete and the workspace compiles. Reason: a half-registered marketplace surfaces empty skills to consumers. Atomic batch update.

## Non-decisions (explicitly out of scope)

- AST patcher choice (swc/oxc/treesitter) — phase-3.
- Scaffold delegation policy (delegate vs own template tree) — phase-2.
- `openai-proxy` wiring mode — phase-1b.
- `rust-mcp-filesystem` submodule path — phase-1.
- Sycophancy-correction extraction *execution* (the actual `git filter-repo` work) — separate phase, blocked on ADR.
