# Assessment — phase-8-scaffold-a2ui-host

- **Phase:** `phase-8-scaffold-a2ui-host`
- **Stage:** assess
- **Date:** 2026-08-28
- **Origin:** Deferred since the ideation-to-app pipeline; recommended by phase-7 reflection
- **Model preflight:** `ok` — judge `k3`, critic `MiniMax-M3`, generator
  `kbd-frontier`, no config defects

---

## Phase Goal

The definition of record is one line
(`.kbd-orchestrator/phases/phase-ideation-to-app-pipeline/assessment.md:292`):

> **phase-8-scaffold-a2ui-host** — A2UI rendering host.

That is thinner than phase-7's three-part definition ("React scaffold + AG-UI
client + openai-proxy AG-UI surface wiring"), and the ambiguity is load-bearing:
"rendering host" could mean a scaffolder that emits an app rendering A2UI specs,
or the existing preview pipeline finished. Resolving it is an open question for
plan (Q1 below), not something assess should decide by assertion.

---

## Method

Phase-7's reflection recommended this phase on the premise that it "exercises the
substrate a second time." That premise was **tested, not assumed** — and it turns
out to hold much less than expected (F-1). Every claim below is grounded in a
file, a schema, or a command that was run.

---

## Findings

### F-1 — BLOCKING to the phase's rationale: A2UI is not AG-UI-shaped

The phase-7 reflection recommended phase-8 as the cheapest reuse of the AG-UI
host substrate. **The two are structurally different, and most of that substrate
does not transfer.**

| | AG-UI (phase-7) | A2UI (phase-8) |
|---|---|---|
| Artifact | event **stream** over SSE | declarative component **tree** |
| Shape | `RUN_STARTED → TEXT_MESSAGE_CONTENT × N → RUN_FINISHED` | `{ version, metadata, bindings, root }` |
| Client need | accumulate deltas into state over time | walk a tree and produce DOM once |
| Transport | POST + `Accept: text/event-stream` | none — the spec is a static document |
| Store role | owns a live subscription | arguably no store at all |

What **does** transfer: the thin-wrapper scaffolder pattern
(`scaffold-react-vite-tauri.sh` → `scaffold-react-vite-agui.sh`), the fixed
architectural ESLint enforcement, and the smoke-gate discipline.

What **does not**: the SSE server surface, the streaming client, the store
reduction semantics, and `@ag-ui/*` — the four pieces that were most of phase-7's
20+20+19 tasks. A2UI has no stream to consume.

Consequence: the "second exercise of the substrate" argument justifies this phase
much less than the reflection claimed. It is not a *bad* next phase, but the
stated reason for picking it is weaker than written, and plan should not inherit
the estimate that reasoning implies.

### F-2 — BLOCKING: the A2UI renderer cannot render any conformant spec

**Evidence — every claim below is one command.** The file is
`assets/templates/a2ui-preview-template.html` (4621 bytes, tracked in-repo):

```
$ grep -n 'renderNode(node)' assets/templates/a2ui-preview-template.html
118:      renderNode(node) {

$ grep -n "case '" assets/templates/a2ui-preview-template.html
122:          case 'text':
125:          case 'button':
135:          case 'container':
```

(An earlier draft cited line 130 for `renderNode`; the correct line is 118.)

Three cases, then `default: html\`<pre>${JSON.stringify(node, null, 2)}</pre>\``.

The schema mandates the opposite casing
(`references/schemas/a2ui-component.schema.json`, `definitions.componentType`):

```json
{"type": "string", "pattern": "^[A-Z][A-Za-z0-9]*$",
 "description": "PascalCase component type name (e.g. 'Container', 'Button', 'TextField')."}
```

The shipped examples, walked programmatically for every `type` field:

```
examples/a2ui-component-refinement/source.a2ui.json:
  ['Button', 'Container', 'Heading', 'TextField', 'password']
examples/a2ui-component-refinement/broken-circular.a2ui.json:
  ['Container']
```

