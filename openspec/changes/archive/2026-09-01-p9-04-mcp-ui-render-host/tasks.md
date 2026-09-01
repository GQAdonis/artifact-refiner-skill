# Tasks: p9-04 — MCP-UI render host

**Scope** (files this change may edit):

```
assets/scaffold/mcp-ui/resource-store.ts
assets/scaffold/mcp-ui/use-mcp-ui.ts
assets/scaffold/mcp-ui/mcp-ui-surface.tsx
assets/scaffold/mcp-ui/vite-plugin-mcp-mock.ts
assets/scaffold/mcp-ui/sandbox-proxy.html
assets/scaffold/mcp-ui/trust-boundary.test.ts
```

`trust-boundary.test.ts` is in scope deliberately: gates 5.3 and 5.4 are unit
tests, and a test with no file has no home. It ships with the other assets so a
scaffolded app inherits the checks rather than trusting that they once passed
here. Run it with the workspace's `vitest` (the base scaffolder provides it);
record the exact command.

Read-only: `examples/mcp-ui-refinement/` (p9-03),
`references/schemas/mcp-ui-resource.schema.json` (p9-01),
`.kbd-orchestrator/phases/phase-9-scaffold-mcp-ui/evidence/` (vendored types).

**Verification workspace.** Gates §3–§6 need a running React app, and p9-05 —
the scaffolder — does not exist yet. That is deliberate: p9-04 must be
independently verifiable, otherwise the two changes are one change and the
browser gate cannot fail until the very end of the phase.

Build the workspace **by hand, in the scratchpad**:

1. `bash scripts/scaffold-react-vite.sh --target <scratch>/mcp9ui` — the base
   scaffolder already exists and is not part of this change.
2. Copy this change's six assets into the generated tree at the paths p9-05
   will later use.
3. `pnpm add` the two pinned packages (task 1.3).
4. **Register the mock plugin** in the workspace's `vite.config.ts` — add it to
   the `plugins` array. Without this, nothing answers `POST /api/mcp` and §3's
   method discovery observes nothing.
5. **Mount `McpUiSurface`** in the workspace's `App.tsx`. Copying a component
   does not render it; without this, §6's browser gates assert against a blank
   page.
6. Copy the p9-03 fixtures where the mock reads them (`rawhtml-resource.json`
   and `broken-scheme.json`, the latter for gate 5.1).

Steps 4–6 are done **by hand here** and are exactly what p9-05 tasks 2.5, 2.7,
and 2.8 later automate — which is why p9-05's §5 gate re-runs these assertions
against scaffolded output: it proves the automation reproduces the hand-built
case rather than merely that the assets work when wired by a human.

This is a test bed, not a deliverable, and nothing under it is committed.

---

## 1. Read the types before writing code

- [x] 1.1 Read the four vendored declarations in `evidence/`. **Do not infer the
      API.** Phase-8 lost two attempts inferring `MessageProcessor` before
      reading the `.d.ts`, which settled it immediately.
- [x] 1.2 Confirm from `evidence/mcp-ui-client-7.1.1--index.d.ts` that
      `UIResourceRenderer` is absent and only `AppRenderer` / `AppFrame` /
      `AppBridge` / `isUIResource` are exported. If a newer install disagrees,
      **stop and report** — the phase's architecture rests on this.
- [x] 1.3 Install `@mcp-ui/client@7.1.1` and `@modelcontextprotocol/ext-apps@1.7.5`
      pinned **exact** in the verification workspace.

## 2. Store, hook, surface

- [x] 2.1 `resource-store.ts` — owns I/O (the `POST /api/mcp` JSON-RPC call) and
      holds the resource plus request state. Per
      `references/scaffolds/state-architecture.md`, stores own I/O.
- [x] 2.2 Discriminate with **`isUIResource` first, then an explicit `ui://`
      scheme check**. Read `evidence/mcp-ui-client-7.1.1--isUIResource.d.ts`: the
      predicate narrows to `type === 'resource'` and says nothing about the URI
      scheme, so it alone cannot satisfy gate 5.1. Use the library predicate for
      the shape and `resource.uri?.startsWith('ui://')` for the scheme — the
      combination upstream's own docs show. Export the combined predicate so 5.1
      can assert on it.
- [x] 2.3 `use-mcp-ui.ts` — reads the store; **re-exports any type the surface
      needs**. A component importing from `stores/` violates the architectural
      ESLint rule (phase-8 hit exactly this).
- [x] 2.4 `mcp-ui-surface.tsx` — reads the hook, renders `AppRenderer` with
      pre-fetched `html` (proposal decision) and `sandbox` config.
