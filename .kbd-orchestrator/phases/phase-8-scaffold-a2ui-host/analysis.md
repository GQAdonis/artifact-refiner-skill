# Analysis — phase-8-scaffold-a2ui-host

- **Phase:** `phase-8-scaffold-a2ui-host`
- **Stage:** analyze
- **Date:** 2026-08-28
- **Mode:** stack-specified
- **Input:** `handoffs/assess.json` — 3 open questions, 7 gaps

---

## Budget

| Tier | Used | Cap |
|---|---|---|
| T1 `gh search` | 3 | 8 |
| T2 Context7 | 3 | 8 |
| T3 npm / registries | 6 | 8 |
| T4 firecrawl/tavily | 0 | 8 |

Within budget. T4 skipped — T1–T3 produced a finding that reframes the phase, and
more breadth would not change the recommendation.

---

## The finding that reframes the phase

**A2UI is a real external protocol, and ours is not it.**

| Signal | Value |
|---|---|
| Upstream | `a2ui-project/a2ui` |
| Stars | **16,230** |
| Last push | **2026-08-28** (today) |
| License | Apache-2.0 (confirmed via `gh api …/license` and npm) |
| Official React renderer | `@a2ui/react@0.10.2`, Apache-2.0 |
| Independent implementations | Blazor, Swift, Android, React Native, CopilotKit (evaluated below) |

**Provenance — the upstream paths below are NOT in this repository.** They are
files in the `a2ui-project/a2ui` GitHub repo, retrieved this session via the
Context7 MCP (library id `/a2ui-project/a2ui`). They will not resolve against
this repo's file tree and are not expected to; they are cited as *external
protocol authority*, not local evidence. Re-verify by re-querying Context7 or
fetching upstream directly:

- `specification/v1_0/docs/a2ui_protocol.md` — envelope model, streaming statement
- `specification/v1_0/catalogs/basic/catalog.json` — catalog schema template
- `specification/v1_0/common_types.json` — `ComponentCommon`, `DynamicString`
- `docs/public/concepts/glossary.md` — A2UI message / streaming semantics
- `docs/public/concepts/transports.md` — JSON Lines transport

(Phase-7's analyze took the same finding from its adversarial review; the lesson
is recorded and applied here rather than relearned.)

What IS locally verifiable: our schema declares
`$id: https://artifact-refiner.dev/schemas/a2ui-component.schema.json`, and
`grep -n -iE 'http|spec|standard|upstream|protocol' references/domain/a2ui.md`
returns no reference to any external A2UI specification.

### The divergence is structural, not cosmetic

| | Ours | Upstream A2UI v1.0 |
|---|---|---|
| Component key | `"type": "Container"` | `"component": "Text"` — a `const` discriminator |
| Document shape | `{ version, metadata, bindings, root }` — one tree | envelope **stream**: `createSurface`, `updateComponents`, `updateDataModel`, `deleteSurface`, `callFunction`, `actionResponse` |
| Data binding | top-level map, kinds `literal`/`ref`/`expression` | `DynamicString` wrappers + `updateDataModel` messages |
| Vocabulary | unconstrained `^[A-Z][A-Za-z0-9]*$` | `catalog.json` declaring an explicit component set |

**Consequence:** a spec our refiner validates is not an A2UI protocol document.
Real agent output fails our validator; our output cannot drive a real renderer.

This is phase-7's `TOOL_CALL_ARGS_DELTA` defect one level up — not a wrong enum
value inside a correct model, but a wrong document model. And it is larger,
because `direct:a2ui` shipped in PR #1 with published examples.

---

## Correction to the assessment (mine, from the previous stage)

Assessment F-1 stated:

> A2UI is a declarative component tree … Transport: **none — the spec is a static
> document** … Store role: **arguably no store at all**

**That is wrong.** Upstream, verbatim:

> The A2UI Protocol facilitates the dynamic rendering of user interfaces by
> **streaming** JSON objects from an agent to a renderer … allowing for
> **progressive rendering** as the renderer processes incoming messages.
> — `specification/v1_0/docs/a2ui_protocol.md`

The glossary defines an A2UI message as one that supports streaming and may be
finished or interrupted. Transports are JSON Lines streams.

I inferred "static document" from *our* schema's single-tree shape without
checking whether that shape was the protocol. It is not.

**This inverts F-1's conclusion.** F-1 argued the phase-7 substrate does *not*
transfer *because* A2UI has no stream. In fact A2UI is streaming-first, so the
store/subscription/progressive-accumulation architecture transfers **more** than
assess concluded. The event vocabulary differs — `updateComponents` rather than
`TEXT_MESSAGE_CONTENT` — but the shape is the same: accumulate a stream into
renderable state.

