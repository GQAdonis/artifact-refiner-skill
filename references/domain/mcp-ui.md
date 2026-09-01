MCP-UI Refiner Module

Domain

MCP-UI Resources (A2UI over MCP Apps)

── WHY THIS EXISTS ─────────────────────────────────────────────────────────────

An agent exposes MCP, HTTP, A2A, and AG-UI endpoints simultaneously. A client may
arrive over any of them, and the UI must be THE SAME regardless.

A2UI is the shared vocabulary. MCP-UI is one ENVELOPE that carries it:

    A2UI surface  ──┬── AG-UI transport      → web host      (phase-8, shipped)
                    ├── MCP-UI resource      → MCP clients   (this module)
                    └── a2ui_flutter         → mobile host   (planned)

So `direct:mcp-ui` does NOT admit arbitrary HTML. A `ui://` resource MUST carry
`a2ui` messages, validated against the same schema the AG-UI host uses. Free-form
markup here would let the MCP surface drift from the other two — the exact
inconsistency this content type exists to prevent.

**This works because the A2UI renderer is FED messages, not a fetcher.**
`MessageProcessor.processMessages()` takes an array, so the surface renders with
`connect-src: none` — the MCP-UI sandbox default. The `text` field holds a
generated host page with the messages inline; it is scaffolding, not authored
content.

Content type: `direct:mcp-ui`
Schema: `references/schemas/mcp-ui-resource.schema.json`
Example: `examples/mcp-ui-refinement/`

Upstream authority

MCP-UI is **not defined by this repository**. It is an external protocol built on
the Model Context Protocol:

  Repository:  https://github.com/MCP-UI-Org/mcp-ui   (Apache-2.0)
  Client:      @mcp-ui/client        7.1.1  (npm, Apache-2.0)
  Server:      @mcp-ui/server        6.1.0  (npm, Apache-2.0) — NOT adopted here
  MCP Apps:    @modelcontextprotocol/ext-apps  1.7.5  (npm, MIT)
  MCP SDK:     @modelcontextprotocol/sdk       1.30.0 (npm, MIT)

  Context7 library ids: /mcp-ui-org/mcp-ui · /websites/mcpui_dev

**Read the vendored type declarations, not the documentation.** Verbatim copies
of the shipped `.d.ts` files live at:

  .kbd-orchestrator/phases/phase-9-scaffold-mcp-ui/evidence/

Reproduce with `npm install @mcp-ui/client@7.1.1` and a diff. This is not
ceremony — see "Traps" below, where documentation and shipped code disagree on
something load-bearing.

---

Transport — the resource rides inside a tool result

An MCP-UI resource is an **`EmbeddedResource` element of a tool-call result's
`content` array**. It is *not* fetched with `resources/read`:

```json
{
  "content": [
    { "type": "text", "text": "Here is your chart" },
    {
      "type": "resource",
      "resource": {
        "uri": "ui://demo/chart",
        "mimeType": "text/html;profile=mcp-app",
        "text": "<!DOCTYPE html>…",
        "a2ui": [{ "version": "v1.0", "createSurface": { "…": "…" } }]
      }
    }
  ]
}
```

Evidence: `evidence/mcp-ui-client-7.1.1--isUIResource.d.ts` types its predicate
against `EmbeddedResource` imported from `@modelcontextprotocol/sdk/types.js` —
a `content`-array element type. The client's own discrimination helper therefore
operates on an item of a tool result.

**Consequence: `resources/list` and `resources/read` are OPTIONAL.** A server
implementing only `initialize`, `tools/list`, and `tools/call` can serve MCP-UI.

The one qualification: `AppRenderer` will *fetch* the resource when it is not
given pre-fetched `html`. Pass `html` and the three methods suffice; omit it and
the host forwards `resources/read` to its MCP client. The host's configuration
and the server's method set are one decision, not two.

---

Identification — a URI scheme, not a message shape

AG-UI is identified by event kinds, A2UI by envelope operations. **MCP-UI is
identified by a URI scheme:**

```ts
mcpResource.type === 'resource' && mcpResource.resource.uri?.startsWith('ui://')
```

`isUIResource` from `@mcp-ui/client` narrows the *shape* (`type === 'resource'`)
and says nothing about the scheme. **Both checks are needed** — the library
predicate alone will accept a non-`ui://` resource.

Never key detection on HTML content: the payload of an MCP-UI resource *is*
`text/html`, so a content-based heuristic captures every `direct:html` artifact.

---

Client — what actually ships in 7.1.1

Complete export surface of `@mcp-ui/client@7.1.1`
(`evidence/mcp-ui-client-7.1.1--index.d.ts`):

  AppRenderer · AppFrame · AppBridge · PostMessageTransport
  isUIResource · getUIResourceMetadata · getResourceMetadata
  UI_EXTENSION_NAME · UI_EXTENSION_CONFIG · UI_EXTENSION_CAPABILITIES

