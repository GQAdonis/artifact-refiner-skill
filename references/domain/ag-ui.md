AG-UI Spec Refiner Module

Domain

AG-UI Agent Specification Artifacts

Content type: `direct:ag-ui`
Schema: `references/schemas/ag-ui-spec.schema.json`
Example: `examples/ag-ui-spec-refinement/`
Spike: `references/domain/ag-ui-spike.md`

Purpose

Refine AG-UI agent specifications into valid, normalized, schema-compliant artifacts
ready for integration into AG-UI compatible frontends and CopilotKit-based applications.

This module ensures that AG-UI specs are structurally correct, have consistent tool
naming, valid event emission rules, and no cross-reference violations — before the spec
reaches a production agent runtime.

---

Inputs
  - specification (from Specify phase)
  - plan (from Plan phase)
  - existing AG-UI JSON/YAML specification (optional)

---

Responsibilities
  1. Validate structural integrity of the AG-UI spec
  2. Enforce schema compliance against `ag-ui-spec.schema.json`
  3. Verify cross-reference integrity (tool names, event kinds)
  4. Normalize structure and field ordering
  5. Detect deprecated or invalid event kind references
  6. Ensure required fields are present (version, agent, tools, event_emission)
  7. Generate a binding coverage report
  8. Persist normalized spec and coverage metadata to disk

---

Deterministic Execution Triggers

Invoke code_interpreter when:
  - Validating against JSON schema
  - Checking tool-name cross-references in event_emission rules
  - Reformatting JSON/YAML
  - Generating binding coverage reports
  - Resolving custom event kind validity
  - Running structural validation scripts (`scripts/normalize-agui.mjs`)

---

Common Constraints
  - Valid JSON or YAML syntax
  - Schema compliance (`ag-ui-spec.schema.json`)
  - Required properties present: `version`, `agent`, `tools`, `event_emission`
  - Tool names match `^[a-z_][a-z0-9_]*$` (snake_case)
  - Every `event_emission[].tool` references a declared tool name
  - Every `event_emission[].on_event` is a valid AG-UI event kind
  - Custom event kinds match `^CUSTOM_[A-Z_]+$`
  - No duplicate tool names
  - No duplicate (tool, on_event) pairs in event_emission

---

Valid AG-UI Event Kinds

Standard event kinds recognized by the validator:

  Run lifecycle:
  - RUN_STARTED
  - RUN_FINISHED
  - RUN_ERROR

  Step lifecycle:
  - STEP_STARTED
  - STEP_FINISHED

  Text message:
  - TEXT_MESSAGE_START
  - TEXT_MESSAGE_CONTENT
  - TEXT_MESSAGE_END
  - TEXT_MESSAGE_CHUNK

  Tool call:
  - TOOL_CALL_START
  - TOOL_CALL_ARGS (carries a `delta` field — the *event* is not named `_DELTA`)
  - TOOL_CALL_END
  - TOOL_CALL_CHUNK
  - TOOL_CALL_RESULT

  Reasoning message:
  - REASONING_MESSAGE_START
  - REASONING_MESSAGE_CONTENT
  - REASONING_MESSAGE_END
  - REASONING_MESSAGE_CHUNK

  State and passthrough:
  - STATE_SNAPSHOT
  - STATE_DELTA
  - MESSAGES_SNAPSHOT
  - RAW
  - CUSTOM (requires a matching entry in `custom_events`)

  Source of truth: `references/schemas/ag-ui-spec.schema.json`
  → `definitions.agEventKind.enum`, which `scripts/normalize-agui.mjs` reads at
  runtime rather than duplicating. The list above mirrors the 23 kinds shipped in
  `@ag-ui/core@0.0.59`; re-derive with:

  ```
  npm pack @ag-ui/core@<version> && tar -xzf ag-ui-core-<version>.tgz
  grep -oE '"(RUN|STEP|TEXT_MESSAGE|TOOL_CALL|REASONING_MESSAGE|STATE|MESSAGES|RAW|CUSTOM)[A-Z_]*"' \
    package/dist/index.js | tr -d '"' | sort -u
  ```

---

Validation Checklist

During Execute and Reflect phases, validate:
  - Spec parses without error
  - Schema validation passes
  - Required fields exist
  - All event_emission tool references resolve to declared tools
  - All event_emission on_event values are valid AG-UI event kinds
  - No duplicate tool names
  - No duplicate (tool, on_event) emission rules
  - Custom event kinds conform to naming convention
  - Coverage report generated (if requested)

---

Expected Outputs
  - Normalized AG-UI spec file
  - Validation report (JSON)
  - Binding coverage report (JSON) — which tools emit which events
  - Updated artifact_manifest.json

---

Reflection Focus
  - Cross-reference integrity (tools ↔ event_emission)
  - Schema alignment
  - Naming convention compliance
  - Completeness of tool definitions (description, parameter schema)
  - Forward compatibility with the AG-UI event kind registry

---

Termination Conditions

Refinement ends when:
  - Spec validates successfully against schema
  - All cross-reference constraints satisfied
  - No structural violations remain
  - Coverage report is complete and attached to manifest
