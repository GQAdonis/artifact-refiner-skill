# mcp-ui-example-corpus Specification

## Purpose
TBD - created by archiving change p9-03-mcp-ui-examples. Update Purpose after archive.

## Requirements

### Requirement: The corpus pins each scope decision with its own fixture

`examples/mcp-ui-refinement/` SHALL carry one negative fixture per
fixture-reachable check, each well-formed in every respect except the single
defect it tests. A fixture carrying two defects reports only the first and
would pass its gate for the wrong reason.

#### Scenario: Every negative fixture reports its expected violation by name

- **GIVEN** the five negative fixtures
- **WHEN** each is passed to `scripts/normalize-mcp-ui.mjs`
- **THEN** each exits 1 and reports exactly the violation it was written to
  test: `uri_scheme`, `unsupported_mime`, `missing_content`, and
  `unsupported_content_shape` for both the `remoteDom` and `externalUrl` shapes

#### Scenario: Both out-of-scope content shapes are pinned separately

- **GIVEN** `broken-remotedom-shape.json` carries `script` and `framework`, and
  `broken-externalurl-shape.json` carries `iframeUrl`
- **WHEN** each is validated
- **THEN** both are rejected, and each names the key it carried — one fixture
  cannot pin two independent scope decisions

### Requirement: Both admitted mimeType spellings are covered

The corpus SHALL prove that the MCP Apps spelling and the legacy spelling both
validate, so a producer that does not use the MCP Apps adapter is not silently
excluded.

#### Scenario: The MCP Apps spelling validates

- **GIVEN** `rawhtml-resource.json` with `mimeType: "text/html;profile=mcp-app"`
- **WHEN** it is validated
- **THEN** it exits 0

#### Scenario: The legacy spelling validates

- **GIVEN** `legacy-mimetype-resource.json` with bare `mimeType: "text/html"`
- **WHEN** it is validated
- **THEN** it exits 0

### Requirement: The live fixture is renderable and self-contained

The fixture driven by the render host SHALL carry the guest half of the iframe
lifecycle and SHALL load nothing off-origin, because it renders inside a
sandbox under a CSP.

#### Scenario: The fixture performs the lifecycle handshake

- **GIVEN** `rawhtml-resource.json`
- **WHEN** its markup is inspected
- **THEN** it posts `ui-lifecycle-iframe-ready` to `window.parent` on load and
  listens for `ui-lifecycle-iframe-render-data`

#### Scenario: The fixture loads no external resources

- **GIVEN** the same fixture
- **WHEN** its markup is scanned for `src` and `href` attributes pointing to
  another origin
- **THEN** none are found
