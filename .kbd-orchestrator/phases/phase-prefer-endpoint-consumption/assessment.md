# Phase Assessment: prefer_endpoint Consumption

**Phase:** `phase-prefer-endpoint-consumption`
**Project:** `artifact-refiner`
**Date:** 2026-05-20
**Author:** Claude Code (Opus 4.7, 1m context)
**Mode:** Assessment only — no implementation
**Sycophancy correction:** applied
**Predecessor:** `phase-1b-inference-routing` (config layer shipped); `phase-2-scaffold-react-vite` and later phases are unrelated to this work

---

## 1. Goal Restatement

Phase-1b shipped the **configuration and discovery** layer for cost-aware inference routing: a JSON schema, doc, health-probe script, and integration doc. The `.kbd-orchestrator/project.json → model_policy` block is fully populated. The live openai-proxy is reachable at `localhost:8181` and verified to respond correctly.

**Nothing reads `model_policy` at runtime.** The PMPO loop runs entirely on host-harness inference today — refining an artifact never consults `prefer_endpoint`. The cost savings the proxy enables are conceptually available but practically unused.

This phase wires the **runtime consumption** layer: the PMPO loop honors `prefer_endpoint` and `prefer_model` per phase, falls back to `host_harness` when the proxy is unhealthy, and logs every routing decision to a per-artifact `model-routing.log` for audit.

### What done looks like

A user running `/refine-ui ...` should:

1. See a routing decision emitted at each phase transition (e.g., `[MODEL_ROUTING] phase=refiner-iterate endpoint=openai_proxy model=gpt-5.4-mini status=healthy`).
2. Have iteration / evaluate / finalize phases actually call the proxy when it's healthy (verified by hitting `localhost:8181/v1/chat/completions`).
3. Have the loop fall back transparently to host-harness when the proxy is down (verified by stopping the proxy mid-refinement).
4. Find a `.refiner/<artifact_name>/model-routing.log` that records every routing decision with timestamp + endpoint + model + reason.

---

## 2. Sycophancy-Corrected Assessment

The user's recommendation in earlier reflections was that this phase ships **internal cost savings, not user-visible features**. That framing is honest. Three corrections shape the scope.

### Correction 1 — The PMPO loop runs in the host harness, not in our code

The refinement loop today is **a prompt that the host LLM follows**. The phase controllers in `prompts/` are markdown instructions that Claude Code, Codex CLI, or another agent reads and executes by making model calls **the harness controls**. We don't own the model-call site.

This means "consume `prefer_endpoint` at runtime" cannot mean "intercept every LLM call and route it". The harness owns model selection. We have **two real consumption surfaces**:

| Surface | Description | Mechanism |
|---|---|---|
| **Routing directive at phase entry** | At each phase transition, emit a structured directive that the host harness (or an MCP tool) can read and route on. The harness *may* honor it (Claude Code can switch models per turn; Codex CLI can; Antigravity may not). | Append to `.refiner/<artifact>/model-routing.log` + emit a `[MODEL_ROUTING] ...` line to stdout |
| **Direct proxy calls from scripts** | The scripts we own (`scripts/normalize-a2ui.mjs`, `scripts/normalize-agui.mjs`, `scripts/convert-htmx-react.mjs`, etc.) that need LLM assistance can call the proxy *directly* via `openai_proxy.base_url`, bypassing the host harness entirely. This is where the cost savings concretely accrue. | A small `scripts/lib/openai-client.mjs` helper that reads model_policy + does the fetch |

**Corrected goal:** ship both surfaces. The routing directive is the harness-cooperation path; the direct proxy client is the immediate-cost-savings path.

### Correction 2 — The "small" tier doesn't need a remote model at all

A real refinement iteration on a small constraint diff is well within the capability of a local LLM, or a 4–8B model running on the proxy at a fraction of the cost. The current `prefer_model: gpt-5.4-mini` is a sensible default but the phase should treat the *tier* as the primary contract, not the model alias. The tier signals what kind of capability is needed; the endpoint+model fields are the *fulfillment*.

**Corrected goal:** wire the routing logic so that swapping a tier's model alias is a config-file edit, not a code change. Avoid hardcoding `gpt-5.4-mini` anywhere in the runtime code.

### Correction 3 — Logging beats config-file behavior

The user can already edit `model_policy` to change which phase prefers which endpoint. Adding more config options is scope creep. What's missing is **observability** — a log that says, for every refinement run, which endpoint actually handled each phase and why.

**Corrected goal:** prioritize logging + the `--probe` mode that lets a user dry-run the routing decisions without invoking the loop. Defer any new config knobs.

