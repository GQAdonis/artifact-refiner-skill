# Reflection: phase-1b-inference-routing

**Date:** 2026-05-20
**Scope outcome:** Configuration / discovery layer wired; runtime consumption deferred to follow-on phase.

## Goal Achievement

| Goal | Status |
|---|---|
| `references/model-routing.md` documents endpoints + preference + aliases | MET |
| `model-policy.schema.json` validates `project.json → model_policy` | MET |
| Health-probe utility detects readiness, falls back cleanly | MET (live-verified) |
| Integration doc tells users how to install/run/disable proxy | MET |
| README "External prerequisites" subsection added | MET |
| **No** PMPO loop runtime refactor in this phase | MET (held the line) |

**Achievement: 6/6 MET (100%).**

## Delivered Changes

| Path | Status |
|---|---|
| `references/schemas/model-policy.schema.json` | created |
| `references/model-routing.md` | extended with 3 new sections + fallback rule |
| `scripts/check-openai-proxy-health.sh` | created, executable, fingerprint-checking |
| `docs/integrations/openai-proxy.md` | created |
| `README.md` | added External prerequisites subsection |
| `.kbd-orchestrator/project.json` | port corrected 8080 → 8181 (project standard) |

## Artifact Quality Summary

| Metric | Value |
|---|---|
| Changes with QA | 6/6 |
| First-pass pass rate | 5/6 (83%) |
| Changes requiring refinement | 1 (health-probe — fingerprint check added after false-positive discovery) |
| Total refinement iterations | 1 |
| Acceptance gates | 5/5 PASS — with live verification |
| Constraint violations | 0 |

### Recurring Constraint Violations

None.

### Live-verification result

```
$ curl -sS http://localhost:8181/health
{"status":"ok"}

$ bash scripts/check-openai-proxy-health.sh
READY: {"status":"ok"}
```

## Technical Debt Introduced

| Debt | Severity | Notes |
|---|---|---|
| PMPO loop does not actually consume `prefer_endpoint` yet | Medium | By design — separate phase `phase-prefer-endpoint-consumption` |
| Historical phase artifacts (assessment, plan, proposal, tasks) reference port 8080 | Low | Records of decisions at the time; live config is correct |
| Fingerprint regex matches any JSON containing one of `status`/`version`/`ok`/`healthy`/`service` — could match unrelated services that happen to return such JSON | Low | Acceptable: any JSON shape containing these keys on the configured port is almost certainly the openai-proxy; a generic web app on port 8181 returning that exact shape would be a coincidence |
| Health-probe runs sync; no caching | Low | At call-site cadence (per-phase) this is fine; revisit if proxy probe gets called in tight loops |

None blocking the next phase.

## Lessons Captured

### Lesson 1 — Test against the real service, not assumptions

The first health-probe pass returned `READY: <!doctype html>...` because port 8080 had a different web service answering 200. That would have been a silent disaster in production: the refiner would have routed inference requests to a wrong target. The fix (response-body fingerprint regex) was small, but the discovery only happened because the script was executed against the actual environment, not just unit-tested. **Live verification beats unit tests for endpoint integrations.**

### Lesson 2 — Default ports are upstream conventions, not project standards

The upstream openai-proxy README documents port 8080 as default. The user runs it on 8181. The proposal/plan/tasks all encoded 8080 as if it were authoritative. The lesson: **when a project standard exists and diverges from upstream defaults, surface it during assessment**. Asking "is the port 8080 or something else?" during the assessment phase would have caught this earlier.

### Lesson 3 — Doc/schema/data triplet alignment is a cheap recurring chore

`project.json → model_policy` was added during phase-0 with endpoint awareness. `references/model-routing.md` lagged for two whole phases until phase-1b synced it. The cost of syncing was small (one edit); the cost of leaving them out of sync would have grown — every future consumer would have to guess which is authoritative. **Treat doc/schema/data sync as a recurring chore that lands as part of the phase that touches any of the three.**

### Lesson 4 — Fingerprint checks are a 2-line investment with disproportionate payoff

`grep -qE '"(status|version|ok|healthy|service)"[[:space:]]*:'` is one line of regex and one `if` statement. It turned a false-positive (`READY: <html>...`) into a correct `NOT_READY`. For any health probe, **the difference between "URL returned 200" and "the right service returned 200" is a fingerprint regex away.**

### Lesson 5 — Sycophancy correction holds even when the user is the source

User said "port 8181 is the standard". The instinct is to update and move on. The actual disciplined action: update, then **re-test against the real service** at 8181 to confirm the proxy is in fact there and responding as expected. The probe returning `READY: {"status":"ok"}` validated both the port correction and the fingerprint check simultaneously.

## Recommended Focus for Next Phase

Two options of comparable value, your call:

### Option A — `phase-prefer-endpoint-consumption`

Wire the PMPO loop to actually honor `prefer_endpoint` and `prefer_model` at runtime. This is the consumption-layer work that turns this phase's config/discovery from documentation-in-the-air into real cost savings. Estimated 1-2 sessions because it touches the model-call sites in the refiner.

### Option B — `phase-2-scaffold-react-vite`

The headline goal from the original ideation-to-app-pipeline assessment. Refined TSX artifact → running Vite project on disk with brand tokens applied. Doesn't require option A (the loop still routes via host harness during scaffold generation). Estimated 2-3 sessions.

**Recommendation: B.** Option A is internally valuable (cost savings, cleaner abstraction); Option B is externally valuable (the first scaffolder the user actually demoes). The phase-1b acceptance was specifically scoped so that B doesn't depend on A — proceed to B without guilt about deferred consumption work.

## Knowledge Base Hooks

- "Live verification beats unit tests for endpoint integrations"
- "Default ports are upstream conventions, not project standards — ask during assessment"
- "Doc/schema/data triplet alignment is a cheap recurring chore"
- "Fingerprint checks turn false-positive 200s into correct NOT_READYs for ~2 lines of code"
- "Sycophancy discipline holds even when the user is the source — re-test after corrections"

Completed kbd-reflect — phase-1b-inference-routing
