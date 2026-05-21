# Tasks: phase-1b-inference-routing

Sequenced. Schema first so doc updates can reference it.

## 1. Author the schema

- [ ] 1.1 Create `references/schemas/model-policy.schema.json`. Required top-level: `default_endpoint`, `phases`, `endpoints`. `phases.<phase-name>`: `tier`, optional `prefer_endpoint`, optional `prefer_model`. `endpoints.<id>`: depends on endpoint type (host_harness has `via`; openai_proxy has `base_url`, `auth_mode`, optional `fallback_auth`, optional `health_probe`).
- [ ] 1.2 Validate the existing `project.json → model_policy` block against the new schema. Prefer `python3 -c "import json,jsonschema; ..."` since Python is universally available; fall back to `node` + `ajv` if Python's jsonschema is missing.
- [ ] 1.3 Add a comment in the schema's `$comment` field noting that `prefer_model` values are upstream-proxy-defined aliases (e.g., `gpt-5.4-mini`), not canonical OpenAI/Anthropic API model IDs.

## 2. Sync `references/model-routing.md` to the schema

- [ ] 2.1 Read current `model-routing.md`. Preserve its existing "Phase → Class Map", "When to Override", "Routing Directive", and "Fallback Rule" sections.
- [ ] 2.2 Add an "Endpoints" section after "Policy Source": enumerate `host_harness` and `openai_proxy` with their semantics. Reference the schema path.
- [ ] 2.3 Add an "Endpoint Preference" section after "Phase → Class Map": explain how `prefer_endpoint` + `prefer_model` modify selection.
- [ ] 2.4 Add a "Model ID Aliases" note: `prefer_model` strings are upstream-proxy aliases; bump downstream if the proxy renames a catalog entry.
- [ ] 2.5 Update the "Fallback Rule" section: if `prefer_endpoint` is set to `openai_proxy` but the health probe fails, fall back to `host_harness` for that phase and log a warning.

## 3. Health-probe utility

- [ ] 3.1 Author `scripts/check-openai-proxy-health.sh`:
  - URL from env `OPENAI_PROXY_HEALTH_URL`, default `http://localhost:8080/health`
  - Timeout: 2 seconds (`curl --max-time 2`)
  - Output on success: `READY: <body-trimmed-to-160-chars>` → exit 0
  - Output on failure: `NOT_READY: <reason>` (timeout, refused, http-code, etc.) → exit 1
  - No retry — the consumer decides retry policy
- [ ] 3.2 `chmod +x scripts/check-openai-proxy-health.sh`.
- [ ] 3.3 Smoke test: run it with no proxy running. Should exit 1 with `NOT_READY: <reason>`. Run with `OPENAI_PROXY_HEALTH_URL=http://localhost:1` to confirm port-refused path.

## 4. Integration doc

- [ ] 4.1 Author `docs/integrations/openai-proxy.md` with sections:
  - **What this integrates** — one-paragraph summary of the proxy + supported model aliases
  - **Prerequisites** — `cargo`, `codex` CLI (ChatGPT subscription path) or `OPENAI_API_KEY` (API path)
  - **Minimum boot sequence** — `codex login` → `cargo build --release` in the proxy repo → `./target/release/openai-proxy serve`
  - **Verifying** — `bash scripts/check-openai-proxy-health.sh` should print `READY: …`
  - **Disabling routing** — set `default_endpoint: host_harness` in `project.json → model_policy` or remove `prefer_endpoint` lines
  - **Fallback behavior** — what happens when proxy is down (host_harness fallback, log warning, no hard fail)
  - **Pointer to upstream** — link to `references/baseline/openai-proxy/README.md` and the official repo
- [ ] 4.2 Validate Markdown — basic parse via `python3 -c "import markdown; markdown.markdown(open('docs/integrations/openai-proxy.md').read())"` or skip if `markdown` not present (linting is nice-to-have, not required).

## 5. README "External prerequisites" subsection

- [ ] 5.1 Read current README "Installation" tree.
- [ ] 5.2 Add a new subsection (after the existing Submodules section) titled "External prerequisites (optional)":
  - One row table: `openai-proxy` | optional | see `docs/integrations/openai-proxy.md`
  - One-sentence paragraph noting cost-routing is enabled when the proxy is reachable.

## 6. Acceptance gates

- [ ] 6.1 `python3 -c "import json,jsonschema; jsonschema.validate(json.load(open('.kbd-orchestrator/project.json'))['model_policy'], json.load(open('references/schemas/model-policy.schema.json')))"` exits 0.
- [ ] 6.2 `references/model-routing.md` contains both "Endpoints" and "Endpoint Preference" section headers.
- [ ] 6.3 `bash scripts/check-openai-proxy-health.sh` runs cleanly — exit 0 or 1, output line matches `^(READY|NOT_READY):`.
- [ ] 6.4 `docs/integrations/openai-proxy.md` exists and contains "Minimum boot sequence" and "Fallback behavior" headings.
- [ ] 6.5 README contains "External prerequisites" subsection mentioning `openai-proxy`.

## Out of scope

- Threading `prefer_endpoint` through the PMPO loop at runtime.
- Vendoring `openai-proxy`.
- AG-UI / A2A surface wiring.
- Cost telemetry.

## Recommended agents

| Tasks | Agent |
|---|---|
| 1.*, 2.* | direct authoring + verify-app for schema validation |
| 3.* | direct authoring (small shell) |
| 4.*, 5.* | direct authoring |
| 6.* | `verify-app` |
