# AG-UI Spec Validation

## ADDED Requirements

### Requirement: Event kind vocabulary matches the AG-UI protocol

The validator SHALL accept exactly the event kinds defined by the AG-UI
protocol as shipped in `@ag-ui/core`, and SHALL reject any other value in
`event_emission[].on_event`.

The vocabulary SHALL have a single source of truth:
`references/schemas/ag-ui-spec.schema.json` → `definitions.agEventKind.enum`.
`scripts/normalize-agui.mjs` SHALL read that enum at runtime rather than
maintaining its own copy.

This requirement is newly captured as a spec. It documents behaviour p7-02
established: before this change the vocabulary contained 14 kinds, one of which
(`TOOL_CALL_ARGS_DELTA`) is not an AG-UI event kind, and the normalizer
duplicated the list by hand rather than deriving it.

#### Scenario: A conformant spec using TOOL_CALL_ARGS validates

- **GIVEN** an AG-UI spec whose `event_emission` includes an entry with
  `on_event: "TOOL_CALL_ARGS"`
- **WHEN** `scripts/normalize-agui.mjs` validates it
- **THEN** validation succeeds and the normalizer exits 0

#### Scenario: A spec using the non-existent TOOL_CALL_ARGS_DELTA is rejected

- **GIVEN** an AG-UI spec whose `event_emission` includes an entry with
  `on_event: "TOOL_CALL_ARGS_DELTA"`
- **WHEN** `scripts/normalize-agui.mjs` validates it
- **THEN** validation fails with `kind: "invalid_event_kind"`, the error names
  the offending value, and the normalizer exits non-zero

#### Scenario: Step, reasoning, and passthrough kinds are accepted

- **GIVEN** an AG-UI spec using `STEP_STARTED`, `STEP_FINISHED`,
  `REASONING_MESSAGE_START`, `REASONING_MESSAGE_CONTENT`,
  `REASONING_MESSAGE_END`, `REASONING_MESSAGE_CHUNK`, `TOOL_CALL_CHUNK`,
  `TOOL_CALL_RESULT`, or `RAW`
- **WHEN** `scripts/normalize-agui.mjs` validates it
- **THEN** validation succeeds — these are protocol kinds the vocabulary
  previously omitted

#### Scenario: The normalizer cannot drift from the schema

- **GIVEN** the schema enum and the normalizer's accepted-kind set
- **WHEN** the two are compared
- **THEN** they are identical by construction, because the normalizer derives
  its set from the schema at runtime rather than duplicating it