(`'password'` is an input-kind value on a `TextField`, not a component type — it
is listed because the walk collects every `type` key, and excluding it silently
would overstate the precision of the extraction.)

The normalizer's own output agrees: `/tmp/p8-probe/normalized.a2ui.json` has
`root.type == 'Container'`.

**Overlap between what the renderer handles and what the schema permits is zero.**
`^[A-Z]` cannot match `'text'`, `'button'`, or `'container'`. Every node of every
conformant spec falls through to the `<pre>` JSON dump — the renderer displays
source, not UI.

This is the same defect class as phase-7's `TOOL_CALL_ARGS_DELTA`: a contract
mismatch that survives because nothing exercises the path end to end.

### F-3 — BLOCKING: no HTML is produced at all

Verified by running the pipeline rather than reading it:

```
node scripts/normalize-a2ui.mjs --input examples/a2ui-component-refinement/source.a2ui.json \
  --artifact-id p8-probe --out-dir /tmp/p8-probe
→ OK
```

Output: `normalized.a2ui.json`, `normalize-report.json`. **No `.html`.**

`normalize-a2ui.mjs:8-11` says so explicitly: "HTML preview generation is owned
by the existing render pipeline (`a2ui-preview-template.html` + Template
Injection)". The template carries `{{A2UI_JSON}}`, `{{MANIFEST_JSON}}`,
`{{GENERATED_AT}}`, and five colour placeholders.

**The obvious candidate owner was checked and does not do it.** The repo ships
`scripts/render-preview.mjs` and a `preview:render` package script, so an earlier
draft's flat claim that "nothing substitutes them" was asserted rather than
verified. Verified now:

```
$ grep -n 'a2ui\|A2UI_JSON\|MANIFEST_JSON\|a2ui-preview-template' scripts/render-preview.mjs
(no matches)

$ grep -rln 'a2ui-preview-template' scripts/ prompts/ references/
scripts/normalize-a2ui.mjs      ← only names it in a comment disclaiming ownership
prompts/meta-controller.md
prompts/plan.md
prompts/execute.md
```

`render-preview.mjs` contains no A2UI reference at all. The only non-prose
mention of the template is the normalizer comment that explicitly disclaims
responsibility for it. The three `prompts/` hits are instructions, not code.

So the two halves were built to meet and never were joined — but that is now a
checked conclusion rather than an inference from one command.

So "A2UI rendering host" is not a finishing task on a working renderer. Nothing
renders today.

### F-4 — Bindings are declared but never resolved

The spec's `bindings` block supports three kinds — `literal`, `ref`, and
`expression` (schema `definitions.binding.kind`) — and the example exercises all
three, including `"expression": "config.api.url + '/login'"`.

`grep -c bindings a2ui-preview-template.html` returns **0**. The renderer never
reads them. A node's `bindings` field is ignored, so even a correctly-cased
component would render unbound placeholder values.

`expression` bindings additionally raise a question assess cannot settle: they
are arbitrary strings requiring an evaluator. That is a security-relevant design
decision (Q3).

### F-6 — The preview pins nothing: five unversioned CDN loads

Grounding G-7, which an earlier draft listed with no finding behind it:

```
$ grep -o 'unpkg\.com/[^"'"'"']*' assets/templates/a2ui-preview-template.html
unpkg.com/lit@latest/index.js?module
unpkg.com/htmx.org@latest
unpkg.com/htmx.org@latest/dist/ext/json-enc.js
unpkg.com/htmx.org@latest/dist/ext/client-side-templates.js
unpkg.com/alpinejs@latest/dist/cdn.min.js
```

Five loads, every one `@latest`. Rendered output is therefore not reproducible
across time and not renderable offline — an upstream release can change what a
preview shows without any change here. Relevant to the verification criteria
below: a browser-DOM test against `@latest` dependencies is a flaky test.

### F-5 — The scaffolder pattern is genuinely reusable (the one strong carry-over)

