# Analysis — phase-9-scaffold-mcp-ui

- **Phase:** `phase-9-scaffold-mcp-ui`
- **Stage:** analyze
- **Date:** 2026-08-30
- **Input:** `assessment.md` (8 gaps, 4 BLOCKING), `handoffs/assess.json`
- **Gate:** D-001 — operator answered G-7 **go** ("the post-1.0 client is stable
  enough"). Recorded in `decision-log.md` in this phase directory, written before
  this analysis began.
- **Evidence:** upstream API claims are cited against type declarations vendored
  into `evidence/` in this phase directory, copied verbatim from an install of
  `@mcp-ui/client@7.1.1`. They are reproducible with
  `npm install @mcp-ui/client@7.1.1` and a diff.

---

## What the go decision settles, and what it does not

D-001 is scoped to the **client**. The operator's rationale names the post-1.0
client, and that is `@mcp-ui/client@7.1.1` — the package the render host depends
on. Assess's evidence *against* proceeding was never about the client; it was
about `@mcp-ui/server@6.1.0`, last published 2026-02-13.

So G-6 (which packages to target) remains genuinely open, and this stage answers
it. Reading "go" as blanket approval of the whole `@mcp-ui/*` line would put
weight on the decision it was not asked to carry.

All seven remaining gaps are addressed below. Every one gets a verdict, including
those where research changed little — the recurring failure across phases 7 and 8
was gaps quietly vanishing between stages when they had nothing interesting
attached.

---

## D-002 — The tool-result envelope carries the resource

**Assess F-2 said phase-9 must build or extend an MCP server because the
`ui://` resource has to be served. That overstated the requirement — but the
relief is smaller than my first draft of this section claimed. See D-003.**

Evidence is the **shipped type declarations** of `@mcp-ui/client@7.1.1`, read
from an actual install, not from documentation prose:

`evidence/mcp-ui-client-7.1.1--isUIResource.d.ts`
```typescript
import { EmbeddedResource } from '@modelcontextprotocol/sdk/types.js';

export declare function isUIResource<T extends {
    type: string;
    resource?: Partial<EmbeddedResource['resource']>;
}>(content: T): content is T & { type: 'resource'; … };
```

`EmbeddedResource` is the MCP SDK's **`content`-array element** type. The
client's own discrimination helper is therefore typed against an item of a tool
result, which is what proves the resource arrives embedded in the result rather
than being fetched separately.

**Consequence: `resources/list` and `resources/read` are not required** for a
server to deliver a `ui://` resource — `tools/call` suffices.

For the repo side, `tools/template-forge-rs/crates/template-mcp/src/main.rs`
(325 lines; the dispatch table at lines 145–187) handles exactly `initialize`,
`notifications/initialized`, `tools/list`, and `tools/call` — hand-rolled
JSON-RPC 2.0 over stdio, no SDK, and `Cargo.toml:3` describes it as
`"MCP server binary \`template-forge-mcp\` (stdio JSON-RPC 2.0)"`. So it is
*method-compatible* with what MCP-UI needs. D-004 still rejects it, on transport
and cohesion grounds rather than protocol coverage.

> **Correction.** My first draft of D-002 cited documentation snippets with no
> package path, and the adversarial review raised a CRITICAL on exactly that.
> Grounding it in shipped types then overturned D-003 below — the docs describe a
> component this version does not export. The review's demand for provenance was
> not pedantry; it found a real error one step downstream.

---

## D-003 — `UIResourceRenderer` does not exist in 7.1.1. There is one path, and it costs more.

This section originally recommended the legacy `UIResourceRenderer` over
`AppRenderer` to avoid a sandbox proxy. **That recommendation was impossible**,
and the error came from trusting documentation that describes a component the
authorized version no longer exports.

The complete export surface of `@mcp-ui/client@7.1.1`
(`evidence/mcp-ui-client-7.1.1--index.d.ts`):

```typescript
export { getUIResourceMetadata, getResourceMetadata } from './utils/metadataUtils';
export { isUIResource } from './utils/isUIResource';
export { …UI_EXTENSION_CAPABILITIES } from './capabilities';
export { AppRenderer, type AppRendererProps, … } from './components/AppRenderer';
export { AppFrame, type AppFrameProps, type SandboxConfig, … } from './components/AppFrame';
export { AppBridge, PostMessageTransport, … } from '@modelcontextprotocol/ext-apps/app-bridge';
```

**No `UIResourceRenderer`.** `dist/src/components/` contains exactly
`AppRenderer.d.ts` and `AppFrame.d.ts` (both vendored into `evidence/`;
`grep -c UIResourceRenderer evidence/*.d.ts` returns 0 for every file). The upstream docs still show
`UIResourceRenderer` for "legacy hosts"; it was removed somewhere before 7.x.

Three consequences, all of which move cost *up*:

**1. `ext-apps` is not deferrable — it is a hard dependency.**
```json
"dependencies": {
  "@modelcontextprotocol/ext-apps": "^1.2.0",
  "@modelcontextprotocol/sdk": "^1.27.1",
  "zod": "^3.23.8"
}
```
The client also *re-exports* `AppBridge` and `PostMessageTransport` from it. So
D-005's "defer `ext-apps`" was never an available option; it arrives
transitively either way, and pinning it explicitly is now the honest choice.

**2. A hosted sandbox proxy is mandatory.** `SandboxConfig.url` is required
(non-optional) on `AppFrameProps`, and `AppRenderer` takes the same config. There
is no in-process rendering path. The scaffolder must emit `sandbox_proxy.html`
and serve it — ideally from the Vite dev server on a distinct path, though
upstream's example uses a separate origin (`http://localhost:8765`). **Spec must
determine whether same-origin-different-path is acceptable, or whether a genuine
second origin is required for the isolation to mean anything.**

**3. `AppFrame` is the lower-level option and is worth considering.** It takes
pre-fetched `html` plus a pre-configured `AppBridge`, skipping `AppRenderer`'s
automatic resource fetching.

### D-003a — The mock's endpoint contract is conditional on host configuration

`AppRenderer`'s documented lifecycle is: *"2. Fetches the tool's UI resource
(HTML) **if not provided**"*, and `AppRendererProps.html` is *"Optional
pre-fetched HTML. **If provided, skips all resource fetching**."*

So D-002's "`tools/call` suffices" is true **only for a host that already holds
the HTML**. Three configurations, with different server obligations:

| Host configuration | Mock must implement | Notes |
|---|---|---|
| `AppFrame` with `html` | `initialize`, `tools/list`, `tools/call` | resource extracted from the tool result by the host |
| `AppRenderer` with `html` | same | fetching explicitly skipped |
| `AppRenderer` with `client`, no `html` | **also `resources/read`** (and `resources/list` if the guest asks) | automatic forwarding to the MCP client |

There is also a fourth path: `AppRenderer` with **no** `client`, supplying
`toolResourceUri` plus `onReadResource`/`onCallTool` callbacks. Those handlers
"override the automatic forwarding", so the host can answer resource reads from
memory without the mock implementing `resources/*` at all.

**Binding constraint for spec:** the host configuration and the mock's method
set are one decision, not two. Whichever is chosen, the guest UI can still issue
`resources/list`, `resources/read`, `prompts/list`, or `tools/call` of its own
accord — `AppRendererProps` exposes a handler for each, plus `onFallbackRequest`
for anything unrecognized. **Wire `onFallbackRequest` to fail loudly** rather
than letting an unhandled method surface as a silent hang; phase-8's renderer
reporting `Unknown component: Heading` instead of degrading quietly is the
precedent worth copying.

Recommendation: extract the resource from the tool result and pass `html`,
keeping the mock at three methods. Confirm against the running app, not the
types — this is the second time in this stage that documentation and shipped
behavior diverged.

**Net:** the phase is *larger* than my first draft assumed, not smaller. The
estimate is revised accordingly below.

---

## D-004 — G-2: extend `template-mcp`? No. Mock in Vite middleware.

Assess framed this as extend-vs-build. Given D-002, the real constraint is
different: **`template-mcp` speaks stdio, and a browser cannot.**

```toml
description = "MCP server binary `template-forge-mcp` (stdio JSON-RPC 2.0)"
```

Bridging stdio to the browser needs a second process plus an HTTP bridge — the
exact cost D-003 is avoiding. And `template-forge` is a *template forge*; a
demo UI resource does not belong in it (assess Q4 raised this cohesion concern
and it holds).

**Reuse the phase-7 precedent instead.** `scaffold-react-vite-agui.sh` already
emits `src/dev/vite-plugin-agui-mock.ts` and registers it into `vite.config.ts`
idempotently. A `vite-plugin-mcp-mock.ts` answering `POST /api/mcp` with
JSON-RPC — `initialize`, `tools/list`, `tools/call` returning an embedded
`ui://` resource — is a direct transposition of proven code.

Those three methods are sufficient **only under the host configurations D-003a
identifies**; if spec chooses a fetching configuration, the mock grows
`resources/read`. The two decisions are coupled and must be made together.

| Option | Second process? | Verdict |
|---|---|---|
| Extend `template-mcp` | yes (stdio bridge) | **rejected** — transport mismatch + poor cohesion |
| New Rust MCP crate | yes | **rejected** — largest cost, no scaffolder precedent |
| **Vite middleware mock** | **no** | **chosen** — mirrors p7 exactly |

This is the answer to assess Q5 as well: no second process, same as both prior
wrappers.

`scaffold-react-vite-axum.sh` was worth the look the round-3 review prompted, but
it is **not** the precedent: it is a *build-time* server that embeds `dist/` via
`rust-embed` for production, not a dev-time API. Explicitly ruled out.

---

## D-005 — G-6: client plus its required transitive deps

Full candidate evaluation is in **`library-candidates.json`** alongside this
document; the verdicts:

| Package | Version | License | Decision |
|---|---|---|---|
| `@mcp-ui/client` | `7.1.1` | Apache-2.0 | **adopt**, pinned exact |
| `@modelcontextprotocol/ext-apps` | `1.7.5` | MIT | **adopt** — required transitively (D-003); pin explicitly |
| `@modelcontextprotocol/sdk` | `1.30.0` | MIT | **arrives transitively**; pin if imported directly for types |
| `@mcp-ui/server` | `6.1.0` | Apache-2.0 | **decline** — see below |

`@mcp-ui/server` is declined on a technical ground, not its staleness:
`createUIResource` builds a small JSON object. The mock needs to emit that shape
inside a Vite middleware; taking a dependency to construct a literal, from the
package whose maintenance signal assess flagged, buys nothing. **The schema
(G-1) becomes the contract instead** — and unlike a dependency, a schema can be
validated against upstream's documented shape in a test.

Note the license split: `@mcp-ui/*` is Apache-2.0, `@modelcontextprotocol/*` is
MIT. Both permissive, no conflict, but the phase now ships packages from two
orgs rather than one.

Pin exact. `@a2ui/*` and `@ag-ui/*` are pinned exact for the same reason, and
`7.1.1` post-1.0 does not change that — post-1.0 is a promise about intent, not a
guarantee. D-003 is the direct evidence for that caution: a documented component
vanished before 7.x.

---

## D-006 — G-5: the trust boundary, concretely

Assess F-5 correctly identified this as the phase's novel risk class: this is the
first host where rendered content is **server-supplied HTML** rather than
validated data. Making it concrete:

**The library's default is the permissive combination.** From
`evidence/mcp-ui-client-7.1.1--AppFrame.d.ts`, `SandboxConfig.permissions`:

> *Override iframe sandbox attribute (default: `"allow-scripts allow-same-origin allow-forms"`)*

`allow-scripts` together with `allow-same-origin` lets framed content reach out
of the sandbox — the pairing browsers explicitly warn against. Upstream mitigates
this differently: the sandbox proxy is a **separate origin**, so
`allow-same-origin` refers to the proxy's origin rather than the host app's. That
mitigation **only holds if the proxy is genuinely cross-origin**, which is
exactly what D-003's open question puts to spec. Serving the proxy from a
different path on the Vite dev server would silently void it.

This turns G-5 from a caution into a concrete, testable requirement:

| Control | Requirement | How it is gated |
|---|---|---|
| iframe sandbox | either override `permissions` to drop `allow-same-origin`, **or** prove the proxy is cross-origin | assert the **rendered** `sandbox` attribute *and* the proxy origin — not the source |
| CSP | pass `SandboxConfig.csp`; prefer the query-param path so the proxy sets real headers | assert the CSP reaches the frame |
| link schemes | reject non-`http(s)` before navigation (`onOpenLink`) | unit test with `javascript:` and `data:` payloads |
| postMessage origin | validate before acting on a message | unit test with a foreign origin |
| `ui://` discrimination | a non-`ui://` resource must not render as MCP-UI | negative fixture, using `isUIResource` |

Five gates, not one "wire it up securely" task. A phase that verified only "it
renders" would verify the least important property — and would ship the
permissive default unexamined.

---

## D-007 — G-8: scope is the "compliant host" reading

Two definitions of record disagreed. Settled: **a working host**, because a
client-only deliverable cannot be demonstrated — something must serve a `ui://`
resource for the browser-DOM gate to have anything to assert. D-004 makes that
cheap enough that the smaller reading saves little.

## D-008 — G-1: content type and schema

`direct:mcp-ui` joins the enum, with a domain adapter, schema, and examples —
**citing upstream from the first commit.** That is the standing lesson from two
consecutive protocol drifts, and it is cheaper here because nothing has shipped
yet to contradict.

The schema validates the resource shape (`ui://` URI, `rawHtml` /
`externalUrl` content, `encoding`) and doubles as the mock's contract per D-005.
`remoteDom` is out of scope — the most complex of the three delivery modes, and
`rawHtml` plus `externalUrl` demonstrate the protocol.

## D-009 — G-3, G-4: host and scaffolder

Following the thrice-proven wrapper shape, with one addition D-003 forces.

**G-3** is `mcp-ui-surface.tsx` (hosting `AppRenderer`/`AppFrame`) plus a
resource store. Per assess F-1 there is little to reduce, so the store tracks
resources rather than accumulating deltas. **Plus `sandbox_proxy.html` and
whatever serves it** — the piece with no analogue in phases 7 or 8, and the main
reason the estimate went up.

**G-4** is `scaffold-react-vite-mcp-ui.sh`, wrapping the base scaffolder exactly
as `-agui.sh` and `-a2ui.sh` do, with `to_kebab` feature naming already correct
in both templates. It emits the surface, the store, the mock plugin, and the
sandbox proxy, registering the plugin idempotently the way `-agui.sh` does.

---

## Gap disposition — all 8

| Gap | Verdict | Where |
|---|---|---|
| G-1 content type/schema/examples | in scope | D-008 |
| G-2 `ui://` server | in scope — Vite mock, **not** `template-mcp` | D-004 |
| G-3 client host | in scope — `AppRenderer`/`AppFrame` + sandbox proxy | D-003, D-009 |
| G-4 scaffolder | in scope | D-009 |
| G-5 trust boundary | in scope — 5 separate gates | D-006 |
| G-6 package target | **resolved** — client + `ext-apps` (required) | D-005, `library-candidates.json` |
| G-7 go/no-go | **resolved** — operator: go | D-001 |
| G-8 scope | **resolved** — compliant host | D-007 |

---

## Revised estimate

**3 sessions** — the top of assess's 2–3 range, not below it.

Two forces pulling opposite ways, and the second wins:

- **Down:** D-002 and D-004 removed the largest assumed cost. No
  protocol-speaking server has to be written; the mock is a transposition of
  `vite-plugin-agui-mock.ts`, and no second process is needed for it.
- **Up:** D-003 added a cost assess never saw. The legacy single-iframe renderer
  does not exist in 7.1.1, so the phase must ship the **double-iframe MCP Apps
  architecture**: a hosted sandbox proxy, an `AppBridge`, `ext-apps` as a real
  dependency, and a sandbox/CSP posture that has to be reasoned about rather
  than accepted (D-006).

My first draft said 2 sessions on the strength of a component that does not
exist. Correcting that moves the number the other way, and I would rather record
3 than repeat phase-8's pattern of an estimate that only looked good because a
constraint had gone unnoticed.

Retained risk: an adopted renderer can still fail to render what we emit — that
is exactly what happened in phase-8, where the shipped renderer could not render
any conformant spec. **The browser-DOM gate is what catches it**, and it is
non-negotiable.

---

## Open questions for spec

1. **Must the sandbox proxy be a genuine second origin?** The decisive question,
   because it determines whether the default `allow-scripts allow-same-origin`
   is safe or a hole. Upstream's example uses `http://localhost:8765`, a separate
   origin from the app. Options for spec: (a) serve the proxy cross-origin and
   keep the default permissions; (b) serve it same-origin on another path and
   **override** `permissions` to drop `allow-same-origin`; (c) both. Settle this
   by observing the rendered frame, not by reading the docs — D-003 is the
   cautionary case.
2. **`AppRenderer` or `AppFrame`?** `AppFrame` is lower-level: pre-fetched `html`
   plus a hand-configured `AppBridge`. For a mock-driven demo the host already
   holds the resource, so `AppFrame` may be the smaller surface. Prefer
   `AppRenderer` unless the bridge wiring is genuinely simpler by hand.
3. Is `externalUrl` worth including in v1, given it loads a third-party origin
   into the smoke test? `rawHtml` alone may be the honest v1, with `externalUrl`
   schema-supported but not exercised live.
4. Which change owns the five D-006 gates — one security change, or distributed
   into the host change? Phase-8's lesson: a constraint gated over the wrong path
   is ungated, so whichever change owns them must own the paths they scan.

---

## Adversarial Review Record

Judge `kbd-judge` vs producer `claude-opus-5`, `verified-distinct`,
isolation `rest-gateway`. 3 rounds, 6 findings, 6/6 accepted.

| # | Round | Finding | Disposition |
|---|---|---|---|
| 1 | 1 | WARNING — no `library-candidates.json` despite the stage deciding package adoption | **Accepted.** Written, with criteria, verdicts, and rejected repo options. |
| 2 | 1 | CRITICAL — D-002's central claim rested on doc snippets with no package path or URL | **Accepted, and it cascaded.** Re-grounding in shipped `.d.ts` overturned D-003 entirely (finding 3). |
| 3 | — | *(consequence of 2)* `UIResourceRenderer` does not exist in 7.1.1 | **Self-caught while fixing 2.** The recommended component is absent from the authorized version. D-003 rewritten, `ext-apps` moved from "defer" to "required", estimate raised 2 → 3 sessions. |
| 4 | 2 | CRITICAL — mock implements only `tools/*` while `AppRenderer` does "automatic resource fetching"; contract left dangling between D-002 and D-004 | **Accepted.** Added D-003a: the endpoint contract is *conditional on host configuration*, four configurations tabulated, and the two decisions declared coupled. |
| 5 | 2 | WARNING — `library-candidates.json` declares license/maintenance criteria but omits them for transitive packages | **Accepted.** Filled in for `@modelcontextprotocol/sdk` and `zod`; added a note on why transitives are evaluated on license/version but not suitability. Surfaced that zod resolves to 3.25.76 while latest is 4.5.4. |
| 6 | 3 | CRITICAL — the G-7 go decision and the cited `.d.ts` files are not in the packet, so no claim is reproducible by the judge | **Accepted — a provenance defect, not a factual one.** `decision-log.md` existed but the packet builder does not include it; the types lived in a scratchpad install. Vendored the four declarations plus a trimmed `package.json` into `evidence/`, and pointed every citation at them. |

### What this stage cost, and what it bought

Finding 2 is the one that mattered. A demand for provenance — which looked
procedural — exposed that **my central recommendation named a component that does
not exist in the version the operator authorized**. Had it survived to spec, the
first implementation task would have failed on an import.

The chain is worth recording: cite docs instead of types → recommend a phantom
component → conclude `ext-apps` is deferrable → underestimate at 2 sessions.
Four errors from one shortcut, and none of them visible without installing the
package.

Finding 6 generalizes it. Evidence that lives in a scratchpad is not evidence;
the review could not reproduce a single API claim. That is now fixed for this
phase, but the packet builder including `decision-log.md` and phase `evidence/`
by default is a **tooling gap** worth carrying to the reflection.

**On exceeding the 2-round cap:** round 3 was run because rounds 1–2 changed
load-bearing conclusions rather than annotating them. It returned no factual
defect — only the provenance gap — which is the confirmation the extra pass was
for. Round 3's own fixes (vendoring evidence, repointing citations) are unvetted;
residual risk is low, since they moved files and changed no claim.
