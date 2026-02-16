# Repository Guidelines

## Project Overview

This repository implements the **PMPO (Prometheus Meta-Prompting Orchestration) Artifact Refiner** - a domain-agnostic, stateful refinement engine for creating and iteratively improving artifacts (logos, UI, A2UI specs, images, content) using AI reasoning and deterministic code execution.

**Key Principle**: This is a refinement compiler, not a traditional codebase. It transforms conversational AI iteration into reproducible, stateful artifact infrastructure.

## Project Structure & Module Organization

Keep a clear source-of-truth boundary:

- `SKILL.md`: canonical PMPO behavior and runtime contract (root source of truth)
- `prompts/`: phase controllers and domain adapters (`prompts/domain/*.md`)
  - `meta-controller.md`: main PMPO loop orchestrator (entry point)
  - `specify.md`, `plan.md`, `execute.md`, `reflect.md`: phase controllers
  - `prompts/domain/*.md`: domain-specific execution adapters (logo, ui, a2ui, image, content)
- `spec/`: JSON schemas for structured state files
  - `artifact-manifest.schema.json`: output contract schema
  - `constraints.schema.json`: constraint definition schema
- `templates/`: reusable artifact templates (HTML, React/TypeScript)
- `.claude-plugin/`: Claude plugin + marketplace manifests
  - `plugin.json`: plugin manifest
  - `marketplace.json`: marketplace catalog
- `skills/artifact-refiner/SKILL.md`: thin Claude adapter; do not duplicate core PMPO logic here
- `scripts/validate-marketplace.sh`: plugin/marketplace validation entrypoint
- `.github/workflows/validate-marketplace.yml`: CI gate for plugin/marketplace validation
- `skill.yaml`: non-Claude skill metadata (YAML format)

## Build, Test, and Development Commands

This project has **no compiled app build**; validation is documentation/schema/plugin focused.

### Primary Validation Commands

```bash
# Validate plugin and marketplace manifests (preferred local + CI command)
./scripts/validate-marketplace.sh

# Validate Claude plugin/marketplace configuration (requires claude CLI)
claude plugin validate .

# Check JSON syntax for plugin manifest
jq empty .claude-plugin/plugin.json

# Check JSON syntax for marketplace manifest
jq empty .claude-plugin/marketplace.json

# Check JSON syntax for schemas
jq empty spec/artifact-manifest.schema.json
jq empty spec/constraints.schema.json

# Quick repository file inventory
rg --files
```

### Testing Approach

Since this is a prompt/skill system, "testing" means validation:

1. **Schema Validation**: All JSON artifacts must conform to their schemas
2. **File Existence**: Required files must exist (enforced by `validate-marketplace.sh`)
3. **Syntax Checking**: JSON and YAML files must be syntactically valid
4. **Reference Integrity**: Prompts must reference correct paths and schemas

### Running Single Test/Validation

To validate a specific component:

```bash
# Validate a single JSON file
jq empty <path-to-file>.json

# Check specific schema against test data
jq --slurpfile schema spec/artifact-manifest.schema.json -e '$schema | test(.[0])' test-manifest.json

# Validate only plugin (without full marketplace check)
claude plugin validate . --only-plugin
```

## Code Style & Naming Conventions

### Markdown Files (Prompts and Documentation)

- Use concise headings and direct, imperative instructions
- Phase controllers use imperative voice ("Specify the intent", "Execute the plan")
- Domain adapters describe domain-specific actions clearly
- Keep line length reasonable (≤100 characters where practical)
- Use code blocks for structured content, examples, and schemas

### JSON Files

- Use **2-space indentation**
- Use stable key ordering (alphabetical where practical)
- Include `$schema` reference for schema files
- Keep arrays and objects compact when small, expanded when complex

Example:
```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["artifact_type", "variants"],
  "properties": {
    "artifact_type": { "type": "string" }
  }
}
```

### YAML Files (skill.yaml)

- Use 2-space indentation
- Use literal block scalars (`>`) for multi-line descriptions
- List items use `- ` prefix with consistent spacing
- Group related configuration sections together

### Naming Conventions

- **Prompts**: lowercase with hyphens (`meta-controller.md`, `specify.md`)
- **Domain adapters**: `prompts/domain/<domain>.md` (e.g., `logo.md`, `ui.md`)
- **Schemas**: kebab-case with `.schema.json` suffix
- **Templates**: descriptive names with `.template.<ext>` suffix
- **Claude skill adapter**: `skills/artifact-refiner/SKILL.md`
- **Scripts**: kebab-case with `.sh` extension
- **Variables in templates**: UPPER_SNAKE_CASE with double braces (`{{VARIABLE_NAME}}`)

