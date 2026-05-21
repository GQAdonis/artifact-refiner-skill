# Tasks: phase-rust-workspace-bootstrap

Sequenced. Each section ends with a `cargo check` gate. Do not advance to the next section until the gate passes.

## 1. Workspace skeleton

- [ ] 1.1 Create `tools/template-forge-rs/` directory.
- [ ] 1.2 Author `tools/template-forge-rs/Cargo.toml` (workspace manifest, 3 members, `[workspace.dependencies]` block mirroring forge-rs structure).
- [ ] 1.3 Author `tools/template-forge-rs/rust-toolchain.toml` (channel "1.80").
- [ ] 1.4 Create `crates/template-core/`, `crates/template-cli/`, `crates/template-mcp/` with minimal `Cargo.toml` + `src/lib.rs` or `src/main.rs` stubs that compile empty.
- [ ] 1.5 **Gate:** `cd tools/template-forge-rs && cargo check --all-targets` exits 0.

## 2. BrandData + TOML deserialization

- [ ] 2.1 In `template-core/src/brand.rs`: define `BrandData`, `BrandMeta`, `ColorPalette`, `BrandColors`, `BrandTypography`, `BrandLogo`, `BrandContact` per session-doc §5. All `#[derive(Debug, Clone, Serialize, Deserialize)]`.
- [ ] 2.2 In `template-core/src/library.rs`: `fn load_brand(library_dir: &Path, name: &str) -> Result<BrandData>` — reads `<library_dir>/brands/<name>.toml`.
- [ ] 2.3 In `template-core/src/library.rs`: `fn list_brands(library_dir: &Path) -> Result<Vec<String>>` — globs `<library_dir>/brands/*.toml`.
- [ ] 2.4 Create `assets/library/brands/knowme.toml` with KnowMe tokens from session-doc §3 (dark palette `#0B0F14`, ember `#E04E28`/`#FF6A3D`, info `#60A5FA`, fonts Space Grotesk + Inter + Roboto + JetBrains Mono).
- [ ] 2.5 Unit test in `template-core`: load knowme.toml from a test-only path, assert non-empty meta.name.
- [ ] 2.6 **Gate:** `cargo test -p template-core` passes.

## 3. TemplateEngine trait + MinijinjaEngine

- [ ] 3.1 In `template-core/src/engine/mod.rs`: define `pub trait TemplateEngine: Send + Sync` with `render(&self, template_name: &str, brand: &BrandData) -> Result<String>`, `has_template(&self, template_name: &str) -> bool`, `engine_id(&self) -> &'static str`.
- [ ] 3.2 In `template-core/src/engine/mod.rs`: `pub enum EngineSelection { Minijinja }` (single variant for now; trait shape supports later additions).
- [ ] 3.3 In `template-core/src/engine/minijinja_engine.rs`: implementor backed by `minijinja::Environment` with `path_loader` rooted at the templates base dir.
- [ ] 3.4 Factory function `build_engine(sel: EngineSelection, template_dir: &Path) -> Result<Box<dyn TemplateEngine>>`.
- [ ] 3.5 Render context convention: `{ "brand": <BrandData> }` as root so templates use `{{ brand.meta.name }}`.
- [ ] 3.6 Unit test: render a tiny inline `{{ brand.meta.name }}` template against a constructed `BrandData`; assert output equals the name.
- [ ] 3.7 **Gate:** `cargo test -p template-core` passes.

## 4. One template: brand-guide.html

- [ ] 4.1 Create `tools/template-forge-rs/templates/brand-guide.html` — Minijinja syntax, single self-contained HTML doc, renders meta.name, color palette swatches with hex values, typography specimens.
- [ ] 4.2 No partials in this phase (deferred). Inline whatever the template needs.
- [ ] 4.3 WCAG AA contrast pairs visually validated in the smoke render (manual eyeball acceptable for phase-0 of the workspace; deterministic validator deferred).

## 5. template-cli binary

