# Claude Code Development Guide

This file provides guidance for AI assistants working **on** this repository (developing, modifying, debugging). For the skill's functionality, see `SKILL.md`. For project overview, see `README.md`.

## Architecture

The skill follows PMPO (Prometheus Meta-Prompting Orchestration):
- **Phase controllers** in `prompts/` drive each loop phase
- **Domain adapters** in `references/domain/` provide domain-specific knowledge
- **Schemas** in `references/schemas/` define the output contracts
- **Subagents** in `agents/` specialize in individual phases
- **Templates** in `assets/templates/` provide output scaffolding

## Key Files

| File | Role |
| --- | --- |
| `SKILL.md` | Canonical skill definition — source of truth for behavior |
| `prompts/meta-controller.md` | Orchestration entry point — routing, iteration, error handling |
| `prompts/persist.md` | Phase 5 — state persistence procedures |
| `hooks/hooks.json` | Lifecycle hooks — validation, logging, cleanup |
| `.claude-plugin/plugin.json` | Plugin manifest — skill/agent/hook/MCP registration |
| `.mcp.json` | e2b sandbox MCP server configuration |

## Development Guidelines

### Modifying Phase Controllers

Each prompt in `prompts/` follows a consistent structure:
1. Purpose/objective section
2. Procedure/steps section
3. Output contract (YAML example)
4. Rules section
5. Examples section (added in v1.1.0)

When modifying, preserve all sections and update cross-references.

### Adding a New Domain

1. Create `references/domain/<name>.md` with domain-specific knowledge
2. Add a template in `assets/templates/` if the domain needs output scaffolding
3. Update the routing table in `prompts/meta-controller.md`
4. Update the domain table in root `SKILL.md`
5. Create `skills/refine-<name>/SKILL.md` as a slash command
6. Add the new skill path to `.claude-plugin/plugin.json`

### Adding a New Subagent

1. Create `agents/<name>.md` with YAML frontmatter (`name`, `description`, `allowed_tools`)
2. Define a focused system prompt in the body
3. Reference existing phase controllers and schemas
4. Plugin auto-discovers agents from the `agents/` directory

### Modifying Hooks

Hooks are defined in `hooks/hooks.json`. Supported events:
- `PostToolUse` — Runs after file write operations
- `SubagentStop` — Runs when a subagent completes
- `Stop` — Runs when the main session ends

Hook scripts live in `scripts/` and must exit 0 (success) or 2 (feedback to agent).

## Testing

```bash
# Run marketplace validation
bash scripts/validate-marketplace.sh

# Validate YAML frontmatter in all skills
for f in skills/*/SKILL.md; do head -5 "$f" | grep -q "^---" && echo "✅ $f" || echo "❌ $f"; done

# Check file reference integrity
grep -roh 'references/[a-zA-Z0-9/_.-]*' prompts/ | sort -u | while read f; do [ -e "$f" ] && echo "✅ $f" || echo "❌ $f"; done

# Verify no hardcoded brand references remain
grep -r "sediment://" . --include="*.md"  # Should return nothing
```
