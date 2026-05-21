# Plan: phase-prefer-endpoint-consumption

**Backend:** OpenSpec (`openspec/changes/phase-prefer-endpoint-consumption/`)
**Tasks:** `openspec/changes/phase-prefer-endpoint-consumption/tasks.md`
**Proposal:** `openspec/changes/phase-prefer-endpoint-consumption/proposal.md`

## Decisions baked in

- **Two surfaces, not three:** routing directive (advisory to host harness) + direct proxy client (for scripts). No PMPO controller rewrite.
- **`host_harness` is always healthy by definition.** Only proxy-style endpoints probe.
- **`host_harness` is the no-op for `chat()`** — throws `HostHarnessRoutingError`. The caller decides whether to surface it or fall back to a non-LLM path.
- **30-second health-probe cache.** Per resolver instance; clears on process exit.
- **Tier is the contract; endpoint+model are fulfillment.** Caller passes phaseKey, not endpoint/model.
- **`--llm-judgment` flag in convert-htmx-react is opt-in.** Default behavior unchanged.
- **Log format is single line, grep-friendly.** No JSON, no multi-line entries.
- **Probe CLI never fails.** Unhealthy endpoints produce fallback rows, exit 0.

## Ordered change list

| # | Change | Section | Gate |
|---|---|---|---|
| 1 | `scripts/lib/model-routing.mjs` resolver + self-test | 1.* | self-test prints 3 healthy resolutions |
| 2 | `scripts/lib/openai-client.mjs` chat helper + self-test | 2.* | self-test returns string + writes log line |
| 3 | `scripts/model-routing-probe.mjs` CLI | 3.* | prints table, exits 0 |
| 4 | Phase controller directives (5 files) | 4.* | grep finds `<!-- MODEL_ROUTING` in each |
| 5 | `convert-htmx-react.mjs` `--llm-judgment` integration | 5.* | sidecar contains LLM suggestions |
| 6 | Acceptance gate sweep | 6.* | 7/7 gates pass |

## Sequencing

```
1 (resolver) → 2 (client, depends on resolver) → 3 (probe, depends on resolver)
                                                     │
                                                     ▼
                                                4 (prompt directives, depends on probe command name)
                                                     │
                                                     ▼
                                                5 (convert-htmx-react consumer, depends on client)
                                                     │
                                                     ▼
                                                6 (acceptance)
```

## Risk register

| Risk | Mitigation |
|---|---|
| `fetch` not available | Node 18+ check; documented as prereq |
| `bash` not on Windows | Health probe shell script is bash; Windows users can override via env, future PR for `.bat` wrapper |
| Babel/parse5 (from phase-3) unaffected | This phase doesn't touch them |
| Concurrent test runs collide on log | Per-artifact path; tests use unique artifactName |
| Live proxy required for smoke gates | Document; gates 6.1-6.4 are conditional on proxy availability |

## Estimated effort

One focused session. Resolver + client are ~150 lines each; probe CLI is ~50 lines; prompt directives are 5 file prepends; convert-htmx-react extension is ~30 lines.

## Reuse from prior phases

- `scripts/check-openai-proxy-health.sh` — phase-1b — invoked by resolver
- `.kbd-orchestrator/project.json → model_policy` — phase-0/1b — read by resolver
- `references/schemas/model-policy.schema.json` — phase-1b — validated source
- `scripts/convert-htmx-react.mjs` — phase-3 — gets `--llm-judgment` extension

Net new: 3 scripts (resolver, client, probe CLI) + 5 prompt prepends + 1 extension to convert-htmx-react.
