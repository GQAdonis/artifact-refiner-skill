# Reflection: phase-4-scaffold-tauri-desktop (hybrid) — FINAL

**Date:** 2026-05-20
**Status:** COMPLETE — all 4 blocks (A/B/C/D), 8/8 acceptance gates PASS
**Supersedes:** the prior session's Block-A checkpoint reflection (now historical)

## Goal Achievement

| Goal | Status |
|---|---|
| State-architecture convention doc | MET (Block A.1) |
| ESLint architectural rules config | MET (A.2) |
| Sample-app rewritten to zustand+immer | MET (A.3) |
| Scaffolder installs zustand+immer + routes `useXxxStore` to `stores/` | MET (A.4) |
| Convert-htmx-react Alpine→store threshold | MET (A.5) |
| SKILL.md updates (scaffold-react-vite + convert-htmx-react) | MET (A.6) |
| Responsive architecture doc | MET (B.1) |
| Safe-area-inset CSS in brand template | MET (B.2) |
| Scaffolder emits useBreakpoint/useIsMobile/ResponsiveShell/runtime | MET (B.3) |
| `vite-plugin-pwa` wiring with brand-resolved manifest | MET (B.4) |
| Branded PWA icon generation | MET (B.4) |
| `scaffold-react-vite-tauri.sh` orchestrator | MET (C.1) |
| `skills/scaffold-react-vite-tauri/SKILL.md` | MET (C.2) |
| `--with-tauri-wrapper` chain + plugin.json registration | MET (C.3) |
| Tauri smoke (`cargo check` + `pnpm tauri info`) | MET (C.4) |
| 8-gate acceptance sweep | MET (D) |

**Achievement: 16/16 MET (100%).**

## Delivered Changes

| Path | Block | Notes |
|---|---|---|
| `references/scaffolds/state-architecture.md` | A.1 | three-layer rule + threshold |
| `references/scaffolds/eslint-architecture.config.mjs` | A.2 | snippet |
| `references/scaffolds/responsive-architecture.md` | B.1 | useBreakpoint + ResponsiveShell + safe-area |
| `assets/templates/sample-app.tsx` | A.3 | zustand+immer reference impl |
| `assets/templates/sample-htmx-multi.html` | A.5 | multi-field x-data for threshold testing |
| `tools/template-forge-rs/templates/vite-shell-css.html` | B.2 | safe-area-inset vars + mobile media query |
| `scripts/scaffold-react-vite.sh` | A.4 + B.4 + C.3 | zustand install + PWA wiring + Tauri chain |
| `scripts/scaffold-react-vite-tauri.sh` | C.1 | new — Tauri 2 hybrid scaffolder |
| `scripts/convert-htmx-react.mjs` | A.5 | Alpine→store threshold (single-boolean stays local) |
| `skills/scaffold-react-vite/SKILL.md` | A.6 | Architectural Baseline section added |
| `skills/convert-htmx-react/SKILL.md` | A.6 | State Lift Threshold section added |
| `skills/scaffold-react-vite-tauri/SKILL.md` | C.2 | new |
| `.claude-plugin/plugin.json` | C.3 | `scaffold-react-vite-tauri` registered (15 skills total) |

## Artifact Quality Summary

| Metric | Value |
|---|---|
| Changes with QA | 15/15 |
| First-pass pass rate | 10/15 (67%) |
| Changes requiring refinement | 5 (all in Block A — patcher regex/awk → Python rewrites) |
| Total refinement iterations | 6 across Block A + 1 in Block B (PWA plugin insert lacked leading comma) |
| Acceptance gates passed | 8/8 |

Block A's iterations are documented in the prior checkpoint reflection. Block B added one iteration (the PWA plugin injection's missing leading comma in `vite.config.ts`). Block C went clean first-try.

### Recurring Constraint Violations

None at the contract level. All iterations were the patcher catching up to the architecture, never the architecture failing.