Two errors in two consecutive stages, same root cause: reading our own artifacts
as though they described the world.

---

## G-8 (new, BLOCKING) — align, rename, or both?

Not present in the assessment's gap report, and it now gates everything else.

| Option | For | Against |
|---|---|---|
| **Align to upstream v1.0** | specs interoperate with real agents; `@a2ui/react` renders them for free; catalogs replace our ad-hoc `componentType` | breaking change to a shipped domain; invalidates both published examples; refiner reworked to the envelope model |
| **Keep the dialect, rename it** | no breaking change; phase-8 stays small | the name is taken and means something else; permanently non-interoperable; future readers will assume conformance |
| **Support both** | migration path | two document models, two renderers, ~double the surface |

**This is not analyze's decision.** It changes the meaning of a shipped domain
and invalidates published examples — an owner's call, informed by whether the
`direct:a2ui` refiner is meant to produce artifacts other systems consume.

What analyze *can* say: option 2 is cheapest today and most expensive later, and
the cost of alignment only grows as more specs are authored against the dialect.

---

## Decision — renderer: **ADOPT `@a2ui/react`, conditional on G-8**

If G-8 aligns upstream, `@a2ui/react@0.10.2` (Apache-2.0) eliminates G-1, G-4,
and most of G-2 outright. Writing a component interpreter that upstream already
ships and maintains would be rebuilding, not building.

**Costs, stated plainly:**

- Pre-1.0 at `0.10.2` — pin exact, as with `@ag-ui/*`.
- **Publish cadence lags the repo**: repo pushed 2026-08-28, package last
  published 2026-07-17. Roughly six weeks — the npm artifact does not track main
  closely. Worth knowing before depending on a recent protocol feature.
- **`@a2ui/markdown-it` is declared as `*`** — an unbounded range in a published
  dependency. A packaging smell and a supply-chain risk that a lockfile mitigates
  but does not remove.
- `peerDependencies` require `react@^19.2.7`; confirm against what the base
  scaffolder installs before committing.

**Third candidate, surfaced by review: `@a2ui/web_core@0.10.6`** (Apache-2.0,
published 2026-08-03). It is the engine beneath `@a2ui/react`, and it is
framework-agnostic — its dependencies are `zod`, `date-fns`,
`zod-to-json-schema`, and `@preact/signals-core`, with **no React peer**. That
matters for two reasons: it is the correct dependency if a host ever needs to
render outside React, and it publishes more recently than `@a2ui/react`
(2026-08-03 vs 2026-07-17), so the staleness concern is specific to the React
wrapper rather than the stack. For a React host, `@a2ui/react` remains the right
adoption — `web_core` arrives transitively — but plan should know the seam
exists.

**Rejected as a basis: the existing Lit renderer.** It handles three lowercase
types that cannot match our own PascalCase schema, resolves no bindings, and
implements neither dialect nor protocol. Its surrounding shell — brand CSS
variables, layout, screenshot harness — is reusable; the ~30-line switch is not.

**Deferred: `CopilotKit/generative-ui`.** Same verdict as phase-7 gave
`@copilotkit/react-core`: a full framework whose opinions collide with this
repo's scaffolder conventions.

**The non-web implementations are landscape, not candidates.** Listing them
without a verdict would be scenery, so: `A2UI.Blazor` (32★, .NET),
`a2ui-swift` (55★), `A2UI-Android` (74★), and `a2ui-react-native` (28★) are all
**out of scope by platform** — this phase targets a Vite/React web host, and none
of them is consumable from TypeScript. Their value here is corroborative: four
independent ports across four ecosystems is evidence that A2UI is a real
multi-implementation standard rather than one vendor's JSON shape, which is
precisely what makes our divergence (D-001) consequential.

---

## Q2 resolved — React, unconditionally

An earlier draft left this conditional on G-8, which would have handed plan a
phase it cannot start. Resolving it properly:

**Under alignment (G-8 option 1):** React. `@a2ui/react` is the official
renderer; adopting it is the whole point.

**Under the dialect (G-8 option 2):** **still React**, and the reason is not
A2UI at all — it is that the scaffolder substrate is React (phase-7's
`scaffold-react-vite-agui.sh`, the architectural ESLint config, the
store/hook/component layering). Building an A2UI host on Lit would mean
maintaining a second frontend stack for one artifact type, with none of the
layering enforcement that phase-7 repaired.

The existing Lit renderer is not an argument for Lit: it has never rendered a
conformant spec (assess F-2), so "keep Lit" means *rewrite in Lit*, not *reuse*.
Rewriting in the non-substrate framework is strictly worse.

**So Q2 is closed: React either way.** What G-8 changes is whether the renderer
is *adopted* (`@a2ui/react`) or *written* (a component interpreter against our
dialect) — a build-vs-adopt question whose answer is already recorded in D-003,
gated only on which document model we are rendering.

