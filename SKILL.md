# Artifact Refiner

## Skill Metadata

| Field | Value |
|-------|-------|
| **Skill ID** | `artifact_refiner` |
| **Version** | 1.0.0 |

---

## Description

A PMPO-driven, artifact-centric refinement engine capable of creating and iteratively improving artifacts across multiple domains using AI reasoning and deterministic code execution.

This skill generalizes structured refinement into a reusable orchestration protocol.

### Supported artifact domains:

- Logos & brand systems
- React / HTML UI concepts
- A2UI specifications
- Image assets
- Content artifacts

---

## Core Principles

1. Artifact-centric (state persisted to disk)
2. Tool-augmented (uses code interpreter when required)
3. Deterministic where necessary
4. Iterative with explicit convergence rules
5. PMPO meta-loop driven

---

## Required Tools

- `code_interpreter` (e.g., e2b)
- `file_system`

### Optional:

- `image_generation`
- `browser_renderer`

---

## Inputs

```yaml
artifact_type: string  # logo | ui | a2ui | image | content
constraints: array

target_state:
  description: object

current_state: optional object
```

---

## Outputs

```yaml
refined_artifact: object
artifact_manifest: object
refinement_log: string
generated_files: array
```

---

## Persistent State Files

The skill must create and maintain the following files:

- `artifact_manifest.json`
- `constraints.json`
- `refinement_log.md`
- `decisions.md`
- `dist/`

**State must never rely on conversational context.**

---

## Claude Plugin Packaging Note

This repository is also distributed as a Claude plugin/marketplace package:

- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `skills/artifact-refiner/SKILL.md`

To avoid duplicated behavior drift, this root `SKILL.md` remains the canonical PMPO definition. The plugin skill file is a thin adapter that points back to this document and phase controllers.

---

## Execution Model (PMPO Loop)

1. Specify
2. Plan
3. Execute (AI + code_interpreter)
4. Reflect
5. Persist
6. Loop or Terminate

---

## Deterministic Execution Rule

Before performing transformations, the skill must determine:

**Does this refinement require deterministic computation?**

### If YES:

- Generate minimal executable code
- Execute via code_interpreter
- Validate file outputs
- Update manifest

### If NO:

- Perform AI-only refinement

---

## Termination Conditions

Refinement ends when:

- No constraint violations remain
- All required artifact outputs exist
- Manifest validates
- Further improvements fall below threshold

---

## Failure Handling

- Tool execution errors must be logged and retried
- Missing files must be detected and regenerated
- Infinite refinement must be prevented via convergence checks

---

## Summary

The Artifact Refiner skill operationalizes PMPO as a stateful, tool-augmented refinement engine that transforms conversational iteration into reproducible artifact infrastructure.
