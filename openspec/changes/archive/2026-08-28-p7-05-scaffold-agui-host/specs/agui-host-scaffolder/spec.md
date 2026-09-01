# AG-UI Host Scaffolder

## ADDED Requirements

### Requirement: A scaffolder produces a running AG-UI host application

`scripts/scaffold-react-vite-agui.sh` SHALL layer an AG-UI agent host onto an
existing `scaffold-react-vite` target, producing an app that builds, lints, and
streams agent responses under `pnpm dev` without a second process.

Emitted sources SHALL respect the layering in
`references/scaffolds/state-architecture.md`: stores own I/O, hooks read stores,
components read hooks.

The generated README SHALL state that the mock agent and dev-server middleware
are development-only, and SHALL document the contract a production backend must
implement.

#### Scenario: A freshly scaffolded app builds and lints

- **GIVEN** a project produced by `scaffold-react-vite.sh`
- **WHEN** `scaffold-react-vite-agui.sh --target <path>` runs
- **THEN** it exits 0
- **AND** `pnpm build` exits 0 in the generated app
- **AND** `pnpm lint` exits 0, with the architectural rules active

#### Scenario: The dev server answers the agent route

- **GIVEN** the generated app running under `pnpm dev`
- **WHEN** a `RunAgentInput` is POSTed to the agent route with
  `Accept: text/event-stream`
- **THEN** the response is `text/event-stream`
- **AND** the stream begins with `RUN_STARTED` and ends with `RUN_FINISHED`
- **AND** no process other than the Vite dev server is required

#### Scenario: Streamed text renders incrementally

- **GIVEN** a run against the generated app's agent route
- **WHEN** the store's accumulated text is sampled after each frame
- **THEN** at least two samples are longer than their predecessor
- **AND** each sample begins with the previous one

#### Scenario: Architectural layering is enforced, not merely documented

- **GIVEN** a component in the generated app importing a store directly
- **WHEN** `pnpm lint` runs
- **THEN** it reports an error naming the layering violation

#### Scenario: Re-running the scaffolder does not duplicate wiring

- **GIVEN** a target already carrying the AG-UI host
- **WHEN** the scaffolder runs again
- **THEN** the Vite plugin registration and README section are left as-is
