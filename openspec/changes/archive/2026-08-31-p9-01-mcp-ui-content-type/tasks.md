# Tasks: p9-01 — `direct:mcp-ui` content type and schema

**Scope** (files this change may edit):

```
references/schemas/content-type.schema.json
references/schemas/mcp-ui-resource.schema.json
references/domain/mcp-ui.md
references/content-types.md
prompts/meta-controller.md
prompts/specify.md
SKILL.md
```

---

## 1. Schema

- [x] 1.1 Create `references/schemas/mcp-ui-resource.schema.json`. Root is the
      `EmbeddedResource` shape: `type: "resource"` (const) and a `resource`
      object with `uri`, `mimeType`, and `text`.
      **`blob` is permitted by the MCP SDK's `EmbeddedResource` but not by this
      schema**: the one in-scope delivery mode is inline markup, so a base64
      payload adds a second encoding path with nothing to exercise it. Every
      branch in 1.3 requires `text`. State that narrowing in the `$comment`, so a
      reader does not mistake it for an oversight.
- [x] 1.2 Constrain `uri` to `^ui://` via `pattern`. This is the protocol's
      identifying marker — a URI scheme, not a message shape (assess F-1).
- [x] 1.3 Model the delivery modes as a `oneOf` over **branches**, not over a
      single scalar. `mimeType` alone cannot express exclusivity — one string
      field holds one value, so a `oneOf` across `mimeType` consts is
      unfalsifiable. Each branch pairs the mimeType with its required payload:
      - branch A — `mimeType: "text/html;profile=mcp-app"`, requires `text`
      - branch B — `mimeType: "text/html"`, requires `text`

      **Use these exact literals.** `text/html;profile=mcp-app` is the MCP Apps
      mimeType and is what `@mcp-ui/client@7.1.1` and
      `@modelcontextprotocol/ext-apps@1.7.5` both emit — verified by grepping
      the installed packages, where the string appears in each. Bare `text/html`
      is the legacy equivalent and is admitted so a non-MCP-Apps producer still
      validates. **`text/uri-list` appears in neither package**; do not use it.
- [x] 1.3b **`remoteDom` is rejected structurally, not by mimeType.** Upstream
      carries it as `content: { type: 'remoteDom', script, framework }` — a
      distinct content shape, not a distinct mimeType — so there is no
      `remoteDom` mimeType literal to exclude. Reject it by requiring `text` and
      admitting no `script`/`framework` properties
      (`additionalProperties: false` on the resource object). Record this in the
      `$comment`: a reader looking for an excluded mimeType will not find one.
- [x] 1.3c **`externalUrl` is out of scope for v1.** Analyze Q3 assumed it was a
      mimeType variant; upstream models it as
      `content: { type: 'externalUrl', iframeUrl }`, another content shape. Since
      neither shipped package exposes a `text/uri-list` mimeType, supporting it
      would mean guessing at a wire format. Out of scope, and p9-03's corpus
      changes accordingly.
- [x] 1.4 Add a `$comment` provenance block naming `@mcp-ui/client@7.1.1`, its
      Apache-2.0 license, and the vendored declarations under
      `.kbd-orchestrator/phases/phase-9-scaffold-mcp-ui/evidence/`.
- [x] 1.5 **Zero-branch rejection.** A fixture matching no branch —
      `mimeType: "application/json"`, a value neither branch admits — must be
      rejected. This proves the branches constrain *something*. It does **not**
      distinguish real `oneOf` from first-match-wins (both reject it), which is
      why 1.5b exists and is not optional.
- [x] 1.5b Add a temporary third branch to the schema that duplicates branch A
      exactly, then validate a conformant `rawHtml` fixture. A genuine `oneOf`
      **rejects** it (two branches match); a first-match-wins implementation
      accepts it. Remove the duplicate branch afterward. **This is the only test
      that distinguishes real `oneOf` from `anyOf`**, and it is the check phase-8
      lacked.
- [x] 1.6 `python3 -c "import json; json.load(open(…))"` on both schemas.

## 2. Content type registration

- [x] 2.1 Add `direct:mcp-ui` to the enum in
      `references/schemas/content-type.schema.json` (currently 12 entries;
      `direct:a2ui` at line 13 and `direct:ag-ui` at line 14 are the models).
- [x] 2.2 Document the type in `references/content-types.md` — direct (not
      meta), evaluation strategy `output_inspection`.
- [x] 2.3 Add the routing row to the Content Type Routing table in
      `prompts/meta-controller.md`, mapping `direct:mcp-ui` →
      `references/domain/mcp-ui.md`.
- [x] 2.4 Add detection heuristics to `prompts/specify.md`: a `ui://` URI, or
      an MCP tool result carrying an embedded resource. **The heuristic must key
      on the URI scheme**, not on HTML content — otherwise every `direct:html`
      artifact matches.
- [x] 2.5 Add the domain row to the table in root `SKILL.md`.

