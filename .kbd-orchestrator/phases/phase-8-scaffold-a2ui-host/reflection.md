# Reflection — phase-8-scaffold-a2ui-host

- **Status:** COMPLETE (5/5 changes, 106/106 tasks, 0 open)
- **Date:** 2026-08-29
- **Backend:** OpenSpec — all five changes verified and archived
- **Sessions:** 2 (assess/analyze/spec/plan + execute) against a 2–3 estimate

---

## 1. Goal Achievement

**Phase goal (definition of record):** "A2UI rendering host."

One line. The ambiguity was load-bearing and assess said so rather than guessing;
G-8 resolved it — align to the real protocol and build a runtime host.

### The acceptance criteria were written pre-alignment

Assess wrote six criteria **before** the G-8 decision. Four assumed the local
dialect that alignment superseded. Scoring them as written would be scoring
against a contract we deliberately replaced, so each is judged on what it was
actually testing:

| # | Criterion (as written) | Verdict | Basis |
|---|---|---|---|
| 1 | `normalize-a2ui.mjs` emits an `.html` file | **SUPERSEDED** | Under alignment the renderer is `@a2ui/react` at runtime. No template injection exists, and p8-03 corrected two `prompts/` instructions that wrongly claimed otherwise. |
| 2 | HTML renders `Container`, `Heading`, `TextField`, `Button` | **SUPERSEDED → MET in substance** | Those were dialect names. The real catalog has 18 components and contains **no `Heading`**. The surface renders `Card`/`Column`/`Text`/`Button` as real DOM. |
| 3 | `literal` and `ref` bindings resolve | **MET in substance** | The protocol has no `literal`/`ref` kinds; it uses `dataModel` + `{"path": …}`. Three pointers resolve in the shipped example. |
| 4 | Unimplemented component fails loudly | **MET** | Observed live: the renderer emitted `Unknown component: Heading` rather than degrading. p8-02 also rejects unknown names at normalize time. |
| 5 | `broken-circular` still rejected | **MET** | exit 1, `reference_cycle` naming the ids. |
| 6 | **Verified in a browser DOM**, not string-matching | **MET** | Playwright: 2 distinct DOM states, `role=button` present, 0 page errors. |

**Substantively 5/6 achieved; 1 superseded by the operator's own decision.**

Criterion 6 is the one that mattered. Phase-7 closed with exactly one PARTIAL
because "renders in the browser" was verified at store level. This phase set out
not to repeat that, and did not.

---

## 2. Delivered Changes

| Change | Tasks | What shipped |
|---|---|---|
| `p8-01-align-a2ui-schema` | 21 | Schema replaced with the real envelope model |
| `p8-02-rewrite-a2ui-normalizer` | 22 | 350-line validator reworked; 8 violation paths |
| `p8-03-rewrite-a2ui-examples` | 19 | Corpus rewritten; 6 referencing files corrected |
| `p8-04-a2ui-render-host` | 24 | `@a2ui/react` adopted; streaming store |
| `p8-05-scaffold-a2ui-host` | 20 | Scaffolder + skill; browser-DOM gate |

Three new spec capabilities: `a2ui-protocol-conformance`, `a2ui-render-host`,
`a2ui-host-scaffolder`. `openspec/specs/` now holds seven.

---

## 3. The Finding That Reframed the Phase

**A2UI is a real external protocol, and ours was not it.**

`a2ui-project/a2ui` — 16,230 stars, Apache-2.0, pushed the same day as the
analysis, with an official React renderer and ports to .NET, Swift, Android, and
React Native. Our schema was `artifact-refiner.dev`-namespaced and cited no
upstream.

The divergence was structural at every level: `type` vs `component`
discriminator, single tree vs envelope stream, bindings map vs `dataModel` +
pointers, open pattern vs catalog. **Specs our refiner validated were not A2UI
documents.** Real agent output failed our validator; ours could not drive any
real renderer.

This is phase-7's `TOOL_CALL_ARGS_DELTA` one level up — not a wrong enum value
inside a correct model, but a wrong document model — and larger, because
`direct:a2ui` had shipped in PR #1 with published examples.

