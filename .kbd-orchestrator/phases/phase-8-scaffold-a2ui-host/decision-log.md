# Decision Log — phase-8-scaffold-a2ui-host

## D-001 · A2UI is an external protocol; ours diverges structurally [analyze · 2026-08-28]

**TL;DR** — `a2ui-project/a2ui` (16,230 stars, pushed today, Apache-2.0) defines
A2UI. Our schema is `artifact-refiner.dev`-namespaced and differs at every level:
`type` vs `component`, single tree vs envelope stream, bindings map vs
`DynamicString` + `updateDataModel`, open pattern vs catalog.

**Why it matters** — specs our refiner validates are not A2UI protocol
documents. Real agent output fails our validator; ours cannot drive a real
renderer. Same defect class as phase-7's `TOOL_CALL_ARGS_DELTA`, one level up:
a wrong document model rather than a wrong enum value, and larger because
`direct:a2ui` shipped in PR #1 with published examples.

**Provenance** — Context7 `/a2ui-project/a2ui`, `gh search repos`, npm registry.

---

## D-002 · Correction: A2UI is streaming-first, not a static document [analyze · 2026-08-28]

**TL;DR** — Assessment F-1 was wrong.

**What I claimed** — "Transport: none — the spec is a static document";
"Store role: arguably no store at all."

**What upstream says** — "The A2UI Protocol facilitates the dynamic rendering of
user interfaces by **streaming** JSON objects from an agent to a renderer …
allowing for **progressive rendering**." Transports are JSON Lines streams.

**Why I got it wrong** — I read *our* single-tree schema and inferred the
protocol's shape from it, without checking whether our shape was the protocol.

**Impact** — F-1 argued the phase-7 substrate does not transfer *because* A2UI
has no stream. The opposite holds: it is streaming-first, so the
store/subscription/accumulation architecture transfers **more** than assess
concluded. Vocabulary differs (`updateComponents` vs `TEXT_MESSAGE_CONTENT`);
architecture does not.

---

## D-003 · Adopt `@a2ui/react`, conditional on G-8 [analyze · 2026-08-28]

**TL;DR** — If we align upstream, adopt the official renderer rather than
hand-writing one.

**Why** — `@a2ui/react@0.10.2` (Apache-2.0) is the official React renderer and
eliminates G-1, G-4, and most of G-2. React 19 is already what the base
scaffolder emits.

**Costs accepted** — pre-1.0 (pin exact); npm publish lags the repo by ~6 weeks
(repo 2026-08-28 vs package 2026-07-17); `@a2ui/markdown-it` declared as `*`,
an unbounded range in a published dependency.

**Rejected** — the existing Lit renderer as a basis: three lowercase types that
cannot match our own PascalCase schema, zero binding resolution, implements
neither dialect nor protocol. Its preview shell is salvageable; the switch is not.

**Deferred** — `CopilotKit/generative-ui`, same reasoning phase-7 applied to
`@copilotkit/react-core`.

---

## D-004 · G-8 escalated to the owner, not decided here [analyze · 2026-08-28]

**TL;DR** — Align / rename / support-both is not analyze's call.

**Why** — It changes the meaning of a shipped domain and invalidates published
examples. The right answer depends on whether `direct:a2ui` is meant to produce
artifacts other systems consume — a product question, not a research one.

**What analyze can say** — "keep the dialect" is cheapest today and most
expensive later; alignment cost grows with every spec authored against the
dialect.

---

## Operator confirmation — G-8 resolved: ALIGN TO UPSTREAM [spec · 2026-08-28]

**Decision: align `direct:a2ui` to the real A2UI protocol (v1.0).** Confirmed by
the operator in session via an explicit four-option prompt (align / rename /
support-both / defer the phase). Not inferred, not assumed from silence.

**What this commits to:**

- The document model becomes the upstream **envelope stream** —
  `createSurface`, `updateComponents`, `updateDataModel`, `deleteSurface`,
  `callFunction`, `actionResponse` — replacing our single `{version, metadata,
  bindings, root}` tree.
- Components carry a `"component"` **const discriminator**, not `"type"`.
- Data binding becomes `DynamicString` wrappers plus `updateDataModel` messages,
  replacing the top-level `bindings` map with `literal`/`ref`/`expression` kinds.
