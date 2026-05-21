# Phase Assessment: Ideation-to-App Pipeline

**Phase:** `phase-ideation-to-app-pipeline`
**Project:** `artifact-refiner` (Travis James skill pack)
**Date:** 2026-05-20
**Author:** Claude Code (Opus 4.7, 1m context)
**Mode:** Assessment only — no implementation
**Sycophancy correction:** applied (S-01 deference, S-03 scope-inflation, S-04 over-agreement audited)

---

## 1. Goal Restatement

Expand `artifact-refiner` so that an LLM-produced React/TSX or HTMX artifact — created mid-conversation during ideation — can be converted into a working project across multiple execution targets:

| Target           | Status today      |
| ---------------- | ----------------- |
| Web (React/Vite) | partial (HTMX/React refinement exists, no scaffolding) |
| Tauri (desktop)  | not present       |
| Tauri (mobile)   | not present       |
| Flutter          | not present       |
| A2UI             | refinement only, no scaffolding |
| AG-UI            | refinement only, no scaffolding |
| MCP-UI           | not present       |

Two cross-cutting capabilities also requested:

1. A `lovable.dev` / `v0.dev`-style toolset: `write`, `edit`, `search-files`, `add-dependency`, `view`, `rename`, `delete`, web fetch, web search, etc., available as **native Rust CLI utilities** and surfaced via an internal MCP server.
2. A filesystem MCP server bundled with the skill pack (build + install + auto-load) so that `artifact-refiner` works inside any harness without depending on host-provided filesystem tools. Reference implementation: `rust-mcp-filesystem` at `github.com/GQAdonis/rust-mcp-filesystem` (24 tools already implemented).

---

## 2. Sycophancy-Corrected Assessment of the Proposal

### Where the proposal is genuinely valuable

These are real, defensible value claims, not flattery:

- **Gap is real.** Today the skill produces *artifacts* (TSX strings, SVG, HTML) but stops at the artifact boundary. Going from a refined artifact to a runnable project is a manual context-shift the user does dozens of times. Closing this loop is concrete leverage.
- **Submoduling `rust-mcp-filesystem` is sound.** The repo already exposes 24 tools (`ReadTextFile`, `WriteFile`, `EditFile`, `SearchFilesContent`, `DirectoryTree`, `ZipFiles`, etc.) over MCP stdio. These map almost 1:1 to the lovable/v0 toolset. Re-implementing is wasted effort.
- **Decoupling from harness file tools is sound.** Antigravity 2.0 (no BYOK), Claude Desktop (no filesystem), and arbitrary MCP clients lack a uniform file edit surface. Bundling our own removes a deployment dependency.
- **Multi-target framing is correct in spirit.** A2UI, AG-UI, and MCP-UI are component/spec languages, not full apps — they need a *host* scaffold (Tauri shell, Flutter shell, web shell) to be runnable. That host gap is the actual unmet need.

### Where the proposal needs to be corrected, not endorsed

These are the honest deltas — places where the request as stated would inflate scope, duplicate existing work, or create maintenance liability.

#### Correction 1 — "Same set of tools as lovable/v0" is the wrong abstraction

Lovable's `lov-write`, `lov-search-files`, `lov-add-dependency` are *named* tools because Lovable controls the model's available tool list. **We are not the model harness.** When `artifact-refiner` runs inside Claude Code, Claude Desktop, or Antigravity, those harnesses already provide `Write`, `Edit`, `Grep`, `Bash`. Wrapping them in our own renamed MCP tools is:

- duplicate surface area
- a context-token tax (extra tool descriptions)
- a fragility risk (our wrapper drifts from harness primitives)

**Corrected goal:** ship an MCP server that provides what the *harness lacks*, not a parallel renamed version of what the harness already has. That means: scaffold generators, framework adapters, dependency resolvers, build runners, framework-specific patchers — not generic `write_file`.

#### Correction 2 — "Native Rust CLI utilities" for everything is over-engineering

The session doc and prior pattern (`template-forge-rs`) already commit to Rust for template rendering. That is justified because Askama/Minijinja are best-in-class Rust libraries and the output is deterministic.

Generic file ops (`patch`, `replace`, `find-in-files`) do **not** benefit from Rust. They benefit from:

