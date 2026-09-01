# Proposal: p7-05 — scaffold-react-vite-agui.sh

**Change ID**: p7-05-scaffold-agui-host
**Phase**: phase-7-scaffold-ag-ui-host
**Status**: specified
**Origin**: assess G-3 (BLOCKING) · analyze Decision 4 (BUILD from in-repo pattern)
**Depends on**: p7-03, p7-04

## Summary

A scaffolder that emits a running AG-UI host application, delivering the phase
goal end to end.

## Follow the thin-wrapper pattern

Analyze rejected external generators: none exist worth adopting, and adopting
one would discard this repo's conventions (brand-TOML injection, kebab-case
rename pass, import-rewrite pass, architectural ESLint config).

| Existing scaffolder | Lines | Shape |
|---|---|---|
| `scaffold-react-vite.sh` | 1160 | base |
| `scaffold-react-vite-axum.sh` | 431 | server-adjacent variant |
| `scaffold-react-vite-tauri.sh` | 230 | **thin wrapper — the model** |

`scaffold-react-vite-agui.sh` layers the AG-UI concern onto the base scaffolder.
It must not fork the 1160-line base.

## What it emits

1. Everything `scaffold-react-vite.sh` produces.
2. `@ag-ui/client` + `@ag-ui/encoder`, pinned exact.
3. The p7-04 store, hook, and panel into the feature slice.
4. The p7-03 Vite plugin, registered in `vite.config.ts`.
5. A README stating plainly that the mock agent and Vite middleware are
   **development-only**, and that production needs a real backend implementing
   the same contract.

Point 5 is not optional. The generated app looks production-shaped; without an
explicit statement a reader will assume the middleware is deployable.

## Skill registration

`skills/scaffold-react-vite-agui/SKILL.md` with valid frontmatter, plus
`plugin.json` registration — matching how the Tauri scaffolder is exposed.

## Acceptance

The phase succeeds only if a freshly scaffolded app streams. The decisive test
is criterion 4 in the assessment: **incremental rendering**. A non-streaming
stub passes every other check.
