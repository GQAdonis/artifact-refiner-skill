# Tasks: p9-05 — `scaffold-react-vite-mcp-ui.sh`

**Scope** (files this change may edit):

```
scripts/scaffold-react-vite-mcp-ui.sh
skills/refine-mcp-ui/SKILL.md
```

**Registration note:** do **not** add the skill to `.claude-plugin/plugin.json`.
It has no `skills` key; component paths are auto-discovered (`CLAUDE.md:31`).
`CLAUDE.md:54` claims otherwise and is stale — p8-05 declined the same edit.

Read-only: `assets/scaffold/mcp-ui/` (p9-04), `examples/mcp-ui-refinement/`
(p9-03), `scripts/scaffold-react-vite-agui.sh` (the pattern),
`scripts/lib/kebab-case.sh`.

---

## 1. Wrapper structure

- [x] 1.1 Create `scripts/scaffold-react-vite-mcp-ui.sh` modelled on
      `scaffold-react-vite-agui.sh`. Layer onto the base scaffolder; **do not
      fork** the 1160-line base.
- [x] 1.2 Source `scripts/lib/kebab-case.sh` and derive the feature name with
      `to_kebab "$(basename "${TARGET}")"`. A raw `basename` creates a second
      feature slice the app never imports.
- [x] 1.3 Guard the existing-slice fallback with `FEATURE_EXPLICIT` so an
      explicit `--feature` still wins — the shape both prior wrappers now use.
- [x] 1.4 Pre-flight: verify every `assets/scaffold/mcp-ui/` file exists before
      touching the target, as `-agui.sh` does.
- [x] 1.5 `--target` required; `--feature` optional.

## 2. What it emits

- [x] 2.1 Run the base scaffolder first.
- [x] 2.2 Add `@mcp-ui/client@7.1.1` and `@modelcontextprotocol/ext-apps@1.7.5`,
      **pinned exact** (no `^`).
- [x] 2.3 Copy store, hook, surface, **and `trust-boundary.test.ts`** into the
      feature slice. The test ships with the code so a scaffolded app inherits
      the link-scheme and postMessage-origin checks rather than trusting they
      once passed in p9-04's workspace.
- [x] 2.4 Copy `vite-plugin-mcp-mock.ts` into `src/dev/`.
- [x] 2.5 Register the plugin in `vite.config.ts` **idempotently** — a second run
      is a no-op. Reuse `-agui.sh`'s approach: match the `plugins: [` opening
      only, so nested brackets cannot terminate the match early.
- [x] 2.6 Copy `sandbox-proxy.html` into `public/` so Vite serves it
      same-origin at a stable path.
- [x] 2.7 Copy the p9-03 fixtures to where the mock reads them — the `rawHtml`
      fixture the default path serves, plus `broken-scheme.json` so the
      discrimination path is exercisable in scaffolded output (p9-04 task 3.4b).
