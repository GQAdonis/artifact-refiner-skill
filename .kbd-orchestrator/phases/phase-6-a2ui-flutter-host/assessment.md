# Assessment — phase-6-a2ui-flutter-host

- **Date:** 2026-09-01
- **Scope (revised):** not "scaffold Flutter" generically — **an A2UI host for
  Flutter with rendering parity to the web host**
- **Why this phase:** `hybrid-mobile-architecture-src` holds the
  `a2ui-surface-contract` skill, which requires *"equivalent semantics across
  supported surfaces"* and *"cross-platform rendering parity."* Web parity
  shipped in phase-8; MCP parity shipped in phase-9. **Mobile has none.**

---

## F-1 — The mobile project's `A2uiEvent` is not A2UI

**This is the third phase running where a local artifact diverges from the
external standard it is named after**, and the first found *before* building on
top of it.

`hybrid-mobile-architecture-src/assets/templates/rust/gen_ui_types/src/events.rs:81`

```rust
pub enum A2uiEvent {
    RunStarted    { run_id }, RunPhaseChanged { run_id, phase, status, message },
    Block         { run_id, block: ContentBlock },
    RunFinished   { run_id }, RunCancelled { … }, RunError { … },
    ContextTelemetry { … },
}
```

Real A2UI v1.0 has six operations: `createSurface`, `updateComponents`,
`updateDataModel`, `deleteSurface`, `callFunction`, `actionResponse`.
**Overlap with the above: zero.**

What it actually models is an **AG-UI-shaped run lifecycle**. `RunStarted` /
`RunFinished` / `RunError` correspond to AG-UI's `RUN_STARTED` / `RUN_FINISHED` /
`RUN_ERROR`, and the file's own comment cites a "27-variant set" — the order of
AG-UI's 23 event kinds, not A2UI's 6 operations.

**Severity: this is a naming collision, not necessarily a defect.** A run-event
stream is a legitimate thing to have; A2UI describes *surfaces*, AG-UI describes
*runs*, and an agent needs both. The problem is that the name claims a protocol
the type does not implement, so a reader wiring "the A2UI path" on mobile would
reach for the wrong seam.

**Do not rename it unilaterally.** It is a frozen seam per the project's own
records, and its consumers are outside this repo. Escalate.

## F-2 — There is no Flutter A2UI rendering path at all

| Artifact | State |
|---|---|
| `scripts/scaffold-flutter.sh` | a 12-line deprecation shim → `builder new --profile flutter-mobile` |
| `profiles/flutter-mobile/runnable/mobile/pubspec.yaml` | **5 lines, zero dependencies** |
| `templates/flutter-feature/` | clean-architecture CRUD slice — screen, entity, repository, provider, test |
| `a2ui_flutter` / `a2ui_core` references | **none anywhere in the project** |

So the Flutter generator produces a well-structured app with **no agent-UI
rendering**. This is genuinely greenfield, unlike phase-9 which had to correct a
shipped content type.

## F-3 — CORRECTED: `a2ui_flutter` is an empty placeholder; `genui` is the renderer

My first pass recommended `a2ui_flutter` on the strength of its
`github.com/flutter/genui` provenance. **Downloading it settled that
immediately, and the answer inverts the risk assessment.**

`a2ui_flutter@0.0.1-wip002` — **1,890 bytes, 52 lines of Dart** — is the
unmodified `dart create` template:

```dart
/// Support for doing something awesome.
class Awesome {
  bool get isAwesome => true;
}
```

README: *"TODO: add readme"*. It is a **reserved package name with no
implementation**. Calling it "pre-alpha" was too generous.

**The real packages, found by following its dependency:**

| Package | Version | Releases | Upstream | Role |
|---|---|---|---|---|
| `a2ui_core` | 0.1.1 | 5 | **`a2ui-project/a2ui`** — same org as `@a2ui/react` | model + messages, 31 files / 3,918 LOC, **no Flutter import** |
| `genui` | **0.10.2** | 11 | (renderer) | **77 files / 11,377 LOC, 12 widget classes** |

