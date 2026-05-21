# Phase Assessment: scaffold-react-vite

**Phase:** `phase-2-scaffold-react-vite`
**Project:** `artifact-refiner`
**Date:** 2026-05-20
**Author:** Claude Code (Opus 4.7, 1m context)
**Mode:** Assessment only — no implementation
**Sycophancy correction:** applied
**Status of prerequisites:** all four foundation phases shipped (phase-0 → phase-1b)

---

## 1. Goal Restatement

Ship the **first real scaffolder**: given a refined React TSX artifact (produced by ideation or `refine-ui` / `convert-htmx-react`) and a brand TOML, generate a **buildable Vite + React + TypeScript project on disk** with brand tokens applied, dependencies installed, and `pnpm build` succeeding. This is the headline goal from the original ideation-to-app-pipeline assessment.

Concretely, the user provides:

```
artifact_name: "bossgravity"
source_tsx:    "<refined TSX content>"
brand:         "knowme"
target:        ".kbd-orchestrator/scaffolds/bossgravity/"
```

and the phase produces:

```
.kbd-orchestrator/scaffolds/bossgravity/
├── package.json
├── vite.config.ts
├── tsconfig.json
├── index.html
├── src/
│   ├── main.tsx
│   ├── App.tsx                  ◀── the refined TSX, patched into the template
│   ├── index.css                ◀── brand tokens injected
│   └── components/              ◀── extracted sub-components if present
├── public/
└── README.md                    ◀── how to run, brand provenance
```

with `pnpm install && pnpm dev` working out of the box and `pnpm build` producing a clean dist.

---

## 2. Sycophancy-Corrected Reframe

The original assessment proposed scaffolders for **seven** targets (React/Vite, Tauri desktop, Tauri mobile, Flutter, AG-UI, A2UI, MCP-UI) and explicitly recommended starting with React/Vite as the v1 proof point. This phase honors that scope: **one target, end-to-end, working**. Three sycophancy corrections apply.

### Correction 1 — Delegate to `npm create vite@latest`, do not own a templated tree

Owning a hand-crafted Vite template tree means maintaining it as Vite, React, TypeScript, ESLint, and Tailwind versions evolve. That is a maintenance debt the official scaffolder already absorbs. The right architecture:

1. **Delegate** to `pnpm create vite@latest <target> --template react-ts` for the initial tree.
2. **Patch** that tree with: refined TSX content, brand tokens, additional dependencies, README provenance.

We own the **patcher**, not the template. Bumps come for free.

### Correction 2 — Don't try to be a CLI; be a skill that runs the scaffold via existing tools

There is no need to build a new Rust CLI for this phase. The scaffold is a sequence of shell commands + file edits + brand-token rendering (which `template-forge` already does). A new SKILL.md + a thin orchestration script is sufficient. The Rust CLI for scaffolding becomes worth building when (a) we have 3+ scaffold targets sharing logic, or (b) the orchestration script gets brittle. Neither is true yet.

### Correction 3 — Brand token injection uses the existing template-forge pipeline

`template-forge render --brand <name> --template <name>` already renders branded artifacts. The phase can extend the templates directory with a `vite-shell-css.html` (Minijinja-rendering `index.css` with brand CSS custom properties on `:root`) rather than hand-rolling the CSS string in a new code path. Reuse > novelty.

---

## 3. Scope of This Phase

### In scope