- [x] 2.8 **Mount the surface into the app's component tree.** Copying files is
      not rendering them: import `McpUiSurface` into the generated `App.tsx` (or
      the feature slice's route) so a fresh `pnpm dev` shows it without manual
      edits. Do this the way `-agui.sh` mounts its panel, and idempotently — a
      second run must not add a duplicate import or element. **Gate 5.8 fails
      without this**, and it would fail on a blank page rather than on anything
      diagnostic.

## 3. README

The scaffolder **generates** this file into the target app at
`<target>/MCP-UI.md`. It is emitted output, not a repo file, which is why it does
not appear in this change's scope — the scope lists what the change edits *here*.
Gate 5.10 asserts it exists in scaffolded output.

- [x] 3.1 State that the mock is **development-only**.
- [x] 3.2 Document the JSON-RPC contract a real MCP server must satisfy: the
      methods (as established by p9-04 task 3.2) and the tool-result shape
      carrying the embedded `ui://` resource.
- [x] 3.3 Document the sandbox posture explicitly: the proxy is served
      same-origin, and `permissions` overrides the library default to drop
      `allow-same-origin`. State that moving the proxy to a separate origin is a
      **security-relevant** change, not a deployment detail.
- [x] 3.4 Note that `remoteDom` and `externalUrl` content shapes are out of
      scope, and that the supported mimeTypes are `text/html;profile=mcp-app`
      and bare `text/html`.

## 4. Skill

- [x] 4.1 Create `skills/refine-mcp-ui/SKILL.md` with YAML frontmatter, matching
      `skills/refine-a2ui/SKILL.md`.
- [x] 4.2 `head -5 skills/refine-mcp-ui/SKILL.md | grep -q '^---'` passes.

## 5. Smoke gate — on a fresh target

Use a target name containing a **digit run** (e.g. `mcp9ui`). Phase-7's smoke
name kebabbed to itself, which is exactly why its feature-name bug survived a
whole phase undetected.

- [x] 5.1 `bash scripts/scaffold-react-vite-mcp-ui.sh --target <tmp>` exits 0.
- [x] 5.2 **Exactly one** directory under `src/features/`, and its name is the
      `to_kebab` form.
- [x] 5.3 An explicit `--feature` overrides derivation.
- [x] 5.4 Re-running the scaffolder is a no-op — `vite.config.ts` gains no second
      plugin registration, and `App.tsx` gains no duplicate import or element
      (task 2.8).
- [x] 5.5 `pnpm install && pnpm build` exits 0.
- [x] 5.6 `pnpm lint` exits 0 with architectural rules active.
- [x] 5.6b `pnpm test` exits 0 — `trust-boundary.test.ts` runs in the scaffolded
      app, proving the checks travel with the code rather than only having passed
      in p9-04's workspace.
- [x] 5.7 `pnpm dev` serves on :5173; verify a **single** listener via `lsof`.
- [x] 5.8 **Browser DOM** — Playwright asserts the fixture's heading and button
      by role/text in the rendered output, with zero page errors. Store-level
      assertions do not satisfy this gate.
- [x] 5.9 Assert the rendered iframe `sandbox` attribute lacks
      `allow-same-origin` — the p9-04 §5.2 decision surviving into scaffolded
      output, not just the asset.
- [x] 5.10 `<target>/MCP-UI.md` exists and contains the four §3 points: the
      development-only warning, the JSON-RPC contract, the sandbox posture, and
      the out-of-scope note. Grep for a distinctive phrase from each — a README
      that exists but omits the sandbox warning is the failure worth catching,
      since a consumer moving the proxy would then not know what they changed.

## 6. Constraint coverage

- [x] 6.1 `no-hardcoded-secrets` scans `scripts/ prompts/ references/`. This
      change creates **two** files: `scripts/scaffold-react-vite-mcp-ui.sh`
      (covered by the standing gate) and `skills/refine-mcp-ui/SKILL.md`
      (**not covered** — `skills/` is outside the scanned paths). Run the secret
      grep over `skills/refine-mcp-ui/` explicitly as a supplementary check.
      ```bash
      grep -rInE "(api[_-]?key|secret|token|password|BEGIN [A-Z ]*PRIVATE KEY)[\"'[:space:]]*[:=]" skills/refine-mcp-ui/
      ```
      Expect no matches.
      (Contrast p9-04, which writes only to `assets/` and is entirely outside
      the standing gate.)
- [x] 6.1b Constraint `no-brand-leakage` — the gate scans `skills/` for
      `*.md`, which covers `skills/refine-mcp-ui/SKILL.md`. It does **not** cover
      `scripts/`, so also grep the new scaffolder:
      ```bash
      grep -rn 'sediment://' prompts/ skills/ agents/ references/ assets/ README.md SKILL.md --include='*.md'
      grep -rn 'sediment://' scripts/scaffold-react-vite-mcp-ui.sh
      ```
      Expect no matches from either.
- [x] 6.2 `bash scripts/validate-marketplace.sh` exits 0.
- [x] 6.3 `git submodule status` shows no `+`/`-` prefixes — the
      `submodules-clean` constraint.
- [x] 6.4 Warning constraint `hook-scripts-executable` — despite the name, its
      check is `for f in scripts/*.sh; do [ -x "$f" ] || …`, covering **every**
      shell script in `scripts/`. Set the mode and verify:
      ```bash
      chmod 755 scripts/scaffold-react-vite-mcp-ui.sh
      ls -l scripts/scaffold-react-vite-mcp-ui.sh   # expect -rwxr-xr-x
      ```
      Both sibling scaffolders are `755`.
- [x] 6.5 Warning constraint `plugin-manifest-current` will flag, **expected and
      acknowledged** in `plan.md`: `plugin.json` has no `skills` key and paths
      are auto-discovered. **The correct action is no change.** Do not silence
      the warning by adding a key the schema does not define.
