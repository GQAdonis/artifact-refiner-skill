# mcp-ui-normalization Specification

## Purpose
TBD - created by archiving change p9-02-mcp-ui-normalizer. Update Purpose after archive.

## Requirements

### Requirement: Violations are reported by name in a fixed precedence order

`scripts/normalize-mcp-ui.mjs` SHALL report a named violation for a
non-conformant resource, and SHALL evaluate checks in a fixed order so that a
document exhibiting several defects always reports the same one:

`uri_scheme` → `unsupported_mime` → `missing_content` →
`unsupported_content_shape` → `schema_violation`

Without a fixed order, a fixture written to test one check could report another
and pass its gate for a non-diagnostic reason.

#### Scenario: A conformant resource is accepted

- **GIVEN** a resource with a `ui://` uri, an admitted mimeType, and non-empty `text`
- **WHEN** the normalizer runs
- **THEN** it exits 0

#### Scenario: A non-ui:// uri reports uri_scheme

- **GIVEN** a resource whose `uri` is `https://example.com/widget`
- **WHEN** the normalizer runs
- **THEN** it exits 1 and reports `uri_scheme`, naming the offending value

#### Scenario: An unrecognised mimeType reports unsupported_mime

- **GIVEN** a resource with `mimeType: "application/json"`
- **WHEN** the normalizer runs
- **THEN** it exits 1 and reports `unsupported_mime`, listing the admitted values

#### Scenario: A missing payload reports missing_content

- **GIVEN** a resource with an admitted mimeType but no `text`
- **WHEN** the normalizer runs
- **THEN** it exits 1 and reports `missing_content`

#### Scenario: An out-of-scope content shape reports unsupported_content_shape

- **GIVEN** a resource that is otherwise conformant but carries `script`,
  `framework`, or `iframeUrl`
- **WHEN** the normalizer runs
- **THEN** it exits 1 and reports `unsupported_content_shape`, naming the key found

### Requirement: Constraints are derived from the schema, never restated

The normalizer SHALL read the admitted mimeTypes and the uri pattern from
`references/schemas/mcp-ui-resource.schema.json` at runtime. It SHALL NOT
restate them as literals, so the script cannot drift from the schema it
enforces.

#### Scenario: Altering the schema's uri pattern changes the normalizer's behaviour

- **GIVEN** a copy of the schema whose uri pattern is changed to `^zz://`
- **WHEN** a conformant `ui://` resource is validated against that copy
- **THEN** it is rejected with `uri_scheme`, proving the pattern is read rather
  than hard-coded
- **AND** the same resource still passes against the unmodified schema

#### Scenario: Removing a mimeType branch changes the accepted set

- **GIVEN** a copy of the schema with the legacy `text/html` branch removed
- **WHEN** a `text/html` resource is validated against that copy
- **THEN** it is rejected with `unsupported_mime`, listing only the remaining value

### Requirement: The shipped JSON Schema validator is reused, not reimplemented

The normalizer SHALL reuse the validator from `scripts/normalize-a2ui.mjs` —
the one repaired in phase-8 to implement genuine `oneOf` exclusivity — rather
than hand-rolling a second one. A separate implementation would mean these gates
exercise code that does not ship.

#### Scenario: Exclusivity holds through the normalizer

- **GIVEN** a copy of the schema with one delivery-mode branch duplicated
- **WHEN** a conformant resource is validated through the normalizer against
  that copy
- **THEN** it is rejected, reporting that more than one branch matched

### Requirement: The schema is never mutated to run a test

Tests requiring a modified schema SHALL operate on a copy, selected through a
schema-path override. The repository's schema SHALL NOT be altered even
transiently, since a run aborting mid-test would leave the tree broken.

#### Scenario: A schema path override is honoured

- **GIVEN** a modified schema written to a scratch location
- **WHEN** the normalizer is invoked with `--schema <that path>`
- **THEN** it validates against the copy, and the repository schema is unchanged
