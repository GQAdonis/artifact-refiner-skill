# A2UI Protocol Conformance

## ADDED Requirements

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
