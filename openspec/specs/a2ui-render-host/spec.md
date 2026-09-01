# a2ui-render-host Specification

## Purpose
TBD - created by archiving change p8-04-a2ui-render-host. Update Purpose after archive.

## Requirements

### Requirement: A2UI messages reduce into renderable surface state

A scaffolded A2UI host SHALL consume the agent message stream in a store and
apply messages **progressively**, so a surface can be created and then updated
without being resent.

All A2UI I/O SHALL live in the store. Hooks and components SHALL NOT open
connections, per `references/scaffolds/state-architecture.md` lines 20, 39, 185,
and 210.

Rendering SHALL use the upstream `@a2ui/react` renderer rather than a
hand-written component switch.

#### Scenario: updateComponents merges rather than replaces

- **GIVEN** a surface holding three components
- **WHEN** an `updateComponents` message carries one of them
- **THEN** that component is updated, the other two remain, and arrival order is
  preserved — replacing the map would look correct on a one-component surface
  and silently drop siblings on a real one

#### Scenario: updateDataModel re-resolves bindings without resending components

- **GIVEN** a component whose leaf is `{"path": "/title"}`
- **WHEN** an `updateDataModel` message changes `/title`
- **THEN** the value that leaf resolves to changes, with no component message in
  between, and unrelated data-model keys survive the merge

#### Scenario: createSurface replaces the surface wholesale

- **GIVEN** an existing surface
- **WHEN** a new `createSurface` arrives
- **THEN** the prior components are gone — a new surface supersedes, it does not
  accumulate

#### Scenario: deleteSurface clears store state

- **GIVEN** a populated surface
- **WHEN** `deleteSurface` arrives
- **THEN** components, data model, and status return to empty

#### Scenario: Operations the pinned renderer cannot draw are recorded, not dropped

- **GIVEN** a message whose operation the pinned renderer version does not
  implement
- **WHEN** the store reduces it
- **THEN** it is recorded as unrenderable and surfaced to the interface, so the
  gap between validated contract and installed renderer is visible rather than
  silent

#### Scenario: I/O stays in the store

- **GIVEN** the hook and surface component source
- **WHEN** they are inspected
- **THEN** neither calls `fetch` nor constructs an `EventSource`, and the store
  imports no React
