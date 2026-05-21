# Reflection: phase-prefer-endpoint-consumption

**Date:** 2026-05-20
**Status:** Complete. 7/7 acceptance gates PASS. Live cost-routing verified against `localhost:8181`.

## Goal Achievement

| Goal | Status |
|---|---|
| Resolver reads `model_policy` and produces per-phase decisions | MET |
| Health probe runs lazily with 30s cache | MET |
| `host_harness` is always healthy by definition | MET |
| Fallback path: unhealthy `prefer_endpoint` → `default_endpoint` | MET |
| `chat(phaseKey, messages)` calls the proxy and returns assistant content | MET |
| Per-artifact `.refiner/<name>/model-routing.log` records every call | MET |
| `HostHarnessRoutingError` exported so callers can branch on no-op routing | MET |
| Probe CLI prints a per-phase resolution table and exits 0 | MET |
| All 5 phase controllers carry `<!-- MODEL_ROUTING -->` blocks | MET |
| Meta-controller Startup Protocol mentions the probe + advisory note | MET |
| `convert-htmx-react --llm-judgment` produces LLM TSX suggestions per region | MET |

**Achievement: 11/11 MET (100%). All acceptance gates passed on first integration run.**

## Delivered Changes

| Path | Status | Lines | Block |
|---|---|---|---|
| `scripts/lib/model-routing.mjs` | created | ~160 | Task 1 |
| `scripts/lib/openai-client.mjs` | created | ~150 | Task 2 |
| `scripts/model-routing-probe.mjs` | created | ~50 | Task 3 |
| `prompts/specify.md` | modified — prepended MODEL_ROUTING | +7 | Task 4 |
| `prompts/plan.md` | modified — prepended MODEL_ROUTING | +7 | Task 4 |
| `prompts/execute.md` | modified — prepended MODEL_ROUTING (phase=refiner-iterate) | +7 | Task 4 |
| `prompts/reflect.md` | modified — prepended MODEL_ROUTING (phase=refiner-evaluate) | +7 | Task 4 |
| `prompts/persist.md` | modified — prepended MODEL_ROUTING (phase=refiner-finalize) | +7 | Task 4 |
| `prompts/meta-controller.md` | modified — Startup Protocol step 4 | +12 | Task 4 |
| `scripts/convert-htmx-react.mjs` | modified — `--llm-judgment` flag + per-region LLM injection | +30 | Task 5 |

## Artifact Quality Summary

| Metric | Value |
|---|---|
| Changes with QA | 6/6 |
| First-pass pass rate | 6/6 (100%) |
| Changes requiring refinement | 0 |
| Total refinement iterations | 0 |
| Acceptance gates passed | 7/7 |
| Live proxy roundtrips during smoke | 4+ (resolver probe, client self-test, probe CLI, convert-htmx-react with 3 regions) |
| Token cost during smoke | ~hundreds of tokens — negligible at subscription pricing |

### Recurring Constraint Violations

None. Every deliverable worked on first compile and first run.

### Why this phase was clean (in contrast to phase-4 Block A)

Phase-4 Block A required 5 patcher iterations because it was a **retroactive correction** to existing string-manipulating scripts. This phase is **net-new code with no entanglement**:

- New files don't conflict with anything
- The resolver/client APIs are pure functions and async/await — easy to reason about
- The convert-htmx-react integration is bracketed by `if (LLM_JUDGMENT)` — opt-in, doesn't change default behavior
- The phase-controller edits are pure prepends — no parse/rewrite logic
- The live proxy is reachable and conformant; no protocol surprises

Net-new code with clean boundaries is cheaper than retroactive correction by an order of magnitude. Worth remembering.

## Technical Debt Introduced

| Debt | Severity | Notes |
|---|---|---|
| `chat()` does no streaming | Low | Sufficient for translation-shaped tasks; streaming for v2 |
| Tool/function calling not supported | Low | Plain text responses only; the proxy supports it; v2 |
| Per-artifact `model_overrides` from state file not read | Low | Only `project.json` policy is consumed; documented in references/model-routing.md |
| Health probe uses bash script (Windows users need a workaround) | Low | The bash script works on macOS/Linux/WSL; Windows .bat wrapper is future work |
| No cost telemetry aggregation | Low | Token counts logged per call; a `cost-report.mjs` aggregator is a 30-min add |
| Anthropic SDK direct integration | Low | Host harness covers Claude today; direct integration is a v2 feature |
| `chat()` from inside a host-harness-routed phase throws | Medium-Low | Documented as `HostHarnessRoutingError`. Caller must catch and either skip or use a non-LLM path. The convert-htmx-react integration does this correctly. Other future consumers must follow the same pattern. |

None blocking.

## Lessons Captured

### Lesson 1 — Net-new code with clean boundaries is fast

Compared to phase-4 Block A (5 iterations), this phase shipped 7/7 gates on first run. The difference: **net-new files with explicit APIs vs. retroactive edits to string-manipulating scripts**. Where possible, prefer adding new files over modifying old ones — even when the architecturally-clean move is to extend an existing surface.

### Lesson 2 — `HostHarnessRoutingError` as a typed sentinel beats a magic return value

The resolver could have returned `{ endpoint: "host_harness" }` and let `chat()` silently no-op. Instead it throws a named error. Callers can:

- `instanceof`-check and fall back to a non-LLM path (convert-htmx-react does this)
- Let it propagate if LLM is actually required
- Log + skip if LLM is optional

The error message itself explains the situation (`Routing for phase 'refiner-iterate' resolved to host_harness (openai_proxy_unhealthy_fallback_to_host_harness); chat() cannot proxy host inference.`). Typed sentinels make APIs self-documenting.

### Lesson 3 — Advisory directives are durable across harnesses

