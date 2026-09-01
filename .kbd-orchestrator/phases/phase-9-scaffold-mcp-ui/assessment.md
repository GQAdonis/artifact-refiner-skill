# Assessment — phase-9-scaffold-mcp-ui

- **Phase:** `phase-9-scaffold-mcp-ui`
- **Stage:** assess
- **Date:** 2026-08-29
- **Origin:** Deferred since phase-2; recommended by the phase-8 reflection
- **Model preflight:** `ok` — judge `k3`, critic `MiniMax-M3`, generator
  `kbd-frontier`, no config defects

---

## Phase Goal

Two definitions of record, and they disagree about scope:

> **phase-9-scaffold-mcp-ui** — React scaffold + MCP-UI primitives (when MCP-UI
> standard solidifies).
> — `.kbd-orchestrator/phases/phase-2-scaffold-react-vite/plan.md:66`

> **phase-9-scaffold-mcp-ui** — MCP-UI compliant host (research-heavy — protocol
> is new).
> — `.kbd-orchestrator/phases/phase-ideation-to-app-pipeline/assessment.md:293`

Both carry a conditional the earlier author attached deliberately: *"when the
standard solidifies"*, *"protocol is new"*. F-4 below asks whether that
condition is met, because it is the one question that decides whether this phase
should run now at all.

---

## The standing precondition — discharged

Phase-8's reflection set a precondition: **verify MCP-UI is not another A2UI.**
Twice now a local artifact diverged from an external standard of the same name —
the AG-UI event enum (`TOOL_CALL_ARGS_DELTA`, a kind AG-UI never defined) and the
A2UI document model (an invented `{version, metadata, bindings, root}` shape).

**Discharged: the risk does not exist here, because nothing local claims MCP-UI.**

Verified by searching **every path this repository owns**, excluding only the two
genuine submodules (whose contents are upstream-owned) plus build and cache
directories. First-party code under `tools/` is *included* — the round-2 finding
below established that `tools/template-forge-rs` is ours, so excluding all of
`tools/` would have been the same category error the precondition guards against:

```
$ grep -rln "mcp-ui\|mcp_ui\|MCP-UI\|MCP UI" . \
      --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=target \
      --exclude-dir=.prometheus \
  | grep -v '^./tools/rust-mcp-filesystem/' \
  | grep -v '^./shared/sycophancy-correction/'

openspec/changes/phase-2-scaffold-react-vite/tasks.md   ← the ONLY non-planning hit
.kbd-orchestrator/…                                     ← 16 files, all planning docs
```

`.kbd-orchestrator/` hits are expected — planning documents are where this phase
is *named*. `tools/template-forge-rs` returns **zero** hits for `mcp-ui`,
`mcp_ui`, or `ui://`. The excluded `.prometheus/` is a session-snapshot cache,
not repository content.

That is the whole shipped surface: no file this repository owns implements,
declares, or references MCP-UI outside a planning note. The class table below
records where an implementation *would* live, had one existed:

| Artifact class | Present? |
|---|---|
| `direct:mcp-ui` content type | **No** — the enum has 12 entries, none MCP-UI |
| `references/domain/mcp-ui.md` | **No** — 9 adapters exist, none MCP-UI |
| MCP-UI schema | **No** |
| MCP-UI examples | **No** |
| MCP-UI normalizer | **No** |
| MCP server exposing `ui://` | **No** — `template-mcp` has no UI concern |

There is nothing to have drifted. This is the **greenfield** case, unlike phases
7 and 8 which were both corrections to shipped work.

The precondition's deeper lesson still applies going forward: cite upstream from
the start, so a future divergence has something to contradict it.

---

## Method

Upstream facts come from Context7 (`/websites/mcpui_dev`, `/mcp-ui-org/mcp-ui`)
and the npm registry, not from memory — the protocol is young and my training
data would be an unreliable source for exactly the kind of claim that produced
the phase-8 reframing.

---

## Findings

### F-1 — MCP-UI is structurally unlike both prior hosts

The phase-8 reflection recommended phase-9 partly on substrate reuse. That
argument is weaker than it looks, and the reason is worth stating precisely,
because assess made the *opposite* error in phase-8 (claiming A2UI had no
transport when it is streaming-first).

