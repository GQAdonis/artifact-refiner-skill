# Kimi Code — Artifact Refiner Installer

Kimi Code (Moonshot) is both a **skill runner** and an **MCP host**:

- Skills live in `~/.kimi-code/skills/<name>/` (SKILL.md format)
- MCP servers are declared as `[mcp_servers.<name>]` tables in `~/.kimi-code/config.toml`

## Install

```bash
scripts/installers/kimi-code/install.sh
```

This symlinks the repository into `~/.kimi-code/skills/artifact-refiner`, which
makes every sub-skill under `skills/` discoverable — including
`convert-htmx-pdf`. Re-running is idempotent.

## MCP registration is opt-in

```bash
scripts/installers/kimi-code/install.sh --with-mcp
```

`template-forge` is frequently already reachable through an existing SSE
registration — commonly `[mcp_servers.forge-rs]` pointing at a locally running
server. Registering it a second time over stdio gives the host two routes to the
same tools, which is why MCP registration is not the default. Check first:

```bash
grep -n 'mcp_servers' ~/.kimi-code/config.toml
```

When enabled, the block is wrapped in `# >>> artifact-refiner (template-forge) >>>` /
`# <<< ... <<<` markers so it can be cleanly removed later, and the existing
config is backed up (`.bak.<timestamp>`) first.

## Prerequisites

Only for `--with-mcp` — the `template-forge-mcp` binary must be on `PATH`:

```bash
scripts/build-vendored-binaries.sh
cargo install --path tools/template-forge-rs/crates/template-mcp --locked
```

## Uninstall

```bash
scripts/installers/kimi-code/install.sh --uninstall
```

Removes the skill symlink and the marker-delimited MCP block.

## After installing

**Restart Kimi Code** so it reloads its skill directory and `config.toml`.