- using the harness primitive when present (zero cost)
- delegating to `rust-mcp-filesystem` when not (already done, by someone else)
- never writing it ourselves

**Corrected goal:** Rust for things that are genuinely Rust-shaped — scaffold generators with embedded templates (Askama), AST transforms (swc/oxc bindings or syn), JSON schema validators (a2ui, ag-ui), framework adapters that need to be fast and embeddable. Not for `mv` and `grep`.

#### Correction 3 — "Path to ideation → web/Tauri/Flutter/AG-UI/A2A apps" is N projects, not 1

The single phrase hides at least seven distinct scaffolders:

1. React/Vite web app
2. Tauri 2.x desktop shell (Rust backend + chosen frontend)
3. Tauri 2.x mobile (iOS + Android targets)
4. Flutter app (Dart, completely different toolchain)
5. AG-UI agent-backed app (TypeScript SDK + agent runtime)
6. A2UI spec→runtime app
7. A2A (Agent-to-Agent) app (different protocol, different runtime)

Treating these as a single epic guarantees no single one finishes well. **They share `convert-artifact-to-component` and `inject-into-template`, but the templates themselves are independent 1–3 week efforts each.**

**Corrected goal:** pick one scaffold target as the v1 deliverable (recommend **React/Vite web** since it is closest to the existing TSX/HTMX refinement output and validates the architecture). Treat Tauri/Flutter/AG-UI/A2UI/MCP-UI as v2…v7, each with its own KBD phase.

#### Correction 4 — Including this skill as a submodule of `prometheus-skill-pack` is fine, but bidirectional submoduling is not

The proposal says "prometheus-skill-pack should include this skill as a submodule" *and* artifact-refiner should consume `rust-mcp-filesystem` as a submodule. That is one-way nesting — fine.

The risk: if `artifact-refiner` also imports things *from* `prometheus-skill-pack` (sycophancy-correction is referenced via a relative path in the session doc), we have a cycle:

```
prometheus-skill-pack ──submodule──▶ artifact-refiner
artifact-refiner      ──path import──▶ prometheus-skill-pack/skills/imported/sycophancy-correction
```

This works only if sycophancy-correction is also extracted to its own repo and consumed as a submodule by both. Otherwise the dependency graph is unresolvable at clone time.

**Corrected goal:** before nesting, extract `sycophancy-correction` to a standalone repo and consume it as a submodule from both packs. Then the graph is a DAG, not a cycle.

#### Correction 5 — Lovable/v0 are not the right north-star for *this* skill

Lovable and v0 are end-user products with a chat UI, a sandbox, a deploy button, billing, and an opinionated stack. They optimize for a fully-managed loop.

We are building a **skill** that runs inside *someone else's* harness. The user already has chat, the harness already has execution, deployment is downstream. Copying lovable's full tool surface ignores that asymmetry.

**Corrected north-star:** the skill should answer "given a refined artifact in memory and the user's chosen target framework, produce a buildable project on disk and hand the harness back control to iterate." That is much smaller than "be lovable."

---

## 3. Current State (Code Inventory)

### What exists in `artifact-refiner` today

| Surface                              | Status                                        |
| ------------------------------------ | --------------------------------------------- |
| PMPO orchestration (`prompts/`)      | complete, v1.2.0 tagged                       |
| Sub-skills (refine-logo/ui/content/image/a2ui/validate/status) | complete                |
| AG-UI domain + schema                | added in `191608e` (just pulled)              |
| A2UI domain + schema + normalizer    | complete                                      |
| State provider waterfall             | complete (`scripts/state-resolve-provider.sh`)|
| Hooks (PostToolUse, SubagentStop, Stop) | complete                                   |
| Examples (a2ui, ag-ui)               | complete                                      |
| `template-forge-rs` Rust workspace   | **scaffolded, never compiled** (per session doc Priority 1) |
| Six new skill dirs (convert-md-to-htmx, convert-htmx-react, rebrand-artifact, refine-moodboard, design-svg-logo, build-artifact-library) | **5 of 6 SKILL.md files incomplete or empty** |
| `tools/` directory at repo root      | **does not exist** (session doc shows it under template-forge-rs only) |
| `.kbd-orchestrator/`                 | **did not exist before this phase**           |
| Filesystem MCP integration           | **none**                                      |
| Scaffold generators (any framework)  | **none**                                      |
| Lovable/v0 prompt corpus             | present at `docs/prompts/{v0,lovable}/` — reference material only, not wired |

