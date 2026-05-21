# Tasks: polish-pass

Doc-heavy, with small script extensions. Closing regression smoke is the critical gate.

## 1. Documentation updates

- [ ] 1.1 Update `README.md`. Add a new section **after** the existing "Installation" section and **before** "How It Works":
  - Section title: `## Pipeline Capabilities`
  - Three subsections:
    - **Conversion skills** — table of 5: convert-htmx-react, convert-md-to-htmx, refine-moodboard, design-svg-logo, rebrand-artifact. For each: what it does, where the script lives, whether it's deterministic / LLM-primary / mode-switching.
    - **Scaffolders** — scaffold-react-vite (with --with-axum-wrapper, --with-tauri-wrapper); link to skills/scaffold-react-vite/SKILL.md and skills/scaffold-react-vite-tauri/SKILL.md.
    - **Inference routing** — model_policy + openai-proxy + chat() helper. Link to references/model-routing.md.
  - Cite explicit file paths for each claim; the section should be grep-able.
- [ ] 1.2 Update `AGENTS.md`. Add a new section **after** "Architecture Overview":
  - Section title: `## Architecture Reference`
  - Four bullets pointing at:
    - `references/scaffolds/clean-architecture.md`
    - `references/scaffolds/state-architecture.md`
    - `references/scaffolds/responsive-architecture.md`
    - `references/scaffolds/kebab-case-rename.md`
  - One sentence each describing what the doc covers.
- [ ] 1.3 Author or update `CHANGELOG.md`. If absent, create it with the standard "Keep a Changelog" header.
  - Add a section: `## v1.3.0 (2026-05-20)` — Phase Pipeline Milestone
  - List the 11 shipped phases with one-line summaries each:
    1. phase-0-unblock — five new SKILL.md files + ADR-0001 sycophancy-correction extraction decision
    2. phase-rust-workspace-bootstrap — template-forge-rs Rust workspace (Minijinja walking skeleton)
    3. phase-1-submodule-topology — rust-mcp-filesystem submodule (upstream v0.4.2)
    4. phase-sc-extraction — sycophancy-correction submodule (Know-Me-Tools standalone repo)
    5. phase-1b-inference-routing — model_policy schema + openai-proxy endpoint discovery
    6. phase-2-scaffold-react-vite — React 19 + Vite + shadcn-on-Base-UI scaffolder + optional axum wrapper
    7. phase-3-conversion-layer — convert-htmx-react + rebrand-artifact execution scripts
    8. phase-prefer-endpoint-consumption — chat() helper + model-routing.log audit + first consumer
    9. phase-4-scaffold-tauri-desktop — zustand+immer architecture + responsive primitives + PWA + Tauri 2 hybrid shell
    10. phase-3b-aux-conversions — convert-md-to-htmx + refine-moodboard (LLM-primary) + design-svg-logo (mode-switching)
    11. polish-pass — quality lift (docs + small script extensions + version bump)

## 2. Moodboard template extension

- [ ] 2.1 Update `tools/template-forge-rs/templates/moodboard.html`:
  - Replace the static "Motifs" section's hardcoded six `.motif` divs with `{% for m in brand.motifs %}<div class="motif"><h3>{{ m.name }}</h3><p>{{ m.description }}</p></div>{% endfor %}`
  - Keep a fallback: `{% if not brand.motifs %}` block emitting the existing six static motifs (so brands without motifs in the TOML still render correctly).
  - Replace the static "Tone" chips with `{% for t in brand.tone %}<span class="tone-chip">{{ t }}</span>{% endfor %}`
  - Fallback: existing five static tone chips when `brand.tone` absent.
- [ ] 2.2 Smoke render against the existing `knowme.toml` (no motifs/tone fields) — verify the fallback path renders the static text.
- [ ] 2.3 Author a tiny test brand TOML at `/tmp/brand-with-motifs.toml` with `motifs = [{name="...", description="..."}, ...]` and `tone = ["Bold", "Direct"]`; render and verify the iteration path works.

## 3. refine-moodboard.mjs improvements

- [ ] 3.1 Replace `node -e "..."` subprocess TOML parse in `refine-moodboard.mjs` `loadBrandAsSpec()` with direct `import { parse as parseToml } from "@iarna/toml"; ... readFileSync(path, "utf8");`
- [ ] 3.2 Update the LLM prompt + the `validateSpec()` validator to require `motifs: [{name, description}, ...]` and `tone: [string, ...]` arrays as part of the response shape. Validator rejects if either is missing or wrong-shaped.
- [ ] 3.3 Extend `toTomlString()` to emit `motifs` and `tone` arrays. TOML array of tables for motifs (`[[motifs]]` style); inline array for tone.
- [ ] 3.4 Wire `culori`-based WCAG contrast report:
  - Import `report` from `scripts/lib/wcag-contrast.mjs` (already exists from phase-3)
  - Compute report against the spec's text-on-bg pairs (ink-on-bg, ember-on-bg, muted-on-bg, white-on-ember) for both light + dark
  - Pass the report into the rendered HTML — append a new `<section class="accessibility">` to the output via a post-render string insertion (or extend the template if the report data can be serialized into TOML as a nested table)
  - Recommendation: post-render string insertion — simpler and doesn't bloat the template