- Component vocabulary comes from a **catalog**, replacing the open
  `^[A-Z][A-Za-z0-9]*$` pattern.
- `@a2ui/react` (Apache-2.0, pinned exact) becomes the renderer. D-003's
  condition is satisfied.

**Accepted cost — this is a breaking change.** Both shipped examples
(`source.a2ui.json`, `broken-circular.a2ui.json`) are invalid under the real
protocol and must be rewritten. `direct:a2ui` shipped in PR #1, so anything
authored against the old shape breaks. The operator chose interoperability over
compatibility with a format that was never interoperable to begin with.

**Consequences for gaps** (from `library-candidates.json`):

| Gap | Now |
|---|---|
| G-1 renderer types | **moot** — the catalog defines the vocabulary; `@a2ui/react` implements it |
| G-4 component coverage | **moot** — same reason |
| G-3 binding resolution | **reshaped** — `DynamicString` + `updateDataModel`, not a bindings map |
| G-6 `expression` evaluation | **NOT moot — corrected** (see below) |
| G-2 template injector | **not required** — a React host renders at runtime; no static template to inject |
| G-5 scope (Q1) | **resolved by implication** — aligning means a runtime renderer, so reading (b) |
| G-7 unpinned CDN | **stands** — independent of G-8 |

### Correction: G-6 / Q3 is not moot

The table above originally recorded `expression` evaluation as moot because the
protocol defines `callFunction` with `callableFrom` metadata. Adversarial review
caught the flaw: **p8-04 explicitly defers `callFunction` round-tripping**, so
the mechanism cited to make the question moot is itself out of this change set.
Nothing would have closed it, and plan would have inherited a false "resolved".

Assess Q3 asked whether to evaluate, sandbox, or reject arbitrary expression
bindings and recommended rejection for v1. **That is now p8-02 tasks 3.3/3.4**,
gated by 5.8: an expression-like `DynamicString` leaf is rejected with a named
error, and the old dialect's `{"kind": "expression"}` form is rejected explicitly
so arbitrary JS cannot survive the migration by omission.

**Provenance** — operator decision, recorded at the spec stage; G-6 correction
from adversarial review.

---

## D-005 · Ported the feature-name fix to the AG-UI scaffolder [post-reflect · 2026-08-29]

**TL;DR** — `scaffold-react-vite-agui.sh` carried the same defect p8-05 fixed for
A2UI. Fixed and verified; the two scaffolders are now at parity.

**The defect.** Line 59 derived the feature name from the raw directory
basename and never sourced `lib/kebab-case.sh`. The base scaffolder names slices
with `to_kebab()`, which inserts separators around digit runs — so any target
whose name contains a digit produced a **second feature directory the generated
app never imports**.

Divergence only appears with digit runs, which is why phase-7's own smoke test
(`agui-smoke` → `agui-smoke`, unchanged) never caught it:

```
agui-demo   -> agui-demo     (identical — bug invisible)
demo2app    -> demo-2-app    (diverges — bug fires)
a2ui-smoke  -> a-2-ui-smoke  (diverges — how it was found)
```

**Fix.** Identical to p8-05: source `lib/kebab-case.sh`, derive via `to_kebab`,
and fall back to an existing slice when one is present, guarded by
`FEATURE_EXPLICIT` so `--feature` still wins.

**Verified end to end** against `demo2app`, a name chosen because it triggers the
divergence:

| Check | Result |
|---|---|
| Base scaffolder creates | `demo-2-app` |
| AG-UI wrapper reports | `Feature: demo-2-app` |
| Feature directories after | **exactly one** |
| Files land in | `src/features/demo-2-app/{stores,components}/` |
| `pnpm build` | exit 0 |
| `pnpm lint` | exit 0 |
| `--feature custom-slice` | honoured — explicit overrides the fallback |

**Why this was done before starting phase-9.** It was a known, diagnosed defect
in shipped code with the fix already written. Leaving one in place while opening
new work is how the AG-UI event-enum drift survived an entire phase.

**Scope note.** `scaffold-react-vite-agui.sh` is untracked in git — created in
phase-7 and never committed — so this shows as a new-file addition rather than a
diff.
