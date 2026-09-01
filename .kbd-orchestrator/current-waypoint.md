# Current Waypoint

**Phase:** `phase-9-scaffold-mcp-ui`
**Stage:** phase-9 COMPLETE · phase-6 (Flutter A2UI) COMPLETE
**Updated:** 2026-09-01

---

## A2UI now renders on all three surfaces

One vocabulary, three transports, one translation — and parity is **tested**,
not asserted:

| Surface | Scaffolder | Renderer | Parity gate |
|---|---|---|---|
| Web / AG-UI | `scaffold-react-vite-a2ui.sh` | `@a2ui/react@0.10.2` | browser DOM |
| MCP clients | `scaffold-react-vite-mcp-ui.sh` | same, in a sandboxed iframe | browser DOM, 3 frames |
| **Flutter** | **`scaffold-flutter-a2ui.sh`** | **`genui@0.10.2`** | **widget test, 2/2** |

All three render the **same `source.a2ui.json`** and assert the **same facts**:
heading, body text, two buttons labelled `Enable` / `Not now`.

**The Flutter scaffolder runs its parity test before reporting success** and
exits 1 if it fails — it will not emit code it has not verified.

## The parity seam — three copies that must agree

The v1.0 → v0.9 translation now lives in three files:

```
assets/scaffold/a2ui/a2ui-surface.tsx          toSdkMessages()   web
assets/scaffold/mcp-ui/guest/a2ui-guest.tsx    toV09Messages()   MCP-UI
assets/scaffold/flutter-a2ui/a2ui_translation.dart  toV09Messages()  Flutter
```

**Both halves are load-bearing.** Without the `catalogId` retarget the renderer
raises "Catalog not found"; without the message split the surface is created but
never populated — it renders **empty, with no error**. That silent mode is why
each copy is a named, tested seam.

## Escalated, not fixed

`hybrid-mobile-architecture-src/assets/templates/rust/gen_ui_types/src/events.rs:81`
defines `A2uiEvent` as `RunStarted` / `RunPhaseChanged` / `RunFinished` /
`RunError` — an **AG-UI-shaped run lifecycle**, with **zero overlap** with A2UI's
six operations. Third instance of a local type diverging from the standard it is
named after, and the first caught before building on it. Frozen seam with
consumers outside this repo — **your call.**

Also: `a2ui_flutter@0.0.1-wip002` on pub.dev is **not** the SDK. It is 1,890
bytes of unmodified `dart create` template. The renderer is `genui`.

## Two constraint holes plan closed

Both were gated by **nothing at all** — harder to spot than a wrong claim,
because there is no assertion to read and contradict.

- **`no-brand-leakage`** (blocking) had no gate across 133 tasks, while
  `no-hardcoded-secrets` was gated five times over. Subtlety: it scans `assets/`
  but only `--include='*.md'`, and **all six of p9-04's files are
  `.ts`/`.tsx`/`.html`** — the standing gate covers none of them.
- **`hook-scripts-executable`** (warning) covers *every* `scripts/*.sh` despite
  its name, and p9-05 creates one. Found by checking the other four warning
  constraints instead of assuming them unaffected.

**`plugin-manifest-current` will flag at archive, and that is correct.**
`plugin.json` has no `skills` key; paths are auto-discovered. Acknowledged in
`plan.md` and recorded as p9-05 task 6.5 so it does not read as an oversight.

## Two scope changes the spec review forced

**`externalUrl` is out.** Analyze's Q3 assumed it was a mimeType variant a
schema could support cheaply. Grepping the installed packages showed **no
`text/uri-list` mimeType in either `@mcp-ui/client@7.1.1` or
`@modelcontextprotocol/ext-apps@1.7.5`** — upstream models it as a distinct
content shape. Supporting it would have meant inventing a wire format, which is
exactly what phases 7 and 8 spent themselves correcting.

**The mimeType is `text/html;profile=mcp-app`**, not bare `text/html` — the MCP
Apps spelling both shipped packages emit. My first schema draft had *both*
branches wrong; the schema would have rejected conformant input.

