# Proposal: phase-prefer-endpoint-consumption

## Why

Phase-1b shipped the configuration and discovery layer for cost-aware inference routing. `project.json → model_policy` is fully populated, schema-validated, and points at a live openai-proxy at `localhost:8181` (verified: returns valid OpenAI-compat JSON with `gpt-5.4-mini`). **Nothing consumes it.** The PMPO refinement loop runs entirely on host-harness inference; the configured cost savings are unrealized.

This phase wires runtime consumption via **two surfaces**:

1. **Routing directive** — phase controllers prepend a `<!-- MODEL_ROUTING -->` block parameterized by phase key. Cooperating host harnesses (Claude Code with routing extension, Codex CLI, etc.) can read it and switch models per phase. Non-cooperating harnesses treat it as a comment and continue with default inference. Strictly advisory.
2. **Direct proxy client** — `scripts/lib/openai-client.mjs` exports `chat(phaseKey, messages)`. Scripts in this repo that want LLM assistance (starting with `convert-htmx-react.mjs`'s ambiguous-region resolver) call it; the helper resolves endpoint via `model_policy`, runs the health probe, calls the proxy (or falls back to a clearly-logged no-op when the proxy is down), and writes an audit line to `.refiner/<artifact>/model-routing.log`.

Together: the loop gets advisory routing for harnesses that honor it; the scripts get real cost-routed inference today.

## What Changes

- **ADDED** `scripts/lib/model-routing.mjs` — `resolvePhase(phaseKey, options?)` reads `model_policy`, runs health probes (30s cache), returns `{ tier, endpoint, model, endpointConfig, healthy, reason }`.
- **ADDED** `scripts/lib/openai-client.mjs` — `chat(phaseKey, messages, options?)` consumes the resolver, calls the OpenAI-compat endpoint via `fetch`, logs each call to `.refiner/<artifact>/model-routing.log`, retries once on 5xx.
- **ADDED** `scripts/model-routing-probe.mjs` — CLI: prints a per-phase resolution table and exits.
- **MODIFIED** `prompts/meta-controller.md` — Startup Protocol step that invokes the probe and persists the table to artifact state.
- **MODIFIED** `prompts/{specify,plan,execute,reflect,persist}.md` — prepend a `<!-- MODEL_ROUTING -->` block parameterized by the controller's phase key.
- **MODIFIED** `scripts/convert-htmx-react.mjs` — extends the ambiguous-region resolver to optionally call `chat("refiner-iterate", ...)` for LLM judgment (gated by `--llm-judgment` flag; default off so existing behavior is preserved).

## Impact

### Affected surfaces

- `scripts/lib/`, `scripts/`, `prompts/`, `scripts/convert-htmx-react.mjs`

### Affected dependencies

None. Pure Node + `node:fs` + global `fetch` (Node 18+).

### Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Host harness ignores MODEL_ROUTING directive | High | Low | Advisory by design; loop continues with default inference |
| Proxy unreachable during a run | Medium | Low | Pre-call health probe; fallback log line; no crash |
| Health-probe cost (HTTP every phase) | Medium | Low | 30s in-memory cache per resolver instance |
| Convert-htmx-react users don't want LLM judgment | High | Zero | Gated behind `--llm-judgment` flag; default off |
| Log file unbounded growth | Low | Low | Per-artifact path; reset at state finalize |

### Out of scope (deferred)

- Streaming completions
- Tool/function calling
- Cost / token telemetry
- AG-UI streaming consumption
- Anthropic SDK direct integration (host harness covers Claude)
- Per-artifact `model_overrides` resolution from state file
- Rewriting PMPO controllers as Node scripts (they stay prompts)

## Integration contract preserved

- The PMPO loop **stays a prompt**. No controller is translated into runnable code.
- The host-harness path **continues to work unchanged** when `model_policy` is absent, when proxy is down, or when MODEL_ROUTING directives are ignored.
- Scripts that don't import `openai-client.mjs` are **unaffected**.

The phase adds capability without removing any.
