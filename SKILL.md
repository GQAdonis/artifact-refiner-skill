---
name: artifact-refiner
description: >
  Use this skill when creating or iteratively refining artifacts (logos, UI components,
  A2UI specifications, images, or content) using structured PMPO orchestration with
  explicit constraints, deterministic execution, and persistent artifact state.
allowed-tools: code_interpreter file_system image_generation browser_renderer
---

# Artifact Refiner

A PMPO-driven, artifact-centric refinement engine capable of creating and iteratively improving artifacts across multiple domains using AI reasoning and deterministic code execution.

## Supported Artifact Domains

- **Logos & brand systems** — SVG/PNG variants, wordmarks, icons, showcase pages
- **React / HTML UI concepts** — Component hierarchies, design tokens, accessibility
- **A2UI specifications** — Structural integrity, schema compliance, normalization
- **Image assets** — Composition, brand colors, resolution, format conversion
- **Content artifacts** — Markdown/HTML structure, tone, heading normalization

## Core Principles

1. **Artifact-centric** — State persisted to disk, never in conversational context
2. **Tool-augmented** — Uses code interpreter / e2b sandbox for deterministic transformations
3. **Constraint-driven** — Structured constraints with severity levels drive convergence
4. **Iterative** — Explicit convergence rules and maximum iteration guards
5. **PMPO meta-loop** — Specify → Plan → Execute → Reflect → Persist → Loop/Terminate

## Execution Model (PMPO Loop)

The skill follows the Prometheus Meta-Prompting Orchestration loop. For full theory, see `references/pmpo-theory.md`.

1. **Specify** (`prompts/specify.md`) — Transform intent into structured specification
2. **Plan** (`prompts/plan.md`) — Convert specification into executable strategy
3. **Execute** (`prompts/execute.md`) — Apply transformations via AI + deterministic tools
4. **Reflect** (`prompts/reflect.md`) — Evaluate outputs against constraints
5. **Persist** (`prompts/persist.md`) — Write validated state to disk
6. **Loop or Terminate** — Continue if constraints unsatisfied, stop if converged

## Required Tools

- `code_interpreter` or e2b MCP sandbox (`mcp__e2b-sandbox__run_python_code`)
- `file_system` — Read/write artifact files

### Optional Tools

- `image_generation` — For logo/image domains
- `browser_renderer` — For UI/A2UI preview rendering
- Local fallback scripts — `node scripts/compile-tsx-preview.mjs` and `node scripts/render-preview.mjs`

## Inputs

```yaml
artifact_type: string  # logo | ui | a2ui | image | content
constraints: array     # See references/schemas/constraints.schema.json
target_state:
  description: object  # Desired end state
current_state: optional object  # Existing artifact to refine
```

## Outputs

```yaml
refined_artifact: object
artifact_manifest: object  # See references/schemas/artifact-manifest.schema.json
refinement_log: string
generated_files: array     # Written to dist/
preview_artifacts: optional array  # dist/previews/<artifact-id>/*
```

## Persistent State Files

The skill creates and maintains these files — **state must never rely on conversational context**:

- `artifact_manifest.json` — Output contract (validated against schema)
- `constraints.json` — Active constraint definitions
- `refinement_log.md` — Iteration history and decisions
- `decisions.md` — Convergence rationale
- `dist/` — Generated artifact outputs
- `dist/previews/` — Browser preview HTML, screenshots, and diagnostics (UI/A2UI)

## Deterministic Execution Rule

Before performing transformations, determine:

> **Does this refinement require deterministic computation?**

- **YES** → Generate minimal executable code → Execute via code interpreter or e2b sandbox → Validate file outputs → Update manifest
- **NO** → Perform AI-only refinement

For `ui` and `a2ui`, deterministic execution includes:
1. TSX preview compilation (when applicable)
2. Browser preview rendering
3. Screenshot + preview diagnostics capture
4. Manifest preview metadata update

## Termination Conditions

Refinement ends when:

- No blocking constraint violations remain
- All required artifact outputs exist in `dist/`
- Required preview evidence exists in `dist/previews/` for `ui`/`a2ui` runs
- Manifest validates against `references/schemas/artifact-manifest.schema.json`
- Further improvements fall below threshold
- Maximum iterations (5) reached

## Failure Handling

- Tool execution errors → Log, retry (max 2 retries), then degrade gracefully
- Missing files → Detect and regenerate
- Infinite refinement → Prevented via `max_iterations` guard in meta-controller

## Domain Adapters

Domain-specific refinement knowledge lives in `references/domain/`:

| Domain | Reference | Template |
|--------|-----------|----------|
| Logo | `references/domain/logo.md` | `assets/templates/logo-showcase.template.html` |
| UI | `references/domain/ui.md` | `assets/templates/react-components-shadcn-ui-template.tsx` |
| A2UI | `references/domain/a2ui.md` | `assets/templates/a2ui-preview-template.html` |
| Image | `references/domain/image.md` | — |
| Content | `references/domain/content.md` | `assets/templates/content-report.template.html` |

## Quick Start

Use domain-specific slash commands for focused refinement:

- `/refine-logo` — Logo and brand system refinement
- `/refine-ui` — React/HTML UI component refinement
- `/refine-content` — Content/Markdown refinement
- `/refine-image` — Image artifact refinement
- `/refine-a2ui` — A2UI specification refinement
- `/refine-status` — Check current refinement progress
- `/refine-validate` — Run validation checks on current state