- [x] 2.5 Wire `onFallbackRequest` to **fail loudly** with the unhandled method
      name. An unhandled JSON-RPC method must not surface as a silent hang;
      phase-8's `Unknown component: Heading` is the precedent.
- [x] 2.6 Wire `onError` to surface errors in the DOM, not only the console —
      gate 6.4 asserts on rendered text.
- [x] 2.7 **Implement `onOpenLink`** with scheme validation: allow `http`/`https`,
      reject everything else (`javascript:`, `data:`, `file:`) and report the
      rejection rather than silently dropping it. Gate 5.3 tests this; without
      this task the gate would test behaviour no task produces.
- [x] 2.8 **Implement `onMessage`** with sender validation, in two steps so the
      ordering is not circular:
      **2.8a — ship permissive, log the origin.** Write an initial `onMessage`
      that accepts any sender but **logs `event.origin`**. This is a code change
      only; it observes nothing yet, so it has no dependency on later tasks.
      **2.8b — enforce, after §4 and §6 exist.** Deferred until the sandbox
      permissions (4.2) and the handshake flow (6.5) are in place: read the
      logged origin from a completed handshake, then tighten `onMessage` to
      accept only that origin **and** require
      `event.source === iframe.contentWindow`. The source check is what actually
      distinguishes our frame from a forged sender, and it is essential when the
      recorded origin is `"null"` — a value any opaque frame can present.
      Export both predicates so 5.3/5.4 can unit-test them without a browser.
      Record the observed origin in the change notes.
      **Ordering note:** 2.8b is listed here for cohesion but **runs after §4 and
      the first execution of gate 6.5**. Expect `"null"` rather than the page
      origin, since 4.2's dropped `allow-same-origin` makes the frame opaque.
      **Gate 6.5 must then be re-run against the enforced handler** (gate 6.5b).
      Without that second run, the browser gate would only ever have passed
      against the permissive version and the shipped code would be unverified —
      the handler changes underneath a green gate.

## 3. Mock — verify the method set against the running app

- [x] 3.1 Write `vite-plugin-mcp-mock.ts` as a **logging skeleton**: it answers
      `POST /api/mcp`, logs every request method it receives, and implements
      `initialize`, `tools/list`, **and `tools/call`** — the last returning the
      embedded `ui://` resource, because without it the host never obtains HTML
      and never reaches the render path 3.2 needs to observe. It deliberately
      does **not** implement `resources/*`: an unimplemented method that shows up
      in the log is exactly the signal 3.2 is looking for.
- [x] 3.2 **Determine empirically which JSON-RPC methods the host actually
      calls** when configured with pre-fetched `html`. Drive one render against
      the 3.1 skeleton and read its log. The proposal specifies three
      (`initialize`, `tools/list`, `tools/call`); if the host also calls
      `resources/read`, implement it and record that the D-003a table's first
      row was wrong. **Do not assume the specified set is correct.**
- [x] 3.2b Complete the mock with the full method set established in 3.2.
- [x] 3.3 `tools/call` returns a result whose `content` array carries a text
      entry and the embedded `ui://` resource (D-002 shape).
- [x] 3.4 The mock serves the p9-03 `rawHtml` fixture — it does not define its
      own copy. A second copy would drift from the corpus.
- [x] 3.4b **Fixture selection must be overridable**, or gate 5.1 cannot run.
      Accept a fixture name via query string (`POST /api/mcp?fixture=<name>`) or
      an env var read at plugin construction, defaulting to the `rawHtml`
      fixture. This is what lets the host be driven with `broken-scheme.json`
      to prove the discrimination path. Restrict resolution to basenames within
      the fixtures directory — a dev-only mock is still not a file-read
      primitive.
- [x] 3.5 Reject non-2.0 `jsonrpc` and unknown methods with proper JSON-RPC
      error objects, following `template-mcp`'s dispatch shape.

## 4. Sandbox proxy

- [x] 4.1 `sandbox-proxy.html` — loads the MCP Apps sandbox proxy script,
      served same-origin from the Vite dev server at a fixed path.
- [x] 4.2 The surface passes `sandbox: { url, permissions }` with `permissions`
      **overriding** the default to drop `allow-same-origin`, per the proposal.
- [x] 4.3 Pass `SandboxConfig.csp`, using the **query-parameter form** so the
      proxy can set real headers. Record which mechanism actually carries it —
      query param or postMessage fallback — because 5.5 asserts on that specific
      mechanism.

## 5. Trust-boundary gates (D-006) — five, each asserted separately