`scaffold-react-vite-agui.sh` (221 lines) demonstrates the wrapper shape end to
end, and phase-7 left it healthier than it found it:

- the architectural ESLint config **now actually runs** (it never had before)
- `pnpm build` works under TypeScript 6
- the smoke-gate sequence (scaffold → build → lint → dev → exercise) is proven

If phase-8 produces a scaffolder, this is a real head start — just a much smaller
fraction of the work than F-1's rebuttal implies.

---

## Gap Report

| ID | Gap | Severity | Evidence |
|---|---|---|---|
| G-1 | Renderer component types cannot match any conformant spec | BLOCKING | F-2 — `^[A-Z]` vs `'text'`/`'button'`/`'container'` |
| G-2 | No template injector; no HTML ever produced | BLOCKING | F-3 — probe run emitted JSON only |
| G-3 | Bindings (`literal`/`ref`/`expression`) never resolved | BLOCKING | F-4 — 0 occurrences in renderer |
| G-4 | Only 3 component types implemented; example needs 4+ | HIGH | F-2 — `Heading`, `TextField` unhandled |
| G-5 | Phase scope undefined: finish preview vs. emit a scaffolder | HIGH | one-line definition of record |
| G-6 | `expression` binding evaluation strategy undecided | HIGH | F-4 — security-relevant |
| G-7 | Preview loads Lit/HTMX/Alpine from `unpkg.com@latest` | MEDIUM | F-6 |

---

## Scope Recommendation

**Settle G-5 before anything else.** The two readings differ by roughly an order
of magnitude in effort, and every other gap's framing depends on the answer.

**In scope under either reading** — a renderer that walks a spec into DOM,
resolves `literal`/`ref` bindings, and covers the shipped example's component
types. The *artifact contract* is shared; only its delivery differs.

| Gap | Reading (a) finish preview | Reading (b) scaffolder |
|---|---|---|
| G-1 types match schema | in scope | in scope |
| G-3 binding resolution | in scope | in scope |
| G-4 component coverage | in scope | in scope |
| **G-2 template injector** | **in scope** — it is the deliverable | **not required** — a React host renders from the spec at runtime; there is no HTML template to inject |

An earlier draft listed G-2 as mandatory under both readings, which contradicted
Q1: reading (b) renders at runtime and never substitutes `{{A2UI_JSON}}` into a
static template. G-2 is reading-(a)-specific.

**Recommend deferring:**

- G-6 (`expression` evaluation) — restrict v1 to `literal` and `ref`, and reject
  `expression` with a clear error rather than shipping an evaluator nobody has
  threat-modelled. The example uses one, so this is a real scope cut, not a
  free pass.
- G-7 (CDN pinning) — worth doing, but it is preview-infrastructure hygiene
  rather than rendering-host work.

---

## Open Questions for analyze/plan

1. **What is a "rendering host"?** (a) finish the existing preview pipeline so
   `normalize-a2ui.mjs` emits working HTML, or (b) a
   `scaffold-react-vite-a2ui.sh` emitting an app that renders A2UI specs at
   runtime? Reading (a) is roughly a session; (b) is phase-7-sized. The
   definition of record does not say, and picking silently would repeat the
   phase-7 estimate error in reverse.
2. **Lit + HTMX, or React?** The existing preview is Lit-based; the scaffolder
   substrate is React. Reading (b) forces this choice; reading (a) keeps Lit.
   This is analyze's build-vs-adopt question.
3. **`expression` bindings — evaluate, sandbox, or reject?** `config.api.url +
   '/login'` is arbitrary JavaScript. Options: a restricted expression grammar,
   a sandboxed evaluator, or v1 rejection. Security-relevant; needs a recorded
   decision rather than a default.

---

## Verification Criteria (for the plan stage)

- [ ] `normalize-a2ui.mjs` (or its successor) emits an `.html` file for the
      shipped example
- [ ] That HTML renders `Container`, `Heading`, `TextField`, `Button` as real
      DOM elements — **not** as `<pre>` JSON
