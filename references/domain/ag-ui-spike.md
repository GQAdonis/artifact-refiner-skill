AG-UI Spike — Fit Assessment for PMPO Artifact Refiner

Spike scope: determine whether the PMPO Artifact Refiner is the right vehicle for
refining AG-UI specs, and if so, which artifact is being refined.

---

## What is AG-UI?

AG-UI (Agent-to-UI) is the open event-stream protocol introduced by CopilotKit that
defines how AI agents communicate with frontend applications in real time. It specifies:

- **Run lifecycle events** — `RUN_STARTED`, `RUN_FINISHED`, `RUN_ERROR`
- **Text streaming events** — `TEXT_MESSAGE_START`, `TEXT_MESSAGE_CONTENT`,
  `TEXT_MESSAGE_END`, `TEXT_MESSAGE_CHUNK`
- **Tool call events** — `TOOL_CALL_START`, `TOOL_CALL_ARGS_DELTA`, `TOOL_CALL_END`
- **State synchronization events** — `STATE_SNAPSHOT`, `STATE_DELTA`,
  `MESSAGES_SNAPSHOT`
- **Custom events** — `CUSTOM` (application-defined payloads)

The message envelope is a JSON object with `type` (event kind), `timestamp` (ms since
epoch), and event-specific fields. The transport is typically SSE (server-sent events)
or WebSocket.

### What an AG-UI spec describes

An **agent-side AG-UI spec** is NOT a runtime event trace (a stream of individual
`TEXT_MESSAGE_CONTENT` events). It IS the *declaration* of how an agent is wired to a
UI: which tools the agent exposes, which events it emits under which conditions, and
which UI fragments / CopilotKit components bind to which events.

This is the artifact this spike is concerned with: a structured YAML/JSON document that
an agent author writes once and refines iteratively as the agent's capabilities and UI
bindings evolve.

---

## Spike Hypothesis

The artifact-refiner refines the **agent-side AG-UI spec** (tool definitions, event
emission rules, UI fragment bindings — NOT runtime traces). The spec is static JSON/YAML
authored by the agent developer.

PMPO's constraint-driven, schema-backed, iterative refinement loop is well suited to
this artifact for the same reason it suits A2UI specs: both are structured JSON/YAML
documents with:

- Required top-level fields (version, agent identity, tool list, event emission map)
- Naming conventions (tool names, event kinds)
- Cross-reference integrity constraints (every bound event kind must be a valid AG-UI
  event type; every tool name in an emission rule must appear in the tool list)
- Schema-validatable structure
- A clear definition of "done" — the spec validates, all constraints pass, and the
  author has reviewed each binding

---

## PMPO Fit Assessment

| Dimension | A2UI | AG-UI spec | Fit? |
|---|---|---|---|
| Artifact type | Structured JSON/YAML | Structured JSON/YAML | YES |
| Schema-validatable | Yes | Yes (proposed) | YES |
| Cross-reference integrity | Circular binding check | Event-kind + tool-name cross-refs | YES |
| Iterative convergence | Normalize → validate → preview | Normalize → validate → verify bindings | YES |
| Deterministic execution | normalize-a2ui.mjs | normalize-agui.mjs (new) | YES |
| Preview evidence | HTML render + screenshot | Binding coverage report (JSON) | YES (adapted) |
| Runtime trace inclusion | No | No (spec only, not traces) | CORRECT BOUNDARY |

**Decision: PMPO fits. Ship the domain.**

The key boundary: the refiner processes the *spec document*, not live event streams.
Streaming AG-UI events are ephemeral and not refinable via PMPO. Specs are static and
refinable.

---

## What the Domain Covers

Artifact being refined: an agent-side AG-UI spec — a JSON or YAML file that declares:

```yaml
version: "ag-ui/v1"
agent:
  name: string
  description: string
tools:
  - name: string           # unique within agent
    description: string
    parameters:            # JSON Schema for tool arguments
      type: object
      properties: {}
event_emission:
  - tool: string           # must reference a tool name above
    on_event: string       # must be a valid AG-UI event kind
    fragment: string       # UI component or slot identifier (optional)
custom_events:             # application-defined event types
  - kind: string
    description: string
    schema:                # JSON Schema for the custom event payload
      type: object
```

Validation constraints enforced by the normalizer:
- Every `event_emission[].tool` must reference a declared tool name
- Every `event_emission[].on_event` must be a valid AG-UI event kind (from the enum)
- Tool names must match `^[a-z_][a-z0-9_]*$` (snake_case)
- Custom event kinds must match `^CUSTOM_[A-Z_]+$`
- No duplicate tool names
- No duplicate event emission rules for the same (tool, on_event) pair

---

## What the Domain Does NOT Cover

- Runtime AG-UI event traces (not refinable by PMPO — they are ephemeral stream output)
- CopilotKit frontend React components (those are UI artifacts, not AG-UI specs)
- Agent conversation history or memory (separate artifact types)
- Transport layer configuration (not part of the spec)

---

## Spike Decision

**Yes — ship the domain.** Add `direct:ag-ui` as a content type, author the schema,
add detection heuristics, and provide an end-to-end example refining an AG-UI spec for
a Rust native agent.

The work mirrors what was done for A2UI. Estimated size: same scope as change-001.