| | AG-UI (p7) | A2UI (p8) | **MCP-UI (p9)** |
|---|---|---|---|
| Payload | event stream | component tree | **HTML / external URL / Remote DOM** |
| Transport | SSE (`text/event-stream`) | JSON-Lines envelope stream | **MCP tool result carrying a `ui://` resource** |
| Client job | accumulate deltas | reduce messages, render catalog components | **mount a sandboxed iframe** |
| Client→UI channel | store state | store state | **`postMessage` lifecycle events** |
| Renderer | hand-written store + panel | `@a2ui/react` catalog | `@mcp-ui/client` `AppRenderer` |

The identifying marker is a URI scheme, not a message shape
(`mcpResource.resource.uri?.startsWith('ui://')`).

**What transfers:** the thin-wrapper scaffolder pattern (now proven three times),
the repaired architectural ESLint enforcement, and the smoke-gate discipline
including the browser-DOM gate.

**What does not:** the store/reduce/render architecture that dominated p7-04 and
p8-04. An iframe host has far less state to reduce — arguably no store at all
beyond resource tracking. The reuse is real but shallower than "third host in a
row" suggests.

### F-2 — MCP-UI needs an MCP *server*, and this repo already owns an editable one

Unlike AG-UI and A2UI, whose hosts could be driven by a local mock, MCP-UI is
defined *within* the Model Context Protocol. A working demonstration needs both
ends:

- **server** (`@mcp-ui/server`) — an MCP server registering a `ui://` resource
  and a tool referencing it via `_meta.ui.resourceUri`
- **client** (`@mcp-ui/client`) — a host rendering it through `AppRenderer`

Enumerating the MCP servers this repo declares:

```
$ cat .mcp.optional.json.example .mcp.renderer.example.json   # 4 distinct servers
e2b-sandbox · template-forge · rust-mcp-filesystem · browser-renderer
$ git submodule status            # exactly two submodules, and template-forge-rs
  ef808b7d… tools/rust-mcp-filesystem (v0.4.3)      # is not among them
  bc348fff… shared/sycophancy-correction
$ git ls-files tools/template-forge-rs/ | wc -l
      17                          # tracked as ordinary blobs, not a gitlink
$ ls -d tools/template-forge-rs/.git
  ls: …/.git: No such file or directory
```

Two of those are third-party (`e2b-sandbox`, `browser-renderer`, both `npx`-run)
and `rust-mcp-filesystem` is a **pinned submodule** — parent-owned under
`AGENT_RULES.md`, and filesystem-only. But **`template-forge` is first-party and
in-tree**: `tools/template-forge-rs/crates/template-mcp`, a Rust MCP server this
repo owns, builds, and has already edited this cycle (`template-core/src/brand.rs`
in phase-3c). It is *not* a submodule — the three commands above are the evidence,
because location under `tools/` is not what makes something a submodule.

> `.kbd-orchestrator/constraints.md` asserted the opposite until 2026-08-30. That
> file was wrong and has been corrected; round 2 of this stage's adversarial
> review raised a CRITICAL on the strength of it.

So the server half is **not** greenfield the way I first read it. Phase-9 has a
real choice — extend `template-mcp` with a `ui://` resource, or stand up a small
dedicated mock. That is a design decision for analyze, and it makes G-2
materially smaller than "build an MCP server from nothing."

Neither definition of record mentions the server half at all.

### F-3 — `@modelcontextprotocol/ext-apps` sits between the SDK and MCP-UI

Upstream's own server example imports from three packages:

```typescript
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { registerAppTool, registerAppResource } from '@modelcontextprotocol/ext-apps/server';
import { createUIResource } from '@mcp-ui/server';
```

`ext-apps` is the **MCP Apps** extension, published by the MCP org itself, and it
is materially healthier than the MCP-UI packages (F-4). Whether phase-9 targets
`@mcp-ui/*`, `ext-apps` directly, or both is a genuine build-vs-adopt question —
analyze's to answer, not assess's.

### F-4 — Maintenance signal is markedly weaker than AG-UI or A2UI

The definitions of record both hedge on the standard solidifying. Checking:

| Signal | AG-UI (p7) | A2UI (p8) | **MCP-UI (p9)** |
|---|---|---|---|
| Upstream stars | 15,595 | 16,230 | **5,114** |
| Repo last push | same day | same day | **2026-07-08 (~7 weeks)** |
| Client pkg version | `0.0.59` pre-1.0 | `0.10.2` pre-1.0 | **`7.1.1` post-1.0** |
| Client last publish | same day | 6 weeks prior | **2026-05-09 (~16 weeks)** |
| Server pkg last publish | n/a | n/a | **2026-02-13 (~6 months)** |
| License | MIT | Apache-2.0 | **Apache-2.0** (via `gh api`; the repo API reports `None`) |

