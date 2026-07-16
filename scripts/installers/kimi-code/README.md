# Kimi Code — Artifact Refiner MCP Installer

Kimi Code (Moonshot) is an **MCP host** configured via
`~/.kimi-code/config.toml` with `[mcp_servers.<name>]` tables. This installer
appends a marker-delimited `[mcp_servers.template-forge]` block.

## Install

```bash
scripts/installers/kimi-code/install.sh
```

The block is wrapped in `# >>> artifact-refiner (template-forge) >>>` /
`# <<< ... <<<` markers so it can be cleanly removed later. The existing config
is backed up (`.bak.<timestamp>`) first, and re-running is idempotent.

> `rust-mcp-filesystem` is commonly already registered in Kimi's config; this
> installer does not touch it.

## Prerequisites

The `template-forge-mcp` binary must be on `PATH`:

```bash
scripts/build-vendored-binaries.sh
cargo install --path tools/template-forge-rs/crates/template-mcp --locked
```

## Uninstall

```bash
scripts/installers/kimi-code/install.sh --uninstall
```

Removes only the marker-delimited block.

## After installing

**Restart Kimi Code** so it reloads `config.toml`.
