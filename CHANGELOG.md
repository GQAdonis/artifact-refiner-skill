# Changelog

All notable changes to the **artifact-refiner** skill pack are documented in
this file. The format is based on [Keep a Changelog](https://keepachangelog.com),
and the project loosely follows [Semantic Versioning](https://semver.org).

## [1.4.0] — 2026-07-28

Adds the HTML → paginated PDF lane, closing the artifact pipeline's last
output gap: branded artifacts could be authored and rebranded but not printed.

### Added

- **skills/convert-htmx-pdf** — HTML/HTMX → paginated, print-correct PDF via
  headless Chromium. Chromium is the renderer by design; WeasyPrint / pdfkit /
  wkhtmltopdf diverge from the browser on grid, flexbox, `print-color-adjust`
  and web fonts, which is precisely what a branded artifact depends on.
- **scripts/convert-htmx-pdf.mjs** — five-stage orchestration:
  1. *Font embedding* — fetches Google Fonts CSS with a browser UA, filters
     `@font-face` blocks to Latin / Latin-Ext by `unicode-range`, base64-inlines
     each woff2. Inter + Roboto Slab + JetBrains Mono drops from 74 blocks
     (~4 MB) to 22 (~1.4 MB) with identical Latin rendering.
  2. *Print CSS* — conservative baseline: hides fixed chrome, collapses the page
     shell, `break-inside: avoid` on components, `break-after: avoid` on
     headings, `orphans/widows: 3`, `thead { display: table-header-group }`,
     `print-color-adjust: exact`. **Inserts no page breaks** — break placement
     stays with the artifact.
  3. *Preflight* — strips `margin` from `@page` when a header is enabled (the
     CSS silently overrides the renderer's margins and the header draws through
     the first line of every page); warns when `break-before: page` applies to
     more than a third of sections; flags remaining external assets.
  4. *Render* — `emulate_media('print')`, `printBackground`, and Chromium
     `headerTemplate` / `footerTemplate` for a running header and
     `pageNumber / totalPages`. Templates use system fonts only — they render in
     a separate document that does not inherit `@font-face`.
  5. *Verification* — content-preservation ratio against the source's visible
     word count, per-page density to catch orphan pages, `pdffonts` embedding
     check, text-extraction check, plus a page-1 preview raster.
- **references/print-pagination.md** — the `@page`-size-only rule, the baseline
  stylesheet, break-placement patterns, the full-page cover recipe, the
  header/footer template contract, font-embedding procedure, the verification
  loop, and a ten-row failure catalogue.

### Notes

Three failure modes are now checked rather than rediscovered: `@page { margin }`
overriding renderer margins, forced breaks on every section producing near-empty
pages, and silent font substitution shifting pagination away from the artifact.

### Changed

- **scripts/installers/kimi-code** — Kimi Code is a skill runner as well as an
  MCP host. The installer now symlinks the repository into
  `~/.kimi-code/skills/artifact-refiner` by default, so every sub-skill under
  `skills/` is discoverable there. MCP registration moved behind `--with-mcp`:
  `template-forge` is frequently already reachable through an existing SSE
  entry (commonly `[mcp_servers.forge-rs]`), and registering it a second time
  over stdio gives the host two routes to the same tools.

## [1.3.0] — 2026-05-20

Eleven-phase delta from v1.1.0. Expands artifact-refiner from a PMPO loop into
a lovable.dev / v0.dev-style **ideation → app** pipeline with cost-aware
inference routing.

### Added

- **phase-0-unblock** — re-scoped baseline; deferred Rust workspace bootstrap
  pending clarified scope.
- **phase-rust-workspace-bootstrap** — `tools/template-forge-rs/` 3-crate Rust
  workspace (`template-core`, `template-cli`, `template-mcp`) with Minijinja
  templating, workspace-level dependency pinning, and a hand-rolled stdio
  JSON-RPC 2.0 MCP server.
- **phase-1-submodule-topology** — submodule topology decisions (upstream
  rust-mcp-stack/rust-mcp-filesystem; sycophancy-correction extracted to its
  own repo; openai-proxy treated as an external prerequisite, not a submodule).
- **phase-sc-extraction** — sycophancy-correction extraction.
- **phase-1b-inference-routing** — `model_policy` block in
  `.kbd-orchestrator/project.json`; `scripts/lib/model-routing.mjs`
  (`resolvePhase()` with a 30s health-probe cache); `scripts/lib/openai-client.mjs`
  with `chat()` / `chatRaw()` helpers, `HostHarnessRoutingError` sentinel, and
  per-artifact `.refiner/<name>/model-routing.log` audit. openai-proxy
  standardized on port **8181**.
- **phase-2-scaffold-react-vite** — `scripts/scaffold-react-vite.sh` emitting
  React 19 + Vite 8 + shadcn/ui on Base UI (`--base base --preset nova`),
  feature-based clean architecture (`src/{app,features,shared}/`),
  kebab-case file naming, zustand+immer stores, ESLint architecture rules,
  PWA wiring via `vite-plugin-pwa`. Companion
  `scripts/scaffold-react-vite-axum.sh` produces an axum 0.8.9 single-binary
  SPA wrapper using `{param}` path syntax and `rust-embed`.
- **phase-3-conversion-layer** — `scripts/convert-htmx-react.mjs`
  (parse5-based HTMX → TSX with the Alpine threshold rule — single boolean
  stays as `useState`, multi-field / non-boolean moves to a zustand store);
  `scripts/rebrand-artifact.mjs` (@babel AST hex-swap + CSS regen);
  `scripts/lib/wcag-contrast.mjs` (culori-based OKLCH + WCAG report).
- **phase-prefer-endpoint-consumption** — `chat()` integrated as the
  primary inference path across all LLM-driven scripts; host harness retained
  as fallback.
- **phase-4-scaffold-tauri-desktop** (hybrid) —
  `scripts/scaffold-react-vite-tauri.sh` producing a Tauri 2.11.2 hybrid
  scaffold supporting desktop + iOS + Android from a single React source,
  with PWA-when-resized responsive behavior
  (`useBreakpoint`, `useIsMobile`, `ResponsiveShell`, safe-area-insets).
- **phase-3b-aux-conversions** — `scripts/convert-md-to-htmx.mjs`
  (markdown-it + markdown-it-anchor + gray-matter, brand CSS via
  template-forge); `scripts/refine-moodboard.mjs` (LLM-primary —
  `chat("refiner-evaluate")` returns JSON spec, validated, with placeholder
  fallback); `scripts/design-svg-logo.mjs` (mode-switching LLM/placeholder,
  per-variant fallback on validation failure);
  `scripts/lib/svg-validate.mjs` (strict XSS-safe validator rejecting
  `<script>`, `on*=` handlers, and `javascript:` URLs).
- **polish-pass** — README "Pipeline Capabilities" section; AGENTS.md
  "Architecture Reference" section; moodboard motifs/tone iteration with
  fallback; WCAG report appended post-render; Tauri default menu in
  `lib.rs` (Tauri 2 convention); theme-provider patcher moved to
  `src/app/`.

### Changed

- React/Vite output now uses **TSX exclusively** (never JSX).
- Files follow kebab-case naming (PascalCase reserved for component
  identifiers, never file names).
- Path parameters in axum routes use the 0.8+ `{param}` curly-brace syntax.
- Default inference endpoint resolution prefers `openai_proxy` for
  `refiner-iterate`, `refiner-evaluate`, and `refiner-finalize` phases,
  with host-harness fallback on routing or health-probe failure.

### Architecture

The following invariants are now enforced across all React/Vite output and
must never be broken:

- **Components → Hooks → Stores → I/O** is strict. Components never import
  stores or call services. Hooks never call `fetch` / HTTP clients. Stores
  alone own I/O and all realtime subscriptions (Supabase realtime,
  WebSocket, SSE).
- **Stores never import React.**
- **TSX only**, never JSX.

See `references/scaffolds/{clean,state,responsive}-architecture.md` and
`references/scaffolds/kebab-case-rename.md` for the full contracts.

## [1.1.0]

Prior PMPO baseline. See `git log` for details.
