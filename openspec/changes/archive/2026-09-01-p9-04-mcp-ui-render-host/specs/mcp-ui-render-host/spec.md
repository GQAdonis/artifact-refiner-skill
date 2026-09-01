# MCP-UI Render Host

## ADDED Requirements

### Requirement: An MCP-UI resource renders its A2UI surface in a sandboxed iframe

The host SHALL render the A2UI messages carried by a `ui://` resource, using the
same renderer the AG-UI web host uses, so a surface is identical across
transports.

#### Scenario: A2UI components render as real DOM

- **GIVEN** an MCP server returning a `ui://` resource whose `a2ui` array
  describes a card with two buttons
- **WHEN** the host renders it
- **THEN** the guest frame contains two interactive buttons with the labels from
  the A2UI document, asserted by role in a live browser

#### Scenario: The renderer is inlined, not fetched

- **GIVEN** the guest runs in an opaque-origin iframe with `connect-src: none`
- **WHEN** the surface renders
- **THEN** it succeeds without any network request, because the renderer is
  bundled into the resource's `text`

### Requirement: The guest translates v1.0 documents for the v0.9 renderer

Our schema validates A2UI v1.0; the pinned renderer implements v0.9. The host
SHALL translate at one boundary, mirroring the AG-UI web host.

#### Scenario: The catalog id is retargeted

- **GIVEN** a v1.0 document naming the v1.0 catalog URL
- **WHEN** the guest processes it
- **THEN** the catalogId is replaced with the renderer's own catalog id, and no
  "Catalog not found" error occurs

#### Scenario: Inline components are split into v0.9 messages

- **GIVEN** a v1.0 `createSurface` carrying `components` and `dataModel` inline
- **WHEN** the guest processes it
- **THEN** it emits `createSurface`, `updateComponents`, and `updateDataModel`,
  and the surface populates rather than remaining at "[Loading root...]"

### Requirement: The iframe trust boundary is enforced and verifiable

The guest SHALL run as an opaque origin, and sender validation SHALL NOT rely on
origin alone.

#### Scenario: The rendered sandbox omits allow-same-origin

- **GIVEN** a rendered surface
- **WHEN** the guest iframe's `sandbox` attribute is read from the live DOM
- **THEN** it contains `allow-scripts` and does **not** contain
  `allow-same-origin`

#### Scenario: A forged sender with the right origin is refused

- **GIVEN** an opaque guest whose messages carry `origin: "null"`
- **WHEN** a message arrives with that origin but a different `source`
- **THEN** it is refused, because origin alone cannot authenticate an opaque frame

#### Scenario: Unsafe link schemes are refused

- **GIVEN** guest content requesting `javascript:` or `data:` navigation
- **WHEN** the host's link handler evaluates it
- **THEN** it is refused; only `http(s)` is opened