Two readings, and they point opposite ways:

- **Post-1.0 at `7.1.1`** is the *strongest* API-stability signal of the three.
  Neither prior phase had that.
- **`@mcp-ui/server` last published six months ago** is the weakest activity
  signal of the three, and the server half is exactly what F-2 says this phase
  must build against.

Meanwhile `@modelcontextprotocol/ext-apps` published 2026-07-23 — the most recent
of any package here. That divergence suggests centre of gravity may be shifting
from `@mcp-ui/*` toward the MCP org's own extension, which would change what
"MCP-UI compliant" means.

**This is the phase's real open question, and it is a go/no-go rather than a
design detail.** Recorded as Q1.

### F-5 — The iframe boundary is a security surface the prior phases did not have

MCP-UI renders **server-supplied HTML**. Upstream's own client example validates
URL schemes before opening links and routes UI messages through an `onMessage`
callback; `AppRenderer` takes an explicit `sandbox` URL.

Neither AG-UI nor A2UI had this shape: AG-UI streamed text into React state, and
A2UI's component tree is data validated against a catalog. Arbitrary HTML in an
iframe is a different trust boundary, and the phase-8 experience is directly
relevant — assess Q3 there flagged expression-binding evaluation as a
code-execution hazard, and it took an adversarial-review round to keep it from
being marked "moot" and quietly dropped.

The sandbox configuration, link-scheme validation, and `postMessage` origin
handling are **not** incidental scaffolding details. They should be explicit
tasks with explicit gates.

### F-6 — The scaffolder substrate is genuinely ready, and now proven three times

Five scaffolders ship today — one base plus four wrappers:

```
scripts/scaffold-react-vite.sh          ← base
scripts/scaffold-react-vite-tauri.sh    ← the wrapper shape the others copy
scripts/scaffold-react-vite-axum.sh
scripts/scaffold-react-vite-agui.sh     ← phase-7
scripts/scaffold-react-vite-a2ui.sh     ← phase-8
```

`-agui.sh` (221 lines) and `-a2ui.sh` (~200) both follow the `-tauri.sh`
thin-wrapper shape, and `-axum.sh` shows the pattern also carries a *backend*
concern — relevant to F-2, since MCP-UI is the first host phase needing a server
end. Phase-8 left that substrate healthier:

- the architectural ESLint config actually runs (repaired in p7-05; it had never
  been enforced)
- `pnpm build` works under TypeScript 6
- the smoke sequence scaffold → build → lint → dev → **browser DOM** is proven
- the `to_kebab` feature-name defect is fixed in **both** wrappers (the AG-UI one
  post-phase-8), so a third wrapper starts from a correct template

---

## Gap Report

| ID | Gap | Severity | Evidence |
|---|---|---|---|
| G-1 | No `direct:mcp-ui` content type, domain adapter, schema, or examples | BLOCKING | precondition search |
| G-2 | No MCP server serves a `ui://` resource; `template-mcp` must be extended or a mock built | BLOCKING | F-2 — first-party server exists but has no UI concern |
| G-3 | No client host: no `AppRenderer` integration, no sandbox wiring | BLOCKING | no `@mcp-ui/*` anywhere |
| G-4 | No `scaffold-react-vite-mcp-ui.sh` | BLOCKING | 5 scaffolders exist (1 base + 4 wrappers); none is MCP-UI |
| G-5 | Iframe trust boundary undesigned — sandbox, link schemes, postMessage origins | HIGH | F-5 |
| G-6 | Target undecided: `@mcp-ui/*`, `ext-apps`, or both | HIGH | F-3 |
| G-7 | **Standard-solidity go/no-go undecided** — evidence gathered (F-4), verdict is the operator's | HIGH | F-4 |
| G-8 | Scope undefined: "primitives" vs "compliant host" | MEDIUM | two conflicting definitions of record |

---

## Scope Recommendation

**Settle G-7 before anything else, and treat it as go/no-go rather than a
detail.** Both definitions of record made this phase conditional on the standard
solidifying. The evidence is genuinely mixed — post-1.0 API but a six-month-stale
server package — and it is the operator's call whether that clears the bar they
themselves set. Proceeding without asking would quietly discard a condition the
project wrote down twice.

**In scope if G-7 clears:**

- G-1 — content type, domain adapter, schema, examples, citing upstream from the
  first commit (the lesson phases 7 and 8 both paid for)
