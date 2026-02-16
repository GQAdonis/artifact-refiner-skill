# PMPO Artifact Refiner Skill

## Overview

The **PMPO Artifact Refiner** is a domain-agnostic, stateful refinement engine designed to iteratively create and improve artifacts using a structured meta-orchestration model.

This skill operationalizes **Prometheus Meta Prompting Orchestration (PMPO)** as a reproducible, tool-augmented workflow capable of generating production-ready outputs across multiple domains.

For complete theoretical foundations and methodology, see [`docs/pmpo/README.md`](docs/pmpo/README.md).

It is not a prompt.
It is not a single agent.
It is a refinement compiler.

---

# Core Philosophy

Traditional conversational AI refinement fails when:

* Context overflows
* State is lost
* Iteration becomes non-deterministic
* Outputs cannot be reproduced

The PMPO Artifact Refiner solves this by being:

* **Artifact-centric, not chat-centric**
* **Stateful, not ephemeral**
* **Tool-augmented where required**
* **Deterministic when necessary**
* **Iterative with explicit convergence rules**

Every refinement cycle persists structured state to disk and produces verifiable artifacts.

---

# What This Skill Does

The Artifact Refiner supports iterative creation and refinement of:

* Logos and brand systems
* React / HTML UI artifacts
* A2UI specifications
* Generated and processed image assets
* Written content artifacts

Each domain uses the same PMPO meta-loop but has its own execution adapter.

---

# The PMPO Meta-Loop

Every artifact refinement follows:

1. **Specify** – Clarify intent and constraints
2. **Plan** – Decompose into executable stages
3. **Execute** – Perform AI + deterministic transformations
4. **Reflect** – Validate against constraints
5. **Persist** – Update artifact state
6. **Loop or Terminate**

This loop prevents drift and enforces reproducibility.

## Entry Point

The skill entry point is `prompts/meta-controller.md`, which orchestrates the complete PMPO loop and manages transitions between phases.

---

# Directory Structure

```
artifact-refiner/
│
├── SKILL.md                      # Canonical PMPO skill behavior
├── skill.yaml                    # Non-Claude skill metadata
├── README.md                     # This overview document
├── CLAUDE.md                     # Claude-specific development guidance
├── AGENTS.md                     # Contributor workflow guide
│
├── .claude-plugin/               # Claude packaging files
│   ├── plugin.json               # Claude plugin manifest
│   └── marketplace.json          # Marketplace catalog
│
├── .github/workflows/            # CI workflows
│   └── validate-marketplace.yml  # Runs plugin/marketplace validation
│
├── skills/                       # Claude plugin skill wrappers
│   └── artifact-refiner/
│       └── SKILL.md              # Thin adapter to canonical root SKILL.md
│
├── docs/                         # Theoretical foundations and documentation
│   └── pmpo/
│       └── README.md             # Complete PMPO methodology and theory
│
├── spec/                         # JSON schemas for structured state
│   ├── artifact-manifest.schema.json  # Output contract schema
│   └── constraints.schema.json   # Constraint definition schema
│
├── scripts/                      # Validation and maintenance scripts
│   └── validate-marketplace.sh   # Validate plugin + marketplace setup
│
├── prompts/                      # Phase controllers and orchestration logic
│   ├── meta-controller.md        # Main PMPO loop orchestrator (entry point)
│   ├── specify.md                # Phase 1: Transform intent → specification
│   ├── plan.md                   # Phase 2: Transform specification → executable plan
│   ├── execute.md                # Phase 3: Execute plan via AI + tools
│   ├── reflect.md                # Phase 4: Validate outputs & determine convergence
│   └── domain/                   # Domain-specific execution adapters
│       ├── logo.md               # Logo generation and rasterization
│       ├── ui.md                 # React/HTML UI refinement
│       ├── a2ui.md               # A2UI specification handling
│       ├── image.md              # Image processing and validation
│       └── content.md            # Content artifact refinement
│
└── templates/                    # Output templates for generated artifacts
    ├── logo-showcase.template.html
    ├── a2ui-preview-template.html
    ├── content-report.template.html
    └── react-components-shadcn-ui-template.tsx
```

## Source-of-Truth Structure (No Duplication)

To keep plugin + marketplace support maintainable:

