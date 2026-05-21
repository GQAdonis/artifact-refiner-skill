# Proposal: phase-rust-workspace-bootstrap

## Why

`artifact-refiner` needs a deterministic, branded artifact renderer so the five new sub-skills authored in phase-0 (and downstream scaffolders in later phases) can produce consistent, brand-coupled output without each skill re-implementing template rendering in chat. The session doc `docs/session-2026-05-20-artifact-refiner-buildout.md` §5 specifies a five-engine workspace; this phase ships a **walking skeleton** with one engine (Minijinja) to prove the workspace pattern works end-to-end before scaling.

## What Changes

- **ADDED** `tools/template-forge-rs/` — Cargo workspace with 3 member crates.
- **ADDED** `tools/template-forge-rs/crates/template-core/` — library: BrandData struct, TemplateEngine trait, MinijinjaEngine implementor, library helpers.
- **ADDED** `tools/template-forge-rs/crates/template-cli/` — binary `template-forge`: `--version`, `list-engines`, `list-brands`, `render`.
- **ADDED** `tools/template-forge-rs/crates/template-mcp/` — binary `template-forge-mcp`: stdio JSON-RPC 2.0 MCP server with tools `template_forge_list_engines` and `template_forge_render`.
- **ADDED** `tools/template-forge-rs/templates/brand-guide.html` — one Minijinja template using `{{ brand.* }}` context paths.
- **ADDED** `tools/template-forge-rs/rust-toolchain.toml` — pin MSRV 1.80.
- **ADDED** `assets/library/brands/knowme.toml` — example brand data seeded from session-doc §3 KnowMe tokens.
- **ADDED** `scripts/install-template-forge.sh` — cargo-binstall probe + `cargo install --path` fallback.
- **MODIFIED** `.mcp.json` — register `template-forge` server entry.

## Impact

### Affected surfaces

- `tools/` — new directory (does not exist today).
- `assets/library/` — new directory.
- `.mcp.json` — additive server entry.
- `scripts/` — one new install script.

### Affected dependencies

New Cargo workspace introduces (matching `prometheus-skill-pack/tools/forge-rs/` versions):

- `tokio 1` (full), `tokio-stream 0.1`
- `serde 1`, `serde_json 1`, `toml 0.8`
- `clap 4` (derive, env)
- `minijinja 2`
- `anyhow 1`, `thiserror 2`
- `tracing 0.1`, `tracing-subscriber 0.3`
- `walkdir 2`, `dirs 5`
- `async-trait 0.1`
- MCP transport: `rmcp` (or `mcp-server-rust` if rmcp not suitable) — confirm during plan
- `tikv-jemallocator 0.6` (binary-only, behind cfg)

### Risk surface

- **Medium** — workspace bootstrap touches new crate types (MCP server with stdio JSON-RPC); proven pattern from forge-rs mitigates most risk.
- **Low** — single-engine scope eliminates the multi-engine compilation cascade that the session doc predicted.

### Out of scope (deferred to follow-on phases)

- Askama compile-time engine
- Tera, Handlebars, Mustache runtime engines
- Multiple brand TOMLs beyond knowme
- `skills/build-artifact-library/SKILL.md`
- Streamable HTTP MCP transport (stdio only)
- Partial templates / engine-specific template directories