Both came from one review question: *what is the actual `remoteDom` mimeType
literal?* There isn't one — and answering it properly invalidated two branches
and a scope decision.

**G-7 settled: go** (D-001, operator — "the post-1.0 client is stable enough").
Scoped to the client; analyze declined `@mcp-ui/server` separately.

## The finding that reshaped the phase

**`@mcp-ui/client@7.1.1` does not export `UIResourceRenderer`.** The upstream
docs still describe it for "legacy hosts", but the shipped `index.d.ts` exports
only `AppRenderer` and `AppFrame` — verified against type declarations now
vendored in `phases/phase-9-scaffold-mcp-ui/evidence/`.

Consequences, all of which raise cost:

- **`ext-apps` is a hard dependency**, not something deferrable — declared in the
  client's `dependencies` and re-exported by it
- **A hosted sandbox proxy is mandatory** — `SandboxConfig.url` is required; there
  is no in-process rendering path
- The phase must ship the **double-iframe MCP Apps architecture**

I had recommended the legacy renderer before checking. Adversarial review
demanded provenance for the claim, and grounding it in shipped types exposed the
error — one shortcut (citing docs instead of types) had produced a phantom
component, a wrong dependency verdict, a wrong architecture, and a low estimate.

**Security finding worth carrying:** the library's *default* sandbox is
`allow-scripts allow-same-origin allow-forms` — the pairing browsers warn
against. Upstream's mitigation is that the proxy is a separate origin, which
holds **only if it genuinely is**.

**Spec resolved it:** serve the proxy same-origin *and* override `permissions`
to drop `allow-same-origin`, keeping the no-second-process property. p9-04's
gate asserts the rendered attribute. A consequence found in review: an opaque
frame posts messages with `origin: "null"`, so origin alone cannot authenticate
it — the check is paired with `event.source === iframe.contentWindow`.

## Precondition — DISCHARGED

**MCP-UI is not another A2UI.** Nothing this repository owns claims MCP-UI at
all: a repo-wide search (excluding only the two genuine submodules) returns one
planning-doc hit and nothing else. No content type, adapter, schema, examples, or
normalizer. **Greenfield, not a divergence to repair** — the first host phase
that is.

The flip side: there is no existing citation to anchor against either, so
upstream provenance must be recorded from the first commit.

---

## Phase-9 progress

| | |
|---|---|
| Gaps | 8 — 3 resolved (G-6, G-7, G-8), 5 scoped into the build |
| Adversarial review | **19 rounds across 3 stages, 43 findings (29 CRITICAL), 43/43 accepted**, `verified-distinct` |
| Estimate | **3 sessions** — top of the assess range; analyze's own first draft said 2 and was wrong |

**Scope settled:** compliant host. Content type + schema + examples, a Vite
middleware MCP mock (transposing phase-7's `vite-plugin-agui-mock.ts`, no second
process), an `AppRenderer`/`AppFrame` surface plus sandbox proxy, five
trust-boundary gates, and `scaffold-react-vite-mcp-ui.sh`.

**Rejected:** extending `template-mcp` (stdio transport, poor cohesion) and
`scaffold-react-vite-axum.sh` as precedent (build-time embed, not a dev API).

**Tooling gap found:** `build-review-packet.sh` includes neither
`decision-log.md` nor a phase `evidence/` directory, so operator decisions and
vendored upstream artifacts are invisible to the judge. Worked around by
vendoring and re-citing; the builder should include both by default.

**Structural finding (F-1):** MCP-UI transfers *less* substrate than phase-8's
reflection implied. The payload is HTML in a sandboxed iframe, not an event
stream or component tree, and the identifying marker is a URI scheme (`ui://`),
not a message shape — so the store/reduce/render architecture that dominated
p7-04 and p8-04 does not carry over. What does: the thin-wrapper scaffolder
pattern, the repaired ESLint enforcement, and the browser-DOM smoke gate.

