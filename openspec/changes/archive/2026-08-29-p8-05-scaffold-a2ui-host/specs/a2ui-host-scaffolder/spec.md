# A2UI Host Scaffolder

## ADDED Requirements

### Requirement: A scaffolder produces a running A2UI rendering host

`scripts/scaffold-react-vite-a2ui.sh` SHALL layer an A2UI rendering host onto an
existing `scaffold-react-vite` target, producing an app that builds, lints, and
renders agent-described UI under `pnpm dev` without a second process.

Emitted sources SHALL respect the layering in
`references/scaffolds/state-architecture.md`, and the scaffolder SHALL emit into
the feature slice the base scaffolder created rather than creating a second one.

#### Scenario: A freshly scaffolded app builds and lints

- **GIVEN** a project produced by `scaffold-react-vite.sh`
- **WHEN** `scaffold-react-vite-a2ui.sh --target <path>` runs
- **THEN** it exits 0, `pnpm build` exits 0, and `pnpm lint` exits 0 with the
  architectural rules active

#### Scenario: The scaffolder reuses the existing feature slice

- **GIVEN** a target whose feature directory was named by the base scaffolder's
  kebab-case rule
- **WHEN** the A2UI scaffolder runs without an explicit `--feature`
- **THEN** it emits into that existing slice, leaving exactly one feature
  directory

#### Scenario: The surface renders as real DOM elements

- **GIVEN** the generated app running under `pnpm dev` with a message source
- **WHEN** the page is inspected in a browser
- **THEN** the surface renders elements discoverable by accessibility role, not
  as a JSON dump or undifferentiated text

#### Scenario: The rendered DOM changes as messages arrive

- **GIVEN** a message source emitting `createSurface`, then `updateDataModel`,
  then `updateComponents`
- **WHEN** the DOM is sampled over time
- **THEN** at least two distinct states are observed, and no page error occurs

#### Scenario: An unknown component fails visibly

- **GIVEN** a surface naming a component the pinned catalog does not implement
- **WHEN** it renders
- **THEN** the renderer reports the unknown component rather than degrading
  silently to a plausible-looking but empty result

#### Scenario: The generated README states the mock is development-only

- **GIVEN** the generated app
- **WHEN** its README is read
- **THEN** it states that the mock message source is development-only and
  documents the message contract a real agent must send
