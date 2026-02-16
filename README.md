# Artifact Refiner

A PMPO-driven, iterative artifact refinement engine for logos, UI components, content, images, and A2UI specifications. Built as a Claude Code plugin and [Agent Skills](https://agentskills.io) compliant skill.

## Quick Start

Use domain-specific slash commands:

```
/refine-logo     — Logo and brand system refinement
/refine-ui       — React/HTML UI component refinement
/refine-content  — Content/Markdown refinement
/refine-image    — Image artifact refinement
/refine-a2ui     — A2UI specification refinement
/refine-status   — Check current refinement progress
/refine-validate — Run validation checks on current state
```

Or invoke the general skill with a free-form request describing what you want to refine.

## Installation

### As a Claude Plugin

```bash
claude plugin install artifact-refiner
```

### Manual

Clone the repository into your Claude Code plugins directory:

```bash
git clone https://github.com/GQAdonis/artifact-refiner-skill.git ~/.claude/plugins/artifact-refiner
```

### e2b Sandbox (Optional)

For sandboxed code execution, set your e2b API key:

```bash
export E2B_API_KEY="your-key-here"
```

The skill works without e2b by falling back to the built-in `code_interpreter`.

## How It Works

The skill uses **PMPO** (Prometheus Meta-Prompting Orchestration) — a structured, iterative refinement loop:

1. **Specify** — Transform intent into structured specification with constraints
2. **Plan** — Convert specification into executable strategy
3. **Execute** — Apply transformations via AI + deterministic tools
4. **Reflect** — Evaluate outputs against constraints
5. **Persist** — Write validated state to disk
6. **Loop or Terminate** — Continue if constraints unsatisfied, stop if converged

For the full PMPO methodology, see [`references/pmpo-theory.md`](references/pmpo-theory.md).

## Directory Structure

```
artifact-refiner/
├── SKILL.md                    # Canonical skill definition (Agent Skills spec)
├── agents/                     # PMPO phase subagents
│   ├── pmpo-specifier.md
│   ├── pmpo-planner.md
│   ├── pmpo-executor.md
│   ├── pmpo-reflector.md
│   └── artifact-validator.md
├── assets/templates/           # HTML/React templates for output generation
├── examples/                   # Complete walkthrough examples
│   ├── logo-refinement/
│   └── content-refinement/
├── hooks/hooks.json            # Lifecycle hooks (validation, logging)
├── prompts/                    # PMPO phase controllers
│   ├── meta-controller.md      # Orchestration entry point
│   ├── specify.md
│   ├── plan.md
│   ├── execute.md
│   ├── reflect.md
│   └── persist.md
├── references/                 # Progressive disclosure content
│   ├── pmpo-theory.md
│   ├── domain/{logo,ui,a2ui,image,content}.md
│   └── schemas/{artifact-manifest,constraints}.schema.json
├── scripts/                    # Validation and hook scripts
├── skills/                     # Slash command skills
│   ├── artifact-refiner/       # Main skill adapter
│   ├── refine-logo/
│   ├── refine-ui/
│   ├── refine-content/
│   ├── refine-image/
│   ├── refine-a2ui/
│   ├── refine-status/
│   └── refine-validate/
├── .claude-plugin/             # Plugin manifest
│   └── plugin.json
└── .mcp.json                   # e2b sandbox MCP server config
```

## Examples

See the [`examples/`](examples/) directory for complete walkthroughs:

- **[Logo Refinement](examples/logo-refinement/)** — NexaFlow brand system from spec to final manifest
- **[Content Refinement](examples/content-refinement/)** — Blog post from rough draft to polished HTML

## Try It

```
> /refine-logo Create a modern logo for "AcmeAPI" using navy blue and gold
```

The skill will:
1. Generate a structured specification with brand constraints
2. Plan an SVG → PNG → showcase pipeline
3. Execute using image generation + code interpreter
4. Reflect on constraint satisfaction
5. Iterate until all constraints are met
6. Output a complete brand system in `dist/`

## Author

**Travis James** — [travisjames.ai](https://travisjames.ai)

## License

MIT — See [LICENSE](LICENSE) for details.