## Technical Debt Introduced

| Debt | Severity | Notes |
|---|---|---|
| Patcher uses regex + Python, not AST | Medium | swc/oxc bindings are the v2 path; works for current samples |
| Vite 7.x pinned by shadcn upstream | Low | bumps when shadcn bumps; not under our control |
| iOS/Android signing manual | None (scope) | Tauri inits the project; user supplies credentials |
| Tauri plugin selection beyond defaults | Low | one-off per project |
| Multi-window Tauri configs | Low | manual customization in tauri.conf.json |
| PNG icon fallback is SVG-with-png-name when rasterizer absent | Low | works for manifest validation; user replaces for production |
| `pnpm build` runs `tsc -b` strictly — third-party type errors can fail builds | Medium | mitigated by current zustand+immer 5.x + react 19 compat; documented as expected behavior |

None blocking. Each item has a clear retirement path or is explicitly out of scope.

## Lessons Captured

### Lesson 1 — The retroactive vs net-new asymmetry holds

Block A (retroactive correction): 5 patcher iterations. Block B (responsive + PWA, mostly net-new): 1 iteration (PWA plugin comma). Block C (Tauri shell, fully net-new): 0 iterations. **Net-new code with clean boundaries is 5x faster than retroactive correction.** This matches the lesson from phase-prefer-endpoint-consumption (which was 0 iterations across 6 changes).

### Lesson 2 — Heredoc-injected JSON requires deliberate punctuation thought

The VitePWA `,\n    VitePWA({...})` insertion needed a leading comma because the source `[react(), tailwindcss()]` had no trailing comma. AST-based JSON patching would handle this automatically; regex/string-based patching needs the comma hand-managed. Worth knowing for future patcher work.

### Lesson 3 — `0` is a number, not a boolean

The Alpine threshold rule's initial implementation treated `count: 0` as a boolean (which it isn't). Subtle. The fix was tightening `isBooleanInit` to only literal `true`/`false`/empty. **JavaScript's truthy/falsy semantics quietly seep into static analysis if you don't draw the line explicitly.**

### Lesson 4 — Tauri 2 + PWA coexist without conditional builds, but the build size grows

`dist/` after `--with-tauri-wrapper`: 12 precache entries, 265 KiB. The PWA manifest is harmless inside Tauri; Tauri's WebView ignores the service worker. Same source, three deploy targets (web, PWA-installed, Tauri shell), one `pnpm build`. The size cost of bundling the SW + manifest into a Tauri-only deployment is < 30 KiB. Acceptable.

### Lesson 5 — `pnpm tauri info` is the cheapest smoke gate

Running `pnpm tauri info` exits 0 if Tauri's prerequisite chain is intact: Rust toolchain, cargo, rustup, node, pnpm, and (on macOS) Xcode + Command Line Tools. It's a 3-second probe that catches misconfiguration before `cargo check` would have to download dependencies. **For tools with rich prereq chains, the tool's own `info` subcommand is usually the right smoke gate.**

### Lesson 6 — Responsive primitives at the hook layer compose with the state architecture for free

`useBreakpoint` is a hook (lives in `src/shared/hooks/`). `<ResponsiveShell>` is a component. Neither imports a store. Neither performs I/O. The state architecture and the responsive architecture **compose without friction** because both respect the same layering rules. No special case for "responsive state" was needed.

### Lesson 7 — Branded PWA icons via Minijinja + rasterize-if-available is the right fallback shape

Generate SVG icons from a brand-resolved Minijinja template (initial letter + ember background). If `rsvg-convert` is on PATH, rasterize to PNG. If not, copy the SVG to a `.png` filename so the manifest reference resolves; emit a warning. **Manifest references always resolve; user upgrades the icon when they want.** Pragmatic over perfect.

## Pipeline Maturity Assessment

