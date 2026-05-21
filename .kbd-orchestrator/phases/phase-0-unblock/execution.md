# Execution: phase-0-unblock

**Status:** HALTED at gate-0 (reality check)
**Backend:** OpenSpec (when resumed)
**Halted by:** Claude Code, 2026-05-20, on first execute attempt

## Why halted

The plan was written against the file tree described in `docs/session-2026-05-20-artifact-refiner-buildout.md`. That session ran inside Claude Desktop's sandboxed filesystem (`/mnt/user-data/outputs/...`). **The file tree it describes does not exist on disk in this repository.**

Verified absent (2026-05-20):

| Plan assumed exists | Reality |
|---|---|
| `tools/template-forge-rs/` (Rust workspace) | does not exist |
| `skills/convert-md-to-htmx/` (partial SKILL.md) | does not exist |
| `skills/convert-htmx-react/` (empty SKILL.md) | does not exist |
| `skills/rebrand-artifact/` | does not exist |
| `skills/refine-moodboard/` | does not exist |
| `skills/design-svg-logo/` | does not exist |
| `skills/build-artifact-library/` | does not exist |
| `assets/library/brands/{knowme,prometheus-ags}.toml` | `assets/library/` does not exist |
| `scripts/install-template-forge.sh` | does not exist |

Verified present:

- `skills/{artifact-refiner,refine-a2ui,refine-content,refine-image,refine-logo,refine-status,refine-ui,refine-validate}/` — the v1.2.0 surface
- `scripts/installers/{antigravity,claude-code,cline,codex,common.sh,cursor,gemini-cli,kilo-code,opencode,roo-code,warp,windsurf,zed}` — per-harness installers, real
- `assets/templates/` + `assets/vendor/` — real
- `openspec/changes/{add-browser-rendering-for-htmx-react-artifacts,agui-spike-and-domain,finish-a2ui-domain}/` — real, in-flight OpenSpec changes

## Implication for the plan

The plan as written conflates two distinct kinds of work:

1. **Authoring** — creating files that have never existed (template-forge-rs, six skill dirs, brand TOMLs, install script).
2. **Unblocking** — fixing files that exist but are broken (which is what `phase-0-unblock` is named for).

There is **no #2** work to do — nothing is broken because nothing has been created. The Priority-1 "six known issues" in the session doc are speculative compile errors against a workspace that was never written to disk.

## Correction required

The phase needs to be renamed and re-scoped before execution can proceed honestly.

### Recommended re-scoping (for user approval before I proceed)

**Option 1 — Rename and re-scope (recommended).**
Rename phase to `phase-0-bootstrap-from-session-doc`. Acknowledge it as a creation phase, not an unblock phase. Tasks become:

- Create `tools/template-forge-rs/` workspace from the session-doc spec
- Create `assets/library/brands/{knowme,prometheus-ags}.toml`
- Create `scripts/install-template-forge.sh`
- Create the six new skill directories with proper `SKILL.md` files
- Compile-check after each engine is added
- Register in marketplace

The session doc becomes the *specification* for this phase, not a status report.

**Option 2 — Use Claude Desktop sandbox as the authoritative source.**
If the workspace was actually written somewhere downloadable (`/mnt/user-data/outputs/` ZIP, etc.), pull it in first, then execute the original phase-0-unblock against the real (broken-as-described) state.

**Option 3 — Defer template-forge-rs entirely.**
Scope phase-0 down to:

- Author the six new `SKILL.md` files only (no Rust workspace yet)
- Write ADR-0001
- Marketplace update
Defer template-forge-rs to a later phase, with its own assessment. This is the smallest credible phase-0 and the lowest risk.

### Sycophancy-check on this halt

I am not halting to defer work. I am halting because executing against a non-existent file tree would mean either:

- silently creating files while claiming to fix them (dishonest), or
- emitting fake "fix" diffs against files that do not exist (broken).

Both are worse than halting and surfacing the question.

## What is preserved

- Assessment is still valid; the analysis of gaps, the routing addendum, and the open questions all stand.
- OpenSpec proposal/tasks/design files are valid as a *target spec* — they just describe authoring, not unblocking.
- Waypoint and progress files remain accurate as of plan-complete.

## Resume path

Once the user picks an option:

1. Update `openspec/changes/phase-0-unblock/proposal.md` "Why" section to reflect creation-from-spec, not unblock-broken-build.
2. Re-emit `tasks.md` with `[CREATE]` markers where files don't exist.
3. Update waypoint `stage` from `plan_complete` back to `plan_revision` until user confirms.
4. Resume `/kbd-execute phase-0-unblock` (or the renamed phase).

## Recommendation

**Option 3** (defer template-forge-rs). Reasoning:

- The session doc's Rust workspace is ambitious: 3 crates, 5 engines, MCP server, CLI, ramhorns proc-macro trick. That is a phase on its own.
- The six SKILL.md files have value *without* the Rust workspace — they document the conversion/rebrand/moodboard/logo workflows even if the rendering binary isn't built yet. Skills referencing `template-forge` can use it as an optional accelerator (fall back to running the template substitution manually or via a small shell script).
- Phase-0 stays small enough to actually finish in one or two sessions.
- The Rust workspace gets a clean assessment of its own, with proper task breakdown — not a port of Priority-1 issues from a session doc.

Awaiting user decision before resuming execution.
