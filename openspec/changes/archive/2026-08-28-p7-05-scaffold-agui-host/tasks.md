# Tasks: p7-05-scaffold-agui-host

**scope**:
- `scripts/scaffold-react-vite-agui.sh` (new)
- `skills/scaffold-react-vite-agui/SKILL.md` (new)
- `.claude-plugin/plugin.json` (register the skill)
- `assets/scaffold/agui/**` (consumed; created by p7-03 and p7-04)

## Scaffolder

- [x] 1.1 Create `scripts/scaffold-react-vite-agui.sh` following the
      `scaffold-react-vite-tauri.sh` wrapper shape — delegate to
      `scaffold-react-vite.sh`, then layer the AG-UI concern. Do not fork the
      1160-line base.
- [x] 1.2 `chmod +x` (repo constraint: hook and scaffolder scripts are executable).
- [x] 1.3 Install `@ag-ui/client` and `@ag-ui/encoder` at exact `0.0.59`.
- [x] 1.4 Emit the p7-04 store into `src/features/<name>/stores/`, the hook into
      `hooks/`, the panel into `components/` — respecting the layer directories
      the base scaffolder already establishes.
- [x] 1.5 Emit the p7-03 plugin and mock agent, and register the plugin in
      `vite.config.ts` via the existing patcher pass.
- [x] 1.6 Emit a README section stating the mock agent and Vite middleware are
      **development-only**, and that production requires a real backend
      implementing the same contract. Non-negotiable — the app looks
      production-shaped and a reader will otherwise assume it is.

## Skill + registration

- [x] 2.1 `skills/scaffold-react-vite-agui/SKILL.md` with valid YAML frontmatter
      (repo constraint: frontmatter present on all skill files).
- [~] 2.2 **N/A — the premise does not hold.** `plugin.json` has no `skills`
      key and no existing skill is listed there, including
      `scaffold-react-vite-tauri`. CLAUDE.md:31 states component paths are
      auto-discovered; CLAUDE.md:54 ("add the new skill path to plugin.json")
      is stale and contradicts both line 31 and the file itself. Adding a
      `skills` key would break the convention. Verified instead: the skill is
      on disk with valid frontmatter and marketplace validation passes.

## Smoke — the phase's real gate

- [x] 3.1 `bash scripts/scaffold-react-vite-agui.sh <tmp-name>` exits 0.
- [x] 3.2 `pnpm build` exits 0 in the generated app.
- [x] 3.3 `pnpm lint` exits 0, including architectural ESLint rules.
- [x] 3.4 `pnpm dev` starts and serves the app with **no second process**.
- [x] 3.5 The agent route streams: `RUN_STARTED` first, `RUN_FINISHED` last,
      ≥2 distinct `TEXT_MESSAGE_CONTENT` frames.
- [x] 3.6 **Incremental rendering** — assert the rendered text *grows across
      frames*, not merely that the final text is correct. This is the one
      criterion a non-streaming stub cannot pass, and the phase does not
      succeed without it.
- [x] 3.7 Repo constraints hold: `bash scripts/validate-marketplace.sh` exits 0;
      frontmatter check passes; no stub comments in new files.
- [x] 3.8 `no-brand-leakage` (blocking): shipped content carries no legacy brand
      references —
      `grep -rn 'sediment://' prompts/ skills/ agents/ references/ assets/ README.md SKILL.md --include='*.md'`
      returns no matches (exit 1). This change emits a README into `assets/`.
- [~] 3.9 **N/A for the same reason as 2.2** — `plugin-manifest-current`
      assumes skills are enumerated in `.claude-plugin/plugin.json`
      lists `skills/scaffold-react-vite-agui` — assert by grep, since this
      change adds a new skill and the constraint exists precisely for that case.

## Gate

- [x] 4.1 All of 3.1–3.9 pass on a freshly scaffolded app in a temp directory —
      not on a hand-edited one.
