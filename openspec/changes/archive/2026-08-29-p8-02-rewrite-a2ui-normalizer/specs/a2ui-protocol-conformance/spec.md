# A2UI Protocol Conformance

## ADDED Requirements

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