- [ ] 5.1 In `template-cli/src/main.rs`: clap derive-based CLI with subcommands `version`, `list-engines`, `list-brands`, `render`.
- [ ] 5.2 `render` flags: `--brand <name>`, `--template <name>`, `--engine <id>` (default minijinja), `--library <path>`, `--templates-base <path>`, `--output <path|->` (default `-` = stdout).
- [ ] 5.3 Wire jemallocator at binary entry behind `#[cfg(not(target_env = "msvc"))]` (matches forge-rs).
- [ ] 5.4 `template-forge --version` prints version from Cargo.toml.
- [ ] 5.5 `template-forge list-engines` prints `minijinja`.
- [ ] 5.6 **Gate:** `cargo build -p template-cli --release` succeeds; binary at `target/release/template-forge`.

## 6. End-to-end smoke render

- [ ] 6.1 Run `./target/release/template-forge list-brands --library ../../assets/library` → outputs `knowme`.
- [ ] 6.2 Run `./target/release/template-forge render --brand knowme --template brand-guide --engine minijinja --library ../../assets/library --templates-base templates --output /tmp/knowme-brand-guide.html`.
- [ ] 6.3 Verify `/tmp/knowme-brand-guide.html` is non-empty, contains KnowMe ember color hex `#E04E28`, opens in a browser.
- [ ] 6.4 **Gate:** smoke output validated by `grep -q '#E04E28' /tmp/knowme-brand-guide.html`.

## 7. template-mcp server

- [ ] 7.1 Add MCP transport dependency (`rmcp` 0.x preferred; if API churn is too painful, use a hand-rolled stdio JSON-RPC loop with `tokio` + `serde_json`).
- [ ] 7.2 In `template-mcp/src/main.rs`: stdio server with two tools: `template_forge_list_engines` (no params) and `template_forge_render` (params: brand, template, engine?, library, templates_base).
- [ ] 7.3 Both tools delegate to `template-core` functions.
- [ ] 7.4 Add `--probe` mode that exercises the same code path as MCP tool dispatch without going through stdio (for testing without an MCP client).
- [ ] 7.5 **Gate:** `cargo build -p template-mcp --release` succeeds; `./target/release/template-forge-mcp --probe list-engines` prints `minijinja`.

## 8. Install script + .mcp.json registration

- [ ] 8.1 Author `scripts/install-template-forge.sh`:
  - probe `cargo-binstall`; if present, attempt `cargo binstall template-forge template-forge-mcp` (will fail until releases exist; that is fine)
  - fall back to `cargo install --path tools/template-forge-rs/crates/template-cli` and `--path tools/template-forge-rs/crates/template-mcp`
  - verify both binaries are on PATH
- [ ] 8.2 `chmod +x scripts/install-template-forge.sh`.
- [ ] 8.3 Read existing `.mcp.json`; add a `template-forge` server entry:
  ```json
  {
    "mcpServers": {
      "template-forge": {
        "command": "template-forge-mcp",
        "args": ["--library", "assets/library"],
        "transport": "stdio"
      }
    }
  }
  ```
- [ ] 8.4 Validate `.mcp.json` parses as JSON.

## 9. Acceptance gates

- [ ] 9.1 `cd tools/template-forge-rs && cargo check --all-targets` exits 0.
- [ ] 9.2 `cargo build --release` produces both binaries.
- [ ] 9.3 `template-forge --version` works.
- [ ] 9.4 `template-forge list-engines` → `minijinja`.
- [ ] 9.5 `template-forge list-brands --library assets/library` → `knowme`.
- [ ] 9.6 `template-forge render ...` → non-empty HTML containing `#E04E28`.
- [ ] 9.7 `template-forge-mcp --probe list-engines` works.
- [ ] 9.8 `bash scripts/install-template-forge.sh` installs both binaries.
- [ ] 9.9 `.mcp.json` includes `template-forge` entry.

## Recommended agents

| Tasks | Agent |
|---|---|
| 1.* through 7.* | `rust-build-resolver` for compile, `rust-reviewer` for review |
| 5.*, 7.* (clap/MCP design) | `code-architect` if non-trivial |
| 8.* | direct edit |
| 9.* | `verify-app` |
