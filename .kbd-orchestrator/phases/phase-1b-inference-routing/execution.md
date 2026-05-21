# Execution: phase-1b-inference-routing

**Status:** COMPLETE
**Backend:** OpenSpec
**Executed:** 2026-05-20

## Acceptance gates — all PASS (verified against live proxy)

| # | Gate | Result |
|---|---|---|
| 6.1 | Schema validates `project.json → model_policy` | PASS |
| 6.2 | `model-routing.md` has Endpoints + Endpoint Preference + Model ID Aliases | PASS (3/3) |
| 6.3 | Health-probe exits 0/1 with `READY:`/`NOT_READY:` line | PASS — **live `READY: {"status":"ok"}` against real proxy at port 8181** |
| 6.4 | Integration doc has Minimum boot sequence + Fallback behavior | PASS |
| 6.5 | README has External prerequisites subsection | PASS |

## Deliverables

| Path | Status |
|---|---|
| `references/schemas/model-policy.schema.json` | created |
| `references/model-routing.md` | modified — added Endpoints + Endpoint Preference + Model ID Aliases sections; extended Fallback Rule |
| `scripts/check-openai-proxy-health.sh` | created, executable, fingerprint-checking |
| `docs/integrations/openai-proxy.md` | created |
| `README.md` | modified — added External prerequisites (optional) subsection |
| `.kbd-orchestrator/project.json` | port updated 8080 → 8181 (project standard) |

## Decisions during execute

1. **Python `jsonschema` package installed via pip3.** Already universally useful; not introducing a new project-level dependency.
2. **Fingerprint check added to health-probe.** Initial test discovered port 8080 had a different HTML-serving service answering 200, which would have produced a false `READY`. Added a regex check on the response body matching openai-proxy's JSON keys (`status`, `version`, `ok`, `healthy`, `service`). This caught the imposter and produced `NOT_READY: HTTP 200 but body did not match openai-proxy fingerprint`.
3. **Default port changed 8080 → 8181 at user direction.** Live verification against the actual deployed proxy at 8181 produced `READY: {"status":"ok"}` confirming the project-standard port and the proxy's actual response shape.
4. **Historical KBD artifacts (assessment, plan, proposal, tasks) left at port 8080.** Those are records of decisions at the time. The live config and the script use 8181.

## Live verification

```bash
$ curl -sS http://localhost:8181/health
{"status":"ok"}

$ bash scripts/check-openai-proxy-health.sh
READY: {"status":"ok"}
$ echo $?
0
```

## Out of scope (deferred to follow-on phase)

- `phase-prefer-endpoint-consumption` — actually threading `prefer_endpoint` selection through the PMPO loop at every model-call site.
- AG-UI / A2A surface integration with openai-proxy.
- Cost telemetry / per-phase accounting.

## Next phase

`/kbd-reflect phase-1b-inference-routing`.