### Correction 4 — Don't break the host-harness path

The PMPO loop must continue to work in an environment where the host harness doesn't honor routing directives (Claude Desktop with no MCP, plain CLI runs, etc.). Routing is a *suggestion*; the loop must remain functional when the suggestion is ignored.

**Corrected goal:** every routing decision is advisory at the prompt-controller level. The directive is emitted; whether the harness honors it is the harness's choice. The fallback behavior is "do what the loop did before phase-1b" — host-harness inference.

### Correction 5 — `host_harness` is always healthy

A robotic implementation would health-check every endpoint. `host_harness` doesn't *have* a health check — the host harness is whatever is running the agent right now. By definition, if we're executing, host_harness is reachable.

**Corrected goal:** the health-check abstraction returns `true` unconditionally for `host_harness`; only proxy-style endpoints actually probe.

---

## 3. Current state inventory

| Surface | Status |
|---|---|
| `.kbd-orchestrator/project.json → model_policy` | populated, schema-validated |
| `references/model-routing.md` | documents the contract |
| `scripts/check-openai-proxy-health.sh` | shipped, fingerprint-validating |
| `references/schemas/model-policy.schema.json` | shipped |
| `prompts/meta-controller.md` etc. | **do not consume model_policy** |
| `scripts/lib/openai-client.mjs` | **does not exist** |
| `scripts/lib/model-routing.mjs` (or similar resolver) | **does not exist** |
| `.refiner/<artifact>/model-routing.log` | per phase-1b doc but **never written** |
| Direct proxy calls from any existing script | **none** |

---

## 4. Architecture choices

### A. Where the resolver logic lives

A single Node helper at `scripts/lib/model-routing.mjs` that exports:

```ts
resolvePhase(phaseKey: string): {
  tier: "small" | "medium" | "frontier",
  endpoint: "host_harness" | "openai_proxy" | string,
  model?: string,
  endpointConfig?: { base_url, auth_mode, ... },
  healthy: boolean,
  reason: string,
}
```

Used by:

- A `--probe` CLI in `scripts/lib/model-routing.mjs` that prints the resolution for every phase and exits (for users to verify config without running the loop).
- An OpenAI-client helper (Correction 1, surface 2) that pulls the resolved endpoint/model.
- A future hook that prepends `[MODEL_ROUTING]` directives to phase-controller output (Correction 1, surface 1).

### B. The OpenAI client helper

```ts
// scripts/lib/openai-client.mjs
import { resolvePhase } from "./model-routing.mjs";

export async function chat(phaseKey, messages, options = {}) {
  const decision = resolvePhase(phaseKey);
  // ... fetch to decision.endpointConfig.base_url + "/chat/completions" ...
  // ... log to .refiner/<artifact>/model-routing.log ...
  return response.choices[0].message.content;
}
```

This is consumed by **scripts we own** that need LLM assistance. The PMPO meta-controller doesn't consume it directly (it's a prompt, not code); but scripts like `convert-htmx-react.mjs`'s ambiguous-region resolver, or any future "ask LLM to translate X" helper, will call `chat("refiner-iterate", ...)` and get cost-routed for free.

### C. Routing directive emission

For the harness-cooperation surface, every phase controller in `prompts/*.md` should begin with a small block that the host harness can read:

```markdown
<!-- MODEL_ROUTING -->
phase: refiner-iterate
preferred_endpoint: openai_proxy
preferred_model: gpt-5.4-mini
fallback_endpoint: host_harness
health_probe_command: bash scripts/check-openai-proxy-health.sh
log_path: .refiner/${artifact_name}/model-routing.log
<!-- /MODEL_ROUTING -->
```

Harnesses that understand the format (Claude Code with a routing extension, Codex CLI with the appropriate plugin) can read it; harnesses that don't will treat it as a comment and continue with host-harness inference.

This is **strictly advisory**. The block is generated by a script that reads `model_policy` and writes a per-artifact phase-controller wrapper to `.refiner/<artifact>/prompts/`. Each phase controller's content is identical to the canonical `prompts/<phase>.md` plus the MODEL_ROUTING block.

### D. Audit log shape

`.refiner/<artifact>/model-routing.log` — append-only, one line per phase transition:

```
2026-05-20T14:32:11Z phase=refiner-iterate tier=small endpoint=openai_proxy model=gpt-5.4-mini status=healthy reason=prefer_endpoint_healthy
2026-05-20T14:32:45Z phase=refiner-evaluate tier=medium endpoint=openai_proxy model=gpt-5.3-codex status=healthy reason=prefer_endpoint_healthy
2026-05-20T14:33:02Z phase=refiner-finalize tier=small endpoint=host_harness model=- status=fallback reason=openai_proxy_unhealthy:http_503
```

