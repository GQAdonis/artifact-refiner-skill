# Claude Desktop — Artifact Refiner MCP Installer

Claude Desktop is an **MCP host**, not an Agent Skill runner. This installer
registers the artifact-refiner's local MCP servers so the desktop app can call
them directly.

## Install

```bash
scripts/installers/claude-desktop/install.sh
```

This merges two servers into
`~/Library/Application Support/Claude/claude_desktop_config.json` under
`mcpServers`:

- **`template-forge`** — deterministic branded-artifact renderer (`template-forge-mcp`)
- **`rust-mcp-filesystem`** — scoped filesystem access (only if the binary is present)

The existing config is backed up (`.bak.<timestamp>`) first, and existing
servers/preferences are preserved. Re-running is idempotent.

## Prerequisites

The `template-forge-mcp` binary must be on `PATH`:

```bash
scripts/build-vendored-binaries.sh
cargo install --path tools/template-forge-rs/crates/template-mcp --locked
```

## Uninstall

```bash
scripts/installers/claude-desktop/install.sh --uninstall
```

Removes only the servers tagged `"_managedBy": "artifact-refiner"`.

## After installing

**Restart Claude Desktop** so it reloads its MCP configuration.