1. **New skill** `skills/scaffold-react-vite/SKILL.md` — quick-start dispatcher with arguments and procedure.
2. **One orchestration script** `scripts/scaffold-react-vite.sh` that:
   - Validates inputs (artifact name, source TSX path, brand name, target dir)
   - Runs `pnpm create vite@latest <target> --template react-ts --yes`
   - Copies the source TSX into `src/App.tsx` (single-component case) or applies a deterministic split heuristic if the source has named exports
   - Renders brand tokens via `template-forge render --template vite-shell-css --brand <brand> --output <target>/src/index.css`
   - Injects an `import "./index.css"` line into `src/main.tsx` (already present in the default Vite template — verify, don't duplicate)
   - Writes a `README.md` recording artifact name, brand, source artifact reference, and run commands
   - Runs `pnpm install --silent` and `pnpm build` to verify the tree compiles
   - Prints the path and a success/failure summary
3. **New Minijinja template** `tools/template-forge-rs/templates/vite-shell-css.html` — outputs `:root { --color-bg: ...; --color-ember: ...; }` etc. with brand tokens.
4. **Smoke artifact**: a minimal hand-written TSX (`assets/templates/sample-app.tsx`) the script can use as a self-test target.
5. **Update `.kbd-orchestrator/scaffolds/` convention** documented in `references/scaffolds.md` — where scaffolded outputs land, how they relate to artifact state, lifecycle.

### Out of scope (deferred)

- Multi-component split heuristics beyond "one file → one App.tsx" (single-component case is the v1 floor).
- Custom routing (the Vite template's default zero-route App is sufficient for v1).
- Tailwind preset injection (deferred — v1 uses plain CSS with brand custom properties; Tailwind comes when a brand TOML declares Tailwind preferences).
- shadcn/ui registry pulls (deferred — Tailwind dependency).
- Deployment (Vercel, Netlify, etc.).
- Storybook / Ladle / preview surfaces beyond what the Vite dev server provides.
- Updating an existing scaffold (idempotent re-run) — v1 errors on existing target dir; user deletes first.
- Tauri or Flutter scaffolders (their own phases).

---

## 4. Current state inventory

| Surface | Status |
|---|---|
| `skills/scaffold-react-vite/` | does not exist |
| `scripts/scaffold-react-vite.sh` | does not exist |
| `tools/template-forge-rs/templates/vite-shell-css.html` | does not exist |
| `.kbd-orchestrator/scaffolds/` | does not exist |
| `references/scaffolds.md` | does not exist |
| `assets/templates/sample-app.tsx` | does not exist |
| Existing scaffold dependencies — `pnpm`, `node`, `npx`, `template-forge` | `template-forge` present (built last phase); `pnpm`/`node`/`npx` are user prerequisites |
| Existing TSX preview pipeline (`compile-tsx-preview.mjs`, `render-preview.mjs`) | exists — can be reused if smoke-test wants to render the scaffolded app, not strictly required |

---

## 5. Architecture choices

### A. Output location

`.kbd-orchestrator/scaffolds/<artifact_name>/`

Rationale: the KBD orchestrator already owns lifecycle for refinement state; scaffolds are a sibling output. Lives outside `src/` and `tools/`, doesn't pollute either. Easy to `.gitignore` if user doesn't want scaffolds committed.

### B. Single-app vs multi-file source

V1 accepts a **single .tsx file** as source. If the file has only a default export → it becomes `App.tsx`. If named exports also exist → they become `src/components/<ExportName>.tsx`. No AST splitting; we use deterministic grep/regex on `export (default |const|function)`.

### C. Brand token injection mechanism

Two layers:

- **CSS custom properties on `:root`** in `src/index.css`, rendered via Minijinja from the brand TOML. This is the surface the TSX consumes via `var(--color-ember)` etc.
- **No JSX-level token injection.** If the source TSX hardcodes hex values, those stay (it's the refined TSX's job to use CSS custom properties; the scaffolder doesn't refactor JSX).

### D. Dependency management

V1: only what `pnpm create vite@latest --template react-ts` installs by default. No additional deps. If the source TSX `import`s anything beyond `react`/`react-dom`, the build will fail and the script will report it. Adding a `--dependencies` flag is a follow-on enhancement.

### E. Failure handling

If `pnpm install` or `pnpm build` fails, the script:

1. Leaves the partial scaffold on disk for inspection.
2. Prints the failure output verbatim.
3. Exits non-zero.

Does not auto-rollback. User can `rm -rf <target>` and re-run.

---

## 6. Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| `pnpm create vite@latest` interactive prompts hang the script | Medium | High | Pass `--yes` flag; use stable Vite version pin via `pnpm create vite@latest --template react-ts` — verify upstream supports `--yes` non-interactively |
| Source TSX imports packages not in the default Vite template | High | Medium | Document explicitly in the SKILL.md; report missing deps from `pnpm build` failure |
| Brand TOML missing `colors.light` / `colors.dark` keys causes Minijinja render to fail | Low | Low | template-forge already validates BrandData schema; render errors are explicit |
| Generated CSS not consumed by source TSX | Medium | Low | Document the contract: source TSX must use `var(--color-*)` to benefit from brand tokens; otherwise the scaffold still builds, brand tokens just sit unused |
| `pnpm` not installed | Medium | Medium | Pre-flight check; clear error message pointing at `corepack enable pnpm` |
| Brand TOML schema doesn't include all needed tokens for the CSS template | Low | Low | Use `default()` filter in Minijinja for optional tokens (already pattern in `brand-guide.html`) |

No high-severity unmitigated risks.

---

## 7. Acceptance criteria

A clear, automatable suite:

1. `skills/scaffold-react-vite/SKILL.md` exists with valid YAML frontmatter.
2. `scripts/scaffold-react-vite.sh` exists, is executable.
3. `tools/template-forge-rs/templates/vite-shell-css.html` exists and renders with the `knowme` brand to produce a non-empty CSS file containing `--color-ember: #E04E28`.
4. `assets/templates/sample-app.tsx` exists — a minimal "Hello, <brand>" TSX using `var(--color-ember)`.
5. End-to-end smoke test: `bash scripts/scaffold-react-vite.sh --name smoke --source assets/templates/sample-app.tsx --brand knowme --target /tmp/smoke-scaffold` produces a directory where `pnpm install --silent && pnpm build` succeeds.
6. `references/scaffolds.md` exists describing the `.kbd-orchestrator/scaffolds/` convention.
7. `.claude-plugin/plugin.json` lists the new `scaffold-react-vite` skill.

7 gates. All deterministically checkable.

---

## 8. Phase decomposition

| # | Sub-change | Effort |
|---|---|---|
| 1 | Author `skills/scaffold-react-vite/SKILL.md` | small |
| 2 | Author `tools/template-forge-rs/templates/vite-shell-css.html` (Minijinja) | small |
| 3 | Verify template-forge can render it for knowme brand (no code change; render + grep) | small |
| 4 | Author `assets/templates/sample-app.tsx` (minimal TSX using brand vars) | small |
| 5 | Author `scripts/scaffold-react-vite.sh` orchestration script | medium |
| 6 | End-to-end smoke test via the script | medium (waits for `pnpm install` + build) |
| 7 | Author `references/scaffolds.md` documenting convention | small |
| 8 | Update `.claude-plugin/plugin.json` with new skill path | trivial |
| 9 | Acceptance gate sweep | small |

Total: one focused session if the network is responsive (`pnpm install` of a Vite template is ~30 seconds).

---

## 9. Open questions

1. **Package manager:** `pnpm` (recommended in your global rules), `npm`, or detect? Recommendation: **`pnpm`** as the documented default; print a friendly error if absent. `corepack enable pnpm` is one command.
2. **Vite version pin:** allow `latest`, or pin a known-good major (Vite 7.x)? Recommendation: **allow `latest`** for v1 — Vite has a strong record of non-breaking releases at the create-template level. Pin only if a future scaffold breaks.
3. **Sample app complexity:** static "Hello" or a small interactive (counter, theme toggle)? Recommendation: **static + one button using CSS var** — demonstrates brand-token consumption without inviting state-management discussions.
4. **Should the script also commit the scaffolded tree to git?** Recommendation: **no.** Scaffolds are outputs, not source code; user decides.
5. **Should we run `pnpm dev` and screenshot the running app as part of smoke?** Recommendation: **no for v1** — `pnpm build` success is sufficient. Visual regression is its own concern; the existing `scripts/render-preview.mjs` is the right tool for visual smoke later.

---

## 10. Honest verdict

This phase ships the originally-promised proof point: ideation TSX → runnable Vite app with brand tokens. It is **architecturally small** (delegate to upstream, patch, render) and **strategically large** (every later scaffolder — Tauri, Flutter, AG-UI host — reuses the patcher pattern established here).

The risk surface is low because we're not re-implementing anything Vite already does. The work is just gluing existing tools (`pnpm create vite`, `template-forge render`, simple shell orchestration).

**Recommendation:** proceed to `/kbd-plan phase-2-scaffold-react-vite`. One focused session of execute.

---

## 11. Assessment metadata

```yaml
assessment_complete: true
phase: phase-2-scaffold-react-vite
prerequisites_met:
  phase-0-unblock: complete
  phase-rust-workspace-bootstrap: complete (template-forge builds, MinijinjaEngine works, brand-guide.html template is a reference for vite-shell-css.html)
  phase-1-submodule-topology: complete
  phase-sc-extraction: complete
  phase-1b-inference-routing: complete (cost routing optional — not required for this phase)
scope_discipline_applied:
  - Delegate to `pnpm create vite@latest`, do not own template tree
  - One target (React/Vite), one brand path (knowme), one source-TSX shape (single file)
  - No Tailwind, no shadcn, no routing, no multi-component split heuristics in v1
recommendation: |
  Proceed to /kbd-plan phase-2-scaffold-react-vite. Expected one focused
  session including the network-bounded pnpm install + build.
next_command: /kbd-plan phase-2-scaffold-react-vite
```

Completed kbd-assess — phase-2-scaffold-react-vite
