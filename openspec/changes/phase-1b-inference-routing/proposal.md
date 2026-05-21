# Proposal: phase-1b-inference-routing

## Why

`.kbd-orchestrator/project.json → model_policy` already carries `endpoints` and `phases.*.prefer_endpoint` / `prefer_model` directives (added during phase-0 scaffolding). But `references/model-routing.md` predates that schema and documents only tier-based selection — no endpoint awareness, no proxy-aliases note. The doc and the data are out of sync.

Separately, the user's `openai-proxy` (six-surface Rust binary at `references/baseline/openai-proxy/`) is the concrete realization of the `openai_proxy` endpoint. Q-003 was answered **B** (external prerequisite, not vendored submodule), so this phase wires the **configuration and discovery** layer:

- doc/schema/data triplet synced and validated
- health-probe utility to detect proxy availability
- integration doc telling users how to install + boot the proxy
- README "External prerequisites" subsection

**Runtime consumption** (the PMPO loop actually honoring `prefer_endpoint` at every model-call site) is deferred to a separate phase. Conflating the two would balloon scope.

## What Changes

- **ADDED** `references/schemas/model-policy.schema.json` — JSON Schema describing the shape of `project.json → model_policy` (endpoints map, phase preferences, fallback rules).
- **MODIFIED** `references/model-routing.md` — adds "Endpoints" section, "Endpoint preference" section, proxy-aliases-not-canonical-IDs note. Keeps existing tier-class semantics intact.
- **ADDED** `scripts/check-openai-proxy-health.sh` — probes a configurable URL (default `http://localhost:8080/health`); prints `READY: <body>` or `NOT_READY: <reason>`; exits 0 or 1.
- **ADDED** `docs/integrations/openai-proxy.md` — pointer doc with minimum boot sequence, health-probe usage, fallback behavior, link to upstream README.
- **MODIFIED** `README.md` — new "External prerequisites" subsection under the existing "Installation" tree, mentioning `openai-proxy` as optional.

## Impact

### Affected surfaces

- `references/model-routing.md`
- `references/schemas/model-policy.schema.json` (new)
- `scripts/check-openai-proxy-health.sh` (new)
- `docs/integrations/openai-proxy.md` (new)
- `README.md`

### Affected dependencies

None at the package level. Health-probe uses `curl` (assumed present on dev machines).

### Risk surface

- **Low** — all changes are docs/schema/scripts. No runtime code path touched.
- **Zero** for the PMPO loop — explicitly out of scope.

### Out of scope (separate phase)

- PMPO loop actually honoring `prefer_endpoint` / `prefer_model` at runtime (→ `phase-prefer-endpoint-consumption`).
- Vendoring `openai-proxy` as a submodule (Q-003 = B forbids).
- AG-UI / A2A surface integration (separate phases each).
- Cost telemetry / per-phase cost accounting (later).
