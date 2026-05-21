# Phase Assessment: Inference Routing via openai-proxy

**Phase:** `phase-1b-inference-routing`
**Project:** `artifact-refiner`
**Date:** 2026-05-20
**Author:** Claude Code (Opus 4.7, 1m context)
**Mode:** Assessment only — no implementation
**Sycophancy correction:** applied
**Decision pre-applied:** Q-003 = B (external prerequisite)

---

## 1. Goal Restatement

Wire `openai-proxy` (the six-surface Rust binary at `references/baseline/openai-proxy/`) as an external endpoint that the artifact-refiner PMPO loop can route inference calls through. The goal is **cost-aware routing** — direct mechanical phases (iterate, finalize) at cheap subscription-priced GPT-5.4-mini calls, and reasoning-heavy phases (evaluate, plan) at host-harness Claude or higher-tier proxy models.

Per Q-003 = B authorization (2026-05-20), `openai-proxy` is a **prerequisite the user installs separately**, not a submodule we vendor and build.

### What done looks like

1. `references/model-routing.md` documents endpoints, including `openai_proxy`, and how phase-tier selection chooses a model from a given endpoint.
2. `.kbd-orchestrator/project.json → model_policy` (already partially populated) is the source of truth, validated against a schema or documented format.
3. A health-probe utility (small script) detects whether the proxy is running at `localhost:8080/health` and reports readiness.
4. A skill or docs file tells the user how to install + run the proxy (referencing the existing `references/baseline/openai-proxy` README + SKILL.md without duplicating).
5. **No** PMPO-loop refactor in this phase. The runtime consumption of `model_policy` is a downstream concern. This phase wires the *configuration and discovery* layer; the loop already routes via host-harness today and can later honor `prefer_endpoint` when consumption code lands.

---

## 2. Sycophancy-Corrected Assessment

### Where the user's framing is correct

- The cost-routing premise is real. Subscription-priced inference (ChatGPT Plus/Pro via `openai-proxy`) at fixed monthly cost is genuinely cheaper for high-volume mechanical phases than per-token API billing.
- `openai-proxy` is real, working code with documented surfaces. Six delivery paths (HTTP, opencode plugin, MCP, ACP, AG-UI, A2A) — we use one (HTTP) plus optionally MCP.
- External-prerequisite is the right wiring choice. The proxy has its own release cadence, `codex login` is naturally a one-time user step, and submoduling would couple our build to its build.

### Where corrections apply

#### Correction 1 — Don't refactor the PMPO loop yet

The seduction is to make this phase the one where the refiner *actually consumes* the `model_policy` block at runtime. That is a much larger change (the loop currently hardcodes host-harness inference; threading endpoint selection through every model-call site is consumption-layer work). 

**Corrected goal:** wire the *configuration and discovery* layer only. The runtime hookup is a separate phase, properly bounded.

#### Correction 2 — The model-routing reference and project.json are already inconsistent

`project.json → model_policy` (added in phase-0) has `endpoints:`, `phases.*.prefer_endpoint`, `phases.*.prefer_model`. The `references/model-routing.md` doc has no `endpoints` section and no `prefer_*` mention. The doc lags the schema.

**Corrected goal:** **first sync the doc to the schema**, then validate them against each other. Without this, future contributors will pick up the doc and write code that doesn't match the data.

#### Correction 3 — Don't hide what `openai-proxy` actually requires

`openai-proxy` itself depends on either `codex login` (ChatGPT subscription path) or an `OPENAI_API_KEY` env var (fallback). Setup is non-trivial. Pretending it's "just an external prerequisite" without documenting the setup is unfair to anyone trying to use the routing.

**Corrected goal:** ship a short skill or doc page `docs/integrations/openai-proxy.md` that:
- points at the upstream README / SKILL.md
- documents the minimum boot sequence (`codex login` → `cargo build --release` → `./target/release/openai-proxy serve`)
- documents the health-probe URL and what a healthy response looks like
- documents how to disable the routing if proxy isn't running (no silent failure)

#### Correction 4 — Health-probe needs a fallback, not a hard fail

The phase ships a health-probe script. If the probe fails, the refiner must **fall back to host-harness routing**, not error out. Subscription cost optimization is a nice-to-have; refiner functionality is the requirement.

**Corrected goal:** the health-probe utility prints a `READY` / `NOT_READY` signal; the consumer (later phase) honors the result by setting `prefer_endpoint` to `host_harness` when `NOT_READY`. Document this fallback behavior now even if runtime consumption is deferred.

#### Correction 5 — The model IDs in project.json are guesses

`project.json` lists models `gpt-5.4-mini`, `gpt-5.3-codex`, etc. — these come from the `openai-proxy` README's "expanded model catalog" section. They are **upstream-defined names**, not Anthropic / OpenAI canonical model identifiers. They are upstream-mediated proxy aliases.

**Corrected goal:** record this clearly in the model-routing doc — these strings are proxy aliases, not direct API model IDs. The proxy translates them. If proxy changes its catalog, our `prefer_model` strings may need to change too.

---

## 3. Current state inventory

| Surface | Status |
|---|---|
| `references/baseline/openai-proxy/` | exists outside repo (own Cargo workspace, MIT-licensed) |
| `.kbd-orchestrator/project.json → model_policy` | exists, has endpoints + phase preferences |
| `references/model-routing.md` | exists but lacks endpoints section |
| `scripts/check-openai-proxy-health.sh` | does not exist |
| `docs/integrations/openai-proxy.md` | does not exist |
| Refiner runtime that honors `prefer_endpoint` | not implemented (deferred) |

