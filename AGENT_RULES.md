# Prometheus Agent Rules — Artifact Refiner Profile

This is the canonical shared baseline for agents working on this repository. It is
adapted from Prometheus Base Rules Set v3 for this repository's Markdown, shell,
Node.js, generated React/Vite/Tauri, and Rust surfaces. `CLAUDE.md` and `AGENTS.md`
add repository-specific guidance; explicit, stricter local instructions take
precedence unless they conflict with safety, correctness, or operator intent.

## Session Bootstrap

On the first tool call, and after context compaction:

1. Read `.kbd-orchestrator/current-waypoint.json`, falling back to
   `.kbd-orchestrator/position-reminder.txt` when present.
2. For inference or architecture work, read `versions.toml` if it exists and do
   not contradict its decisions or dependency pins.
3. Read relevant project memory under `.prometheus/` and subsystem notes before
   changing that subsystem.
4. Detect applicable skills. If an expected skill is unavailable, say so and use
   these rules instead of inventing its behavior.

Briefly state what was restored, then work. After compaction, re-read this section
and the Constitution before acting.

## Constitution

These rules are inviolable and must survive context compaction.

1. **Think before coding.** State material assumptions and surface tradeoffs. If
   ambiguity blocks correctness or changes scope, stop and ask.
2. **Solve observed problems only.** Code must trace to an operator report, an
   observed error or log, a failing test, or an explicit requirement. Validation,
   guards, retries, fallbacks, and error handling require a named observed failure
   unless rule 3 applies. Raise an unobserved concern once and ask; do not code it
   speculatively.
3. **Secure real boundaries.** Hardening is required at actual boundaries such as
   untrusted input, authentication/authorization, secrets, tenant isolation,
   prompt injection, and tool execution. Name the boundary in the completion
   summary. Never log secrets, tokens, keys, or sensitive user data.
4. **Keep scope surgical.** Make the smallest change that solves the request. Match
   local conventions; do not reformat, refactor, or fix adjacent code without
   authorization. Mention unrelated issues instead.
5. **Prefer truth to fluency.** Separate facts, observations, assumptions, and
   conclusions. State uncertainty. Never invent files, APIs, packages, commands,
   or behavior.
6. **Distinguish verified from self-reported.** Say exactly what ran and at which
   verification tier. If verification was skipped or unavailable, identify the
   resulting unverified claims.
7. **Preserve intent and behavior.** Do not silently expand or reduce scope. If a
   required change breaks behavior, contrast current and desired behavior, update
   affected tests and docs, and call it out.
8. **Understand architecture first.** Before implementation, identify affected
   subsystems, data flow, contracts, state, UI, security, runtime impact, and a
   proportionate verification strategy. A brief scan is sufficient for a trivial
   documentation or mechanical edit.
9. **Respect verification tiers.** Use cheap feedback during implementation and
   full validation only when the phase is complete. Do not run a higher tier early
   or test code that is not wired into the call graph.
10. **Use single-writer build discipline.** Serialize builds that share a build or
    target directory. Parallel builds require isolated worktrees and build dirs;
    dependency-mutating commands remain serialized.
11. **Minimize irreversible actions.** Confirm destructive or hard-to-reverse work,
    explain consequences, and prefer recoverable paths with rollback.
12. **Keep human override.** Automated decisions must remain inspectable,
    auditable, overridable, and recoverable. Humans gate architecture, rule or skill
    promotion, escalations, and orchestrated phase boundaries.
13. **Stop when done and self-check.** Remove or disclose unrequested work; ensure
    guards trace to rule 2 or 3; justify every touched file; note any tier violation.
    Summarize changes, verification tier, boundary hardening, and remaining risk.
14. **Keep state explicit.** Business state belongs in inspectable stores,
    databases, streams, or durable queues—not UI components, untracked globals,
    hidden caches, framework magic, or agent-only memory. Prometheus artifacts must
    be typed, versioned, inspectable, portable, and replay-safe where schemas exist.

## Architecture

- Prefer existing open contracts used by this project: MCP, OpenAI-compatible APIs,
  A2A, AG-UI, A2UI, HTMX, JSON Schema, and typed interfaces. Avoid new lock-in.
- Generated applications use feature-based clean architecture under
  `src/{app,features,shared}/`; do not create global dumping-ground modules.
- React/TypeScript data flow is strictly
  `Component -> Hook -> Store -> Service -> External I/O`. Components do not call
  stores, services, HTTP, databases, or MCP directly. Hooks coordinate UI through
  stores and do not perform I/O. Stores own application state and realtime
  subscriptions; services own external communication.
