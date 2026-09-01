A2UI Refiner Module

Domain

A2UI (Agent-to-UI) Protocol Messages — v1.0

Content type: `direct:a2ui`
Schema: `references/schemas/a2ui-component.schema.json`
Example: `examples/a2ui-component-refinement/`

Upstream authority

A2UI is **not defined by this repository**. It is an external protocol:

  Repository:  https://github.com/a2ui-project/a2ui  (Apache-2.0)
  Spec:        specification/v1_0/docs/a2ui_protocol.md
  Common types: specification/v1_0/common_types.json  (ComponentCommon, DynamicString)
  Basic catalog: specification/v1_0/catalogs/basic/catalog.json
  Renderer:    @a2ui/react (npm, Apache-2.0)

Those paths live upstream, not here. Re-verify before changing anything in this
module:

  Context7 library id: /a2ui-project/a2ui

This citation block exists because its absence is what allowed drift: an earlier
version of this module described a locally-invented format under the A2UI name,
and nothing pointed at the real specification to contradict it.

⸻

A2UI is streaming-first

Messages arrive **progressively** from an agent to a renderer over a JSON Lines
transport — the protocol is not a single static document. A surface is created,
then updated; the renderer applies each message as it arrives.

This matters for anything consuming A2UI: a host accumulates a message stream
into renderable state. It does not fetch one document and render it once.

⸻

Message model

Every message is an object carrying `version` plus **exactly one** operation:

  createSurface     create a surface: components + optional dataModel
  updateComponents  merge components into an existing surface, by id
  updateDataModel   merge values into the surface data model
  deleteSurface     remove a surface
  callFunction      invoke a catalog-declared function
  actionResponse    respond to an action

Two operations in one message is invalid, not a convenience.

⸻

Components are a flat array

Components are a **flat list**, not a nested tree. Parent-child structure is
expressed by **id reference**:

  {
    "version": "v1.0",
    "createSurface": {
      "surfaceId": "main",
      "catalogId": "basic",
      "components": [
        {"id": "root",   "component": "Card",   "child": "node_0"},
        {"id": "node_0", "component": "Column", "children": ["node_1", "node_2"]},
        {"id": "node_1", "component": "Text",   "text": {"path": "/title"}},
        {"id": "node_2", "component": "Button", "child": "node_3",
                          "action": {"event": {"name": "accept"}}},
        {"id": "node_3", "component": "Text",   "text": "Yes"}
      ],
      "dataModel": {"title": "Enable notification"}
    }
  }

`component` — not `type` — is the discriminator, and its value is a PascalCase
name declared by the catalog.

⸻

Data binding

A leaf value is either a literal JSON primitive or a **pointer into the data
model**:

  "text": "Yes"                  literal
  "text": {"path": "/title"}     resolved against dataModel

There is no expression language. An object carrying `expression` or `kind` is
rejected — arbitrary expression evaluation is a code-execution hazard, and the
protocol provides catalog-declared `functions` for computed behaviour instead.

⸻

Inputs
	•	specification (from Specify phase)
	•	plan (from Plan phase)
	•	existing A2UI message or message stream (optional)

⸻

Responsibilities
	1.	Validate the envelope: exactly one operation, valid `version`
	2.	Enforce schema compliance
	3.	Verify component id uniqueness
	4.	Resolve `child` / `children` id references; reject dangling ids
	5.	Detect cycles in the id-reference graph
	6.	Reject components unreachable from the root
	7.	Resolve `{"path": …}` leaves against `dataModel`; reject dead pointers
	8.	Validate component names against the declared catalog
	9.	Normalize structure and field ordering
	10.	Persist the normalized message and a report to disk

⸻

Deterministic Execution Triggers

Invoke code_interpreter when:
	•	Validating against the JSON schema
	•	Indexing the flat component array by id
	•	Walking id references for cycles and reachability
	•	Resolving JSON Pointers into the data model
	•	Running `scripts/normalize-a2ui.mjs`

⸻

Common Constraints
	•	Valid JSON
	•	Schema compliance (`a2ui-component.schema.json`)
	•	Exactly one envelope operation per message
	•	`createSurface` requires `surfaceId`, `catalogId`, `components`
	•	Component ids unique within a surface
	•	Every `child` / `children` id resolves to a declared component
	•	No cycles in the id-reference graph
	•	Every `{"path": …}` resolves against `dataModel`
	•	No `expression` / `kind` objects in leaf positions
	•	Component names are PascalCase and catalog-declared

Cycle detection, reachability, and catalog membership cannot be expressed in
JSON Schema; `scripts/normalize-a2ui.mjs` enforces them.

⸻

Validation Checklist

During Execute and Reflect phases, validate:
	•	Message parses without error
	•	Schema validation passes
	•	Exactly one envelope operation present
	•	All required fields present for that operation
	•	All id references resolve
	•	No id-reference cycles
	•	All data-model pointers resolve
	•	All component names valid for the catalog

⸻

Expected Outputs
	•	Normalized A2UI message file
	•	Normalization report (errors, warnings, resolved reference counts)

⸻

Reflection Focus
	•	Did any message fail envelope validation, and why?
	•	Were dangling id references or dead pointers introduced?
	•	Did a component name fall outside the catalog?
	•	Was a rejected message actually invalid, or is the catalog incomplete?

⸻

Termination Conditions

Refinement ends when:
	•	The message validates against the schema
	•	The normalizer reports no errors
	•	All references and pointers resolve
	•	The normalized output is persisted

⸻

History

Prior to phase-8, this module described a locally-invented format —
`{version, metadata, bindings, root}` with a `type` discriminator, a nested
component tree, and `literal`/`ref`/`expression` bindings — under the A2UI name.
That format was never the A2UI protocol. Specs authored against it are not
interoperable and are rejected by the current schema.
