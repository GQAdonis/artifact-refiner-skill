# MCP-UI Host Scaffolder

## ADDED Requirements

### Requirement: The scaffolder produces a running MCP-UI host

`scaffold-react-vite-mcp-ui.sh` SHALL layer a working host onto an existing
Vite/React project, wiring it so a fresh `pnpm dev` renders without manual edits.

#### Scenario: A fresh scaffold builds, lints, and tests

- **GIVEN** a project produced by `scaffold-react-vite.sh`
- **WHEN** the MCP-UI scaffolder runs against it
- **THEN** `pnpm build`, `pnpm lint`, and `pnpm test` all exit 0

#### Scenario: The surface is mounted, not merely copied

- **GIVEN** a freshly scaffolded app
- **WHEN** it is loaded in a browser
- **THEN** the A2UI surface renders its buttons — the component is imported and
  rendered by the app entry point, not just present on disk

#### Scenario: Exactly one feature slice is created

- **GIVEN** a target whose directory name contains a digit run, such as `smoke9ui`
- **WHEN** the scaffolder derives the feature name
- **THEN** it uses the same `to_kebab` form as the base scaffolder
  (`smoke-9-ui`), leaving exactly one directory under `src/features/`

#### Scenario: A second run changes nothing

- **WHEN** the scaffolder runs twice against the same target
- **THEN** the plugin registration, the surface mount, and the feature slice are
  each present exactly once, and the app still builds

### Requirement: The scaffolder supplies what the base project lacks

The base scaffolder does not provide test or bundler tooling, and its ESLint
config scopes only TypeScript sources. The MCP-UI scaffolder SHALL install what
its own output needs rather than assuming the base provides it, and SHALL pin
renderer dependencies to versions that resolve to a single copy.

#### Scenario: Test and bundler tooling is installed

- **GIVEN** a base project with no `vitest`, no `esbuild`, and no `test` script
- **WHEN** the scaffolder runs
- **THEN** it installs both, adds a `test` script, and scopes ESLint so Node
  build scripts under `src/dev/` do not fail `no-undef`

#### Scenario: Renderer dependencies resolve to a single copy

- **GIVEN** `@a2ui/react@0.10.2` requires `@a2ui/web_core@^0.10.5`
- **WHEN** the scaffolder pins dependencies
- **THEN** it pins `@a2ui/web_core@0.10.6`, so only one copy is installed and
  the type-check passes