### What exists in `rust-mcp-filesystem` (the candidate submodule)

24 MCP tools already implemented (`src/tools/`):
`ReadTextFile`, `WriteFile`, `EditFile`, `CreateDirectory`, `DirectoryTree`, `ListDirectory`, `ListDirectoryWithSizes`, `MoveFile`, `SearchFiles`, `SearchFilesContent`, `GetFileInfo`, `ReadFileLines`, `HeadFile`, `TailFile`, `ReadMediaFile`, `ReadMultipleTextFiles`, `ReadMultipleMediaFiles`, `FindEmptyDirectories`, `FindDuplicateFiles`, `CalculateDirectorySize`, `ListAllowedDirectories`, `ZipFiles`, `UnzipFile`, `ZipDirectory`.

Read-only by default; opt-in write tier. Distributed via cargo-binstall, brew, npm, Docker, prebuilt binaries.

### What exists in `prometheus-skill-pack` (the pattern reference)

Workspace tools (`tools/`):
- `forge-rs` — 6-crate Rust workspace (forge-core, forge-skills, forge-enricher, forge-reflect, forge-mcp, forge-cli) — Karpathy loop implementation
- `prometheus-cli` — wraps forge crates as a CLI
- `liter-llm` — model router
- `prometheus-knowledge` — knowledge graph
- `surreal-memory-server` — memory MCP
- `prometheus-rust-auditor` — Rust review

This is the proven multi-crate pattern to mirror.

---

## 4. Gap Analysis (What is Missing, by Layer)

### Layer A — Tooling Layer (Rust workspace under `artifact-refiner/tools/`)

| Component                    | Have | Need | Gap severity |
| ---------------------------- | ---- | ---- | ------------ |
| `template-forge-rs` workspace skeleton | yes (session-doc) | yes | builds-broken (Priority 1 in session doc) |
| Compiling Rust workspace     | no   | yes  | **HIGH**     |
| `rust-mcp-filesystem` submodule under `tools/` | no | yes | **HIGH**     |
| Build script that builds both rust-mcp-filesystem and template-forge | no | yes | MEDIUM |
| Install script wiring binaries into PATH | partial (template-forge only) | yes | MEDIUM |
| `.mcp.json` registering bundled MCP servers | partial | yes | MEDIUM |

### Layer B — Scaffold Layer (project generators)

This layer is entirely absent. To produce a runnable project from a refined artifact, we need:

| Generator               | Inputs                            | Outputs                          | Gap |
| ----------------------- | --------------------------------- | -------------------------------- | --- |
| `scaffold-react-vite`   | refined TSX, brand tokens, deps   | `vite + react + ts` project tree | missing |
| `scaffold-tauri-desktop`| refined TSX/HTMX, brand           | Tauri 2.x app w/ Rust backend    | missing |
| `scaffold-tauri-mobile` | refined TSX                       | Tauri mobile (iOS/Android)       | missing |
| `scaffold-flutter`      | refined UI spec or rebuilt widgets| Flutter app                       | missing |
| `scaffold-ag-ui-app`    | AG-UI spec (we now have schema)   | TS host app + agent runtime      | missing |
| `scaffold-a2ui-host`    | A2UI component                    | host renderer                     | missing |
| `scaffold-mcp-ui`       | MCP-UI component spec             | MCP-UI compliant host             | missing |

Each generator must:

1. Read the refined artifact from refinement state.
2. Resolve dependencies (e.g., shadcn/ui registry, Radix, Tailwind preset).
3. Emit a template tree (Askama at build time, runtime variables for brand/data).
4. Run the framework's init command (`pnpm create vite`, `cargo create-tauri-app`, `flutter create`) where doing it ourselves is wasteful.
5. Patch the init output with our artifact.
6. Verify build (`pnpm build`, `cargo tauri build`, `flutter build`).

### Layer C — Conversion Layer (artifact → component)

