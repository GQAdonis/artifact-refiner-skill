# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## About This Project

The **PMPO Artifact Refiner** is a domain-agnostic, stateful refinement engine that implements Prometheus Meta Prompting Orchestration (PMPO) as a structured skill for creating and iteratively improving artifacts. This is not a traditional codebase but rather a **refinement compiler** that transforms conversational iteration into reproducible artifact infrastructure.

## Understanding PMPO (Prometheus Meta-Prompting Orchestration)

### What PMPO Is
PMPO is **not** a prompt template, single agent pattern, or chain-of-thought wrapper. It is a **meta-level control architecture** that governs how thinking, planning, execution, and reflection occur across iterative refinement cycles. PMPO operates as a **cognitive orchestration protocol** that functions like a compiler for artifacts.

### Why PMPO Exists
Traditional AI usage suffers from systemic limitations that PMPO was designed to solve:

**Problems with Conversational AI:**
- Context window overflow
- Loss of refinement history
- Non-deterministic iteration
- Hallucinated outputs
- Lack of reproducibility
- Fragile conversational state

**PMPO Solutions:**
- Structured iteration with explicit phases
- Persistent state written to disk
- Explicit, structured constraints
- Deterministic tool integration
- Clear convergence rules

### Theoretical Foundations
PMPO draws from multiple disciplines:
- **Systems architecture** - Modular, composable design
- **Compiler design** - Spec → Plan → Execute → Validate pipeline
- **Control theory** - Feedback loops and convergence
- **Iterative design refinement** - Progressive improvement cycles
- **Declarative constraint systems** - Structured validation rules

### PMPO's Five Core Principles

1. **Artifact-Centric State**: The artifact is the source of truth. State must be written to disk (manifests, constraints, logs, outputs). Conversation is not state - artifacts are state.

2. **Separation of Cognition and Computation**: AI handles reasoning (analysis, planning, abstraction) while deterministic tools handle transformation (code, rendering, validation). This prevents hallucination and enforces reproducibility.

3. **Recursive Structured Iteration**: All refinement follows the 6-step PMPO meta-loop until convergence conditions are satisfied.

4. **Constraint-Driven Convergence**: Constraints are structured objects with blocking vs non-blocking rules, deterministic validation hooks, and measurable thresholds that drive reflection decisions.

5. **Deterministic Validation**: If a requirement can be measured, it must be validated via tool integration (WCAG compliance, schema validity, file existence, build success, etc.)

## Architecture Overview

### PMPO as Meta-Architecture
PMPO operates at the meta level - it doesn't solve domain problems directly but orchestrates how domain problems are solved. Within this system:
- **Domain modules** (logo, UI, A2UI, image, content) implement domain-specific logic
- **PMPO governs** how those modules execute, refine, and converge
- **The meta-loop is invariant** across all domains, only domain adapters change

### Preventing Context Collapse
A core motivation for PMPO is preventing catastrophic context loss in long refinement sessions. By externalizing state to artifacts and logs, refinement survives:
- Token limits and context window overflow
- Session resets and model swaps
- Multi-agent handoffs and distributed execution
- Loss of conversational history

**PMPO turns fragile chat into resilient stateful orchestration.**

### Core Architecture Principles
- **Artifact-centric, not chat-centric**: State persists to disk, never relies on conversation history
- **Tool-augmented**: Combines AI reasoning with deterministic code execution via `code_interpreter`
- **Stateful**: Every refinement cycle produces verifiable artifacts and structured state
- **Domain-agnostic**: Same PMPO meta-loop works across multiple artifact types
- **Compiler-like**: Intent → Parse → Plan → Execute → Validate → Loop until stable

### PMPO Meta-Loop (The Heart of the System)
Every artifact refinement follows this exact 6-step loop:

1. **Specify** - Transform ambiguous intent into structured refinement specification
2. **Plan** - Decompose specification into executable stages with tool mapping
3. **Execute** - Perform AI reasoning + deterministic transformations via code_interpreter
4. **Reflect** - Validate against constraints and determine convergence
5. **Persist** - Update artifact state to disk (never rely on conversation memory)
6. **Loop or Terminate** - Based on constraint satisfaction and convergence rules

### Supported Domains
Each domain uses the same PMPO loop but has specialized execution adapters:

- **Logo**: Font acquisition, SVG generation, PNG rasterization, showcase creation
- **UI (React/HTML)**: Component refinement, accessibility validation, build execution
- **A2UI**: Schema validation, structural normalization, preview rendering
- **Image**: Batch processing, format conversion, contrast validation
- **Content**: Structural editing, markdown conversion, report generation

## Directory Structure & Key Files

```
artifact-refiner/
├── skill.yaml                    # Non-Claude skill metadata
├── SKILL.md                      # Canonical PMPO behavior + runtime contract
├── README.md                     # Project overview
├── AGENTS.md                     # Contributor workflow guide
├── CLAUDE.md                     # Claude-specific development guidance
│
├── .claude-plugin/
│   ├── plugin.json               # Claude plugin manifest
│   └── marketplace.json          # Claude marketplace catalog
│
├── skills/
│   └── artifact-refiner/
│       └── SKILL.md              # Thin adapter that points to canonical docs
│
├── docs/                         # Theoretical foundations
│   └── pmpo/
│       └── README.md             # Complete PMPO theory and methodology
│
├── prompts/                      # Phase controllers (core orchestration logic)
│   ├── meta-controller.md        # Main PMPO loop orchestrator
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
├── spec/                         # JSON schemas for structured state
│   ├── artifact-manifest.schema.json  # Output contract schema
│   └── constraints.schema.json   # Constraint definition schema
│
├── scripts/
│   └── validate-marketplace.sh   # One-command plugin/marketplace validation
│
├── .github/workflows/
│   └── validate-marketplace.yml  # CI validation for plugin/marketplace setup
│
└── templates/                    # Output templates for generated artifacts
    ├── logo-showcase.template.html      # Logo presentation showcase
    ├── a2ui-preview-template.html       # A2UI specification preview
    ├── content-report.template.html     # Content artifact reports
    └── react-components-shadcn-ui-template.tsx  # React component boilerplate
```

### Source-of-Truth Rules (Avoid Duplication)

- Canonical PMPO behavior lives in root `SKILL.md` and `prompts/`.
- `skills/artifact-refiner/SKILL.md` must remain a thin Claude adapter, not a second full spec.
- `.claude-plugin/plugin.json` defines installable plugin metadata and component paths.
- `.claude-plugin/marketplace.json` defines distribution metadata and plugin source only; keep plugin entries minimal unless explicit marketplace overrides are needed.
- Keep behavior changes in one canonical location, then update references.

## Essential Development Concepts

### State Persistence Contract
The skill MUST create and maintain these files after every refinement cycle:
- `artifact_manifest.json` - Structured output contract conforming to schema
- `constraints.json` - Applied constraints with severity levels
- `refinement_log.md` - Execution history and decisions
- `decisions.md` - Reasoning and choice documentation
- `dist/` - Generated artifact outputs

**Critical Rule**: No artifact state can exist only in conversation memory.

### Deterministic Execution Rule
Before any transformation, the skill must decide:
**"Does this refinement require deterministic computation?"**

- **If YES**: Generate minimal executable code → Execute via `code_interpreter` → Validate outputs → Update manifest
- **If NO**: Perform AI-only refinement

### Constraint System
Constraints are structured objects with:
- **Severity levels**: `blocking`, `high`, `medium`, `low`
- **Types**: `visual`, `structural`, `semantic`, `technical`, `brand`, `performance`, `accessibility`
- **Validation hooks**: Deterministic validation methods when required
- **Target metrics**: Measurable thresholds for objective evaluation

### Termination Conditions
Refinement ends when:
- No constraint violations remain (especially blocking constraints)
- All required artifact outputs exist and validate
- Manifest conforms to schema
- Further improvements fall below improvement threshold

## PMPO Methodology in Practice

The PMPO methodology follows a 6-step process that maps directly to the phase controllers:

### Step 1: Formalize Intent (Specify Phase)
- Convert ambiguous goals into structured specifications
- Extract explicit and implicit constraints
- Define measurable success criteria
- Identify unknowns and validation requirements
- **Output**: Structured specification with constraints