`genui` is the Dart counterpart of `@a2ui/react`, and `a2ui_core` of
`@a2ui/web_core`. It renders the same catalog vocabulary the web host does —
`Card`, `Column`, `Text`, `Button`, `Row` — and carries the **same version
number, 0.10.2**, as the web renderer.

Maturity is therefore comparable to what phase-8 already shipped on, not worse:

| | version | releases |
|---|---|---|
| `@a2ui/react` (web, shipped) | 0.10.2 | 20+ |
| **`genui` (Flutter)** | **0.10.2** | **11** |

**G-6 is effectively resolved:** the pre-alpha risk I flagged was attached to the
wrong package. This is a normal pre-1.0 dependency of the kind this repo already
depends on.

## F-4 — G-2 ANSWERED: Dart speaks v0.9, the same version as the web renderer

This was the question gating the estimate. **`a2ui_core@0.1.1` implements
v0.9** — string-matched in its own sources, and confirmed structurally:

| A2UI v1.0 operation | present in `a2ui_core` |
|---|---|
| `createSurface` · `updateComponents` · `updateDataModel` · `deleteSurface` | yes |
| `callFunction` · `actionResponse` | **absent** |

That absence is the v0.9 signature — the web SDK omits the same two. And
`CreateSurfaceMessage` carries `surfaceId` + `catalogId` with **no `components`
field**, which is exactly the v0.9 split shape.

**Consequence: no third protocol version, and the SAME translation applies.**
The `toV09Messages()` written for the MCP-UI guest — retarget `catalogId`, split
v1.0's inline `components`/`dataModel` into three v0.9 messages — transfers
directly to Dart. Parity stays a two-version property across three surfaces
rather than becoming a three-version one.

This is the best answer G-2 could have had.

---

## Gaps

| ID | Gap | Severity |
|---|---|---|
| G-1 | No Flutter A2UI host: no renderer integration, no surface widget, no state layer | BLOCKING |
| G-2 | ~~protocol version unknown~~ **RESOLVED: v0.9, same as web** | closed |
| G-3 | No Flutter scaffolder in *this* repo; the generator lives in the mobile project | BLOCKING (ownership question) |
| G-4 | No parity harness — nothing proves web and Flutter render the same document the same way | HIGH |
| G-5 | `A2uiEvent` naming collision (F-1) | HIGH — escalate, do not fix here |
| G-6 | ~~`a2ui_flutter` maturity~~ **RESOLVED: wrong package; `genui@0.10.2` is comparable to what phase-8 shipped** | closed |
| G-7 | No Flutter toolchain verified on this machine | MEDIUM |

## Open questions — one left

~~1. G-6 maturity~~ — **closed by F-3.** The pre-alpha risk was attached to
`a2ui_flutter`, which turned out to be an empty placeholder. The real renderer
`genui@0.10.2` is a normal pre-1.0 dependency, same version as the web one.

1. **G-3 — where does the Flutter scaffolder live?** The mobile project owns
   Flutter generation today (`builder new --profile flutter-mobile`). This repo
   owns the A2UI/MCP-UI hosts. Options: (a) this repo emits Flutter A2UI assets
   the mobile builder consumes; (b) this repo ships a
   `scaffold-flutter-a2ui.sh` mirroring the web wrapper; (c) the work happens in
   the mobile project instead. **This is an architecture decision, not a
   detail** — and picking wrong means building in the wrong repo.

3. **G-5 — escalate the `A2uiEvent` name?** It is a frozen seam with consumers
   outside this repo. Flagging is right; renaming unilaterally is not.

## What I recommend

**Proceed, once G-3 is answered.** The two things that could have made this
expensive are both resolved:

- the renderer is real and mature enough (`genui@0.10.2`, 11 releases, same
  version as the shipped web renderer);
- the protocol version matches, so the existing translation transfers rather
  than a third one being invented.

The shape is the same as phase-8: adopt a renderer, wrap it in a store/hook/
surface, prove it renders in a real runtime. The one genuinely new thing is a
**parity harness** (G-4) — the same A2UI document driven through the web host
and the Flutter host, asserting equivalent output. That is what makes
"cross-platform rendering parity" a tested property rather than a claim, and it
is the deliverable the mobile project's contract actually asks for.