The G-8 decision was escalated rather than made in analyze: it invalidates
published examples and changes what a shipped content type *means*. That is an
owner's call.

---

## 4. Assessment Errors I Made, and How They Surfaced

Two of my own findings were wrong, in consecutive stages, from the same root
cause: **reading our artifacts as though they described the world.**

**Assess F-1 — "A2UI is a static document with no transport."** Upstream says
the opposite: "streaming JSON objects from an agent to a renderer… progressive
rendering." I inferred the protocol's shape from our schema's single-tree shape.
This inverted F-1's conclusion — the phase-7 store/subscription substrate
transfers *more* than assess claimed, not less.

**Assess F-2 cited `renderNode` at line 130.** It is line 118. Caught by
adversarial review demanding reproducible evidence.

Both were corrected in-stage with the correction recorded rather than quietly
edited.

---

## 5. Defects Found in Pre-Existing Code

Six, none previously known, every one found by **running** something:

| Defect | Where | How found |
|---|---|---|
| Renderer could not render any conformant spec | `a2ui-preview-template.html:118` — 3 lowercase cases vs a `^[A-Z]` schema; **zero overlap** | grep + schema diff |
| No HTML ever produced | `normalize-a2ui.mjs` emits JSON only; nothing substitutes `{{A2UI_JSON}}` | ran the pipeline |
| Bindings never resolved | `grep -c bindings` on the renderer → **0** | grep |
| **`oneOf` was implemented as `anyOf`** | built-in validator stopped at first match, so two-operation messages validated | wrote a two-op fixture |
| `not` and `anyOf` unimplemented | every dialect guard and the expression guard were silently inert | same |
| Two `prompts/` instructions unexecutable | `execute.md` told executors to run an HTML injection step that does not exist | traced the cited script |

The `oneOf` one is the most consequential: p8-01's envelope exclusivity depended
on an operator the validator did not implement, so the guarantee existed on paper
only until p8-02 fixed it.

---

## 6. Defects I Introduced, Caught by Gates

Five, all caught by running rather than reviewing:

| Defect | Caught by |
|---|---|
| `dynamicString` defined but never applied — an expression leaf validated | my own schema-gate fixture |
| `oneOf` where `{path}` matched two branches, so **valid** input failed | same |
| Orphan detection could not detect orphans (every unreferenced node treated as a root) | task 2.4's fixture |
| Wrong feature directory — used raw basename, not `to_kebab`; created a **second** slice | smoke test |
| Component imported a type from `stores/` — architectural layering violation | `pnpm lint` |

The layering violation is notable: the ESLint config I repaired in p7-05 caught
me. It was inert for the whole life of the scaffolder before that fix.

---

## 7. Artifact Quality Summary

No `artifact-refiner` logs: that gate applies to refined artifacts, and every p8
change is code, schema, or data. **Adversarial review was the QA gate.**

| Metric | Value |
|---|---|
| Stages vetted | 4/4 |
| Rounds | 8 (2 per stage — every stage hit the revision cap) |
| Findings | 33 |
| CRITICAL | 13 |
| WARNING | 20 |
| Verified correct | **33/33** |
| Declined with reasoning | 1 |

Isolation: analyze and plan ran true cross-model (`verified-distinct`); assess
and spec ran degraded — spec because the packet builder supports only the
native-kbd layout, so the packet was assembled by hand.

### Recurring pattern — dropped carry-forward items

**Third phase running.** Findings across analyze and spec repeatedly caught me
omitting gaps that had no interesting research attached:

- analyze R2: three of seven assessment gaps dropped (G-5, G-6, G-7)
- spec R1: p8-04's test depended on a p8-03 fixture while declared siblings
- spec R2: p8-05 declared only p8-04, so the graph was satisfiable **without
  p8-03 ever running** — its smoke gate would have used old-dialect fixtures

Same shape each time: my prose asserted an ordering or coverage the declared
structure did not enforce.

### Second pattern — coverage claimed over the wrong path

