# Proposal: p8-05 — scaffold-react-vite-a2ui.sh

**Change ID**: p8-05-scaffold-a2ui-host
**Phase**: phase-8-scaffold-a2ui-host
**Status**: specified
**Origin**: G-5 (Q1) resolved by implication — aligning means a runtime renderer, so reading (b)
**Depends on**: p8-03, p8-04

p8-03 is a real dependency, not a courtesy: gates 3.5/3.6 drive the store with
the example corpus, and the declared graph `p8-01 → p8-02 → p8-04 → p8-05` is
satisfiable **without p8-03 ever running** — which would smoke-test against
old-dialect fixtures. Caught by adversarial review after p8-04 task 5.4 asserted
p8-03 would "already be upstream" here while nothing guaranteed it.

## Summary

A scaffolder that emits a running A2UI host, delivering the phase goal.

## Follow the thin-wrapper pattern

Third instance of the shape: `scaffold-react-vite-tauri.sh` (230 lines) →
`scaffold-react-vite-agui.sh` (221 lines) → this. Layer one concern onto the
base scaffolder; do not fork the 1160-line base.

Phase-7 left that substrate healthier than it found it — the architectural
ESLint config now actually runs, and `pnpm build` works under TypeScript 6. This
change is the first to benefit from those repairs rather than discover them.

## What it emits

1. Everything `scaffold-react-vite.sh` produces.
2. `@a2ui/react` pinned exact.
3. The p8-04 store, hook, and surface component into the feature slice.
4. The mock surface source into `src/dev/`.
5. A README stating the mock source is **development-only** and documenting the
   envelope contract a real agent must send.

Point 5 is not optional, for the same reason it was mandatory in p7-05: the
generated app looks production-shaped.

## Verification is browser-level, deliberately

Phase-7 closed with exactly one PARTIAL because "renders in the browser" was
verified at the store level and never in a DOM. **This phase does not repeat
that.** Gate 3.6 asserts rendered DOM via Playwright (already in
`devDependencies` at `^1.51.0`) — a rendering host whose rendering is never
observed is the wrong thing to verify twice.

Note the interaction with G-7: the *preview template* loads five unpinned
`unpkg@latest` scripts, which would make a DOM test flaky. That template is not
in this path — the scaffolded app bundles `@a2ui/react` through Vite — so the
DOM test here is deterministic. G-7 remains open for the preview.

## Scope

- `scripts/scaffold-react-vite-a2ui.sh` (new)
- `skills/scaffold-react-vite-a2ui/SKILL.md` (new)
- `assets/scaffold/a2ui/**` (consumed; created by p8-04)

## Out of scope — tracked deferrals

**G-7 — five unpinned `unpkg@latest` loads in
`assets/templates/a2ui-preview-template.html`.** No change in this set owns it,
and that is deliberate rather than an omission: under G-8 alignment the preview
template is superseded by the runtime renderer, so pinning a template that may
be deleted would be wasted work. It stays open against the *preview* path.

Recorded here so it has a named owner-of-record rather than living only in a
handoff warning. Revisit when deciding the preview template's fate — deleting it
closes G-7 outright.