---

## 4. Scope

### In scope (this phase)

1. **Sync `references/model-routing.md`** to the existing `model_policy` schema in `project.json`. Add `endpoints:` section explaining `host_harness` vs `openai_proxy`. Add an "Endpoint preference" section explaining `prefer_endpoint` / `prefer_model`. Add the proxy-aliases-not-canonical-IDs note.
2. **Add a schema** at `references/schemas/model-policy.schema.json` describing the shape of `project.json → model_policy`. Validate the existing block against it.
3. **Ship a health-probe utility** at `scripts/check-openai-proxy-health.sh` that:
   - Probes `localhost:8080/health` (URL configurable via env var)
   - Exits 0 + prints `READY: <version>` if healthy
   - Exits 1 + prints `NOT_READY: <reason>` if not
4. **Author `docs/integrations/openai-proxy.md`** — pointer doc to upstream, minimum setup steps, health-probe usage, fallback behavior.
5. **Update README "Submodules and vendored binaries"** with a new "External prerequisites" subsection noting `openai-proxy` is optional and how to opt in.

### Out of scope (deferred to runtime-consumption phase)

- Refactoring the PMPO loop to actually thread `prefer_endpoint` through to model calls.
- Adding `openai_proxy` as a submodule (Q-003 = B explicitly forbids this for v1).
- Implementing OAuth/credential flow inside artifact-refiner (`openai-proxy` handles its own auth).
- AG-UI / A2A surface integration (separate phases).
- Cost telemetry / per-phase cost accounting.

---

## 5. Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Schema doesn't match real project.json shape | Low | Low | Validate during execute |
| Health-probe URL hardcoded; user runs proxy on different port | Medium | Low | Make URL configurable via `OPENAI_PROXY_HEALTH_URL` env var |
| Doc references a moving upstream README | Medium | Low | Pin to a specific upstream commit in the doc; relative link form |
| Future consumers ignore fallback behavior and hard-fail when proxy is down | Medium | Medium | Document explicitly; add an integration test placeholder in the consumption phase plan |

No high-severity risk.

---

## 6. Acceptance criteria

1. `references/model-routing.md` includes an "Endpoints" section listing `host_harness` and `openai_proxy` with semantics matching `project.json`.
2. `references/schemas/model-policy.schema.json` validates the existing `project.json → model_policy` block (round-trip test or schema-validator pass).
3. `bash scripts/check-openai-proxy-health.sh` exits cleanly (0 or 1) with a recognizable status line. Configurable URL via env var.
4. `docs/integrations/openai-proxy.md` exists with boot sequence + fallback notes.
5. README has a paragraph (or table row) about the optional `openai-proxy` external prerequisite.

---

## 7. Phase decomposition

| # | Sub-change | Effort |
|---|---|---|
| 1 | Author `references/schemas/model-policy.schema.json` | small |
| 2 | Validate current `project.json → model_policy` against the schema | small |
| 3 | Update `references/model-routing.md` with endpoints section + prefer_endpoint/prefer_model semantics + proxy-aliases note | small |
| 4 | Author `scripts/check-openai-proxy-health.sh` (env-configurable URL) | small |
| 5 | Author `docs/integrations/openai-proxy.md` | small |
| 6 | README "External prerequisites" subsection | trivial |
| 7 | Acceptance gate sweep | small |

Total: one focused session.

---

## 8. Open questions

1. **Health-probe transport.** `curl`-only (most portable), or also offer a Rust-based prober? Recommendation: `curl` for v1; promote to Rust if dependency-free probing becomes a real requirement.
2. **Schema validator.** Use `ajv` (Node, already in repo via `node_modules`) or `python3 -c "import jsonschema"` (probably present)? Recommendation: detect at runtime; prefer `node node_modules/.bin/ajv` if available, fall back to `python3 -c "import jsonschema; ..."`.
3. **Where the openai-proxy integration doc lives.** `docs/integrations/openai-proxy.md` (recommended — clear external-integration namespace) vs `references/endpoints/openai-proxy.md`. Recommendation: `docs/integrations/`.

---

## 9. Honest verdict

This phase is a clean configuration-and-discovery wire-up. It does **not** ship runtime cost savings — that happens in a follow-on phase when the refiner actually honors `prefer_endpoint`. What it does ship:

- A coherent doc/schema/data triplet so future consumption code has a stable surface to read.
- A health-probe so consumption code can ask "is the proxy up?" cheaply.
- A user-facing integration doc so installing the prerequisite is straightforward.

This is "make the contract real, defer the consumption" — the same pattern as TemplateEngine trait being shipped with one implementor in phase-rust-workspace-bootstrap.

**Recommendation:** proceed to `/kbd-plan phase-1b-inference-routing`.

---

## 10. Assessment metadata

```yaml
assessment_complete: true
phase: phase-1b-inference-routing
decisions_pre_applied:
  Q-003: "B (external prerequisite, not submodule)"
scope_discipline_applied:
  - No PMPO loop refactor in this phase
  - No vendoring openai-proxy
  - Doc/schema/data triplet only
recommendation: |
  Proceed to /kbd-plan phase-1b-inference-routing.
  ~1 focused session of work. No risk-surface above low severity.
next_command: /kbd-plan phase-1b-inference-routing
```

Completed kbd-assess — phase-1b-inference-routing
