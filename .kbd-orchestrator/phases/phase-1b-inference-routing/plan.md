# Plan: phase-1b-inference-routing

**Backend:** OpenSpec (`openspec/changes/phase-1b-inference-routing/`)
**Tasks:** `openspec/changes/phase-1b-inference-routing/tasks.md`
**Proposal:** `openspec/changes/phase-1b-inference-routing/proposal.md`
**Scope:** Configuration / discovery layer only. No PMPO loop refactor.

## Decisions baked in

- **Q-003 = B:** `openai-proxy` consumed as **external prerequisite**, not submodule. No `tools/openai-proxy/` directory created.
- **Schema validator:** Python's `jsonschema` (universally available); Node `ajv` is the documented fallback.
- **Health probe:** `curl`-based shell script with env-configurable URL (`OPENAI_PROXY_HEALTH_URL`).
- **Integration doc location:** `docs/integrations/openai-proxy.md` (consistent namespace for future external integrations).
- **No runtime consumption** — the PMPO loop still routes via host harness today. Honoring `prefer_endpoint` at runtime is a separate `phase-prefer-endpoint-consumption`.

## Ordered change list

| # | Change | Section | Gate |
|---|---|---|---|
| 1 | Author `model-policy.schema.json` + validate current `project.json` block | 1.* | jsonschema validation passes |
| 2 | Sync `references/model-routing.md` with endpoints + preference sections | 2.* | required headings present |
| 3 | Author `scripts/check-openai-proxy-health.sh` | 3.* | exits 0/1 with `READY:`/`NOT_READY:` line |
| 4 | Author `docs/integrations/openai-proxy.md` | 4.* | required headings present |
| 5 | Add "External prerequisites" subsection to README | 5.* | section present |
| 6 | Acceptance gate sweep | 6.* | verify-app |

## Sequencing

Strictly sequential. Schema (1) must land before doc (2) can reference it accurately. Doc (2) before health-probe (3) so the script's exit semantics match what the doc says. Integration doc (4) and README (5) parallel-safe once 1-3 land.

## Risk register

| Risk | Mitigation in plan |
|---|---|
| Python `jsonschema` not installed | Plan task 1.2 detects and falls back to `node + ajv` (already in repo via `node_modules`) |
| Health-probe `curl` not installed | Modern macOS/Linux ship with it; document as a prereq in the integration doc |
| Doc duplicates upstream README | Plan task 4.1 references the upstream README; doesn't restate |
| Future consumers misread "external prerequisite" as "we'll auto-install it" | Plan task 4.1 explicitly lists the boot sequence the user runs themselves |

## Estimated effort

One focused session. All small files, no compile-loop.