| Component | Takes | Use when |
|---|---|---|
| `AppRenderer` | a live MCP `client` *or* `onReadResource`/`onCallTool` callbacks; optional pre-fetched `html` | default choice; manages the full lifecycle |
| `AppFrame` | pre-fetched `html` + a hand-built `AppBridge` | you already hold the HTML and want the smaller surface |

Both require `sandbox: { url }` — a **hosted sandbox proxy HTML page**. There is
no in-process rendering path.

---

Traps

**1. `UIResourceRenderer` does not exist in 7.1.1.**
Upstream documentation still shows it for "legacy hosts". It is absent from the
shipped `index.d.ts`, and `dist/src/components/` contains only `AppRenderer.d.ts`
and `AppFrame.d.ts`. Code written from the docs will fail on the import.

**2. `@modelcontextprotocol/ext-apps` is not optional.**
It is a declared dependency of `@mcp-ui/client` (`^1.2.0`) and is re-exported by
it (`AppBridge`, `PostMessageTransport`). It arrives transitively whether or not
you name it.

**3. The mimeType is `text/html;profile=mcp-app`, not bare `text/html`.**
That exact string appears in both `@mcp-ui/client@7.1.1` and
`@modelcontextprotocol/ext-apps@1.7.5` — verified by grepping the installed
packages. Bare `text/html` is the legacy spelling; the schema admits both.
**`text/uri-list` appears in neither package.**

**4. `remoteDom` and `externalUrl` are content SHAPES, not mimeTypes.**
Upstream carries them as `{type:'remoteDom', script, framework}` and
`{type:'externalUrl', iframeUrl}`. There is no mimeType to exclude, so the schema
rejects them structurally via `additionalProperties: false`. Both are out of
scope for `direct:mcp-ui`.

**5. The schema's `oneOf` branches are deliberately self-contained.**
Each repeats `required`, `additionalProperties`, and the `uri` pattern rather
than sharing them with sibling keywords. The validator returns as soon as it has
evaluated `oneOf`, so anything placed beside `oneOf` in the same object is never
reached — a natural-looking schema would leave those constraints silently inert.
Verified by fixture.

---

Security — the trust boundary

This is the first content type in this repository where **the rendered content is
supplied by the server** rather than validated as data. The iframe is the
boundary, and it needs deliberate configuration.

**The library default is permissive.** From
`evidence/mcp-ui-client-7.1.1--AppFrame.d.ts`, `SandboxConfig.permissions`:

> *default: `"allow-scripts allow-same-origin allow-forms"`*

`allow-scripts` together with `allow-same-origin` lets framed content escape the
sandbox. Upstream's mitigation is that the sandbox proxy runs on a **separate
origin**, so `allow-same-origin` names the proxy's origin rather than the host
app's. **That mitigation holds only if the proxy genuinely is cross-origin** —
serving it from another path on the same dev server silently voids it.

Five controls, each verified separately:

| Control | Requirement |
|---|---|
| iframe sandbox | drop `allow-same-origin`, **or** prove the proxy is cross-origin. Assert the *rendered* attribute, not the source |
| CSP | pass `SandboxConfig.csp`; prefer the query-parameter form so the proxy can set real headers |
| link schemes | `onOpenLink` rejects anything but `http(s)` |
| postMessage sender | an opaque frame (no `allow-same-origin`) posts with `origin: "null"`, which **any** opaque frame can present — pair the origin check with `event.source === iframe.contentWindow` |
| `ui://` discrimination | a non-`ui://` resource must not render as MCP-UI |

A host that verifies only "it renders" has verified the least important property.

---

Normalization

`scripts/normalize-mcp-ui.mjs` enforces what JSON Schema cannot, and reports
violations by name in a fixed precedence order:

  uri_scheme → unsupported_mime → missing_content
             → unsupported_content_shape → schema_violation

Precedence matters: several violations can be true of one document, and a fixture
written to test one check must not report another.

---

Refinement focus

When refining a `direct:mcp-ui` artifact, evaluate in this order:

1. **Conformance** — `ui://` scheme, admitted mimeType, non-empty `text`, no
   out-of-scope content-shape keys.
2. **Self-containment** — the HTML must not load off-origin scripts or styles.
   It renders in a sandbox with a CSP; external references will be blocked, and
   an unpinned CDN load is a supply-chain dependency in someone else's page.
3. **Lifecycle** — the guest posts `ui-lifecycle-iframe-ready` on load and
   listens for `ui-lifecycle-iframe-render-data`. Without the first, the host
   never completes the handshake.
4. **Accessibility** — the payload is real DOM in a real browser. Headings,
   roles, and focus order apply exactly as they would anywhere else.
5. **Failure behaviour** — unknown methods and render errors must surface
   visibly rather than hanging. A silent stall is worse than a loud failure.