```
Ideation → refined artifact          (LLM-driven via phase-0 skill specs)
        ↓
Conversion (HTMX → React)            (phase-3, with --llm-judgment via openai-proxy)
        ↓
Rebranding                           (phase-3)
        ↓
Scaffolding (Vite/React/Tailwind v4/shadcn-on-Base-UI/zustand+immer)  (phase-2 + phase-4 A)
        ↓
Responsive primitives + PWA          (phase-4 B)
        ↓
Single-binary axum deployment        (phase-2 --with-axum-wrapper)
        ↓
Tauri 2 hybrid (desktop + iOS/Android)  (phase-4 C, --with-tauri-wrapper)

Inference routing config             (phase-1b)
Inference routing runtime            (phase-prefer-endpoint-consumption)
```

**Three deployment targets from one source:**
1. Web (PWA-installable)
2. Tauri desktop (macOS / Windows / Linux)
3. Tauri mobile (iOS / Android)

**Plus** the single-binary axum option (orthogonal — for backend-served deployments).

## Recommended Focus for Next Phase

The original ideation-to-app pipeline is complete end-to-end. Remaining work is **additive scaffolders** for other targets, plus the auxiliary conversions:

### Option A — `phase-3b-aux-conversions` (recommended)

Complete the three deferred phase-0 conversion skills: `convert-md-to-htmx`, `refine-moodboard`, `design-svg-logo` execution layers. Self-contained, rounds out the phase-0 promise. Smaller scope; no new architecture to design.

### Option B — `phase-7-scaffold-ag-ui-host`

Leverage openai-proxy's AG-UI SSE surface (already running via phase-1b) + the scaffolder substrate. Builds an agent-backed app host. More ambitious — raises new design questions about how stores integrate with streaming events.

### Option C — `phase-6-scaffold-flutter`

Apply the scaffold-substrate pattern to Flutter. Largest architectural divergence (Dart instead of TS, Riverpod/Bloc instead of zustand). Substantial reuse of the *concepts* but the *implementation* is largely fresh.

### Option D — Polish phase

Audit existing scaffolds for: PNG icon quality, Tauri menu bar polish, native window controls, plugin selection automation, Vite 8 upgrade when shadcn ships. No new capabilities; quality lift across what shipped.

**Recommendation: A.** It's the smallest unfinished commitment from the original phase-0 plan. After A, B or C becomes the next visible expansion.

## Knowledge Base Hooks

- "Retroactive correction is 5x more iteration-heavy than net-new code with clean boundaries"
- "Regex/string-based config patching requires deliberate punctuation handling that AST-patching handles automatically"
- "`0` is a number, not a boolean — explicit type-shape detection beats JavaScript truthy/falsy reasoning"
- "Tauri 2 + PWA coexist without conditional builds at modest bundle-size cost"
- "Use the tool's own `info` subcommand as the cheapest prereq-chain smoke gate"
- "Responsive primitives at the hook layer compose freely with the state architecture"
- "Branded asset generation via Minijinja + rasterize-if-available is the pragmatic fallback shape"

## Reflection Metadata

```yaml
phase: phase-4-scaffold-tauri-desktop
goals_met: 16/16 (100%)
acceptance_gates_passed: 8/8
first_pass_quality: 10/15 (67%; concentrated in Block A retroactive work)
refinement_iterations:
  block_a: 5 (patcher regex → Python rewrites)
  block_b: 1 (PWA plugin leading comma)
  block_c: 0 (clean first-try)
  block_d: 0 (sweep)
technical_debt_blocking: false
deployment_targets_shipped: web, PWA-installable, Tauri desktop, Tauri mobile
pipeline_maturity: ideation-to-app loop complete across 4 deployment targets
next_phase_recommended: phase-3b-aux-conversions
alternates: [phase-7-scaffold-ag-ui-host, phase-6-scaffold-flutter, polish-pass]
```

Completed kbd-reflect — phase-4-scaffold-tauri-desktop
