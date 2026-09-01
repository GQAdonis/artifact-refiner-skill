# Tasks: p9-03 — MCP-UI example corpus

**Scope** (files this change may edit):

```
examples/mcp-ui-refinement/
```

Read-only inputs: `references/schemas/mcp-ui-resource.schema.json`,
`scripts/normalize-mcp-ui.mjs`.

---

## 1. Positive fixtures

- [x] 1.1 `examples/mcp-ui-refinement/rawhtml-resource.json` — a `ui://`
      resource, **`mimeType: "text/html;profile=mcp-app"`** (the MCP Apps
      spelling both shipped packages emit), self-contained markup with a heading
      and a button. **This is the fixture p9-04's live gate drives**, so it must
      use the spelling the client actually produces.
- [x] 1.2 The HTML must post `{ type: 'ui-lifecycle-iframe-ready' }` to
      `window.parent` on load, and listen for
      `ui-lifecycle-iframe-render-data`. That is the lifecycle the host wires in
      p9-04, and a fixture that omits it cannot exercise the handshake.
- [x] 1.3 `examples/mcp-ui-refinement/legacy-mimetype-resource.json` — the same
      shape as 1.1 but with the bare `text/html` spelling instead of
      `text/html;profile=mcp-app`. Proves both admitted mimeType branches
      validate. Fixture-only; p9-04's live gate uses the MCP Apps spelling, which
      is what the shipped packages emit.
- [x] 1.4 `examples/mcp-ui-refinement/README.md` — what each fixture proves,
      which are live-exercised and which are validation-only, and the upstream
      citation.

## 2. Negative fixtures — five, one per check they must reach

**Construction rule for all five.** Each fixture must be well-formed in every
respect *except* the one defect it tests, so p9-02's precedence rule reaches
that check. A fixture with two defects reports only the first, and would pass
its gate for the wrong reason — indistinguishable from a correct rejection.

- [x] 2.1 `broken-scheme.json` — `uri` is `https://example.com/widget`, not
      `ui://`. Otherwise complete: `type: "resource"`,
      `mimeType: "text/html;profile=mcp-app"`, non-empty `text`, no
      `script`/`framework`/`iframeUrl`. Pins the URI-scheme marker.
      Expected violation: **`uri_scheme`**.
- [x] 2.2 `broken-unsupported-mime.json` — `mimeType: "application/json"`, a
      value neither branch admits. Otherwise complete: valid `ui://` uri,
      non-empty `text`, no out-of-scope keys. Pins the mimeType allowlist.
      Expected violation: **`unsupported_mime`**.
      (There is no `remoteDom` *mimeType* to test — p9-01 task 1.3b rejects that
      shape structurally, and fixture 2.4 covers it.)
- [x] 2.3 `broken-missing-content.json` — a well-formed `ui://` resource with
      `mimeType: "text/html"` and **no `text`**. Pins the requirement that a
      declared mimeType arrives with its payload.
      Otherwise complete: valid `ui://` uri, no out-of-scope keys.
      Expected violation: **`missing_content`**, per p9-02's precedence
      (`uri_scheme → unsupported_mime → missing_content →
      unsupported_content_shape → schema_violation`). Do **not** name `blob` in this fixture: p9-01 task 1.1
      narrows the schema to text-only payloads, so a `blob` key would be rejected
      as an unknown property and the fixture would fail for a different reason
      than it tests.

      **No fixture proves `oneOf` is genuine exclusivity.** A first-match-wins
      implementation rejects every constructible negative here too. That proof is
      p9-01 task 1.5b's duplicate-branch probe, which is transient by nature —
      a static fixture cannot carry two values in one `mimeType` field.
- [x] 2.4 `broken-remotedom-shape.json` — a `remoteDom` payload. **Must be
      well-formed in every earlier respect** so p9-02's precedence reaches the
      shape check: a valid `ui://` uri, `mimeType: "text/html;profile=mcp-app"`,
      a non-empty `text`, **plus** `script` and `framework`. Omitting `text`
      would report `missing_content` instead and the fixture would test the
      wrong thing. Expected violation: **`unsupported_content_shape`**, naming
      `script`.
- [x] 2.5 `broken-externalurl-shape.json` — an `externalUrl` payload, same
      construction: valid uri, admitted mimeType, non-empty `text`, **plus**
      `iframeUrl`. Pins p9-01 task 1.3c independently of 2.4 — the proposal
      claims the corpus pins *both* out-of-scope shapes, and one fixture cannot
      pin two decisions. Expected violation: **`unsupported_content_shape`**,
      naming `iframeUrl`.

## 3. Verification

- [x] 3.1 Each positive fixture: `node scripts/normalize-mcp-ui.mjs <f>` exits 0.
- [x] 3.2 Each negative fixture exits 1 **and names its expected violation**:
      `uri_scheme`, `unsupported_mime`, `missing_content`,
      `unsupported_content_shape`, `unsupported_content_shape` respectively —
      the names p9-02's precedence rule guarantees for these specific fixtures.
      **No fixture expects `schema_violation`**: it is p9-02's catch-all (task
      3.4b), and manufacturing a fixture for a catch-all defeats its purpose. Assert the name, not just the exit
      code — phase-8's lesson that a rejection for the wrong reason is not a
      passing test.
- [x] 3.3 All fixtures parse as JSON:
      `for f in examples/mcp-ui-refinement/*.json; do python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$f"; done`
- [x] 3.4 The `rawHtml` fixture's markup is self-contained — no external script
      or style URLs. Grep for `src=` and `href=` pointing off-origin. (The
      preview template's five unpinned `unpkg@latest` loads are a standing
      deferral in this repo; do not add a sixth.)
- [x] 3.5 `bash scripts/validate-marketplace.sh` exits 0.
- [x] 3.6 Constraint `no-hardcoded-secrets` — the standing gate scans
      `scripts/ prompts/ references/`. **This change writes only to
      `examples/`, which the gate does not scan at all.** Run the secret grep
      over `examples/mcp-ui-refinement/` explicitly as a supplementary check.
      ```bash
      grep -rInE "(api[_-]?key|secret|token|password|BEGIN [A-Z ]*PRIVATE KEY)[\"'[:space:]]*[:=]" examples/mcp-ui-refinement/
      ```
      Expect no matches.
      Fixtures carry HTML and URLs, so this is not a formality: a plausible-looking
      token in example markup would ship uncaught.
