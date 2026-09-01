# AG-UI Client Store

## ADDED Requirements

### Requirement: Streamed agent events reduce into renderable state

A scaffolded AG-UI host SHALL consume the agent event stream in a store, and
SHALL accumulate streamed text so the interface renders it as it arrives.

All agent I/O SHALL live in the store. Hooks and components SHALL NOT open
connections, per `references/scaffolds/state-architecture.md` lines 20, 39, 185,
and 210.

#### Scenario: Text deltas accumulate rather than replace

- **GIVEN** a run emitting `TEXT_MESSAGE_CONTENT` events with deltas
  `"Hello, "`, `"world"`, `"!"` for one `messageId`
- **WHEN** the store reduces them
- **THEN** that message's content is `"Hello, world!"`
- **AND** it is not merely the final delta

#### Scenario: Interleaved messages stay isolated

- **GIVEN** two open messages whose `TEXT_MESSAGE_CONTENT` events arrive
  interleaved
- **WHEN** the store reduces them
- **THEN** each message accumulates only its own deltas
- **AND** arrival order is preserved

#### Scenario: Content for an unknown message is dropped, not synthesised

- **GIVEN** a `TEXT_MESSAGE_CONTENT` whose `messageId` has no open message
- **WHEN** the store reduces it
- **THEN** no message is created
- **AND** the drop is counted and a warning emitted, so the protocol ordering
  violation surfaces instead of being hidden behind plausible output

#### Scenario: A run error surfaces to the interface

- **GIVEN** a `RUN_ERROR` event carrying a message
- **WHEN** the store reduces it
- **THEN** status becomes `error` and the message is exposed for display

#### Scenario: Rendered text grows across frames

- **GIVEN** a live agent run against a conformant SSE endpoint
- **WHEN** state is sampled after each received frame
- **THEN** at least two samples are longer than their predecessor
- **AND** each sample begins with the previous one, so growth is monotonic
  rather than a single terminal flush

#### Scenario: I/O stays in the store

- **GIVEN** the hook and component source
- **WHEN** they are inspected
- **THEN** neither constructs an agent client nor calls `fetch` or `EventSource`
- **AND** the store imports no React