### Step 2: Constrain the Solution Space (Plan Phase)
- Break transformation into minimal, deterministic stages
- Determine which stages require tool execution vs AI-only
- Design state mutation plan (files to create/update)
- Create validation plan for constraint checking
- **Output**: Executable plan with tool mapping

### Step 3: Execute With Tool Separation (Execute Phase)
- Follow stage order strictly from plan
- Use AI for reasoning, tools for deterministic transformation
- Generate minimal, purpose-specific code when needed
- Validate outputs after each deterministic stage
- **Output**: Generated artifacts and execution logs

### Step 4: Reflect Against Structured Criteria (Reflect Phase)
- Evaluate constraint compliance (satisfied/violated/partial)
- Verify deterministic validation results
- Assess target state alignment
- Detect regressions from previous iterations
- **Output**: Structured reflection with convergence decision

### Step 5: Persist State (All Phases)
- Update artifact_manifest.json with generated outputs
- Log all decisions and execution results
- Write constraint evaluations to disk
- Ensure all state is externalized from conversation
- **Output**: Complete artifact state on disk

### Step 6: Loop or Terminate (Meta-Controller)
- Continue if convergence criteria not met
- Terminate when constraints satisfied and outputs complete
- Handle infinite loop prevention via convergence checks
- **Output**: Either new refinement cycle or final artifacts

## Working with This Skill

### Entry Point
The skill entry point is `prompts/meta-controller.md` which orchestrates the PMPO loop.

### Phase Controllers
Each phase has its own controller with specific responsibilities:
- **Specify**: Never generates artifacts, only clarifies intent and extracts constraints
- **Plan**: Never generates artifacts, only creates executable transformation strategy
- **Execute**: Implements the plan faithfully using AI + tools, persists all state
- **Reflect**: Evaluates outputs against constraints, decides convergence

### Domain Modules
When working with specific domains, the relevant domain module in `prompts/domain/` provides specialized behavior while following the same PMPO orchestration pattern.

### Schema Validation
Always validate outputs against:
- `spec/artifact-manifest.schema.json` for output contracts
- `spec/constraints.schema.json` for constraint definitions

### Plugin/Marketplace Validation
For packaging changes, run:
- `./scripts/validate-marketplace.sh`
- `claude plugin validate .`

CI uses `.github/workflows/validate-marketplace.yml` to run the same validation flow on push and pull request.

## Key Implementation Patterns

### Tool Separation
- **AI handles**: Reasoning, aesthetic decisions, content generation, constraint evaluation
- **Code interpreter handles**: SVG generation, file validation, schema validation, build execution, format conversion, measurements

### Idempotency
All deterministic operations should be idempotent where possible to support re-running phases without state corruption.

### Error Handling
- Tool execution errors must be logged and retried once
- Missing files must be detected and regenerated
- Infinite refinement prevented via explicit convergence checks

### Progressive Refinement
The system supports iterative improvement through the PMPO loop until convergence criteria are met, making it suitable for complex artifact development that requires multiple refinement passes.

## Multi-Domain Adaptability

PMPO is domain-agnostic because:
- **The meta-loop is invariant** - Same 6-step process across all domains
- **Constraints are structured** - Uniform constraint system works for any domain
- **Execution is modular** - Only domain adapters need to change

This makes PMPO applicable beyond the current domains to:
- Infrastructure design and provisioning
- Documentation generation systems
- Agent specification development
- Brand system development
- API design and validation

## Future Evolution

PMPO is designed to evolve into a general orchestration framework for agentic systems. Potential expansions include:
- **Distributed multi-agent PMPO graphs** - Parallel refinement across agent teams
- **Visual diffing between refinement cycles** - Track artifact evolution over time
- **Regression detection automation** - Automated quality assurance
- **Versioned artifact lineage tracking** - Complete artifact provenance
- **CI/CD blocking constraints** - Integration with deployment pipelines

## Summary

This architecture implements **refinement as infrastructure** - converting ephemeral conversational iteration into structured, reproducible artifact development. The PMPO Artifact Refiner demonstrates how cognitive orchestration can solve the fundamental problems of context collapse, non-deterministic refinement, and fragile conversational state.

**Key insight**: PMPO is not about prompting better - it's about orchestrating thinking itself into reliable, persistent, tool-augmented workflows that survive context limitations and enable true artifact-driven development.
