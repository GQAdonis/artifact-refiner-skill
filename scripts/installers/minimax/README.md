# MiniMax Code — Artifact Refiner Installer

MiniMax Code supports **both** Agent Skills and MCP servers, so this installer
does both:

- **Skill** — symlinks the repo into `~/.minimax/skills/artifact-refiner`
- **MCP** — registers `template-forge` (and `rust-mcp-filesystem`, if present) in `~/.minimax/mcp/mcp.json`

## Install

```bash
scripts/installers/minimax/install.sh            # skill + MCP (default)
scripts/installers/minimax/install.sh --skill-only
scripts/installers/minimax/install.sh --mcp-only
```

`mcp.json` is backed up (`.bak.<timestamp>`) first, existing servers are
preserved, added servers are tagged `"_managedBy": "artifact-refiner"`, and
re-running is idempotent.

## Prerequisites

For the MCP portion, the `template-forge-mcp` binary must be on `PATH`:

```bash
scripts/build-vendored-binaries.sh
cargo install --path tools/template-forge-rs/crates/template-mcp --locked
```

## Uninstall

```bash
scripts/installers/minimax/install.sh --uninstall
```

Removes the skill symlink and only the MCP servers tagged
`"_managedBy": "artifact-refiner"`.

## After installing

**Restart MiniMax Code** so it discovers the new skill and reloads MCP config.