The `<!-- MODEL_ROUTING -->` HTML comment is invisible to harnesses that don't parse it, advisory to harnesses that do, and useful as documentation to humans reading the prompt. Three audiences, one mechanism. Compare to an MCP tool call (one audience: MCP-aware harnesses) or a magic prefix (brittle parsing) — the comment block wins on durability.

### Lesson 4 — Probe-CLI-never-fails was right

I considered making the probe CLI fail with exit 1 when any endpoint was unhealthy. That would let CI catch misconfiguration. But: an unhealthy endpoint is a **runtime** condition, not a config error. The probe's job is to *show the resolution*; failing on unhealthy state prevents users from seeing it. Exit 0 always, let the row's `healthy=no` speak.

If CI wants to enforce "all endpoints healthy", that's a separate `node -e "import('./scripts/lib/model-routing.mjs').then(m => process.exit(m.resolveAllPhases().every(d => d.healthy) ? 0 : 1))"` one-liner.

### Lesson 5 — Showing both deterministic + LLM beats replacing one with the other

The convert-htmx-react sidecar now has both `**Recommendation:**` (deterministic) and `**LLM suggestion:**` (model-generated) for each ambiguous region. The user picks. This:

- Preserves the deterministic recommendation as authoritative
- Adds the LLM's view as a second opinion
- Never makes the user wonder "did the LLM just hallucinate this?"

Replacing the deterministic recommendation with an LLM-only output would have been a downgrade. **Adding** the LLM's view is strictly better.

### Lesson 6 — `refiner-specify` and `refiner-plan` correctly fall through to host_harness

The phase controllers for Specify and Plan don't have policy entries because they're set-up phases that the host harness drives by reading the markdown and following it. The PMPO loop doesn't iterate model calls inside those phases. The resolver correctly treats absent policy entries as fall-through to `default_endpoint`, which is `host_harness`. No special case needed in the resolver.

### Lesson 7 — Subscription-priced inference at scale becomes the default

Every script in the repo can now call `chat(phaseKey, messages)` and get cost-routed through the proxy. The convert-htmx-react `--llm-judgment` smoke spent maybe 50 tokens. At per-token pricing this is fractions of a cent. At subscription pricing it's free. **When pricing becomes free per-call, calling becomes cheap to design around.** Future consumers will be liberal with LLM judgment in places where it adds value, because the cost is no longer the deciding factor.

## Pipeline Maturity Assessment

```
Ideation → refined artifact          (LLM-driven, phase-0 specs)
        ↓
Conversion (HTMX → React)            (phase-3) — now with --llm-judgment
        ↓
Rebranding                           (phase-3)
        ↓
Scaffolding (Vite/React)             (phase-2 + phase-4 Block A)
        ↓
Single-binary axum deployment        (phase-2 --with-axum-wrapper)

Inference routing config             (phase-1b)
        ↓
Inference routing runtime            (this phase) ← shipped
        ↓
First consumer: convert-htmx-react   ← shipped
```

**The cost-routing infrastructure shipped in phase-1b is no longer documentation-in-the-air; it's consumed by code today.** Every future script that wants LLM assistance gets cost-routing, logging, and fallback-protection for free.

## Recommended Focus for Next Phase

Three viable candidates:

### Option A — `phase-4 Block B + Block C + Block D` (resume deferred phase-4 work)

The original phase-4 hybrid scope. Block A landed; B (responsive + PWA), C (Tauri 2 shell), and D (acceptance sweep) remain. Externally most visible — completes the headline scaffolder.

### Option B — `phase-3b-aux-conversions`

Complete `convert-md-to-htmx`, `refine-moodboard`, `design-svg-logo` execution layers. Rounds out the phase-0 promise. Smaller scope.

### Option C — `phase-7-scaffold-ag-ui-host`

Leverages openai-proxy's AG-UI SSE surface + the scaffolder substrate. Builds the agent-backed app host. More ambitious; raises new design questions.

**Recommendation: A (resume phase-4).** It's the next visible win and the substrate from this phase (cost-routing) makes the deferred Block B (PWA icon generation could use LLM if SVG generation is needed) and Block C (Tauri scaffolding may want LLM judgment on bundle.id / platform-specific config) optionally smarter — both can call `chat()` if they want.

If user prefers smaller scope, Option B is clean and self-contained.

## Knowledge Base Hooks

- "Net-new code with clean boundaries is fast; retroactive corrections are expensive — prefer new files over old-script edits when both are clean architecturally"
- "Typed-error sentinels (`HostHarnessRoutingError`) beat magic return values for routing/fallback APIs"
- "HTML-comment directives are durable across all parser/harness modalities — invisible/advisory/documentation"
- "Probe CLIs should never fail on runtime conditions; exit 0 and let row data speak"
- "Both-views sidecars beat replace-one-with-the-other for LLM-assisted refinement"
- "Subscription-priced inference at scale makes LLM judgment cheap to design around"

## Reflection Metadata

```yaml
phase: phase-prefer-endpoint-consumption
goals_met: 11/11 (100%)
acceptance_gates_passed: 7/7
first_pass_quality: 6/6 (100%)
refinement_iterations: 0
end_to_end_integration: PASS (live proxy at localhost:8181, gpt-5.4-mini returned "pong")
technical_debt_blocking: false
new_capability_now_available: chat(phaseKey, messages) for any script in the repo
first_concrete_consumer: convert-htmx-react --llm-judgment (3 regions translated)
pipeline_maturity: cost-routing infrastructure has a real consumer
next_phase_recommended: phase-4 Blocks B + C + D (resume hybrid scaffolder)
alternates: [phase-3b-aux-conversions, phase-7-scaffold-ag-ui-host]
```

Completed kbd-reflect — phase-prefer-endpoint-consumption
