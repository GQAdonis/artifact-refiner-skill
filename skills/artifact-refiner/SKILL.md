---
name: artifact-refiner
description: This skill should be used when creating or iteratively refining artifacts (logo, UI, A2UI, image, or content) using PMPO with explicit constraints, deterministic execution when needed, and persistent artifact state.
---

# Artifact Refiner

## Purpose

This is the Claude plugin adapter for this repository's PMPO skill.
It intentionally stays thin to avoid duplicating core methodology across files.

## When To Use This Skill

Use this skill when the user asks for structured, iterative refinement of:

- Logos and brand artifacts
- React/HTML UI artifacts
- A2UI specs
- Image assets
- Content artifacts

## Source Of Truth (Load In This Order)

1. `SKILL.md` (canonical PMPO behavior)
2. `prompts/meta-controller.md` and phase files under `prompts/`
3. `spec/artifact-manifest.schema.json` and `spec/constraints.schema.json`
4. `README.md` and `CLAUDE.md` for repository-level guidance

Do not redefine PMPO rules here if they already exist in those files.

## Non-Negotiable Runtime Expectations

- Persist state artifacts to disk (`artifact_manifest.json`, `constraints.json`, `refinement_log.md`, `decisions.md`, `dist/`).
- Use deterministic execution for measurable requirements.
- Validate outputs against schema contracts before termination.
