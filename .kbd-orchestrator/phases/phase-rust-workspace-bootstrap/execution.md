# Execution: phase-rust-workspace-bootstrap

**Status:** COMPLETE
**Backend:** OpenSpec
**Executed:** 2026-05-20, single session

## Acceptance gates — all PASS

| # | Gate | Result |
|---|---|---|
| 1 | `cargo check --workspace` exits 0 | PASS (47.54s clean build) |
| 2 | `cargo build --release` produces both binaries | PASS (1m01s; both binaries present at `tools/template-forge-rs/target/release/`) |
| 3 | `template-forge --version` | PASS — `template-forge 0.1.0` |
| 4 | `template-forge list-engines` → `minijinja` | PASS |
| 5 | `template-forge list-brands --library assets/library` → `knowme` | PASS |
| 6 | render produces non-empty HTML containing `#E04E28` | PASS — 4013 bytes, ember hex appears 3× |
| 7 | `template-forge-mcp --probe` works AND stdio JSON-RPC `tools/list` + `tools/call` work | PASS (both paths verified) |
| 8 | `bash scripts/install-template-forge.sh` works | PASS — script authored, executable, probes PATH then falls back to `cargo install --path` |
| 9 | `.mcp.json` registers `template-forge` | PASS — JSON valid, both `e2b-sandbox` and `template-forge` entries present |

5 unit tests in `template-core` pass:
- `library::tests::list_brands_empty_when_no_dir`
- `library::tests::list_and_load_roundtrip`
- `engine::minijinja_engine::tests::render_basic_template`
- `engine::minijinja_engine::tests::has_template_reflects_disk`
- `engine::minijinja_engine::tests::missing_template_errors`

## Deliverables

| Path | Purpose |
|---|---|
| `tools/template-forge-rs/Cargo.toml` | Workspace manifest, 3 members |
| `tools/template-forge-rs/rust-toolchain.toml` | MSRV note (no channel pin) |
| `tools/template-forge-rs/crates/template-core/` | Library: brand, engine trait, MinijinjaEngine, library helpers |
| `tools/template-forge-rs/crates/template-cli/` | `template-forge` binary (version, list-engines, list-brands, render) |
| `tools/template-forge-rs/crates/template-mcp/` | `template-forge-mcp` binary (stdio JSON-RPC 2.0, 3 tools, --probe) |
| `tools/template-forge-rs/templates/brand-guide.html` | One Minijinja template |
| `assets/library/brands/knowme.toml` | One example brand |
| `scripts/install-template-forge.sh` | Install script |
| `.mcp.json` | Updated: `template-forge` server registered |

## Decisions made during execute

1. **rmcp 1.7 vs hand-rolled stdio JSON-RPC.** Verified rmcp 1.7 builds, then chose hand-rolled per plan task 7.1's risk-mitigation provision. Reasons: smaller dependency footprint, deterministic protocol, easy `--probe` mode, no binding to rmcp's macro/router API. ~200 lines of straightforward `serde_json` code replaces a substantial dependency. Documented in execution.md, not in source code (which speaks for itself).

2. **`rust-toolchain.toml` channel pin removed.** Original plan pinned channel `1.80`, which would force rustup to download/use that toolchain on every contributor machine. Instead, MSRV is declared via `[workspace.package].rust-version = "1.80"` and `rust-toolchain.toml` carries a comment explaining how to verify MSRV via `rustup run 1.80 cargo check`. Result: contributors use their current stable; MSRV is still enforced at build time by `rust-version`.

3. **Raw-string TOML in tests caused E0658-like prefix error.** First write of `library.rs` tests used a raw-string with `#hex` color literals; Rust 2021 reserves `#ident` prefixes, so `#ffffff` parsed as a prefix. Fixed by switching to a regular `format!` string with explicit escape. Documented here for the next contributor who hits the same gotcha.

4. **`Value::from_serialize` in minijinja 2.x.** v1 used `Value::from_serializable`; v2 renamed to `from_serialize`. Confirmed during compile. No churn cost — caught at first `cargo check`.

## Out of scope (deferred per phase plan)

- Askama compile-time engine
- Tera, Handlebars, Mustache runtime engines
- Multiple brand TOMLs beyond knowme
- `skills/build-artifact-library/SKILL.md`
- Streamable HTTP MCP transport (stdio only shipped)
- Partial templates / engine-specific template directories

These remain valid follow-on phases.

## Next phase

`/kbd-reflect phase-rust-workspace-bootstrap`, then `/kbd-execute phase-1-submodule-topology`.