| Conversion                          | Have                                 | Need                                | Gap |
| ----------------------------------- | ------------------------------------ | ----------------------------------- | --- |
| HTMX ↔ React TSX (bidirectional)    | `skills/convert-htmx-react/` (empty) | complete SKILL.md + executable      | **HIGH** |
| Markdown → HTMX (branded)           | `skills/convert-md-to-htmx/` (partial)| finish SKILL.md                    | MEDIUM |
| React TSX → Flutter widgets         | none                                  | new skill `convert-tsx-to-flutter`  | HIGH |
| React TSX → A2UI                    | none                                  | new skill                            | MEDIUM |
| React TSX → AG-UI fragment          | none (we have AG-UI domain but no converter from refined UI) | new skill | MEDIUM |
| Rebrand existing artifact           | `skills/rebrand-artifact/` (empty)   | complete                             | MEDIUM |

### Layer D — Filesystem & Editing Layer

| Capability                          | Source              | Action |
| ----------------------------------- | ------------------- | ------ |
| Read/write/edit/search/move files   | rust-mcp-filesystem | submodule, build, register |
| Patch (line-based or AST)           | rust-mcp-filesystem `EditFile` covers line-based; AST patching not present | add as new tool only if needed |
| Grep / regex search                 | rust-mcp-filesystem `SearchFilesContent` | already present |
| Dependency add (npm/cargo/pub)      | none in fs MCP      | new helper (small Rust crate or shell wrapper) |
| Build runner / test runner          | none                | thin wrapper, low priority |

**Conclusion:** rust-mcp-filesystem covers ~85% of the lovable/v0 raw file ops. The remaining 15% is package-manager integration, which is naturally per-target.

### Layer E — Submodule / Repo Topology

Required topology (DAG, not cycle):

```
sycophancy-correction (extracted to own repo)
        ▲                ▲
        │                │
artifact-refiner ──submodule──▶ rust-mcp-filesystem
        ▲
        │
prometheus-skill-pack
```

Action items:

1. Extract `prometheus-skill-pack/skills/imported/sycophancy-correction/` to a standalone repo.
2. Add `sycophancy-correction` as a submodule of `artifact-refiner` (path: `skills/_imports/sycophancy-correction/`).
3. Add `rust-mcp-filesystem` as a submodule of `artifact-refiner` (path: `tools/rust-mcp-filesystem/`).
4. Add `artifact-refiner` as a submodule of `prometheus-skill-pack` (path: `skills/imported/artifact-refiner/`).

### Layer F — Documentation & Skill Definitions

| Skill                       | SKILL.md status        |
| --------------------------- | ---------------------- |
| `build-artifact-library`    | complete               |
| `convert-md-to-htmx`        | **partial**            |
| `convert-htmx-react`        | **empty**              |
| `rebrand-artifact`          | **empty**              |
| `refine-moodboard`          | **empty**              |
| `design-svg-logo`           | **empty**              |
| `scaffold-react-vite` (new) | **missing**            |
| `scaffold-tauri` (new)      | **missing**            |
| `scaffold-flutter` (new)    | **missing**            |
| `scaffold-ag-ui` (new)      | **missing**            |
| `scaffold-a2ui-host` (new)  | **missing**            |
| `scaffold-mcp-ui` (new)     | **missing**            |
| `add-dependency` (new)      | **missing**            |

---

## 5. Viability Assessment

### Feasibility: HIGH for v1, MEDIUM for v2+

- v1 (React/Vite + bundled filesystem MCP + 6 existing partial skills completed): genuinely achievable in 2–3 focused sessions.
- v2 onward (Tauri, Flutter, AG-UI host, A2UI host, MCP-UI): each is one phase; viable if scoped independently and not bundled.

### Value: HIGH if scoped, LOW if bundled

The single highest-leverage delta is **"refined TSX artifact → running Vite project on disk with brand tokens applied"**. Every downstream target reuses that mechanism. Skipping straight to Flutter without doing React first means rebuilding the conversion+scaffold+brand-injection plumbing for an unfamiliar runtime simultaneously.

### Risk: MEDIUM, concentrated in three areas