### E. No new dependencies

Everything is plain Node + `node:fs` + `node:fetch` (available since Node 18). No new npm packages. The `culori`, `@iarna/toml`, etc. from phase-3 are not needed here.

### F. Backwards compatibility

If `model_policy` is absent from `project.json`, the resolver returns `{ endpoint: "host_harness", reason: "no_policy" }` for every phase. The loop continues working exactly as before this phase ran. **No regressions to the host-harness-only path.**

---

## 5. Scope of this phase

### In scope

1. **`scripts/lib/model-routing.mjs`** — resolver that reads `project.json → model_policy`, runs health probes, returns per-phase decisions.
2. **`scripts/lib/openai-client.mjs`** — minimal OpenAI Chat Completions client over `fetch`, consumes the resolver, logs each call to `.refiner/<artifact>/model-routing.log`.
3. **`scripts/model-routing-probe.mjs`** — CLI: `node scripts/model-routing-probe.mjs [--artifact <name>]` prints the resolution for every phase + exits. Lets the user verify config without running the loop.
4. **Update `prompts/meta-controller.md`** — add a "Startup Protocol" step that invokes the probe and includes the result in the artifact's state file.
5. **Update each phase controller (`prompts/{specify,plan,execute,reflect,persist}.md`)** — prepend a `<!-- MODEL_ROUTING -->` block parameterized by phase key. The host harness reads it advisorily.
6. **A converter integration** — update `scripts/convert-htmx-react.mjs` to optionally call `chat("refiner-iterate", ...)` when its ambiguous-region detection wants LLM judgment. This is the first concrete consumer.
7. **End-to-end smoke** — run a small refinement, observe log entries, kill proxy mid-run, observe fallback line in log.

### Out of scope (deferred)