- Core PMPO behavior belongs in root `SKILL.md` and `prompts/`.
- `skills/artifact-refiner/SKILL.md` stays a thin adapter for Claude plugin invocation.
- `.claude-plugin/plugin.json` is only for plugin metadata and path registration.
- `.claude-plugin/marketplace.json` is only for marketplace distribution metadata; keep plugin entries minimal (`name` + `source`) unless an override is required.

If behavior changes, update canonical files first, then adjust adapters/manifests.

---

# Artifact State Model

Each refinement produces persistent state:

* `artifact_manifest.json`
* `constraints.json`
* `refinement_log.md`
* `decisions.md`
* `dist/` (generated outputs)

No artifact state is allowed to live only in conversation.

---

# Deterministic Execution

The skill uses a `code_interpreter` (e.g., e2b) for:

* SVG generation
* PNG rasterization
* Schema validation
* Build execution
* Accessibility checks
* File validation
* Format conversions

AI handles reasoning.
The interpreter handles transformation.

This separation prevents hallucinated outputs and ensures reproducibility.

---

# Manifest Contract

Every refinement must produce a valid `artifact_manifest.json` conforming to the schema in `spec/artifact-manifest.schema.json`.

The manifest serves as:

* Output contract
* Verification anchor
* Re-entry checkpoint
* CI validation target

---

# Constraint System

Constraints are structured objects defined by `constraints.schema.json`.

They support:

* Severity levels (blocking, high, medium, low)
* Deterministic validation hooks
* Measurable thresholds
* Termination conditions

Constraints drive reflection and convergence.

---

# Domain Modules

Each domain module defines specialized behavior:

## Logo

* Font acquisition
* SVG generation
* PNG export
* Showcase generation

## UI (React / HTML)

* Component refinement
* Token enforcement
* Accessibility validation
* Build execution

## A2UI

* Schema validation
* Structural normalization
* Preview rendering

## Image

* Batch resizing
* Format conversion
* Contrast validation

## Content

* Structural editing
* Markdown → HTML conversion
* Report generation

All domains share the same orchestration loop.

---

# Why This Exists

This skill exists to solve a systemic problem:

Conversational refinement is fragile.

By converting refinement into a stateful, tool-driven protocol, we:

* Prevent context collapse
* Enable reproducibility
* Support CI workflows
* Allow multi-agent orchestration
* Enable artifact diffing and regression detection

---

# Integration Strategy

This skill is designed to integrate with:

* Prometheus runtime
* AgentSkills.io processors
* Multi-agent orchestration graphs
* CI/CD pipelines
* Artifact-driven development workflows

---

# Future Extensions

* Visual diffing between refinement iterations
* Multi-agent distributed refinement graphs
* Automated regression detection
* Versioned artifact lineage tracking
* CI integration with blocking constraints

---

# Developer Guidance

For developers working with this skill system, see [`CLAUDE.md`](CLAUDE.md) which provides comprehensive guidance for Claude Code instances, including:

* Complete PMPO theoretical foundations
* Architecture overview and implementation patterns
* Phase controller responsibilities and workflows
* Essential development concepts and state management
* Domain module integration strategies

---

# Claude Plugin & Marketplace Support

This repository is now packaged as a Claude plugin and can be distributed through a Claude marketplace.

## Plugin Files

- `.claude-plugin/plugin.json` - plugin metadata and skill registration
- `skills/artifact-refiner/SKILL.md` - thin Claude skill adapter to canonical docs

## Marketplace Files

- `.claude-plugin/marketplace.json` - marketplace catalog containing the `artifact-refiner` plugin

## Local Validation and Testing

```bash
./scripts/validate-marketplace.sh
claude --plugin-dir .
```

## CI Validation

Marketplace/plugin validation is enforced in GitHub Actions via:

- `.github/workflows/validate-marketplace.yml`

This workflow runs on push and pull request and executes:

```bash
./scripts/validate-marketplace.sh
```

## Local Marketplace Install Flow

```bash
/plugin marketplace add .
/plugin install artifact-refiner@travisjames-skills
```

# Summary

The PMPO Artifact Refiner transforms conversational iteration into deterministic infrastructure.

It is a refinement engine.
It is a meta-skill compiler.
It is a foundation for reproducible AI-assisted artifact development.

**Key insight**: PMPO is not about prompting better—it's about orchestrating thinking itself into reliable, persistent, tool-augmented workflows that survive context limitations and enable true artifact-driven development.