- [ ] `literal` and `ref` bindings resolve to their values in rendered output
- [ ] A spec using an unimplemented component type fails loudly, rather than
      silently degrading to a JSON dump
- [ ] The negative-path example (`broken-circular.a2ui.json`) is still rejected
- [ ] Rendering is verified **in a browser DOM**, not by string-matching HTML

The last criterion is deliberate. Phase-7 closed with exactly one PARTIAL because
"renders incrementally in the browser" was verified at the state level and never
in a DOM. Playwright is already available — `package.json` `devDependencies` lists
`"playwright": "^1.51.0"` — so a rendering phase that repeats that gap would be
verifying the wrong thing twice with the tool to avoid it already installed.

---

## Adversarial Review

Two rounds, true cross-model isolation both times (`rest-gateway`,
`cross_model_check: verified-distinct`, producer `claude-opus-5` ≠ judge
`kbd-judge`). Both returned BLOCK; the revision cap is reached.

**Round 1 — 3 CRITICAL, 1 WARNING.** All four were correct and all were applied:

| Finding | Disposition |
|---|---|
| Renderer findings rested on an uncited file | **Fixed** — F-2 now shows the exact `grep` commands and line numbers. Found a real error while doing so: `renderNode` is at line **118**, not the 130 I first cited. |
| Component coverage rested on an unverified example | **Fixed** — types now extracted programmatically, with `'password'` disclosed as an input-kind value rather than quietly dropped |
| "Nothing substitutes the placeholders" was asserted, not checked | **Fixed, and it mattered** — the judge named `scripts/render-preview.mjs` as an unchecked candidate owner. I checked: zero A2UI references. F-3 is now a verified conclusion instead of an inference from one command. |
| G-7 had no finding behind it | **Fixed** — F-6 added, showing all five `@latest` CDN loads |

**Round 2 — 1 CRITICAL, 3 WARNING.** Two applied, two recorded as packet
artifacts:

| Finding | Disposition |
|---|---|
| Scope table contradicted Q1 | **Fixed** — G-2 is reading-(a)-specific; a runtime React host has no template to inject. This was a real self-contradiction. |
| Playwright claim unsupported | **Fixed** — `package.json` lists `"playwright": "^1.51.0"`, now quoted |
| Template existence "not supported by the packet" (CRITICAL, repeated) | **Not a defect in the evidence.** The packet's `file_tree` lists **directories only** — it contains zero `.html` paths anywhere, so no file inside `assets/templates/` can ever satisfy this rule. Ground truth: `git ls-files assets/templates/a2ui-preview-template.html` returns the path; the file is tracked, 4621 bytes. |
| Prior-phase conclusions absent from packet | **Correct and unfixable here.** `prior_handoffs` is null because phase-8 has no handoffs yet — this is its first stage. The phase-7 reflection is cited by path for a reader; the judge simply cannot see it. |

The repeated CRITICAL is worth naming as a **tooling gap, not an artifact
defect**: `build-review-packet.sh` emits a directory-level `file_tree`, so any
finding grounded in a specific file will be flagged as uncited no matter how it
is written. Third packaging gap this project after the missing
`research-pipeline.md`/`library-candidates.schema.json` and the openspec-blind
spec-stage collector.

## Estimate

Depends entirely on Q1.

| Reading | Shape | Estimate |
|---|---|---|
| (a) finish the preview pipeline | injector + renderer fix + bindings + types | **1 session, 4–6 changes** |
| (b) emit a scaffolder | (a) plus wrapper, skill, smoke gates | **2–3 sessions, 8–12 changes** |

Phase-7 came in at one session against a 2–3 estimate, but that was a phase whose
risk (the SSE surface) turned out to be well-bounded. The risk here is different:
three separate contracts (schema, renderer, template) currently disagree, and
reconciling contracts tends to surface more mismatches once the first is fixed.
I would not carry phase-7's under-run forward as a reason to estimate low.