**Execution order.** Section numbers are not run order. Gates 5.1–5.3 and 5.5
run once §2–§4 are complete. **Gate 5.4 runs last**, after §6's first handshake
(6.5) has surfaced the real `event.origin` and 2.8b has been tightened against
it; 6.5b then re-verifies the handshake under enforcement. The dependency chain
is: `2.8a → 4.2 → 6.5 → 2.8b → {5.4, 6.5b}`. It is acyclic — 2.8a and 2.8b are
separate steps precisely so that it is.

- [x] 5.1 **`ui://` discrimination** — a resource whose URI is not `ui://` is not
      rendered as MCP-UI. Drive with p9-03's `broken-scheme.json`.
- [x] 5.2 **Sandbox attribute** — assert the **rendered** `sandbox` attribute in
      the DOM contains `allow-scripts` and **not** `allow-same-origin`. Read it
      off the live element, not the source. If the handshake breaks without
      `allow-same-origin`, see the proposal: fall back to a second origin,
      **do not restore the permissive default**.
- [x] 5.3 **Link schemes** — `onOpenLink` rejects non-`http(s)`. Unit-test with
      `javascript:` and `data:`.
- [x] 5.4 **postMessage origin** — a message from an unexpected origin is not
      acted on.
      Asserts the **2.8b** predicate, using the origin recorded in 2.8a — no
      re-derivation here, so there is no dependency on a later gate.
      Unit-test, calling the exported predicates directly: (a) a message from
      `https://evil.example` is ignored; (b) a message bearing the recorded
      origin but a foreign `source` is ignored. Case (b) is the one that matters
      when the recorded origin is `"null"`, since any opaque frame can present
      that value.
- [x] 5.5 **CSP reaches the frame** — assert on a **named observable**, chosen
      in this order and recorded in the change's notes:
      1. *preferred* — the proxy iframe's resolved `src` URL contains the `csp`
         query parameter, read from the live DOM element via Playwright;
      2. *if the proxy sets headers* — the `Content-Security-Policy` response
         header on the proxy request, captured from Playwright's network log;
      3. *behavioural fallback* — inject a resource the CSP should block and
         assert a CSP violation is reported.
      "Observable on the rendered frame" is not a gate until one of these is
      picked. If none is achievable, **say so and mark this gate FAILED** rather
      than restating the intent — an unfalsifiable security gate is worse than
      an absent one, because it reads as coverage.

## 6. Browser-DOM gate — non-negotiable

- [x] 6.1 Scaffold the workspace app, `pnpm install`, `pnpm build` exits 0.
- [x] 6.2 `pnpm lint` exits 0 **with the architectural rules active** — this is
      what catches 2.3's layering.
- [x] 6.3 `pnpm dev`, then drive with Playwright: the fixture's heading and
      button are present **in the rendered DOM**, asserted by role/text.
- [x] 6.4 Zero uncaught page errors during the render.
- [x] 6.5 The `ui-lifecycle-iframe-ready` handshake completes — assert the host
      observed it, proving the double-iframe bridge works end to end. First run
      is against 2.8a's permissive handler, and exists to surface the real
      `event.origin`.
- [x] 6.5b **Re-run 6.5 against 2.8b's enforced handler.** This is the run that
      counts: it proves the origin+source check accepts the legitimate frame
      rather than locking it out. A handshake verified only against the
      permissive handler verifies code that does not ship.
- [x] 6.6 Phase-7 closed with one PARTIAL because "renders in the browser" was
      verified at store level. **Store-level assertions do not satisfy 6.3.**

## 7. Constraint coverage

- [x] 7.1 `no-hardcoded-secrets` scans `scripts/ prompts/ references/`. **This
      change edits none of those** — it writes only to `assets/scaffold/mcp-ui/`.
      Run this explicitly and record it as an *additional* check, not the
      standing gate (phase-8 lost two review rounds to exactly this confusion):
      ```bash
      grep -rInE "(api[_-]?key|secret|token|password|BEGIN [A-Z ]*PRIVATE KEY)[\"'[:space:]]*[:=]" assets/scaffold/mcp-ui/
      ```
      Expect no matches.
- [x] 7.1b Constraint `no-brand-leakage` — the gate scans `assets/` but only
      `--include='*.md'`, so **none of this change's six files are covered**:
      all are `.ts`/`.tsx`/`.html`. Run the same grep without the `*.md` filter
      over `assets/scaffold/mcp-ui/` as a supplementary check:
      ```bash
      grep -rn 'sediment://' assets/scaffold/mcp-ui/
      ```
      Expect no matches.
- [x] 7.2 No `unpkg`/CDN `@latest` loads in `sandbox-proxy.html`. Five unpinned
      loads in `a2ui-preview-template.html` are a standing deferral; do not add
      more.