### Compatibility verified, not assumed

An earlier draft both asserted React 19 compatibility and flagged it unchecked.
Checked now:

```
$ npm view @a2ui/react peerDependencies   → react ^19.2.7
$ npm view react version                  → 19.2.8
```

`19.2.8` satisfies `^19.2.7`, and `scaffold-react-vite.sh:148` runs shadcn init
targeting React 19. No conflict.

---

## Open Questions Remaining

1. **G-8 (blocking):** align, rename, or support both. Owner's decision.
2. **Q1 (from assess):** finish the preview vs. emit a scaffolder — now
   subordinate to G-8. Aligning makes the scaffolder reading substantially
   cheaper, because `@a2ui/react` does the rendering.
3. **Q3 (from assess):** `expression`-binding evaluation. Moot under alignment —
   the protocol defines `callFunction` with `callableFrom` metadata instead.
   Live if the dialect stays.

---

## Adversarial Review — 2 rounds, revision cap reached

True cross-model isolation both rounds (`rest-gateway`, `verified-distinct`,
producer `claude-opus-5` ≠ judge `kbd-judge`). Both returned BLOCK.

**Round 1 — 1 CRITICAL, 4 WARNING. All applied:**

| Finding | Disposition |
|---|---|
| Q2 left conditional, so plan has no decidable path | **Fixed** — Q2 closed unconditionally: React either way. The Lit renderer has never rendered a conformant spec, so "keep Lit" means *rewrite* in Lit, which is strictly worse than the substrate framework. |
| Upstream paths not verifiable from the packet | **Fixed** — provenance block added; upstream files marked external-not-local, with the locally verifiable half separated out |
| `@a2ui/web_core` unevaluated despite being named | **Fixed** — evaluated: framework-agnostic, no React peer, publishes *more* recently than the React wrapper |
| Blazor/Swift/Android/RN listed but never judged | **Fixed** — explicit OUT-OF-SCOPE-BY-PLATFORM verdict; their real value is corroborating that A2UI is a multi-implementation standard |
| React 19 compat both asserted and flagged unchecked | **Fixed** — verified: `^19.2.7` vs npm latest `19.2.8`; contradictory risk line removed |

**Round 2 — 2 CRITICAL, 1 WARNING.** Two applied, one declined:

| Finding | Disposition |
|---|---|
| Three of seven assessment gaps dropped | **Fixed, and it is the phase-7 lesson recurring.** An earlier draft collapsed G-1..G-4 into one row and omitted G-5/G-6/G-7. All eight gaps now carry explicit verdicts. This is the third phase where I have dropped carry-forward items that had no interesting research attached. |
| React compat recorded as both unchecked and verified | **Fixed** — stale risk line removed from the JSON |
| "Scope decision unresolved, plan has no determinate target" | **Declined — see below** |

### The declined CRITICAL

The judge is right that G-8 is unresolved. It is unresolved **deliberately**, and
resolving it inside analyze would be the error, not the fix.

G-8 asks whether to align a shipped domain to an external protocol, rename it, or
support both. That decision invalidates published examples and changes what
`direct:a2ui` *means* to anyone consuming it. It turns on whether the refiner is
meant to produce artifacts other systems ingest — a product question the owner
answers, not one research settles.

What analyze owes plan is a **decidable** phase, and that is now delivered:
Q2 is closed unconditionally, every gap has a verdict, the renderer decision is
recorded with costs, and both G-8 branches carry an estimate. Plan can be written
the moment G-8 is answered, and the answer is a single choice among three
documented options rather than open research.

Escalating rather than deciding is the recorded protocol for exactly this shape
(kbd-analyze SKILL.md, contested-choice escalation). Silently picking would have
buried a breaking-change decision inside a research artifact.

## Estimate

Unchanged from assess in shape, but the branches have moved:

| Path | Estimate |
|---|---|
| Keep dialect + finish preview | 1 session, 4–6 changes — but ships a permanently non-interoperable artifact type |
| Align upstream + adopt `@a2ui/react` | 2–3 sessions, 8–12 changes — most of it reworking the refiner and examples, not writing a renderer |
| Support both | 4+ sessions — not recommended |

The assess estimate assumed a hand-written renderer was the work. Under
alignment it is not: the renderer is adopted, and the work moves to the schema,
the normalizer, and the examples.

---

## Process note

Third confirmed packaging gap: `kbd-analyze` ships only `SKILL.md`, so
`references/research-pipeline.md` (its declared source of truth for tiers and
evidence format) and `references/schemas/library-candidates.schema.json` are both
absent. `library-candidates.json` follows the field set described inline and is
**unvalidated against any schema**.
