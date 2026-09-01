# agui-server-surface Specification

## Purpose
TBD - created by archiving change p7-03-agui-server-surface. Update Purpose after archive.

## Requirements

### Requirement: Scaffolded apps expose an AG-UI-conformant SSE endpoint

A scaffolded AG-UI host SHALL serve an endpoint accepting a `RunAgentInput` POST
body and responding with an AG-UI event stream, without requiring a second
process alongside the dev server.

The endpoint SHALL encode frames with `EventEncoder.encodeSSE` from
`@ag-ui/encoder` rather than hand-formatting them, so the wire format tracks the
upstream protocol.

#### Scenario: A conformant request receives an SSE stream

- **GIVEN** a POST to the agent route with `Content-Type: application/json`,
  `Accept: text/event-stream`, and a valid `RunAgentInput` body
- **WHEN** the middleware handles it
- **THEN** the response carries `Content-Type: text/event-stream`,
  `Cache-Control: no-cache`, and `Connection: keep-alive`
- **AND** the body is a sequence of `data: {…}\n\n` frames, each parsing as JSON

#### Scenario: Content streams as multiple deltas

- **GIVEN** a run producing assistant text
- **WHEN** the stream is read
- **THEN** at least two distinct `TEXT_MESSAGE_CONTENT` events are emitted
- **AND** concatenating their `delta` fields reproduces the message exactly,
  including whitespace

#### Scenario: Events follow the protocol sequence

- **GIVEN** a completed run
- **WHEN** its events are inspected in order
- **THEN** `RUN_STARTED` is first and `RUN_FINISHED` is last
- **AND** no `TEXT_MESSAGE_CONTENT` or `TEXT_MESSAGE_END` precedes its
  `TEXT_MESSAGE_START`
- **AND** no run is started twice

#### Scenario: A non-JSON content type is refused

- **GIVEN** a POST with `Content-Type: text/plain`
- **WHEN** the middleware handles it
- **THEN** it responds `415` with a JSON error and opens no stream

#### Scenario: A malformed RunAgentInput is refused

- **GIVEN** a POST with valid JSON that is not a conformant `RunAgentInput`
- **WHEN** the middleware handles it
- **THEN** it responds `400` with a JSON error listing the specific issues,
  and opens no stream

#### Scenario: A client disconnecting mid-run does not destabilise the server

- **GIVEN** a client that aborts while events are still being emitted
- **WHEN** the run continues
- **THEN** emission stops once the response is closed
- **AND** the server handles subsequent requests normally
