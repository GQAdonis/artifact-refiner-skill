# mcp-ui-resource-conformance Specification

## Purpose
TBD - created by archiving change p9-01-mcp-ui-content-type. Update Purpose after archive.

## Requirements

### Requirement: direct:mcp-ui denotes MCP-UI resources as defined upstream

`direct:mcp-ui` SHALL denote a `ui://` resource embedded in an MCP tool-call
result, as defined by `MCP-UI-Org/mcp-ui` and the MCP Apps extension — not a
locally-invented format. The schema SHALL record its upstream authority, the
package versions it was encoded against, and the location of the vendored type
declarations, so the contract cannot drift unnoticed.

#### Scenario: A conformant MCP Apps resource validates

- **GIVEN** an embedded resource with `type: "resource"`, a `uri` beginning
  `ui://`, `mimeType: "text/html;profile=mcp-app"`, and non-empty `text`
- **WHEN** it is validated against `references/schemas/mcp-ui-resource.schema.json`
- **THEN** validation succeeds

#### Scenario: The legacy mimeType spelling also validates

- **GIVEN** the same resource with bare `mimeType: "text/html"`
- **WHEN** it is validated
- **THEN** validation succeeds, so a producer that does not use the MCP Apps
  adapter is still conformant

#### Scenario: A resource whose URI is not ui:// is rejected

- **GIVEN** a resource whose `uri` is `https://example.com/widget`
- **WHEN** it is validated
- **THEN** validation fails — the protocol's identifying marker is the URI
  scheme, not the payload shape

#### Scenario: An unrecognised mimeType is rejected

- **GIVEN** a resource with `mimeType: "application/json"`
- **WHEN** it is validated
- **THEN** validation fails — the mimeType allowlist is closed

### Requirement: Out-of-scope content shapes are rejected structurally

`remoteDom` and `externalUrl` SHALL be rejected. Upstream models both as distinct
content shapes rather than mimeType variants, so there is no mimeType literal to
exclude; the schema SHALL reject them by refusing their carrier properties.

#### Scenario: A remoteDom payload is rejected

- **GIVEN** a resource that is otherwise conformant but additionally carries
  `script` and `framework`
- **WHEN** it is validated
- **THEN** validation fails, because the resource object admits no additional
  properties

#### Scenario: An externalUrl payload is rejected

- **GIVEN** a resource that is otherwise conformant but additionally carries
  `iframeUrl`
- **WHEN** it is validated
- **THEN** validation fails for the same reason

### Requirement: Schema exclusivity is enforced, not merely declared

The schema's delivery-mode branches SHALL be genuinely exclusive under the
validator that ships in this repository. A guard that is inert against the actual
validator is not a guard.

#### Scenario: A duplicated branch causes a conformant resource to be rejected

- **GIVEN** a copy of the schema with one delivery-mode branch duplicated
- **WHEN** a conformant resource is validated against that copy
- **THEN** validation fails, reporting that more than one branch matched —
  proving `oneOf` is exclusive rather than first-match-wins
- **AND** the same resource still validates against the unmodified schema

### Requirement: MCP-UI is detected by URI scheme, never by payload content

Content-type detection SHALL key on the `ui://` URI scheme. It SHALL NOT key on
the presence of HTML, because an MCP-UI resource carries an HTML payload and a
content-based heuristic would capture every `direct:html` artifact.

#### Scenario: An HTML artifact with no ui:// URI is not classified as MCP-UI

- **GIVEN** an artifact containing HTML markup but no embedded resource with a
  `ui://` URI
- **WHEN** content-type detection runs
- **THEN** it is not classified as `direct:mcp-ui`
