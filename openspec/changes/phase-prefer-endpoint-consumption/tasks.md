# Tasks: phase-prefer-endpoint-consumption

## 1. Resolver — `scripts/lib/model-routing.mjs`

- [ ] 1.1 Author module. Exports:
  - `resolvePhase(phaseKey, opts?)` → `{ tier, endpoint, model, endpointConfig, healthy, reason }`
  - `resolveAllPhases(opts?)` → array of decisions for every phase in `model_policy.phases`
  - `clearHealthCache()` (testing helper)
- [ ] 1.2 Loads `.kbd-orchestrator/project.json` lazily; if missing → returns `{ endpoint: "host_harness", reason: "no_project_json" }` for every phase.
- [ ] 1.3 `host_harness` is always `healthy: true` (no probe).
- [ ] 1.4 `openai_proxy` health is probed via `bash scripts/check-openai-proxy-health.sh` with the `OPENAI_PROXY_HEALTH_URL` env set from `endpointConfig.health_probe`. Result cached for 30 seconds per endpoint URL.
- [ ] 1.5 If `prefer_endpoint` is unhealthy, decision falls back to `default_endpoint` with `reason: "<endpoint>_unhealthy_fallback_to_default"`.
- [ ] 1.6 Self-test: invoke with no args → resolves all phases against the live proxy; print result.

## 2. OpenAI client — `scripts/lib/openai-client.mjs`

- [ ] 2.1 Author module. Exports:
  - `chat(phaseKey, messages, opts?)` → returns string (assistant message content)
  - `chatRaw(phaseKey, messages, opts?)` → returns full JSON response
- [ ] 2.2 `opts` shape: `{ artifactName?: string, maxTokens?: number, temperature?: number, timeoutMs?: number }`.
- [ ] 2.3 Behavior:
  - Calls `resolvePhase(phaseKey)`.
  - If endpoint is `host_harness` → throws `HostHarnessRoutingError` (caller decides: ignore or surface). This is the no-op fallback case.
  - If endpoint is `openai_proxy` → fetch `endpointConfig.base_url + "/chat/completions"` with `{ model, messages, max_tokens?, temperature? }`. Retry once on 5xx after 1s.
  - On 4xx → throw with the proxy's error body.
  - Logs every call (success, fallback, error) to `.refiner/<artifactName>/model-routing.log` (or `unknown/` if no artifactName).
- [ ] 2.4 Log line format (one line, append-only):
  ```
  <ISO8601> phase=<phaseKey> tier=<tier> endpoint=<endpoint> model=<model> status=<ok|fallback|error> reason=<reason> tokens_in=<n> tokens_out=<n> duration_ms=<n>
  ```
- [ ] 2.5 Self-test: `chat("refiner-iterate", [{role:"user", content:"reply 'pong'"}])` against the live proxy returns a string; log line written.

## 3. Probe CLI — `scripts/model-routing-probe.mjs`

- [ ] 3.1 Author CLI. Accepts `--artifact <name>` (optional, defaults to `_probe`).
- [ ] 3.2 Calls `resolveAllPhases()`, prints a plain-text table:
  ```
  PHASE                  TIER     ENDPOINT       MODEL              HEALTHY  REASON
  refiner-iterate        small    openai_proxy   gpt-5.4-mini       yes      prefer_endpoint_healthy
  refiner-evaluate       medium   openai_proxy   gpt-5.3-codex      yes      prefer_endpoint_healthy
  refiner-finalize       small    openai_proxy   gpt-5.4-mini       yes      prefer_endpoint_healthy
  ```
- [ ] 3.3 Exit 0 always (probe never fails; unhealthy endpoints just produce fallback rows).
- [ ] 3.4 Smoke: run against live proxy; verify three "yes" rows.

## 4. Phase controller directives

- [ ] 4.1 For each of `prompts/{specify,plan,execute,reflect,persist}.md`, prepend a `<!-- MODEL_ROUTING -->` block listing:
  ```
  <!-- MODEL_ROUTING
  phase: refiner-<phase>
  policy_source: .kbd-orchestrator/project.json → model_policy.phases.refiner-<phase>
  probe_command: node scripts/model-routing-probe.mjs
  log_path: .refiner/${artifact_name}/model-routing.log
  -->
  ```
- [ ] 4.2 `prompts/meta-controller.md` Startup Protocol: add a step that suggests running the probe at session start so the host harness has the routing table in context.

## 5. First consumer: convert-htmx-react

- [ ] 5.1 Add `--llm-judgment` CLI flag to `scripts/convert-htmx-react.mjs` (default off).
- [ ] 5.2 When enabled, the ambiguous-region recorder calls `chat("refiner-iterate", ...)` for each region with a structured prompt asking for a JSX translation suggestion.
- [ ] 5.3 The LLM's suggestion is appended to the sidecar markdown under a `**LLM suggestion:**` block (in addition to the existing `**Recommendation:**`).
- [ ] 5.4 Smoke: run convert against `sample-htmx.html` with `--llm-judgment`; verify sidecar has LLM suggestions; verify proxy log line written.

## 6. Acceptance gates

- [ ] 6.1 `node scripts/lib/model-routing.mjs` (self-test mode) prints three resolutions, all with `healthy: true`.
- [ ] 6.2 `node scripts/lib/openai-client.mjs` self-test calls the proxy, returns a string, writes a log line.
- [ ] 6.3 `node scripts/model-routing-probe.mjs` prints the table cleanly and exits 0.
- [ ] 6.4 `.refiner/_probe/model-routing.log` does not exist (probe doesn't write); `.refiner/<artifact>/model-routing.log` does exist after a real `chat()` call.
- [ ] 6.5 Each phase controller in `prompts/` has the `<!-- MODEL_ROUTING -->` block at the top.
- [ ] 6.6 With proxy stopped (`OPENAI_PROXY_HEALTH_URL=http://localhost:1`), `resolvePhase("refiner-iterate")` returns `endpoint=host_harness, reason=openai_proxy_unhealthy_fallback_to_default`.
- [ ] 6.7 Convert-htmx-react `--llm-judgment` flag works end-to-end; sidecar contains LLM suggestions.

## Out of scope

- Streaming completions, tool calling, cost telemetry, AG-UI streaming, Anthropic SDK direct integration, PMPO controller rewrite.

## Recommended agents

| Tasks | Agent |
|---|---|
| 1.*, 2.*, 3.* | direct authoring |
| 4.* | direct edit |
| 5.* | direct + verify-app |
| 6.* | verify-app |
| Post-execute review | code-reviewer + typescript-reviewer |