**New risk class (F-5):** first host phase where rendered content is
*server-supplied HTML* rather than validated data. Sandbox policy, link-scheme
validation, and postMessage origins need their own gates — a phase verifying
only "it renders" would verify the least important property.

**Repo-level fix made:** `.kbd-orchestrator/constraints.md` listed
`tools/template-forge-rs` as a submodule. It is not — `git submodule status`
names only `shared/sycophancy-correction` and `tools/rust-mcp-filesystem`.
`template-forge-rs` is first-party in-tree Rust containing an editable MCP server
(`template-mcp`), which is why G-2 is smaller than "build an MCP server from
nothing." The error dated from `/kbd-init` and was caught only because an
adversarial reviewer raised a CRITICAL against a *correct* finding that
contradicted it.

---

## Phase-8 outcome

| | |
|---|---|
| Changes | 5/5 archived |
| Tasks | 106 done, 0 open |
| Acceptance | 5/6 substantively met, 1 superseded by the G-8 decision |
| Sessions | 2 (estimated 2–3) |
| Adversarial review | 8 rounds, 33 findings, 33/33 verified correct |

**Shipped:** `direct:a2ui` aligned to the real A2UI v1.0 protocol, plus
`scaffold-react-vite-a2ui.sh`. A freshly scaffolded app builds, lints, and
renders agent-described UI under `pnpm dev` — verified in a **browser DOM** with
Playwright, closing the equivalent of phase-7's only PARTIAL.

**The reframing:** A2UI is a real external protocol (16,230 stars, Apache-2.0,
four independent ports) and ours was not it. Specs our refiner validated were not
A2UI documents. Operator chose alignment over renaming — a breaking change that
invalidated both shipped examples.

**Six pre-existing defects found**, the most consequential being that the
built-in validator implemented `oneOf` as `anyOf` and lacked `not`/`anyOf`
entirely — so every schema guard was silently inert.

`openspec/specs/` now holds 7 capabilities (was empty before phase-7).

---

## Completed phases (14)

phase-0-unblock · phase-rust-workspace-bootstrap · phase-1-submodule-topology ·
phase-sc-extraction · phase-1b-inference-routing · phase-2-scaffold-react-vite ·
phase-3-conversion-layer · phase-prefer-endpoint-consumption ·
phase-4-scaffold-tauri-desktop · phase-3b-aux-conversions · polish-pass ·
phase-3c-brand-data-extend · phase-7-scaffold-ag-ui-host ·
**phase-8-scaffold-a2ui-host**

## Deferred

`phase-6-scaffold-flutter` (largest divergence — Dart, Riverpod, least reuse)

`phase-9-scaffold-mcp-ui` is no longer deferred — assessed, precondition
discharged, awaiting the G-7 go/no-go above.

---

## Open follow-ups

- **HIGH — G-7:** `prometheus kbd` returns `committedLocally: true` for writes
  that never reach the audit log. Reproduced across every phase-8 stage.
  **The filesystem remains authoritative for KBD records.**
- **Protocol version skew:** schema validates A2UI **v1.0**; `@a2ui/react@0.10.2`
  implements **v0.9**. Translated at one boundary; `deleteSurface` /
  `callFunction` / `actionResponse` are reduced into state but reported as
  unrendered rather than silently dropped.
- `@a2ui/*` and `@ag-ui/*` are pre-1.0, pinned exact. `@a2ui/markdown-it` is
  declared `*` upstream; npm publish lags the repo ~6 weeks.
- Five unpinned `unpkg@latest` loads in `a2ui-preview-template.html` — tracked
  deferral; the template may be superseded by the runtime renderer.
- `CLAUDE.md:54` contradicts `CLAUDE.md:31` on whether skills go in
  `plugin.json`. Flagged since phase-7, still unfixed.
- Tooling gaps: `kbd-analyze` ships without `research-pipeline.md` or
  `library-candidates.schema.json`; `adversarial-review`'s packet builder handles
  only the native-kbd spec layout, so spec-stage vets are assembled by hand.
- 14 unarchived OpenSpec changes predating phase-7.
- **Nothing committed this session.** `git status` shows the full working tree.
