# Design: p7-03 — AG-UI server surface

## Dependency pin

| Package | Version | Range | License |
|---|---|---|---|
| `@ag-ui/encoder` | `0.0.59` | **exact — no caret** | MIT |

Transitively pulls `@ag-ui/core@0.0.59` and `@ag-ui/proto@0.0.59`.

**Why exact.** `@ag-ui/*` is pre-1.0 (`0.0.59`, 74 releases, latest published
2026-08-27). Under semver, a `^0.0.x` range does not permit patch upgrades — but
pre-1.0 projects routinely ship breaking changes in the patch position, and a
caret would still let `0.0.60` in on a fresh lockfile resolution. Pinning exact
means an upstream break becomes a deliberate bump, not a surprise.

**Verified working before adoption** (not assumed from documentation):

```
getContentType()          → "text/event-stream"
encodeSSE({type:"RUN_STARTED",…}) → 'data: {"type":"RUN_STARTED",…}\n\n'
frame ends with blank line → true
```

## Install note (environment, not this change)

`pnpm add` initially failed with `ERR_PNPM_UNEXPECTED_STORE`: `node_modules` had
been linked against pnpm store v10 while pnpm 11.11.0 expects v11. Resolved with
a full `CI=true pnpm install` (the `CI` flag supplies the non-interactive consent
pnpm needs to purge `node_modules`).

`pnpm-lock.yaml` came back **byte-identical** — the reinstall was purely a
`node_modules` relink, so the lockfile churn this risked did not occur.

## Decisions inherited from earlier stages

| Decision | Source | Rationale |
|---|---|---|
| Mock agent, not a real LLM | spec | A real LLM adds credentials, streaming translation, and its own failure modes; a mock proves the transport and satisfies every verification criterion |
| Vite dev-server middleware, not a standalone server | spec | Self-containment — `pnpm dev` alone runs the demo, no second process |
| Adopt `@ag-ui/encoder` rather than hand-format frames | analyze D-002 | Keeps client and server tracking one upstream contract; `encodeSSE` is the canonical framing |

## Dev-only, stated plainly

A Vite `configureServer` middleware serves the **dev server only**. Production
would need this route reimplemented behind the app's real backend. That is
acceptable because the phase goal is a scaffolder demonstrating the protocol,
not a production agent host — but p7-05 task 1.6 requires the generated README
to say so, because the emitted app otherwise looks production-shaped.

## Path contract

`assets/scaffold/agui/{mock-agent.ts,vite-plugin-agui-mock.ts}` are read **by
name** by p7-05 tasks 1.4/1.5. Renaming or relocating either silently breaks
p7-05 with no gate catching it. Update p7-05 in the same commit if a path must
change.
