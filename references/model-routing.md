# Artifact Refiner — Model Routing

The refiner uses tiered model selection at the phase level. Iteration (delta generation) and finalization (manifest write) are mechanical and run on small models. Evaluation (constraint violation judgment) requires calibrated scoring and routes to a medium model. Each tier additionally picks an **endpoint** (host harness, openai-proxy, etc.) and optionally a **preferred model alias** on that endpoint.

## Policy Source

```
.kbd-orchestrator/project.json → model_policy
```

Schema: `references/schemas/model-policy.schema.json`. Validate via:

```bash
python3 -c "import json, jsonschema; \
  jsonschema.validate( \
    json.load(open('.kbd-orchestrator/project.json'))['model_policy'], \
    json.load(open('references/schemas/model-policy.schema.json')))"
```

If `project.json` is absent or lacks `model_policy`, treat all phases as `frontier` and log a warning to `.refiner/<artifact_name>/model-routing.log`.

## Endpoints

The `endpoints` map in `model_policy` registers reachable model providers. v1.2.0 defines two:

| Endpoint id   | Shape                                            | Use when                                                                 |
|---------------|--------------------------------------------------|--------------------------------------------------------------------------|
| `host_harness` | `{ "via": "host" }`                              | Inference goes through whichever LLM harness hosts the refiner (Claude Code, Codex CLI, Antigravity). Best for reasoning-heavy phases when host is a frontier model. |
| `openai_proxy` | `{ "base_url", "auth_mode", "health_probe", ... }` | Subscription-priced inference via the `openai-proxy` external prerequisite. Best for high-volume mechanical phases. See `docs/integrations/openai-proxy.md`. |

Endpoint entries are validated by `model-policy.schema.json`.

## Phase → Class Map

| Phase Key            | Class    | Rationale                                                          |
|----------------------|----------|--------------------------------------------------------------------|
| `refiner-iterate`    | small    | Constraint-diff delta generation per violation. Mechanical edits.  |
| `refiner-evaluate`   | medium   | Constraint violation judgment. Needs calibrated scoring rubric.    |
| `refiner-finalize`   | small    | Manifest write, log commit, archive. No reasoning required.        |

## Endpoint Preference

Each phase entry may additionally declare `prefer_endpoint` and `prefer_model`:

```jsonc
"refiner-iterate": {
  "tier": "small",
  "prefer_endpoint": "openai_proxy",
  "prefer_model": "gpt-5.4-mini"
}
```

Selection algorithm at phase entry:

1. If `prefer_endpoint` is set and the endpoint is **healthy**, route to that endpoint using `prefer_model` (when present) or the tier's default model.
2. Else fall back to `default_endpoint` from the policy root.
3. If `default_endpoint` is also unhealthy (rare; `host_harness` is always considered healthy), emit a warning and continue on host.

Health is determined per-endpoint:

| Endpoint id   | Health check |
|---------------|--------------|
| `host_harness` | Always considered healthy (inference is host-driven). |
| `openai_proxy` | `bash scripts/check-openai-proxy-health.sh` (uses `OPENAI_PROXY_HEALTH_URL` or the `health_probe` URL from the endpoint entry). |

## Model ID Aliases

The strings appearing in `prefer_model` (e.g., `gpt-5.4-mini`, `gpt-5.3-codex`) are **proxy-mediated aliases**, not canonical OpenAI / Anthropic API model identifiers. `openai-proxy` maintains its own catalog and translates aliases to upstream endpoints. If the proxy renames a catalog entry in a future release, the `prefer_model` strings in `project.json` must be updated to match.

When inference goes through `host_harness`, model selection is controlled by the host harness — the `prefer_model` field is ignored for that endpoint.

## When to Override

The defaults assume direct content (`direct:*`) refinement against a clear constraint set. Override to a higher class when:

- **Meta-prompt refinement (`meta:*`)** — prompt quality evaluation benefits from `frontier` for `refiner-evaluate`
- **First-iteration creative seed** — initial artifact generation from scratch (no prior version) may use `medium` for `refiner-iterate` if the constraint set is sparse
- **Cross-domain artifacts** — artifacts that span domain adapters (e.g., logo + brand voice + UI mock) may need `frontier` evaluation

Specify overrides in the artifact's state file under `model_overrides`:

```json
{
  "artifact_name": "acme-logo",
  "model_overrides": {
    "refiner-evaluate": "frontier"
  }
}
```

## Routing Directive

Emit a directive at each phase transition for external orchestrators:

```
[MODEL_ROUTING] phase=refiner-iterate class=small model=Qwen3.5-9B-Q8_0 env=local
```

Append to `.refiner/<artifact_name>/model-routing.log`.

## Fallback Rule

If `model_policy` is absent from `project.json`:

- Treat all phases as `frontier`
- Log: `[WARN] model_policy absent — defaulting to frontier for all refiner phases`
- Do not silently downgrade evaluation to a smaller model

If `prefer_endpoint` is set to a non-`host_harness` endpoint and its health check fails:

- Route the phase to `default_endpoint` (typically `host_harness`)
- Log: `[WARN] endpoint <id> unhealthy — falling back to <default_endpoint> for phase <phase>`
- Continue without raising — cost-routing is a nice-to-have; functional inference is the requirement