1. **Submodule cycle (Correction 4)** — must be resolved before adding any submodules.
2. **template-forge-rs has never compiled** (session doc Priority 1). Until it compiles, every downstream skill that depends on rendered templates is blocked. This is the single most-urgent unblock.
3. **Tool sprawl** — if every framework target gets its own Rust crate, the workspace will balloon. Need an early policy on what is shared vs. per-target.

### Maintenance cost: MEDIUM

- One Rust workspace (template-forge + new scaffold crates) is fine.
- One submodule (rust-mcp-filesystem) is fine if upstream tracks releases.
- Per-target scaffold templates (Vite, Tauri, Flutter) are real maintenance debt as those frameworks evolve. Mitigation: delegate initial scaffold to `npm create vite@latest` / `cargo create-tauri-app` rather than reimplementing, and only own the patcher.

---

## 6. Recommended Phase Decomposition (for the Planning phase)

This is the input to `/kbd-plan`, not a plan itself.

| Proposed phase                          | Scope                                                                   | Blocks   |
| --------------------------------------- | ----------------------------------------------------------------------- | -------- |
| **phase-0-unblock**                     | Get template-forge-rs compiling. Complete 5 partial SKILL.md files. Extract sycophancy-correction to own repo. | none |
| **phase-1-submodule-topology**          | Add rust-mcp-filesystem + sycophancy-correction submodules. Build script. .mcp.json registration. | phase-0 |
| **phase-2-scaffold-react-vite**         | New `scaffold-react-vite` skill + Rust crate. End-to-end: refined TSX → running Vite app with brand tokens. | phase-1 |
| **phase-3-conversion-layer**            | Complete convert-htmx-react, rebrand-artifact. Add convert-tsx-to-ag-ui-fragment. | phase-0 |
| **phase-4-scaffold-tauri-desktop**      | Tauri 2.x desktop scaffolder reusing phase-2 patcher.                   | phase-2 |
| **phase-5-scaffold-tauri-mobile**       | Tauri mobile (iOS+Android).                                              | phase-4 |
| **phase-6-scaffold-flutter**            | Flutter scaffolder. Independent toolchain — investigate Dart codegen.   | phase-3 |
| **phase-7-scaffold-ag-ui-host**         | AG-UI agent host app using existing AG-UI schema.                       | phase-3 |
| **phase-8-scaffold-a2ui-host**          | A2UI rendering host.                                                     | phase-3 |
| **phase-9-scaffold-mcp-ui**             | MCP-UI compliant host (research-heavy — protocol is new).               | phase-3 |

Recommendation: only commit to phases 0–2 now. Re-evaluate after phase 2 ships.

---

## 6a. Addendum — Inference Cost/Routing Layer (`openai-proxy`)

Added after first-draft review. The user surfaced `references/baseline/openai-proxy` as a candidate inference layer. Reviewed; it changes the assessment in concrete ways.

### What `openai-proxy` actually is

Rust binary (workspace under `references/baseline/openai-proxy/`) exposing **six** delivery surfaces from one process:

| Surface       | Route                          | Consumer                                |
| ------------- | ------------------------------ | --------------------------------------- |
| HTTP proxy    | `POST /v1/chat/completions`    | Any OpenAI-compatible SDK               |
| opencode      | npm plugin `@prometheus-ags/opencode-codex-proxy` | opencode AI coding agent |
| MCP server    | stdio + Streamable HTTP        | Claude Code, Codex CLI, Gemini CLI      |
| ACP server    | stdio (Agent Client Protocol v0.11) | Zed, JetBrains                     |
| AG-UI         | `POST /ag-ui/stream` (SSE)     | CopilotKit, AG-UI frontends             |
| A2A agent     | `GET /.well-known/agent.json`  | A2A multi-agent discovery               |

Auth modes: ChatGPT Plus/Pro OAuth (via `codex login` → `~/.codex/auth.json`) **or** raw OpenAI API key. Auth waterfall handled by the npm plugin.

Model catalog: eight canonical IDs (`gpt-5.5`, `gpt-5.5-pro`, `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.4-nano`, `gpt-5.3-codex`, `gpt-5.3-chat`, `gpt-5.2-chat`), with dynamic refresh from `/v1/models`.

