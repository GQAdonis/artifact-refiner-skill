# Plan: phase-rust-workspace-bootstrap

**Backend:** OpenSpec
**Proposal:** `openspec/changes/phase-rust-workspace-bootstrap/proposal.md`
**Tasks:** `openspec/changes/phase-rust-workspace-bootstrap/tasks.md`
**Scope discipline:** Minijinja-only walking skeleton

## Ordered change list

| # | Change | Section | Gate |
|---|---|---|---|
| 1 | Workspace skeleton + 3 empty crates | 1 | `cargo check` |
| 2 | BrandData + TOML deser + knowme.toml | 2 | `cargo test -p template-core` |
| 3 | TemplateEngine trait + MinijinjaEngine | 3 | `cargo test -p template-core` |
| 4 | brand-guide.html template | 4 | manual |
| 5 | template-cli with 4 subcommands | 5 | `cargo build` + version check |
| 6 | End-to-end smoke render | 6 | grep ember hex |
| 7 | template-mcp stdio server (2 tools + probe mode) | 7 | `--probe` smoke |
| 8 | Install script + .mcp.json registration | 8 | manual install |
| 9 | Acceptance gates 1–9 | 9 | verify-app |

## Sequencing

Strictly sequential — each section's gate must pass before next begins. Inside a section, sub-tasks can run interleaved.

## Risk register (carried forward from assessment §5)

| Risk | Mitigation in plan |
|---|---|
| Minijinja path_loader misconfig | Task 3.6 tests rendering inline before file loader |
| BrandData TOML deser mismatch | Task 2.4 writes the TOML first, then task 2.1 mirrors its shape |
| MCP server hard to test | Task 7.4 adds `--probe` mode |
| rmcp API churn | Fallback to hand-rolled stdio JSON-RPC documented in 7.1 |

## Estimated effort

One focused session if rmcp's API is stable; two sessions if MCP transport needs hand-rolling.