## 3. Domain adapter

- [x] 3.1 Create `references/domain/mcp-ui.md` following the shape of
      `references/domain/a2ui.md`.
- [x] 3.2 Document the transport: the resource rides **inside a tool result's
      `content` array**, not fetched via `resources/read` (D-002). State that
      `resources/*` is optional for a server, and cite `isUIResource` being
      typed against `EmbeddedResource` as the evidence.
- [x] 3.3 Document the client side: `@mcp-ui/client@7.1.1` exports
      `AppRenderer` and `AppFrame` — **and explicitly note that
      `UIResourceRenderer` does not exist in this version** despite appearing in
      upstream docs. This is the exact trap analyze fell into; the adapter is
      where a future reader will look.
- [x] 3.4 Document the sandbox posture: a hosted proxy is mandatory, and the
      library default is `allow-scripts allow-same-origin allow-forms` — safe
      only if the proxy is genuinely cross-origin (D-006).
- [x] 3.5 Cite upstream: repo, license, package versions, and the vendored
      evidence path.

## 4. Verification

**Validator and fixtures.** p9-02's normalizer does not exist yet, so these
gates need a validator of their own. Use a **scratchpad harness**: a short Node
script that loads `mcp-ui-resource.schema.json` and validates with the same
built-in validator `scripts/normalize-a2ui.mjs` uses (imported, not copied — it
is the one with real `oneOf`/`anyOf`/`not` after phase-8). Fixtures for these
gates are scratchpad-local; the durable corpus is p9-03's.

Name them concretely so the gates are reproducible:

```
<scratch>/p9-01-validate.mjs          # the harness
<scratch>/fixtures/ok-mcp-app.json    # 4.1  text/html;profile=mcp-app + text
<scratch>/fixtures/ok-legacy.json     # 4.2  text/html + text
<scratch>/fixtures/bad-scheme.json    # 4.3  https:// uri
<scratch>/fixtures/bad-shape.json     # 4.4  script + framework
<scratch>/fixtures/bad-mime.json      # 4.5  application/json
```

Each gate is then `node <scratch>/p9-01-validate.mjs <fixture>`, exit 0 or 1.
Record the resolved `<scratch>` path in the change notes.

If the harness cannot import the `normalize-a2ui.mjs` validator, **say so and
stop** — writing a second ad-hoc validator here would test a different
implementation than the one that ships, which is precisely how phase-8's `oneOf`
defect stayed invisible.

- [x] 4.1 A conformant `rawHtml` resource validates.
- [x] 4.2 A conformant resource using the bare `text/html` spelling validates,
      proving both admitted mimeType branches work.
- [x] 4.3 A resource whose `uri` lacks the `ui://` scheme is **rejected**.
- [x] 4.4 A `remoteDom`-shaped resource (carrying `script` and `framework`) is
      **rejected** by the `additionalProperties` guard from 1.3b — there is no
      `remoteDom` mimeType to test, which is the point of that task.
- [x] 4.5 The zero-branch fixture from 1.5 is **rejected**.
- [x] 4.6 The duplicate-branch probe from 1.5b **rejects** a conformant fixture
      while the duplicate is present, and accepts it once removed. This is the
      test that proves `oneOf` is genuine exclusivity rather than first-match.
- [x] 4.7 `bash scripts/validate-marketplace.sh` exits 0.
- [x] 4.8 Every `references/…` path newly cited resolves. Scan **every path this
      change edits**, not only `prompts/` — `SKILL.md` and
      `references/content-types.md` can introduce citations too:
      `grep -roh 'references/[a-zA-Z0-9/_.-]*' prompts/ references/ SKILL.md | sort -u | while read f; do [ -e "$f" ] || echo "MISSING $f"; done`
- [x] 4.9b Constraint `no-brand-leakage` — the gate scans
      `prompts/ skills/ agents/ references/ assets/ README.md SKILL.md`
      (`*.md` only). This change writes `references/domain/mcp-ui.md`,
      `references/content-types.md`, two `prompts/` files and `SKILL.md`, all
      covered. Run it:
      ```bash
      grep -rn 'sediment://' prompts/ skills/ agents/ references/ assets/ README.md SKILL.md --include='*.md'
      ```
      Expect no matches.
- [x] 4.9 Constraint `no-hardcoded-secrets` — the standing gate scans
      `scripts/ prompts/ references/`. This change edits `prompts/` and
      `references/` (covered) **and `SKILL.md`, which the gate does not scan**.
      Run the secret grep over `SKILL.md` explicitly as a supplementary check and
      record it as such.
      ```bash
      grep -rInE "(api[_-]?key|secret|token|password|BEGIN [A-Z ]*PRIVATE KEY)[\"'[:space:]]*[:=]" SKILL.md
      ```
      Expect no matches. Phase-8 lost two review rounds to constraints claimed
      over paths they did not cover; naming the uncovered file is the fix, not
      asserting the gate is sufficient.