### Why this is materially relevant — not just "another LLM"

Three things are different from "use another model provider":

1. **Subscription-backed inference** — routes Codex / GPT-5.x calls through a $20/mo ChatGPT Plus or $200/mo Pro subscription instead of per-token API billing. For agentic loops doing many small turns (which is exactly what the scaffold/conversion phases will do), this is the difference between "experiment freely" and "watch the meter."
2. **Native AG-UI and A2A surfaces already exist.** The artifact-refiner just added AG-UI domain + schema (`191608e`). The natural runtime host is a system that already speaks AG-UI over SSE. `openai-proxy` does. This is not a coincidence we should ignore.
3. **Six surfaces from one binary.** This is the same pattern `template-forge-rs` adopts (CLI + MCP from shared core). Architecturally compatible — both can be co-installed and registered in `.mcp.json` without conflict.

### Cost-aware-llm-pipeline routing fit

A `cost-aware-llm-pipeline` skill already exists in the available skill list. The realistic routing intent for artifact-refiner phases looks like:

| Phase                                  | Routing target                                           | Rationale                              |
| -------------------------------------- | -------------------------------------------------------- | -------------------------------------- |
| `refiner-iterate` (small)              | `openai-proxy` → `gpt-5.4-mini` or `gpt-5.4-nano` (subscription) | High call volume, cheap turns          |
| `refiner-evaluate` (medium)            | `openai-proxy` → `gpt-5.4` or `gpt-5.3-codex`            | Reflection, code reasoning             |
| `refiner-finalize` (small)             | `openai-proxy` → `gpt-5.4-mini`                          | Final pass, low risk                   |
| Plan / design (heavy reasoning)        | Claude Opus / Sonnet via host harness                    | Best deep reasoning, used sparingly    |
| Scaffold codegen (deterministic)       | `gpt-5.3-codex` via proxy, or local model via opencode   | Codex-tuned, subscription-priced       |

This is **not** "always use the cheapest model." It is "use the right tier through whichever billing surface gives the best price for that tier." The proxy makes that switch a config change, not a code change.

### What `openai-proxy` does NOT solve

Honest list, to prevent over-claiming:

- It does **not** give us Claude/Anthropic models — those still go through the host harness or Anthropic's SDK directly. The proxy is OpenAI-compatible upstream, not Anthropic.
- It does **not** replace the host harness's tool-calling for filesystem / bash. We still need `rust-mcp-filesystem` for that.
- It does **not** itself host AG-UI *applications*. Its `/ag-ui/stream` endpoint emits structured events for CopilotKit-style frontends; it is not a CopilotKit scaffold generator.
- It is **a separate Cargo workspace** (`baseline/openai-proxy`) — submoduling it means another moving part to track upstream.

### Where `openai-proxy` slots into the topology

Revised DAG (extends §4 Layer E):

```
sycophancy-correction  ◀── extracted, standalone
        ▲ ▲
        │ │
artifact-refiner ──submodule──▶ rust-mcp-filesystem
        │
        └──submodule (optional)──▶ openai-proxy
        ▲
        │
prometheus-skill-pack
```

Two viable wiring options (decision deferred to planning):

| Option | How                                                                                     | Pros                                                          | Cons                                                                 |
| ------ | --------------------------------------------------------------------------------------- | ------------------------------------------------------------- | -------------------------------------------------------------------- |
| **A — Submodule** | Add `openai-proxy` as a submodule under `tools/openai-proxy/`. Build script builds it. Install script registers its MCP surface in `.mcp.json`. | Self-contained skill pack; reproducible installs.            | Larger workspace; rebuilds the proxy on every install; coupling.    |
| **B — External dependency** | Document the proxy as a prerequisite. Detect it at install time. Register its MCP endpoint if running. | Lighter footprint; proxy upgrades independently. | Less reproducible; user must install proxy separately.              |

**Recommendation:** start with Option B for phase-1. Promote to Option A only if independent upgrades cause friction. Reason: the proxy already has its own release cadence and the install dance (`codex login`, auth files) is naturally a one-time user step, not a per-skill-pack step.

### Impact on `references/model-routing.md`