## Estimate

**2 sessions**, contingent on G-3 and on a working Flutter toolchain (G-7,
unverified on this machine).

Stated with the caveat that phase-9's estimate moved twice: down when research
removed assumed work, then up when shipped types contradicted documentation.
Here the equivalent research is already done — the packages are downloaded and
read, not inferred.

---

# SPIKE RESULT — parity proven before planning

Run 2026-09-01, after the assessment above. The spike test is preserved at
`spike-a2ui-parity-test.dart` in this directory.

## Toolchain (G-7 — closed)

```
Flutter 3.48.0-0.1.pre (beta) · Dart 3.14.0    genui needs >=3.10.0 — satisfied
```

## What was proven

A Flutter widget test rendered **the same `source.a2ui.json`** the AG-UI web
host and the MCP-UI guest render, and asserted **the same observable facts** the
browser gate asserts:

```
PARITY OK: heading + body + 2 buttons, same as the web host
00:00 +1: All tests passed!
```

- `find.text('Enable notifications')` — heading
- `find.textContaining('Get alerts')` — body
- **two** `ButtonStyleButton`s labelled `Enable` / `Not now`

**Cross-platform rendering parity is now a demonstrated property, not a claim** —
which is what `a2ui-surface-contract` asks for.

## The API, read rather than inferred

Three of my first guesses were wrong; all three were settled by reading the
package. Recording them so the implementation does not re-derive them:

| Guessed | Actual |
|---|---|
| `CoreCatalogItems.asCatalog()` | **`BasicCatalogItems.asCatalog()`** |
| `A2uiMessage.fromMap()` | **`A2uiMessage.fromJson()`** |
| `controller.surfaces[...]` | **`controller.contextFor(surfaceId)`** |

The rendering pipeline is a direct analogue of the web host:

```
SurfaceController(catalogs: [BasicCatalogItems.asCatalog()])   ~ MessageProcessor([basicCatalog])
  .handleMessage(A2uiMessage.fromJson(m))                      ~ .processMessages(msgs)
  .contextFor(surfaceId)  ->  Surface(surfaceContext: ctx)     ~ <A2uiSurface surface={…} />
```

`SurfaceController implements A2uiMessageSink` and wraps `core.MessageProcessor`
internally — the same class name as the web SDK, because both come from
`a2ui-project/a2ui`.

## The translation transfers unchanged

`toV09()` in the spike is a line-for-line port of `toV09Messages()` from the
MCP-UI guest: retarget `catalogId` to `basicCatalogId`, split v1.0's inline
`components`/`dataModel` into three v0.9 messages. **It worked first time.**

Confirms F-4: no third protocol version, one translation shared by three
surfaces.

## One correction to F-3

`genui@0.10.2` resolves `a2ui_core@**0.0.1-wip002**`, not the `0.1.1` I inspected
from pub.dev. The renderer pins an older core than the latest published. Not a
problem — it works — but the pin must be recorded, and a future bump to
`a2ui_core@0.1.x` is a change to verify, not assume.

## Revised gaps

| ID | State |
|---|---|
| G-1 Flutter A2UI host | open — but the API path is now known end to end |
| G-2 protocol version | **closed** — v0.9, same translation |
| G-3 scaffolder ownership | **decided: this repo**, as `scaffold-flutter-a2ui.sh` |
| G-4 parity harness | **prototyped** — the spike IS the harness; it needs packaging as a shipped asset |
| G-5 `A2uiEvent` naming | open — escalate, do not fix here |
| G-6 renderer maturity | **closed** — `genui@0.10.2`, comparable to the shipped web renderer |
| G-7 toolchain | **closed** — Flutter 3.48 / Dart 3.14 present and working |

## Estimate — now grounded

**1–2 sessions.** Lower than the assessment's 2 because the spike removed the
two unknowns that would have consumed the first: which renderer, and how to
drive it. What remains is packaging — a store/hook/surface trio in Dart, the
parity test as a shipped asset, and the scaffolder that emits them.