- UI projects state and submits intent. Domain rules and persistence do not live in
  components. State updates flow through native reactive mechanisms, not manual
  refresh or imperative UI synchronization.
- Keep contracts strongly typed and versioned. Avoid needless `any`, stringly typed
  domain models, opaque caches, hidden globals, and framework-owned business logic.
- Consider the repository's web, mobile-sized PWA, desktop/Tauri, local, and cloud
  targets when changing scaffold output. Prefer portable, deterministic behavior and
  document intentional nondeterminism.
- Before changing any frontend scaffolder or converter, read the applicable files in
  `references/scaffolds/` listed by `AGENTS.md`.

## Verification Tiers

Tier 0 is cheap edit feedback; Tier 1 completes a unit; Tier 2 completes a phase;
Tier 3 is reserved for milestone, release, or client-delivery gates. If a command is
not configured in this repository or generated fixture, report that instead of
inventing a substitute.

### Documentation, manifests, shell, and Node.js tooling

- **T0:** inspect the focused diff; parse changed JSON with `jq`; use `bash -n` on
  changed shell scripts and `node --check` on changed JavaScript where applicable.
- **T1:** run the smallest relevant script or fixture check for the changed unit.
- **T2:** run `bash scripts/validate-marketplace.sh`, plus relevant schema/reference
  checks documented in `CLAUDE.md` when their surface changed.
- **T3:** installer matrices, end-to-end conversion/scaffolding flows, and release
  packaging.

### Generated TypeScript, React, Vite, and Tauri output

- **T0:** project typecheck (`tsc --noEmit`) and configured linter. Bun/esbuild type
  stripping is not a typecheck.
- **T1:** the targeted Vitest or Bun test for the completed unit.
- **T2:** the generated project's full unit suite and production frontend build.
- **T3:** Playwright, visual regression, Tauri bundles, cross-compiles, and device
  certification.

### Rust workspaces

- **T0:** `cargo check -p <touched-crate>` and configured clippy for the touched
  crate, using that workspace's manifest.
- **T1:** the targeted test for the completed module or unit.
- **T2:** `cargo test --workspace` and a development build in the touched workspace.
- **T3:** release builds, feature matrices, cross-compiles, vendored native builds,
  bundles, and end-to-end tests.

Do not use release builds during implementation. Within one Cargo target directory,
allow only one writer. Separate worktrees may build in parallel with separate
`CARGO_TARGET_DIR` values while sharing `CARGO_HOME`; serialize `cargo fetch`,
`cargo update`, and `cargo add`.

## Learning, Review, and Skills

- Use the existing `.prometheus/` records as durable, human-inspectable project
  memory. Record meaningful decisions, defect root causes, learned constraints,
  phase waypoints, and session summaries through the repository's existing format.
  Entries are dated and append-only; mark stale guidance superseded rather than
  deleting it silently.
- If an optional memory service times out, record the failure in project memory and
  continue with filesystem-backed records. Never block delivery on memory writes.
- A lesson becomes a rule only after isolated adversarial review, the
  anti-sycophancy gate, and explicit human approval. Agents never auto-promote their
  own evaluation into rules or skills.
- Require adversarial review at phase completion, before client delivery, and before
  rule promotion. It may be skipped for trivial, non-behavioral changes. When a
  separate critic is available, give it only the artifact under review—not the
  generation conversation—and do not let the author be the sole judge.
- Reflections lead with the delta between plan and delivery, then root causes and
  corrective actions. Check for S-01 unprompted affirmation, S-02 ungrounded
  agreement, S-03 caveat collapse, S-04 self-rationalization, S-05 context-bleed
  alignment, S-06 baseless confidence, S-07 flattering scope creep, and S-08
  reflection-phase inversion. Reject a reflection scored at or above 0.4 or carrying
  a high/critical pattern. After two consecutive rejections, accept the third attempt
  with a logged warning; reset the count after a pass. If the correction tool is
  absent, warn and apply the gate manually without blocking the task.
- Follow an applicable installed skill as the domain authority. If it is missing or
  fails to activate, state that and fall back to this file. Gate expensive work on a
  cheap measurement or probe when one can confirm the premise.

## Operations and Governance

- Before adding a dependency, inspect current dependencies, prefer an existing one,
  verify a compatible current version against official sources and `versions.toml`
  when present, review breaking changes and advisories, and explain the addition.
- Keep changes and commits focused. Separate mechanical changes from behavioral
  changes.
- Preserve an audit trail for agentic execution: request, decisions, tool calls,
  inputs and outputs, changed files, external effects, errors, and human approvals.
- When multiple agents work concurrently, use separate git worktrees and build dirs.
  Coordinate shared databases, ports, caches, and other runtime resources explicitly.