Both plan CRITICALs were one error: `no-hardcoded-secrets` scans
`scripts/ prompts/ references/`; p8-04's gate grepped `assets/scaffold/a2ui/`;
p8-05 creates a script. **Gating a constraint over a path it does not cover is
not gating it.** Round 2 repeated because round 1 fixed the task file but left
the plan's compliance table crediting the wrong change — fixing an artifact
without fixing its index.

---

## 8. Technical Debt

| Item | Severity | Note |
|---|---|---|
| **`scaffold-react-vite-agui.sh` has the feature-name bug** | HIGH | Same defect p8-05 fixed here: derives the feature name from the raw basename instead of `to_kebab`, so phase-7's scaffolder also creates a second feature directory. Found while fixing mine; out of phase-8 scope. |
| G-7 — runtime silently drops writes | HIGH | Reproduced across every phase-8 stage; `kbd audit` shows zero phase-8 events. Filesystem remains authoritative. |
| No `progress.json` for phase-8 | MEDIUM | Driver disabled under the G-7 rule. Archived changes are the record. |
| Protocol version skew | MEDIUM | Schema validates **v1.0**; `@a2ui/react@0.10.2` implements **v0.9**. Translated at one boundary; `deleteSurface`/`callFunction`/`actionResponse` are reduced but reported as unrendered. |
| `@a2ui/*` pre-1.0 | MEDIUM | Pinned exact. npm publish lags the repo ~6 weeks; `@a2ui/markdown-it` declared `*`. |
| G-7 (preview CDN) — 5 unpinned `unpkg@latest` | LOW | Tracked deferral; the preview template may be superseded entirely. |
| `CLAUDE.md:54` contradicts `:31` | LOW | Still unfixed; flagged since phase-7. |

---

## 9. Lessons

- **Check whether the name is taken.** Two phases running, a local artifact
  diverged from an external standard it was named after. Nothing pointed at
  upstream, so nothing contradicted the drift. A citation block is cheap
  insurance.
- **Read the library's types; do not infer them.** Two failed inference attempts
  on `MessageProcessor` cost more than installing the package and reading the
  `.d.ts`, which settled it immediately — both types were exported by name.
- **A guarantee is only as real as the operator implementing it.** `oneOf`
  looked correct in the schema and was implemented as `anyOf` in the validator.
- **Enumerate the catalog; do not trust the type union.** `Heading` appeared in a
  type but not among the 18 shipped components.
- **A gap with no research still needs a recorded verdict.** Third phase for this
  lesson. It has now cost CRITICALs in phase-7 analyze and phase-8 analyze/spec.
- **Read each gate's actual command, not its label.** A constraint gated over the
  wrong directory is ungated.

---

## 10. Advancing the Waypoint

Deferred phases remaining: `phase-6-scaffold-flutter`, `phase-9-scaffold-mcp-ui`.

**Recommended next: fix the `scaffold-react-vite-agui.sh` feature-name bug
first.** It is a known, diagnosed, one-line defect in shipped code that produces
a broken second feature directory in every AG-UI scaffold. The fix is already
written for A2UI; porting it is minutes. Leaving a known defect in place while
starting a new phase is how the AG-UI enum drift survived a whole phase.

**Then `phase-9-scaffold-mcp-ui`**, with one precondition: **verify MCP-UI is not
another A2UI**. Twice now a local artifact has diverged from an external standard
of the same name. Before assessing phase-9, check whether MCP-UI has an upstream
specification and whether anything in this repo already claims to implement it.

`phase-6-scaffold-flutter` remains the larger divergence — Dart, Riverpod, a
different toolchain — and reuses the least substrate.

```yaml
phase: phase-8-scaffold-a2ui-host
changes: 5/5
tasks: 106 done, 0 open
acceptance: 5/6 substantively met, 1 superseded by the G-8 decision
adversarial_review: 8 rounds, 33 findings, 33/33 verified correct, 1 declined
preexisting_defects_found: 6
own_defects_caught_by_gates: 5
technical_debt_blocking: false
sessions_used: 2 (estimated 2-3)
next_recommended: fix scaffold-react-vite-agui.sh feature-name bug, then phase-9-scaffold-mcp-ui
alternates: [phase-6-scaffold-flutter]
```