The file `references/model-routing.md` was added in v1.2.0 and references a `model_policy` block in `.kbd-orchestrator/project.json`. The current routing reference does **not** mention `openai-proxy` as an endpoint. Phase-1 should add an `endpoints:` section to the routing reference, e.g.:

```yaml
endpoints:
  openai_proxy:
    base_url: "http://localhost:8080/v1"
    auth_mode: "chatgpt_oauth"   # or "openai_api_key"
    models: [gpt-5.5, gpt-5.5-pro, gpt-5.4, gpt-5.4-mini, gpt-5.4-nano, gpt-5.3-codex, gpt-5.3-chat, gpt-5.2-chat]
  anthropic_host:
    via: "host_harness"
    models: [claude-opus, claude-sonnet, claude-haiku]
```

The phase mappings (`refiner-iterate: small`, etc.) become endpoint-aware:

```yaml
phases:
  refiner-iterate:
    tier: small
    prefer_endpoint: openai_proxy
    prefer_model: gpt-5.4-mini
  refiner-evaluate:
    tier: medium
    prefer_endpoint: openai_proxy
    prefer_model: gpt-5.3-codex
```

### Sycophancy check on this addition

S-04 audit applied — am I just agreeing because the user surfaced it? Three independent reasons it survives correction:

1. The new AG-UI domain support in v1.2.0 needs a runtime that emits AG-UI events. `openai-proxy` already does. Convergence, not coincidence.
2. The model-routing reference (`references/model-routing.md`) is already in the repo with no concrete endpoint binding. The proxy is a concrete answer to a question already asked.
3. Cost is real. Without subscription-backed inference, the phase-2 scaffolder's iteration loop is metered per token; with it, it's effectively flat-rate. This changes what kinds of experiments are affordable.

What does **not** survive: the implicit suggestion that we should depend on it *now*. Phase-0 doesn't need it. Phase-1's submodule topology decision should account for it but not require it. Phase-2 (scaffold-react-vite) is the first phase where the cost benefit is large enough to justify wiring.

### Adjusted phase decomposition

Inserting **phase-1b** between submodule topology and the first scaffolder:

| Phase                            | Scope adjustment                                                                       |
| -------------------------------- | -------------------------------------------------------------------------------------- |
| phase-0-unblock                  | unchanged                                                                              |
| phase-1-submodule-topology       | unchanged for filesystem MCP. Defer `openai-proxy` submodule decision. Document Option B as default. |
| **phase-1b-inference-routing** (NEW) | Wire `openai-proxy` as an external endpoint. Extend `references/model-routing.md` with `endpoints:`. Make `cost-aware-llm-pipeline` consume the endpoint config. Add a health probe to the install script. |
| phase-2-scaffold-react-vite      | unchanged in scope. Benefits from phase-1b's cost routing immediately.                 |
| phase-3 …                        | unchanged                                                                              |

phase-1b is a **small** phase (≤1 session) by design. If it grows past that during planning, it is being over-scoped.

### Two new open questions added to §7

(See questions 9 and 10 below.)

---

## 7. Open Questions for the Planning Phase

These must be answered before `/kbd-plan` produces a useful plan:

1. **Is the user committing to phase-0 first**, or insisting on parallel phase-0 + phase-1 + phase-2? (Parallel is doable but raises risk.)
2. **Sycophancy-correction extraction**: own GitHub repo, or remain inside prometheus-skill-pack with the cycle accepted? (Recommendation: extract.)
3. **rust-mcp-filesystem fork or upstream submodule?** GQAdonis owns a fork. If patches are needed (e.g., a custom tool), fork-and-track. If not, point at upstream `rust-mcp-stack/rust-mcp-filesystem`.
4. **Scaffold delegation policy**: do we `exec` the framework's official scaffolder (`npm create vite@latest`, `cargo create-tauri-app`, `flutter create`) and then patch, or do we ship a templated tree of our own? (Recommendation: delegate then patch — lower maintenance.)
5. **AST patcher choice for TSX**: swc (Rust binding `swc_ecma_parser`), oxc, or treesitter? (Recommendation: swc — most mature Rust bindings; matches Tauri ecosystem.)
6. **MCP-UI**: is this a real protocol the user already targets, or an aspiration? (If aspiration, drop from current scope.)
7. **Brand-token registry**: where does the source of truth live? `assets/library/brands/*.toml` is the current pattern. Should scaffolders pull from there, from a remote registry, or both?
8. **Do scaffolded apps inherit the refinement loop** (so the user can keep refining inside the generated project) or are they handed off cleanly? (Recommendation: clean handoff for v1, refinement re-entry as v2 feature.)
9. **`openai-proxy` wiring mode**: submodule (Option A) or external prerequisite (Option B)? (Recommendation: Option B for phase-1b; revisit if upgrade friction shows up.)
10. **Default inference endpoint per phase**: should `refiner-iterate` default to `gpt-5.4-mini` via proxy, fall back to host-harness Claude, or be user-configurable in `.kbd-orchestrator/project.json → model_policy`? (Recommendation: user-configurable with proxy as the *suggested default* when the proxy health probe passes.)

