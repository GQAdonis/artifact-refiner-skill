# Execution: phase-prefer-endpoint-consumption

**Status:** COMPLETE
**Backend:** OpenSpec
**Executed:** 2026-05-20

## Acceptance gates — 7/7 PASS

| # | Gate | Result |
|---|---|---|
| 6.1 | Resolver self-test prints 3 healthy resolutions | PASS — 3/3 `healthy=yes` against live proxy |
| 6.2 | Client self-test calls proxy + returns string + writes log | PASS — reply `"pong"`, log written |
| 6.3 | Probe CLI prints + exits 0 | PASS |
| 6.4 | Log file exists at `.refiner/<artifact>/model-routing.log` | PASS — `.refiner/_self_test/model-routing.log` created |
| 6.5 | All 5 phase controllers have `<!-- MODEL_ROUTING -->` blocks | PASS (5/5) |
| 6.6 | Fallback works when proxy unhealthy | PASS — `endpoint=host_harness, reason=openai_proxy_unhealthy_fallback_to_host_harness` |
| 6.7 | Convert-htmx-react `--llm-judgment` produces sidecar LLM suggestions | PASS — `gpt-5.4-mini` returned concrete TSX for HTMX regions |

## Live verification

```
$ node scripts/lib/model-routing.mjs
  refiner-iterate        tier=small    endpoint=openai_proxy   model=gpt-5.4-mini    healthy=yes  reason=prefer_endpoint_healthy
  refiner-evaluate       tier=medium   endpoint=openai_proxy   model=gpt-5.3-codex   healthy=yes  reason=prefer_endpoint_healthy
  refiner-finalize       tier=small    endpoint=openai_proxy   model=gpt-5.4-mini    healthy=yes  reason=prefer_endpoint_healthy

$ node scripts/lib/openai-client.mjs
  reply: "pong"
  log:   .refiner/_self_test/model-routing.log

$ cat .refiner/_self_test/model-routing.log
2026-05-20T21:38:01.058Z phase=refiner-iterate tier=small endpoint=openai_proxy
  model=gpt-5.4-mini status=ok reason=prefer_endpoint_healthy
  tokens_in=28 tokens_out=5 duration_ms=1168 attempt=0

$ node scripts/model-routing-probe.mjs
PHASE                 TIER     ENDPOINT        MODEL               HEALTHY  REASON
refiner-iterate       small    openai_proxy    gpt-5.4-mini        yes      prefer_endpoint_healthy
refiner-evaluate      medium   openai_proxy    gpt-5.3-codex       yes      prefer_endpoint_healthy
refiner-finalize      small    openai_proxy    gpt-5.4-mini        yes      prefer_endpoint_healthy

$ # Fallback path verification
$ # (with health_probe temporarily pointed at dead port)
$ endpoint: host_harness / healthy: true / reason: openai_proxy_unhealthy_fallback_to_host_harness
```

## Deliverables

| Path | Status | Notes |
|---|---|---|
| `scripts/lib/model-routing.mjs` | created (~160 lines) | resolver + health probe + 30s cache |
| `scripts/lib/openai-client.mjs` | created (~150 lines) | `chat()` + `chatRaw()` + log + retry once on 5xx |
| `scripts/model-routing-probe.mjs` | created (~50 lines) | CLI table printer |
| `prompts/specify.md` | modified | MODEL_ROUTING block prepended |
| `prompts/plan.md` | modified | MODEL_ROUTING block prepended |
| `prompts/execute.md` | modified | MODEL_ROUTING block prepended (phase=refiner-iterate) |
| `prompts/reflect.md` | modified | MODEL_ROUTING block prepended (phase=refiner-evaluate) |
| `prompts/persist.md` | modified | MODEL_ROUTING block prepended (phase=refiner-finalize) |
| `prompts/meta-controller.md` | modified | new Startup Protocol step 4 (probe + advisory note) |
| `scripts/convert-htmx-react.mjs` | modified | `--llm-judgment` flag + per-region LLM suggestion injection |

## Decisions during execute

1. **`HostHarnessRoutingError` exported** from `openai-client.mjs` — caller can `instanceof`-check to decide whether to surface the fallback or use a non-LLM path. The convert-htmx-react integration catches it and falls back to deterministic recommendation only.

2. **Sample sidecar shows both deterministic + LLM suggestion** rather than replacing one with the other. User sees both surfaces and picks. Avoids "LLM gospel" behavior — the deterministic recommendation remains authoritative; LLM is supplementary.

3. **Log line includes `attempt=` count** — makes it easy to grep for retry occurrences in audit. v1 retries at most once on 5xx; future tuning is one config change.

4. **Phase keys differ between controllers and model_policy in two places**:
   - `prompts/specify.md` → `refiner-specify` (no policy entry; resolver falls back to `default_endpoint`)
   - `prompts/plan.md` → `refiner-plan` (same)
   - `prompts/execute.md` → `refiner-iterate` (in policy)
   - `prompts/reflect.md` → `refiner-evaluate` (in policy)
   - `prompts/persist.md` → `refiner-finalize` (in policy)

   Specify and Plan don't have policy entries because they're set-up phases that don't iterate model calls; they fall through to `default_endpoint` which is `host_harness`. Documented in `references/model-routing.md`.

5. **Probe CLI deliberately never fails.** Unhealthy endpoints produce fallback rows with `healthy=no`; exit is always 0. Reasoning: the probe is a discovery tool; failing on unhealthy state would prevent users from seeing the resolution at all.

## Known follow-ups (not blocking)

- Streaming completions — when a consumer wants progress feedback
- Tool/function calling — when a consumer needs structured outputs
- Per-artifact `model_overrides` from state file — currently only `project.json` policy is read
- Anthropic SDK direct integration — host harness covers Claude today; direct integration is a v2 feature
- Cost telemetry aggregation — log lines have tokens; a `node scripts/cost-report.mjs` could aggregate
- Windows .bat wrapper for `check-openai-proxy-health.sh` (currently bash-only)

## Out of scope (deferred per phase plan)

All listed in proposal §Out of scope. Nothing changed during execute.

## Next phase

`/kbd-reflect phase-prefer-endpoint-consumption`.
