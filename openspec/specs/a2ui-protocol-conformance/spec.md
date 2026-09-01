# a2ui-protocol-conformance Specification

## Purpose
TBD - created by archiving change p8-01-align-a2ui-schema. Update Purpose after archive.

## Requirements

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

### Requirement: Structural rules JSON Schema cannot express are enforced by the normalizer

`scripts/normalize-a2ui.mjs` SHALL enforce the A2UI structural constraints that
JSON Schema cannot express — component id uniqueness, id-reference resolution,
acyclicity, reachability, and data-model pointer resolution — and SHALL derive
its accepted component vocabulary from the schema rather than duplicating it.

#### Scenario: A cycle in the id-reference graph is rejected

- **GIVEN** components whose `child` references form a cycle
- **WHEN** the normalizer runs
- **THEN** it exits non-zero with a `reference_cycle` violation naming the
  participating ids

#### Scenario: A component unreachable from the root is rejected

- **GIVEN** a surface containing a component no other component references, and
  which is not the surface root
- **WHEN** the normalizer runs
- **THEN** it exits non-zero with an `unreachable_component` violation

#### Scenario: A dangling id reference is rejected

- **GIVEN** a `child` or `children` entry naming an id no component declares
- **WHEN** the normalizer runs
- **THEN** it exits non-zero with a `dangling_reference` violation

#### Scenario: A duplicate component id is rejected

- **GIVEN** two components sharing an `id`
- **WHEN** the normalizer runs
- **THEN** it exits non-zero — a later entry would otherwise shadow an earlier one

#### Scenario: A dead data-model pointer is rejected

- **GIVEN** a leaf `{"path": "/missing"}` that resolves to nothing in `dataModel`
- **WHEN** the normalizer runs
- **THEN** it exits non-zero with a `dead_data_pointer` violation

#### Scenario: An expression-like leaf is rejected with a named error

- **GIVEN** a leaf object carrying `expression` or `kind`
- **WHEN** the normalizer runs
- **THEN** it exits non-zero with an `expression_leaf` violation stating that
  A2UI has no expression language and that arbitrary evaluation is a
  code-execution hazard

#### Scenario: A pre-alignment document is rejected by name

- **GIVEN** a document in the former local dialect
- **WHEN** the normalizer runs
- **THEN** the report names the format explicitly, ahead of generic schema
  errors, so the holder learns which format they have rather than only that
  validation failed

#### Scenario: The accepted vocabulary comes from the schema

- **GIVEN** the schema's component-name definition
- **WHEN** the normalizer validates component names
- **THEN** it reads that definition at runtime and records in its report which
  check mode applied, so the strictness actually enforced is visible

### Requirement: The example corpus exercises the protocol it documents

The shipped `direct:a2ui` examples SHALL be A2UI v1.0 protocol messages, and the
corpus SHALL exercise data-model binding, id-reference nesting, and interaction —
not only static structure — so a consumer that ignores any of those cannot pass.

The corpus SHALL retain a negative fixture in the superseded local dialect, so a
regression toward it fails visibly rather than silently.

#### Scenario: The positive example normalizes clean

- **GIVEN** the shipped positive example
- **WHEN** the normalizer runs
- **THEN** it exits 0 and writes a normalized message and report

#### Scenario: The positive example exercises data binding

- **GIVEN** the shipped positive example
- **WHEN** its leaves are inspected
- **THEN** at least two are `{"path": …}` references resolved against `dataModel`,
  so a renderer ignoring data binding cannot produce correct output

#### Scenario: The positive example exercises nesting and interaction

- **GIVEN** the shipped positive example
- **WHEN** its components are inspected
- **THEN** parent-child structure is expressed by `children` id references, and
  at least one component carries an `action` with an `event`

#### Scenario: A cycle fixture is rejected

- **GIVEN** the shipped circular fixture
- **WHEN** the normalizer runs
- **THEN** it exits non-zero with a `reference_cycle` violation

#### Scenario: The superseded dialect is rejected by name

- **GIVEN** the shipped legacy-dialect fixture
- **WHEN** the normalizer runs
- **THEN** it exits non-zero and reports `legacy_dialect` before any generic
  schema error, so the format is identified rather than merely rejected

#### Scenario: Documentation describes only executable steps

- **GIVEN** the execution prompts for `direct:a2ui`
- **WHEN** they are followed
- **THEN** every step they instruct is one the repository can actually perform;
  no step directs an HTML template injection that no code implements