- Streaming completions (v1 is request/response only)
- Tool-calling / function-calling (proxy supports it via OpenAI spec; we don't use it yet)
- Cost telemetry (token counts, per-phase $$ — interesting but not the contract)
- Per-artifact `model_overrides` resolution (the `model-routing.md` doc references it; the resolver passes through but doesn't read from the artifact state file in v1)
- AG-UI streaming consumption (separate phase if/when we wire it)
- Authentication switching between `chatgpt_oauth` and `openai_api_key` (the proxy handles its own auth; we just hit the URL)
- Anthropic / Claude API direct integration (host harness covers Claude)

### Out of scope explicitly: rewriting prompts to be model-call sites

The PMPO loop **stays a prompt**. We don't translate the meta-controller markdown into a Node script that drives the LLM ourselves. That would be a fundamental architecture change that this phase is not the place for.

---

## 6. Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Host harness ignores MODEL_ROUTING block | High | Low | Block is advisory; loop continues with host inference |
| Proxy goes down mid-refinement | Medium | Low | Health-probe before each phase; fallback to host |
| Log file grows unbounded | Medium | Low | Append-only per artifact; reset when state is finalized |
| Concurrent refinements write to same log | Low | Low | Per-artifact path makes collision impossible |
| Resolver's health probe slows phase transitions | Medium | Low | Cache health result for 30 seconds per resolver instance |
| `chat()` helper's user wants tool-calling | Medium | Low | v1 returns plain text; tool-calling is a v2 extension |
| Brand-swap rebrand-artifact also wants LLM judgment | Low | Low | The same chat() helper works there; no special-case |

No high-severity unmitigated risk.

---

## 7. Acceptance criteria

1. `scripts/lib/model-routing.mjs` exists; `resolvePhase("refiner-iterate")` returns `{ endpoint: "openai_proxy", model: "gpt-5.4-mini", healthy: true, ... }` when the live proxy at 8181 is up.
2. `scripts/lib/model-routing.mjs` `resolvePhase` returns `{ endpoint: "host_harness", reason: "openai_proxy_unhealthy" }` when the proxy is unreachable.
3. `scripts/lib/openai-client.mjs` exports a `chat(phaseKey, messages)` function that successfully calls `localhost:8181/v1/chat/completions` and returns the assistant message content.
4. `scripts/lib/openai-client.mjs` writes a line to `.refiner/<artifact>/model-routing.log` for every call.
5. `scripts/model-routing-probe.mjs` CLI prints a resolution table for every phase key in `model_policy.phases` and exits 0.
6. Each phase controller in `prompts/` has a `<!-- MODEL_ROUTING -->` block at the top.
7. A small end-to-end test: import `chat` from the helper, call it with `"refiner-iterate"`, verify the proxy was hit and the log line was written.
8. With proxy stopped, the same end-to-end test produces a fallback log line and (since the host harness is the test runner itself, we can't directly test host-fallback inference) at minimum exits cleanly with `reason=openai_proxy_unhealthy_no_host_inference_available_in_this_test`. The fallback path is mechanically verified by reading the log line; the actual host-harness inference is exercised in real PMPO runs.

8 acceptance gates, all deterministic.

---

## 8. Phase decomposition

| # | Sub-change | Effort |
|---|---|---|
| 1 | Author `scripts/lib/model-routing.mjs` — resolver + health-probe wrapper + 30s cache | medium |
| 2 | Author `scripts/lib/openai-client.mjs` — `chat()` + log emission | medium |
| 3 | Author `scripts/model-routing-probe.mjs` — CLI wrapping the resolver | small |
| 4 | Update `prompts/meta-controller.md` Startup Protocol to invoke the probe at session start and capture the table in state | small |
| 5 | Prepend `<!-- MODEL_ROUTING -->` blocks to `prompts/{specify,plan,execute,reflect,persist}.md` | small |
| 6 | Wire `convert-htmx-react.mjs` to use `chat()` for ambiguous-region recommendations (optional first consumer) | medium |
| 7 | End-to-end smoke: call `chat("refiner-iterate", [{role:"user", content:"hi"}])`, verify proxy hit + log entry | small |
| 8 | Stop proxy, re-run, verify fallback log line | small |
| 9 | Acceptance gate sweep | small |

Total: one focused session.

---

## 9. Open questions

1. **Should the chat() helper retry on transient failures (5xx, network errors)?** Recommendation: yes, with one retry after 1s; further retries belong in a higher-level wrapper.
2. **Where does the artifact_name come from in chat()?** Recommendation: the caller passes it; if absent, fall back to a process-wide env (`REFINER_ARTIFACT_NAME`) or `unknown`.
3. **Should host_harness route through some intermediary (anthropic SDK direct call) instead of being "rely on the host"?** Recommendation: no in v1. Direct Anthropic SDK calls duplicate what Claude Code already does and would require API keys we don't manage. Stay advisory.
4. **Should the routing log include token counts?** Recommendation: no in v1. The proxy's response includes `usage.{prompt,completion,total}_tokens` — we could log them, but it's noise until someone wants cost telemetry.
5. **Should the MODEL_ROUTING block be a real MCP tool call rather than a markdown comment?** Recommendation: comment for v1 — works with any harness. MCP tool can be a v2 add if a harness wants structured routing input.
6. **Should the probe CLI print colors / boxes / fancy tables, or stay plain text?** Recommendation: plain text for v1 — easy to grep, easy to pipe to logs.

---

## 10. Honest verdict

This phase delivers **internal cost savings + observability**, not a new user-visible capability. That's the right scoping per the original pipeline maturity assessment.

The mechanical work is small: two helpers + one CLI + light prompt edits. The conceptual work is keeping the boundary clean — the PMPO loop stays a prompt; we add a *parallel script-driven path* that other scripts can use when they want LLM assistance.

The headline outcome: every script in this repo that wants to "ask the model to translate / classify / summarize X" can do so with one line (`await chat(phaseKey, messages)`) and get cost-routed, logged, and proxy-fallback-protected for free.

**Recommendation:** proceed to `/kbd-plan phase-prefer-endpoint-consumption`. One focused session of execute expected.

---

## 11. Assessment metadata

```yaml
assessment_complete: true
phase: phase-prefer-endpoint-consumption
prerequisites_met:
  phase-1b-inference-routing: complete (config layer)
  live_proxy_verified: localhost:8181 reachable, returns valid OpenAI-compat JSON
scope_discipline_applied:
  - Two surfaces (routing directive + direct proxy client), not "intercept every LLM call"
  - Tier is the contract; endpoint+model are fulfillment (avoid hardcoded model aliases)
  - Logging beats new config knobs
  - Loop stays a prompt; no PMPO controller rewrite
recommendation: |
  Proceed to /kbd-plan phase-prefer-endpoint-consumption. One focused session.
  Concrete first consumer: convert-htmx-react ambiguous-region resolver.
next_command: /kbd-plan phase-prefer-endpoint-consumption
```

Completed kbd-assess — phase-prefer-endpoint-consumption
