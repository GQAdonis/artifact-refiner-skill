# Contributing to Artifact Refiner

Guidelines for contributors working on this repository.

## Commit Conventions

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat: add new domain adapter for diagrams
fix: remove hardcoded brand references from logo.md
docs: update README quickstart section
refactor: consolidate phase controller examples
chore: update marketplace.json version
```

## Branch Strategy

- `main` — Stable, release-ready
- `feat/*` — Feature branches
- `fix/*` — Bug fix branches

## Pull Request Process

1. Create a feature branch from `main`
2. Make changes following the development guidelines in `CLAUDE.md`
3. Run validation: `bash scripts/validate-marketplace.sh`
4. Verify all SKILL.md files have YAML frontmatter
5. Ensure no cross-reference links are broken
6. Ensure `git submodule status` shows a clean state (no unintended `+`/`-` prefixes)
6. Submit PR with clear description of changes

## Code Review Checklist

- [ ] YAML frontmatter present on all `.md` files in `skills/` and `agents/`
- [ ] No duplicated content across docs (README, CLAUDE.md, SKILL.md)
- [ ] All `references/` and `assets/` paths resolve to real files
- [ ] New domains added to meta-controller routing table
- [ ] Hook scripts are executable (`chmod +x`)
- [ ] Examples updated if behavior changed
- [ ] `plugin.json` updated if new skills/agents added

## Architecture Overview

See `CLAUDE.md` for the technical architecture and development guidelines.
See `README.md` for project overview and quickstart.
See `SKILL.md` for the canonical skill definition.

## Architecture Reference

Deep-dive references for scaffolded React/Vite/Tauri output. Read these before
touching any scaffolder or conversion script that emits frontend code:

- **`references/scaffolds/clean-architecture.md`** — feature-based clean
  architecture (`src/{app,features,shared}/`); boundaries between app shell,
  feature slices, and shared primitives; where stores, hooks, and components
  live in each layer.
- **`references/scaffolds/state-architecture.md`** — the strict
  Components → Hooks → Stores → I/O rule, zustand+immer store conventions,
  the `useState` vs. store threshold (single boolean stays local; multi-field
  or non-boolean must move to a store), and why stores own all realtime
  subscriptions (Supabase realtime, WebSocket, SSE).
- **`references/scaffolds/responsive-architecture.md`** — `useBreakpoint` /
  `useIsMobile`, `ResponsiveShell`, safe-area-inset CSS variables, and the
  PWA-when-resized behavior that lets a Tauri shell serve desktop + mobile
  from the same source.
- **`references/scaffolds/kebab-case-rename.md`** — kebab-case file naming
  convention (files only — PascalCase component identifiers stay), the
  `scripts/lib/kebab-case.sh` helpers, and the patcher passes that rewrite
  imports after renames.

### React / TypeScript frontends (cross-repo)

For sibling projects that use React (e.g. agent runtimes, dashboards):

1. **Components** never talk to APIs or stores directly — only to **hooks**.
2. **Hooks** only talk to **stores** — never to `fetch`, services, or HTTP clients.
3. **Stores** manage state and subscriptions; they alone call **service** modules that perform HTTP/SSE.

Do not deviate from this layering in application UI code.
