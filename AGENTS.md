# Repository Guidelines

## Project Structure & Module Organization
This repository ships one PMPO skill in multiple packaging formats. Keep a clear source-of-truth boundary:
- `SKILL.md`: canonical PMPO behavior and runtime contract.
- `prompts/`: phase controllers and domain adapters (`prompts/domain/*.md`).
- `spec/`: schema contracts for state files.
- `templates/`: reusable artifact templates.
- `.claude-plugin/`: Claude plugin + marketplace manifests.
- `skills/artifact-refiner/SKILL.md`: thin Claude adapter; do not duplicate core PMPO logic here.
- `scripts/validate-marketplace.sh`: plugin/marketplace validation entrypoint.
- `.github/workflows/validate-marketplace.yml`: CI gate for plugin/marketplace validation.

## Build, Test, and Development Commands
There is no compiled app build; validation is documentation/schema/plugin focused.
- `./scripts/validate-marketplace.sh` - validates plugin and marketplace manifests (preferred local + CI command).
- `claude plugin validate .` - validates Claude plugin/marketplace configuration.
- `jq empty .claude-plugin/plugin.json` - checks plugin manifest syntax.
- `jq empty .claude-plugin/marketplace.json` - checks marketplace manifest syntax.
- `jq empty spec/artifact-manifest.schema.json` and `jq empty spec/constraints.schema.json` - checks schema JSON syntax.
- `rg --files` - inventory repository files quickly.

## Coding Style & Naming Conventions
- Markdown-first repository: use concise headings and direct, imperative instructions.
- JSON files use 2-space indentation and stable key ordering where practical.
- Keep naming consistent:
  - prompts: lowercase (`meta-controller.md`, `specify.md`)
  - domain adapters: `prompts/domain/<domain>.md`
  - Claude skill adapter: `skills/artifact-refiner/SKILL.md`

## Testing Guidelines
- Run `./scripts/validate-marketplace.sh` after plugin, marketplace, or skill-path changes.
- Ensure `.github/workflows/validate-marketplace.yml` remains aligned with local validation steps.
- Validate changed JSON artifacts with `jq empty <file>`.
- For prompt or schema edits, ensure references in `README.md` and `CLAUDE.md` remain accurate.
- Keep diffs focused; avoid combining unrelated prompt/schema/template edits in one PR.

## Commit & Pull Request Guidelines
- Commit format: `type(scope): summary` (e.g., `docs(readme): add plugin packaging structure`).
- One concern per commit.
- PRs should include: purpose, touched paths, commands run, and expected behavioral impact.
- Add screenshots only when template/UI output changes.
