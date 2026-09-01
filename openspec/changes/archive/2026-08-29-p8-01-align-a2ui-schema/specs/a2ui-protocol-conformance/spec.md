# A2UI Protocol Conformance

## ADDED Requirements

### Requirement: direct:a2ui artifacts conform to the A2UI v1.0 protocol

`direct:a2ui` SHALL denote messages of the A2UI v1.0 agent-to-renderer protocol
defined by `a2ui-project/a2ui`, not a locally-invented format. The schema SHALL
record its upstream authority so the contract cannot drift unnoticed.

#### Scenario: A conformant createSurface message validates

- **GIVEN** a message with `version` and a `createSurface` carrying `surfaceId`,
  `catalogId`, and a flat `components` array whose parent-child links are id
  strings
- **WHEN** it is validated against the schema
- **THEN** validation succeeds

#### Scenario: A message carrying two operations is rejected

- **GIVEN** a message containing both `createSurface` and `deleteSurface`
- **WHEN** it is validated
- **THEN** validation fails — the envelope permits exactly one operation

#### Scenario: The pre-alignment dialect is rejected

- **GIVEN** a document shaped `{version, metadata, bindings, root}` with a `type`
  discriminator
- **WHEN** it is validated
- **THEN** validation fails, so specs authored against the former local format
  cannot pass as protocol messages

#### Scenario: Expression leaves are rejected

- **GIVEN** a component whose leaf value is an object carrying `expression` or
  `kind`
- **WHEN** it is validated
- **THEN** validation fails — the protocol has no expression language, and
  arbitrary expression evaluation is a code-execution hazard

#### Scenario: Data-model pointers and literals are accepted

- **GIVEN** a leaf that is a JSON primitive, or an object `{"path": "/pointer"}`
- **WHEN** it is validated
- **THEN** validation succeeds

#### Scenario: The schema states its upstream provenance

- **GIVEN** the schema file
- **WHEN** it is inspected
- **THEN** it names the target catalog and references the upstream project, so a
  reader can tell it expresses an external protocol rather than defining one
