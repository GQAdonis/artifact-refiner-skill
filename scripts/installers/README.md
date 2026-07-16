# Artifact Refiner — Multi-Environment Installers

One-command installation for 15 AI coding environments. Skill-based environments
use symbolic links to the cloned repository; MCP-host environments (Claude
Desktop, Kimi Code) register the bundled `template-forge` MCP server in their
config instead.

## Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/GQAdonis/artifact-refiner-skill.git
cd artifact-refiner-skill

# 2. Run the installer for your environment
scripts/installers/<environment>/install.sh --global
```

## Supported Environments

| Environment | Installer | Install Type | Global Path | Project Path |
|---|---|---|---|---|
| [Claude Code](claude-code/) | `claude-code/install.sh` | Symlink (skill dir) | `~/.claude/skills/` | `.claude/skills/` |
| [Claude Desktop](claude-desktop/) | `claude-desktop/install.sh` | MCP server (JSON) | `~/Library/Application Support/Claude/claude_desktop_config.json` | — |
| [Kimi Code](kimi-code/) | `kimi-code/install.sh` | MCP server (TOML) | `~/.kimi-code/config.toml` | — |
| [MiniMax Code](minimax/) | `minimax/install.sh` | Symlink + MCP server | `~/.minimax/skills/` + `~/.minimax/mcp/mcp.json` | — |
| [Codex CLI](codex/) | `codex/install.sh` | Symlink (skill dir) | `~/.codex/skills/` | `.codex/skills/` |
| [OpenCode](opencode/) | `opencode/install.sh` | Symlink (skill dir) | `~/.config/opencode/skills/` | `.opencode/skills/` |
| [Antigravity](antigravity/) | `antigravity/install.sh` | Symlink (skill dir) | `~/.gemini/antigravity/skills/` | `.agent/skills/` |
| [Cursor](cursor/) | `cursor/install.sh` | .mdc rule + symlink | `~/.cursor/rules/` | `.cursor/rules/` |
| [Gemini CLI](gemini-cli/) | `gemini-cli/install.sh` | Extension link | `~/.gemini/extensions/` | `.gemini/skills/` |
| [Windsurf](windsurf/) | `windsurf/install.sh` | .md rule + symlink | `~/.codeium/windsurf/rules/` | `.windsurf/rules/` |
| [Roo Code](roo-code/) | `roo-code/install.sh` | Symlink (rules dir) | `~/.roo/rules/` | `.roo/rules/` |
| [Cline](cline/) | `cline/install.sh` | Symlink (skill dir) | `~/.cline/skills/` | `.clinerules/` |
| [Kilo Code](kilo-code/) | `kilo-code/install.sh` | Symlink (rules dir) | `~/.kilocode/rules/` | `.kilocode/rules/` |
| [Warp](warp/) | `warp/install.sh` | AGENTS.md + symlink | `~/.warp/skills/` | `.warp/skills/` |
| [Zed](zed/) | `zed/install.sh` | .rules + symlink | `~/.config/zed/skills/` | `.zed/skills/` |

## Common Flags

All installers support:

| Flag | Description |
|---|---|
| `--global` | Install to user-level directory (default for most) |
| `--project` | Install to current project directory |
| `--uninstall` | Remove the symlink / generated files |
| `--help` | Show usage information |

## How It Works

Each installer creates a **symbolic link** from the environment's expected skill/rules directory to the cloned repository. This means:

- ✅ **One copy of the code** — no duplication
- ✅ **Always up-to-date** — `git pull` updates all environments
- ✅ **Idempotent** — safe to run multiple times
- ✅ **Clean uninstall** — `--uninstall` removes only what was created

### MCP-host environments

Some environments are MCP hosts rather than skill runners. For these, the
installer registers the bundled `template-forge` MCP server (and, where
applicable, `rust-mcp-filesystem`) in the host's config file instead of creating
a skill symlink:

- **Claude Desktop** — merges `mcpServers` into `claude_desktop_config.json` (JSON).
- **Kimi Code** — appends a marker-delimited `[mcp_servers.template-forge]` block to `config.toml` (TOML).
- **MiniMax Code** — does *both*: symlinks the skill into `~/.minimax/skills/` **and** registers the MCP servers in `~/.minimax/mcp/mcp.json`.

Every config edit is backed up (`.bak.<timestamp>`) first, every added MCP
server is tagged so `--uninstall` removes exactly what was added, and re-running
is idempotent. These installers require the `template-forge-mcp` binary on
`PATH` — build it with `scripts/build-vendored-binaries.sh` and
`cargo install --path tools/template-forge-rs/crates/template-mcp`. **Restart the
host app** after installing so it reloads its MCP config.

### Special Cases

- **Cursor** and **Windsurf** use rule files (`.mdc`/`.md`) rather than skill directories. The installer generates an appropriate rule file *and* creates a symlink for full skill access.
- **Gemini CLI** uses its built-in `gemini extensions link` command when available, falling back to a manual symlink otherwise.
- **Cline** requires Skills to be explicitly enabled in settings before they're discoverable.
- **Warp** uses `AGENTS.md` for project rules; the installer appends a section to it and creates a skill symlink.
- **Zed** uses `.rules` files at the worktree root; the installer appends a section and creates a skill symlink.

## Directory Structure

```
scripts/installers/
├── README.md          ← You are here
├── common.sh          ← Shared helpers (colors, symlink ops, MCP config merge, flag parsing)
├── antigravity/       ← Google Antigravity
├── claude-code/       ← Claude Code (skill symlink)
├── claude-desktop/    ← Claude Desktop (MCP server registration)
├── kimi-code/         ← Kimi Code / Moonshot (MCP server registration)
├── minimax/           ← MiniMax Code (skill symlink + MCP server)
├── cline/             ← Cline / Cline CLI
├── codex/             ← OpenAI Codex CLI
├── cursor/            ← Cursor Agent
├── gemini-cli/        ← Google Gemini CLI
├── kilo-code/         ← Kilo Code
├── opencode/          ← OpenCode
├── roo-code/          ← Roo Code
├── warp/              ← Warp Terminal
├── windsurf/          ← Windsurf (Codeium)
└── zed/               ← Zed IDE
```

Each subdirectory contains `install.sh` + `README.md`.

## Requirements

- **Git** — for cloning the repository
- **Bash** — all scripts are POSIX-compatible bash
- **The target environment** — whichever editor/CLI you're installing for

## Author

Built by [Travis James](https://travisjames.ai) as part of the Artifact Refiner skill project.