---

## 8. Pre-Planning Action Items (Independent of Plan Approval)

These can start now without committing to the full pipeline:

- [ ] Fix Priority 1 from `session-2026-05-20-artifact-refiner-buildout.md` — make `tools/template-forge-rs` compile. Single highest-leverage unblock.
- [ ] Complete the 5 partial SKILL.md files (Priority 2 from same doc).
- [ ] Decide on sycophancy-correction extraction (governance, not code).
- [ ] Audit `rust-mcp-filesystem` upstream activity (release cadence, issue count) before committing to it as a submodule. If maintenance is shaky, fork.
- [ ] Skim `docs/prompts/v0/tools.json` and `docs/prompts/lovable/agent-tools.json` and produce a short "what is covered by rust-mcp-filesystem vs. what we'd need new" mapping. (~30 minutes of work.)

---

## 9. Honest Verdict (Sycophancy-Corrected)

The proposal **identifies a real gap with real leverage**, but the way it is currently framed conflates seven scaffold targets, an MCP wrapping layer, a submodule reorganization, and a still-broken Rust workspace into a single ask. Treated that way it will not converge.

Treated as a sequenced phase pipeline starting from `phase-0-unblock` (compile template-forge, finish the 5 SKILL.md files, decide submodule topology) and proceeding to `phase-2-scaffold-react-vite` as the first real proof point, it is achievable and high-value.

**The most important thing to do *before* planning** is to commit to phasing — not to ship anything new yet. Planning a single 7-target epic will produce a plan that cannot be executed; planning phase-0 → phase-2 will produce a plan that can.

---

## 10. Assessment Metadata

```yaml
assessment_complete: true
phase: phase-ideation-to-app-pipeline
inputs_reviewed:
  - docs/session-2026-05-20-artifact-refiner-buildout.md
  - SKILL.md (v1.2.0)
  - docs/prompts/v0/{prompt.md,tools.json}
  - docs/prompts/lovable/{agent-prompt.md,agent-tools.json}
  - /Users/gqadonis/Projects/references/rust-mcp-filesystem (24 tools cataloged)
  - /Users/gqadonis/Projects/prometheus/prometheus-skill-pack (tools/, skills/)
  - examples/{a2ui,ag-ui}-* (new in v1.2.0)
  - /Users/gqadonis/Projects/references/baseline/openai-proxy (six-surface inference router)
sycophancy_patterns_addressed:
  - S-01 deference: countered by Corrections 1, 2, 4, 5
  - S-03 scope-inflation: countered by Correction 3 (phase decomposition)
  - S-04 over-agreement: countered by explicit risk + verdict sections
recommendation: |
  Proceed to /kbd-plan but constrain the plan to phase-0 (unblock) +
  phase-1 (submodule topology, filesystem MCP) + phase-1b (inference
  routing via openai-proxy as external endpoint) + phase-2 (scaffold-
  react-vite). Defer remaining scaffold targets to later KBD phases.
addendum_2026_05_20: |
  openai-proxy reviewed and integrated as phase-1b. Routing strategy
  added to §6a. Two open questions (9, 10) added covering wiring mode
  and default endpoint per phase. Recommendation: Option B (external
  prerequisite) for v1.
next_command: /kbd-plan phase-0-unblock
```

Completed kbd-assess — phase-ideation-to-app-pipeline
