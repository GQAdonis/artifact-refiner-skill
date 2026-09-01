# MCP-UI Refinement Corpus

Fixtures for `direct:mcp-ui`. Validate with:

```bash
node scripts/normalize-mcp-ui.mjs --input examples/mcp-ui-refinement/<file>
```

Exit 0 = valid. Exit 1 = a **named** violation on stdout (`VIOLATION <name>`),
with detail on stderr.

## Upstream

MCP-UI is an external protocol, not defined by this repository.

- `MCP-UI-Org/mcp-ui` (Apache-2.0) · `@mcp-ui/client@7.1.1`
- MCP Apps: `@modelcontextprotocol/ext-apps@1.7.5` (MIT)
- Schema: `references/schemas/mcp-ui-resource.schema.json`
- Adapter: `references/domain/mcp-ui.md`
- Vendored type declarations:
  `.kbd-orchestrator/phases/phase-9-scaffold-mcp-ui/evidence/`

## Positive fixtures

| File | Proves | Live-exercised? |
|---|---|---|
| `rawhtml-resource.json` | A conformant MCP Apps resource validates | **yes** — this is the fixture p9-04's browser gate renders |
| `legacy-mimetype-resource.json` | Bare `text/html` also validates | validation only |

Both carry the same self-contained HTML: it posts
`ui-lifecycle-iframe-ready` on load and listens for
`ui-lifecycle-iframe-render-data`, which is the handshake the render host
depends on. A fixture omitting that cannot exercise the bridge.

The markup loads **nothing off-origin**. It renders inside a sandbox with a CSP,
so external references would be blocked — and an unpinned CDN load would put a
third-party supply chain inside someone else's page.

## Negative fixtures

Five, one per fixture-reachable check. Each is well-formed in every respect
*except* the single defect it tests — a fixture carrying two defects only ever
reports the first, and would pass its gate for the wrong reason.

| File | Expected violation | Pins |
|---|---|---|
| `broken-scheme.json` | `uri_scheme` | the `ui://` scheme is the identifying marker |
| `broken-unsupported-mime.json` | `unsupported_mime` | the mimeType allowlist is closed |
| `broken-missing-content.json` | `missing_content` | a declared mimeType must arrive with its payload |
| `broken-remotedom-shape.json` | `unsupported_content_shape` | `remoteDom` is out of scope |
| `broken-externalurl-shape.json` | `unsupported_content_shape` | `externalUrl` is out of scope |

The last two are separate fixtures on purpose: they pin two independent scope
decisions, and one fixture cannot pin two.

### Why there is no "both delivery modes" fixture

Delivery mode is carried by a single `mimeType` string, so "both modes present"
is not constructible — one field holds one value. And a fixture matching *zero*
branches proves nothing about exclusivity: a correct `oneOf` and a broken
first-match-wins implementation both reject it.

Genuine exclusivity is proven by a **transient duplicate-branch probe**: copy the
schema, duplicate one branch, and confirm a conformant fixture is then rejected
with `Matched 2 oneOf branches`. That cannot live in a static corpus. It is
p9-01 task 1.5b and p9-02 task 2.3, run against scratchpad copies — the repo
schema is never mutated.

## Out of scope

`remoteDom` and `externalUrl`. Upstream models both as distinct *content shapes*
(`{type:'remoteDom', script, framework}`, `{type:'externalUrl', iframeUrl}`),
not as mimeType variants — and no `text/uri-list` mimeType exists in either
shipped package. Supporting them would mean inventing a wire format.