## 4. Tauri default menu generator

- [ ] 4.1 Update `scripts/scaffold-react-vite-tauri.sh`:
  - After `pnpm tauri init`, append a default menu to `src-tauri/src/lib.rs` (Tauri 2 generates `lib.rs` as the main module).
  - Use Tauri 2 `Menu` API to build File / Edit / View / Window / Help with standard items (Quit, Cut/Copy/Paste, Reload, Toggle Fullscreen, About).
  - Wire into the `Builder::default().setup(|app| ...)` block via `app.set_menu(menu)?`.
- [ ] 4.2 Smoke: re-scaffold with `--with-tauri-wrapper`; verify `cargo check src-tauri/` passes with the menu code.

## 5. theme-provider patcher fix

- [ ] 5.1 In `scripts/scaffold-react-vite.sh` Step 3 (Reorganize), after the `src/components/ui/` move block, add:
  ```bash
  # Move shadcn-nova preset's theme-provider.tsx from components/ to app/
  if [[ -f src/components/theme-provider.tsx ]]; then
    mv src/components/theme-provider.tsx src/app/theme-provider.tsx
    rmdir src/components 2>/dev/null || true
  fi
  ```
- [ ] 5.2 Verify the existing import-rewrite block (Step 3 "Rewriting shadcn-default import paths") catches any reference to `@/components/theme-provider` and rewrites to `@/app/theme-provider`.
- [ ] 5.3 Smoke: re-scaffold sample-app; verify `src/components/` does not exist post-scaffold (or only contains generated dirs).

## 6. Plugin manifest + marketplace version bump

- [ ] 6.1 `.claude-plugin/plugin.json`: `"version": "1.1.0"` → `"version": "1.3.0"`.
- [ ] 6.2 `.claude-plugin/marketplace.json`: same — `"version": "1.1.0"` → `"version": "1.3.0"`.
- [ ] 6.3 Validate both as JSON.

## 7. Regression smoke (critical gate)

- [ ] 7.1 `rm -rf /tmp/smoke-polish; bash scripts/scaffold-react-vite.sh --name smoke-polish --source assets/templates/sample-app.tsx --brand knowme --target /tmp/smoke-polish --with-tauri-wrapper`
- [ ] 7.2 Verify `pnpm build` succeeds in the scaffolded target.
- [ ] 7.3 Verify `cargo check src-tauri/` succeeds in the scaffolded target.
- [ ] 7.4 Verify `src/components/` no longer exists OR only contains intentional generated subdirs (no orphan `theme-provider.tsx`).
- [ ] 7.5 Run `node scripts/refine-moodboard.mjs --use-case "test" --audience "test" --aesthetic "test" --output /tmp/mb-polish.html --mode placeholder` → verify HTML produced.
- [ ] 7.6 Run the same in `--mode` (default LLM): verify HTML produced AND contains an "Accessibility Report" section.

## 8. Acceptance gate sweep

- [ ] 8.1 README has "Pipeline Capabilities" section
- [ ] 8.2 AGENTS.md has "Architecture Reference" section
- [ ] 8.3 `moodboard.html` template has `{% for m in brand.motifs %}` and `{% for t in brand.tone %}` blocks
- [ ] 8.4 LLM moodboard output renders LLM-supplied motifs and tone
- [ ] 8.5 Moodboard HTML contains WCAG report
- [ ] 8.6 `refine-moodboard.mjs` no longer uses `node -e` for TOML
- [ ] 8.7 Tauri scaffolder generates a default menu; `cargo check` passes
- [ ] 8.8 Patcher moves `theme-provider.tsx`
- [ ] 8.9 Plugin version 1.3.0; marketplace 1.3.0; both valid JSON
- [ ] 8.10 CHANGELOG.md has v1.3.0 entry listing 11 phases
- [ ] 8.11 Regression smoke: `pnpm build` + `cargo check` pass

## Out of scope

(All items in assessment §3 "Out of scope" list — feature work explicitly rejected.)

## Recommended agents

| Tasks | Agent |
|---|---|
| 1.* (docs) | direct authoring; cite paths against grep |
| 2.*, 3.* | direct authoring + smoke per change |
| 4.* | direct + Tauri menu Rust syntax; `cargo check` smoke |
| 5.* | direct edit |
| 6.* | direct edit + JSON validate |
| 7.* | verify-app (regression) |
| 8.* | verify-app (final sweep) |
| Post-execute review | code-reviewer |
