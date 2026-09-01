# Tasks: p8-05-scaffold-a2ui-host

**scope**:
- `scripts/scaffold-react-vite-a2ui.sh` (new)
- `skills/scaffold-react-vite-a2ui/SKILL.md` (new)
- `assets/scaffold/a2ui/**` (consumed, created by p8-04)

**Registration note:** do **not** add the skill to `.claude-plugin/plugin.json`.
It has no `skills` key and no existing skill is listed there; `CLAUDE.md:31`
states component paths are auto-discovered. (`CLAUDE.md:54` says otherwise and is
stale — this cost a detour in p7-05.)

## Scaffolder

- [x] 1.1 Create `scripts/scaffold-react-vite-a2ui.sh` following the
      `scaffold-react-vite-agui.sh` wrapper shape: `--target`, pre-flight,
      dependency install, emit, patch, README.
- [x] 1.2 `chmod +x`.
- [x] 1.3 Install `@a2ui/react` at exact `0.10.2` **and `@a2ui/web_core` at exact
      `0.10.6`**; add zustand/immer only if the target lacks them.
      **Both are required.** `a2ui-surface.tsx` imports `MessageProcessor`
      from `@a2ui/web_core/v0_9`, and `@a2ui/react` does **not** re-export it
      (verified: grep count 0 in its type definitions). Installing only
      `@a2ui/react` leaves the import unresolvable under pnpm's strict
      isolation — discovered during p8-04, recorded here so it is not
      rediscovered as a build failure.
- [x] 1.4 Emit the p8-04 store into `src/features/<name>/stores/`, hook into
      `hooks/`, surface component into `components/`.
- [x] 1.5 Emit the mock surface source into `src/dev/`.
- [x] 1.6 Emit a README section: mock source is development-only; document the
      envelope contract (`createSurface`/`updateComponents`/`updateDataModel`) a
      real agent must send, and how to point the store at it.
- [x] 1.7 Idempotent — a second run must not duplicate the README section or
      re-emit over local edits.

## Skill

- [x] 2.1 `skills/scaffold-react-vite-a2ui/SKILL.md` with valid YAML frontmatter.

## Smoke — on a freshly scaffolded app

- [x] 3.1 `scaffold-react-vite.sh` then `scaffold-react-vite-a2ui.sh` both exit 0
      on a temp target.
- [x] 3.2 `pnpm build` exits 0 in the generated app.
- [x] 3.3 `pnpm lint` exits 0, architectural rules active.
- [x] 3.4 `pnpm dev` serves with no second process.
- [x] 3.5 The mock source drives `createSurface` → `updateDataModel` →
      `updateComponents` through the store.
- [x] 3.6 **Browser DOM (Playwright):** the surface renders as real elements —
      assert by role/text, not by string-matching HTML — and a subsequent
      `updateDataModel` visibly changes rendered text without a reload. This is
      the criterion phase-7 left PARTIAL; it is the phase's acceptance test.
- [x] 3.7 Repo constraints: `marketplace-validates` (`validate-marketplace.sh`
      exits 0); `skill-frontmatter-present` — every `skills/*/SKILL.md` and
      `agents/*.md` opens with `---`, asserted across the whole repo rather than
      only the new file; `no-stub-comments` in new files.
- [x] 3.9 `submodules-clean` (blocking): `git submodule status` shows no
      unintended `+`/`-` prefixes. No p8 change enters `shared/` or `tools/`, so
      this should be trivially clean — asserted rather than assumed.
- [x] 3.10 `no-hardcoded-secrets` (blocking) — PASS with 3 pre-existing false
      positives, none introduced here: `convert-htmx-react.mjs:16` ('ask-LLM'
      matched by the `sk-` substring) and two `model-policy.schema.json` enum
      NAMES carrying no values. p8-05's own surface is clean.
      Original: run the constraint's own scan over
      its own paths — `grep -rn 'sk-\|api_key\|API_KEY\|secret.*=.*["'"'"'][A-Za-z0-9]' scripts/ prompts/ references/`
      returns nothing. This change adds `scripts/scaffold-react-vite-a2ui.sh`,
      which the constraint scans. p8-04's gate covers only
      `assets/scaffold/a2ui/` and does NOT satisfy this constraint for `scripts/`.
- [x] 3.11 `hook-scripts-executable` (warning): `[ -x scripts/scaffold-react-vite-a2ui.sh ]`
      — verifies task 1.2's `chmod +x` actually took effect.
- [x] 3.8 `no-brand-leakage` over shipped content returns nothing.

## Gate

- [x] 4.1 All of 3.1–3.8 pass on a freshly scaffolded app in a temp directory,
      not a hand-edited one.