### TypeScript/React Templates

- Use functional components with explicit return types where beneficial
- Import order: React/core → third-party → local/components
- Use TypeScript strict mode conventions
- Props interfaces use PascalCase with `Props` suffix
- Event handlers use `handle` prefix (`handleClick`, `handleSubmit`)
- Template variables use `{{VARIABLE_NAME}}` format for replacement

Example:
```typescript
import React from "react";
import { Button } from "@/components/ui/button";

interface ExampleProps {
  title: string;
}

export function Example({ title }: ExampleProps) {
  const handleAction = () => {
    // Implementation
  };

  return <Button onClick={handleAction}>{title}</Button>;
}
```

## Error Handling Patterns

### PMPO Error Handling Philosophy

1. **Tool Execution Errors**: Must be logged and retried once before failing
2. **Missing Files**: Must be detected and regenerated via deterministic paths
3. **Schema Violations**: Must block progression until resolved (blocking constraints)
4. **Infinite Refinement Prevention**: Explicit convergence checks required

### Constraint Severity Levels

- `blocking`: Must be satisfied before termination; halt refinement until resolved
- `high`: Should be satisfied; significant degradation if violated
- `medium`: Preferably satisfied; minor impact if violated
- `low`: Nice-to-have; does not block convergence

### Validation Hooks

When deterministic validation is possible, use:
- File existence checks via `file_system` tool
- Schema validation via `code_interpreter` with JSON Schema libraries
- Build execution validation for UI artifacts
- WCAG compliance checks for accessibility constraints

## Multi-Modal Support (Opencode & Antigravity)

When working with this repository in different AI environments:

### Opencode Considerations

- Maintain strict file path references (all paths relative to repository root)
- Use explicit tool calls rather than implicit capabilities
- State persistence to disk is critical (opencode may reset context)
- Follow the PMPO loop strictly: Specify → Plan → Execute → Reflect → Persist → Loop/Terminate

### Antigravity Considerations

- Artifact manifests must be complete and self-describing
- Constraints must include measurable thresholds for objective evaluation
- Generated code must be production-ready without additional context
- Templates should minimize external dependencies (prefer shadcn/ui components already available)

### Cross-Platform Compatibility

- Use standard file formats (JSON, Markdown, YAML) universally readable
- Avoid environment-specific path separators (use forward slashes)
- Schema versions should be explicit (`$schema` references)
- Tool requirements listed in `skill.yaml` should be minimal and well-documented

## Testing Guidelines

- Run `./scripts/validate-marketplace.sh` after any plugin, marketplace, or skill-path changes
- Ensure `.github/workflows/validate-marketplace.yml` remains aligned with local validation steps
- Validate changed JSON artifacts with `jq empty <file>` before committing
- For prompt or schema edits, ensure references in `README.md` and `CLAUDE.md` remain accurate
- Keep diffs focused; avoid combining unrelated prompt/schema/template edits in one PR
- Test template rendering by checking variable substitution works correctly

## Commit & Pull Request Guidelines

- **Commit format**: `type(scope): summary` (e.g., `docs(readme): add plugin packaging structure`)
- **One concern per commit**: Don't mix prompt changes with schema changes
- **PRs should include**:
  - Purpose and motivation
  - Touched paths and files
  - Commands run for validation
  - Expected behavioral impact
- Add screenshots only when template/UI output changes
- Ensure CI passes (`validate-marketplace.yml`) before requesting review

## Source-of-Truth Rules (Critical)

- Canonical PMPO behavior lives in root `SKILL.md` and `prompts/` directory
- `skills/artifact-refiner/SKILL.md` must remain a thin Claude adapter, not a second full spec
- `.claude-plugin/plugin.json` defines installable plugin metadata and component paths
- `.claude-plugin/marketplace.json` defines distribution metadata only
- Keep behavior changes in one canonical location, then update references
- Never duplicate logic between root `SKILL.md` and `skills/artifact-refiner/SKILL.md`

## State Persistence Contract

The skill MUST create and maintain these files after every refinement cycle:

- `artifact_manifest.json` - Structured output contract conforming to schema
- `constraints.json` - Applied constraints with severity levels
- `refinement_log.md` - Execution history and decisions
- `decisions.md` - Reasoning and choice documentation
- `dist/` - Generated artifact outputs

**Critical Rule**: No artifact state can exist only in conversation memory. All state must be written to disk.