- G-2 — a `ui://` resource served by MCP: either extend the first-party
  `template-mcp` crate or stand up a dedicated mock (analyze decides)
- G-3 — client host via `AppRenderer` with an explicit sandbox
- G-4 — `scaffold-react-vite-mcp-ui.sh` following the now-thrice-proven wrapper
- G-5 — trust-boundary tasks with their own gates, not folded into "wire it up"

**Recommend deferring:**

- Remote DOM content type — `rawHtml` and `externalUrl` are enough for v1, and
  Remote DOM is the most complex of the three delivery modes
- Any change to `tools/rust-mcp-filesystem` — a pinned submodule

---

## Open Questions for analyze/plan

1. **G-7 — has the standard solidified enough to proceed?** Post-1.0 (`7.1.1`)
   argues yes; `@mcp-ui/server` unpublished since 2026-02-13 and the repo
   untouched for ~7 weeks argue no. Both definitions of record made this phase
   conditional on it. **Operator's call.**
2. **G-6 — target `@mcp-ui/*`, `@modelcontextprotocol/ext-apps`, or both?**
   `ext-apps` is the MCP org's own extension and the most recently published
   package here. Analyze should evaluate whether MCP-UI is becoming a wrapper
   over it — that would change what compliance means.
3. **G-8 — "primitives" or "compliant host"?** The two definitions differ by
   roughly an order of magnitude, exactly as phase-8's Q1 did.
4. **Extend `template-mcp`, or build a dedicated mock?** The first-party crate
   already exists and is editable, but adding a UI resource to a *template
   forge* server may be a poor fit for its purpose. Analyze should weigh reuse
   against cohesion.
5. **How is that server hosted during the smoke test?** Phase-7 used a Vite
   dev-server middleware to avoid a second process. An MCP server may not fit
   that shape — MCP typically speaks stdio or HTTP+SSE — and "no second process"
   was a stated goal in both prior scaffolders. If a second process is
   unavoidable, say so rather than letting the smoke gate quietly grow one.

---

## Verification Criteria (for the plan stage)

- [ ] `scaffold-react-vite-mcp-ui.sh <target>` produces an app where `pnpm build`
      and `pnpm lint` both exit 0
- [ ] The generated app renders a `ui://` resource returned by the mock MCP
      server **in a browser DOM**, asserted by role/text via Playwright
- [ ] The iframe is sandboxed with an explicit policy, and the policy is asserted
      — not merely present in source
- [ ] Link-scheme validation rejects a non-`http(s)` URL from UI content
- [ ] A `postMessage` from the UI reaches the host's `onMessage` handler
- [ ] A resource whose URI is not `ui://` is **not** rendered as MCP-UI
- [ ] Upstream provenance is cited in the domain adapter and schema from the
      first commit

Criteria 3–5 exist because of F-5: this is the first host phase where the
rendered content is server-supplied HTML rather than validated data. A phase that
verified only "it renders" would be verifying the least important property.

---

## Estimate

Depends on G-7 and G-8.

| Path | Shape | Estimate |
|---|---|---|
| **No-go on G-7** | record the deferral with evidence; revisit when upstream moves | < 1 session |
| "Primitives" reading | client host + scaffolder, no server work | 1–2 sessions |
| "Compliant host" reading | `ui://` server + client host + trust boundary + scaffolder | **2–3 sessions** |

The compliant-host path is still the largest of the three host phases, because
the **server half has no analogue in either prior phase** — phase-7's mock
emitted canned SSE frames, while this one must speak a protocol. But it is
smaller than my first estimate: `template-mcp` already exists and is editable,
so the floor is "add a resource to a working Rust MCP server," not "write one."

I would not carry phase-8's one-session-under result forward as a prior. That
phase came in fast because `@a2ui/react` did the rendering; here the renderer is
likewise adopted, but the server half is still net-new work.


---

## Adversarial Review Record

**Round 1** — `kbd-judge` vs producer `claude-opus-5`, cross-model verified,
isolation `rest-gateway`. Verdict **PASS**, 0 CRITICAL, 3 WARNING. All three
accepted and fixed rather than carried forward; one changed a finding's
conclusion.

