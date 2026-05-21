# Integration: openai-proxy

`openai-proxy` is an **optional external prerequisite** that enables subscription-priced inference for the artifact-refiner PMPO loop. When it is reachable, mechanical phases (`refiner-iterate`, `refiner-finalize`) can route to GPT-5.4-mini-class models via a ChatGPT Plus/Pro subscription instead of per-token API billing. When it is **not** reachable, the refiner falls back transparently to host-harness inference (whatever LLM the harness already provides — Claude Code, Codex CLI, Antigravity, etc.).

This document covers integration. The proxy itself has its own documentation; see [Pointer to upstream](#pointer-to-upstream) below.

## What this integrates

`openai-proxy` is a single Rust binary exposing six delivery surfaces from one process:

| Surface       | Route                                       | Used by artifact-refiner v1.2.0          |
|---------------|---------------------------------------------|------------------------------------------|
| HTTP proxy    | `POST /v1/chat/completions`                 | ✓ (this is what `prefer_endpoint: openai_proxy` consumes) |
| opencode      | npm plugin `@prometheus-ags/opencode-codex-proxy` | not yet                              |
| MCP server    | stdio + Streamable HTTP                     | not yet                                  |
| ACP server    | stdio (Agent Client Protocol v0.11)         | not yet                                  |
| AG-UI         | `POST /ag-ui/stream` (SSE)                  | not yet                                  |
| A2A agent     | `GET /.well-known/agent.json`               | not yet                                  |

For the artifact-refiner integration only the HTTP `/v1/chat/completions` surface matters.

The proxy's model catalog at the time of writing exposes eight aliases: `gpt-5.5`, `gpt-5.5-pro`, `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.4-nano`, `gpt-5.3-codex`, `gpt-5.3-chat`, `gpt-5.2-chat`. These are **proxy-mediated aliases**, not canonical API model IDs. See `references/model-routing.md` "Model ID Aliases".

## Prerequisites

- A working `cargo` toolchain (`rustup` → stable)
- One of:
  - **`codex` CLI installed and authenticated** (ChatGPT Plus/Pro subscription path), OR
  - **`OPENAI_API_KEY` exported** (regular OpenAI API path)
- `curl` available on PATH (used by the health-probe script)
- The proxy source checked out somewhere — typically at `references/baseline/openai-proxy/` for this project, or `~/Projects/openai-proxy` if you maintain it elsewhere

## Minimum boot sequence

```bash
# 1. Authenticate (ChatGPT subscription path)
codex login

# 2. Build the proxy (one-time per Rust upgrade)
cd path/to/openai-proxy
cargo build --release

# 3. Run the proxy (foreground; use a process manager for persistent setups)
./target/release/openai-proxy serve
# Listens on http://localhost:8181 by default (project standard; upstream default is 8080)
```

For the API-key path, skip step 1 and ensure `OPENAI_API_KEY` is in the environment before step 3.

The proxy logs each request to stderr. For a persistent setup (launchd, systemd, tmux session), see the upstream README's deployment section.

## Verifying

Once the proxy is running, the health-probe script should report `READY`:

```bash
bash scripts/check-openai-proxy-health.sh
# Expected: READY: {"status":"ok", ... }
```

If you get `NOT_READY`, see [Troubleshooting](#troubleshooting).

The probe URL is configurable:

```bash
OPENAI_PROXY_HEALTH_URL=http://my-host:9090/health bash scripts/check-openai-proxy-health.sh
```

It does a single 2-second `curl` with a fingerprint check on the response body so it correctly rejects unrelated services answering on the same port.

## Fallback behavior

The artifact-refiner PMPO loop does not hard-fail when the proxy is unavailable. The selection algorithm (documented in `references/model-routing.md` "Endpoint Preference") is:

1. If a phase has `prefer_endpoint: openai_proxy` and the health probe passes → use the proxy
2. Else fall back to `default_endpoint` (typically `host_harness`)
3. Log a warning to `.refiner/<artifact_name>/model-routing.log`

Cost-routing is a nice-to-have; functional inference is the requirement.

> **Note (v1.2.0):** The runtime consumption of `prefer_endpoint` lives in a separate forthcoming phase (`phase-prefer-endpoint-consumption`). Today the schema and discovery layer are in place; the PMPO loop still routes through the host harness regardless. Use the health-probe and configuration to validate readiness; the runtime hookup lands in a follow-on phase.

## Disabling routing

To opt out of openai-proxy routing entirely without uninstalling anything, edit `.kbd-orchestrator/project.json`:

- **Option 1 — remove `prefer_endpoint` per phase.** Each phase entry falls back to `default_endpoint`.
- **Option 2 — switch `default_endpoint` to `host_harness`.** Combined with removing `prefer_endpoint` overrides, this routes everything through the host harness.
- **Option 3 — stop the proxy.** The health-probe will report `NOT_READY` and the refiner will fall back automatically. No config change required.

Option 3 is the lowest-effort way to A/B test cost routing.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `NOT_READY: curl: (7) Failed to connect …` | Proxy not running | Start it (`./target/release/openai-proxy serve`) |
| `NOT_READY: HTTP 200 but body did not match openai-proxy fingerprint` | Different service answering on the configured port | Stop the conflicting service or set `OPENAI_PROXY_HEALTH_URL` to the proxy's actual URL |
| `NOT_READY: HTTP 401` | Auth not configured | Run `codex login` or set `OPENAI_API_KEY` |
| `NOT_READY: HTTP 503` | Upstream OpenAI unavailable or rate-limited | Wait; retry; verify subscription is active |
| Probe times out after 2s | Proxy is slow to start | Wait 2-3s after `serve` then probe again |

## Pointer to upstream

- **Local checkout (reference):** `references/baseline/openai-proxy/`
- **Upstream README:** see `references/baseline/openai-proxy/README.md`
- **Upstream SKILL.md:** `references/baseline/openai-proxy/SKILL.md` — contains the canonical opencode plugin setup, MCP server details, ACP wiring
- **Release notes:** upstream Cargo.toml `version` field; check `git log` of the local checkout

## Schema

The endpoint shape in `project.json → model_policy.endpoints.openai_proxy` is formalized in:

- `references/schemas/model-policy.schema.json` — JSON Schema
- `references/model-routing.md` — human-readable spec
