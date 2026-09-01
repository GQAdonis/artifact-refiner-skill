# Proposal: p9-05 — `scaffold-react-vite-mcp-ui.sh`

**Change ID**: p9-05-scaffold-mcp-ui-host
**Phase**: phase-9-scaffold-mcp-ui
**Status**: specified
**Origin**: G-4 (D-009)
**Depends on**: p9-03, p9-04

**Both dependencies are real.** p9-04 supplies the assets this scaffolder emits;
p9-03 supplies the fixture the mock serves and the smoke gate asserts. Declaring
only p9-04 would leave the graph satisfiable without the corpus existing — the
precise hole adversarial review caught in phase-8's p8-05.

## Summary

A scaffolder that emits a running MCP-UI host, delivering the phase goal.

## Fourth instance of the thin-wrapper pattern

`scaffold-react-vite-tauri.sh` (230 lines) → `-agui.sh` (221) → `-a2ui.sh` (~200)
→ this. Layer one concern onto the base scaffolder; do not fork the 1160-line
base.

`-axum.sh` is **not** the model despite also provisioning a backend: it is a
build-time server embedding `dist/` via `rust-embed`, not a dev-time API. The
applicable precedent is `-agui.sh`'s Vite middleware registration.

## Two defects this inherits as fixed

- **Feature naming.** Both prior wrappers now derive the feature name via
  `to_kebab()` from `scripts/lib/kebab-case.sh`, with the existing-slice fallback
  guarded so `--feature` still wins. The AG-UI one was fixed after phase-8. Use
  `to_kebab` from the start; a raw `basename` produces a second feature directory
  the app never imports, and only shows up on names containing digit runs.
- **Architectural ESLint.** Repaired in p7-05, where it had never actually run.
  This scaffolder's lint gate is therefore meaningful.

## What it emits

1. Everything `scaffold-react-vite.sh` produces.
2. `@mcp-ui/client@7.1.1` and `@modelcontextprotocol/ext-apps@1.7.5`, pinned
   exact.
3. The p9-04 store, hook, and surface into the feature slice.
4. The mock plugin into `src/dev/`, registered into `vite.config.ts`
   idempotently (the `-agui.sh` mechanism).
5. `sandbox-proxy.html` into `public/`, served same-origin.
6. A README documenting that the mock is **development-only**, the JSON-RPC
   contract a real MCP server must satisfy, and the sandbox posture.

Point 6 is not optional, for the reason it was mandatory in p7-05 and p8-05: the
generated app looks production-shaped. It must additionally state the
`allow-same-origin` decision (p9-04) so a consumer moving the proxy to another
origin knows what they are changing.

## Verification is browser-level

Same standard as p8-05: the smoke sequence is scaffold → build → lint → dev →
**browser DOM**, and the DOM assertion is the one that matters.

## Scope

```
scripts/scaffold-react-vite-mcp-ui.sh   # new
skills/refine-mcp-ui/SKILL.md           # new — slash command
```

**Do not add the skill to `.claude-plugin/plugin.json`.** That file has no
`skills` key — it carries metadata only, and standard component paths are
auto-discovered (`CLAUDE.md:31`). `CLAUDE.md:54` says the opposite and is the
stale half of a contradiction flagged since phase-7; p8-05 declined the same
edit for the same reason. Following `:54` would add a key the schema does not
define.

## Non-goals

- No changes to the base scaffolder. If a base defect surfaces, report it —
  phase-7 fixed three there, and each was a deliberate, separately-justified
  decision rather than incidental drift.
- No real MCP server.