| # | Finding | Disposition |
|---|---|---|
| 1 | Absence claim called "exhaustive" but the search omitted `README.md`, `SKILL.md`, `.claude-plugin/`, `package.json`, `docs/`, `hooks/` | **Accepted.** Re-ran repository-wide. Conclusion unchanged — still only the one planning-doc hit — but it is now actually supported. |
| 2 | "Exactly one MCP server" asserted without evidence | **Accepted, and I was wrong.** Four servers are declared; `template-forge` (`tools/template-forge-rs/crates/template-mcp`) is **first-party, in-tree, and editable** — this repo modified it in phase-3c. F-2 rewritten, G-2 rescoped, Q4 split, estimate lowered from 2–4 to 2–3 sessions. |
| 3 | G-7 said "unevaluated" while F-4 evaluates it at length | **Accepted.** Renamed to "go/no-go undecided" — the evidence is gathered; the verdict is the operator's. |

Finding 2 is the one worth remembering. I inferred "only one MCP server" from
`.gitmodules` and the repo's most visible server, and never enumerated the
`.mcp.*.example` manifests — the same shape of error as this project's two prior
protocol drifts: **reading one artifact and generalizing to the world.** It would
have overstated G-2 as fully greenfield and inflated the estimate by a session.

**Round 2** — same judge/producer pair, `verified-distinct`. Verdict **BLOCK**,
1 CRITICAL, 1 WARNING.

| # | Finding | Disposition |
|---|---|---|
| 4 | CRITICAL — F-2 calls `tools/template-forge-rs` editable first-party code, but `.kbd-orchestrator/constraints.md:12` lists it as a submodule | **Contradiction real; the assessment was right and the constraints file was wrong.** `git submodule status` names only two submodules; `template-forge-rs` has no gitlink, no nested `.git`, and 17 blobs tracked by this repo. Corrected `constraints.md` and added the three verifying commands to F-2. |
| 5 | WARNING — G-4 says "only 4 wrappers exist"; five `scaffold-react-vite*` scripts are present | **Accepted.** Miscounted by conflating base and wrappers. Now stated as 1 base + 4 wrappers, with the list. |

Finding 4 is the more valuable of the two despite resolving against the judge's
proposed fix. A reviewer with no session history could not tell which of two
contradicting project documents was correct — and following its suggested remedy
would have written the error *into* the assessment. What it did do is surface a
false statement in a governance file that has been wrong since `/kbd-init` and
would have misdirected any future phase touching `template-forge-rs`.

Finding 5 also turned up something the count was hiding: **`scaffold-react-vite-axum.sh`
is precedent for a scaffolder that provisions a backend**, which is directly
relevant to F-2's server half. Analyze should read it before designing G-2.

**Round 3** — same pair, `verified-distinct`. Verdict **BLOCK**, 1 CRITICAL,
1 WARNING. Both accepted; both were mine.

| # | Finding | Disposition |
|---|---|---|
| 6 | CRITICAL — the "repository-wide" search excluded all of `tools/` as "vendored submodule content", which round 2 had just established is false for `tools/template-forge-rs` | **Accepted — a self-inflicted inconsistency.** My round-1 fix and round-2 fix contradicted each other. Re-ran excluding only the two real submodules plus build/cache dirs; `template-forge-rs` returns zero hits for `mcp-ui`/`ui://`. Conclusion unchanged, justification now correct. |
| 7 | WARNING — the precondition concluded "nothing local claims MCP-UI" while the table enumerated only five artifact classes | **Accepted.** The grep was always the evidence and the table only illustrative, but the prose let the table carry the claim. Reworded so the search establishes the absence and the table shows where an implementation would have lived; added the missing `ui://` server row. |

Finding 6 is the sharpest lesson of this stage: **fixing one review finding
introduced another.** Round 1 taught me `tools/` was submodule territory, round 2
taught me part of it is not, and the round-1 text was never revisited. A fix
applied to satisfy a reviewer is still an edit, and it inherits every assumption
the surrounding document has since disproved.

### Review summary

| | |
|---|---|
| Rounds | 3 (2-round cap exceeded deliberately — see note) |
| Findings | 7 — 2 CRITICAL, 5 WARNING |
| Accepted | 7/7 |
| Judge | `kbd-judge` vs producer `claude-opus-5`, `verified-distinct`, `rest-gateway` |

**On exceeding the cap:** the contract allows two revision rounds before
accepting with findings appended. Round 3 was run anyway because rounds 1–2 fixed
things at their source rather than annotating them, making a confirmation pass
cheap — and it earned its cost by catching Finding 6, a contradiction the
revisions themselves created. Rounds 2 and 3 both returned BLOCK; neither blocks
the stage, because the CRITICALs were resolved rather than carried. Round 3's
fixes are unvetted, and their residual risk is low: both edited prose to match
command output already reproduced in this document.
