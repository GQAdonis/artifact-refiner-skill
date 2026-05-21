# Phase Assessment: Sycophancy-Correction Submodule Wiring

**Phase:** `phase-sc-extraction`
**Project:** `artifact-refiner`
**Date:** 2026-05-20
**Author:** Claude Code (Opus 4.7, 1m context)
**Mode:** Assessment only — no implementation
**Sycophancy correction:** applied (S-03 scope inflation aggressively cut)

---

## 1. Critical reality check — most of this phase's premise is wrong

The phase was named `phase-sc-extraction` based on ADR-0001 Option A, which assumed `sycophancy-correction` was an embedded directory inside `prometheus-skill-pack` that needed to be **extracted** to a standalone GitHub repo, then submoduled by both packs.

That assumption is false. Verified 2026-05-20:

1. **The standalone repo already exists** at `https://github.com/Know-Me-Tools/sycophancy-correction-skill.git`.
2. **`prometheus-skill-pack` already consumes it as a submodule.** From `prometheus-skill-pack/.gitmodules`:
   ```
   [submodule "skills/imported/sycophancy-correction"]
       path = skills/imported/sycophancy-correction
       url = https://github.com/Know-Me-Tools/sycophancy-correction-skill.git
   ```
3. **The directory at `prometheus-skill-pack/skills/imported/sycophancy-correction/` is a submodule checkout, not an embedded copy.** The `.git` file is the 68-byte gitlink form, confirming submodule status.
4. **Git remote responds 200** on the public repo URL. HEAD SHA `01150389...` matches what `prometheus-skill-pack` is pinned to.

The work the phase was originally scoped to do — `git filter-repo`, create new GitHub repo, curate commit history, update `prometheus-skill-pack` to consume it — **has already been done**. By someone, at some prior date.

This phase therefore reduces to one task: **add the existing standalone repo as a submodule of `artifact-refiner`.**

---

## 2. Sycophancy-Corrected Reframe

The honest action when discovering the premise is wrong is to:

1. Acknowledge the prior work explicitly, not paper over it.
2. Cut the scope to what is actually needed.
3. Update ADR-0001 to reflect that Option A is already in flight (the repo exists; consumption-by-second-pack is the remaining step).

This is what S-03 (scope inflation) correction looks like in practice: the failure mode would be to plow ahead with the original 8-task extraction plan and "do extraction work" that is already done. The corrected behavior is to do the 1-task work that remains.

---

## 3. Revised goal

Add `https://github.com/Know-Me-Tools/sycophancy-correction-skill.git` as a submodule of `artifact-refiner` at `shared/sycophancy-correction/`, pinned to a tag or commit, and update the documentation noting that ADR-0001 Option A is now fully realized.

That is the entire scope.

---

## 4. Out of scope (explicitly)

- Forking the standalone repo (no reason to).
- Migrating any code from `prometheus-skill-pack` (everything is already in the standalone repo).
- Updating `prometheus-skill-pack`'s submodule pin (it's pinned and works; not our concern).
- Refactoring `artifact-refiner` code to consume sycophancy-correction's MCP server (out of scope; this phase only adds the submodule path; consumption wiring is a follow-on if/when needed).
- Building sycophancy-correction's binaries during install — defer until a consumer actually needs them. Phase-1's `build-vendored-binaries.sh` can be extended later.

---

## 5. Current state inventory

| Surface | Status |
|---|---|
| `shared/` directory in artifact-refiner | does not exist |
| `tools/rust-mcp-filesystem/` submodule | present (phase-1 shipped) |
| `.gitmodules` | exists, lists rust-mcp-filesystem only |
| ADR-0001 status | Accepted (Option A) — needs an addendum noting the standalone repo already exists |
| The standalone repo `Know-Me-Tools/sycophancy-correction-skill` | exists, public, accessible via HTTPS, HEAD on `main` |
| `prometheus-skill-pack` consumption of it | already submoduled |

---

## 6. Risk surface

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Standalone repo goes private or renames | Low | Medium | Pin to specific SHA, not `main` HEAD |
| Standalone repo diverges from what artifact-refiner needs | Low | Low | We pin via submodule; no auto-bump |
| `Know-Me-Tools` org becomes inactive | Low | Medium | Fork at our own org as recovery; submodule URL swap is one line |

Nothing high-severity. This is the smallest credible phase in the pipeline so far.

---

## 7. Acceptance criteria

1. `git submodule status` lists `shared/sycophancy-correction` with a pinned SHA matching what `prometheus-skill-pack` pins to (`01150389...`) or a newer release tag if one exists.
2. `bash scripts/setup-submodules.sh` no longer prints the "pending" warning; instead reports the submodule as initialized.
3. ADR-0001 has an addendum recording that Option A is realized via the existing `Know-Me-Tools/sycophancy-correction-skill` repo.
4. `.gitmodules` includes both `tools/rust-mcp-filesystem` and `shared/sycophancy-correction`.

That is the entire acceptance suite.

---

## 8. Phase decomposition (for the upcoming Plan)

| Order | Sub-change | Effort |
|---|---|---|
| 1 | `git submodule add https://github.com/Know-Me-Tools/sycophancy-correction-skill.git shared/sycophancy-correction` | trivial |
| 2 | Pin to `prometheus-skill-pack`'s currently-pinned SHA (`01150389...`) or the newest release tag — verify by listing tags first | trivial |
| 3 | Update `scripts/setup-submodules.sh`: remove the "pending" warning block; replace with normal status reporting | trivial |
| 4 | Update README.md "Submodules and vendored binaries" section: change `*(pending)*` → realized | trivial |
| 5 | Append ADR-0001 addendum: note Option A is realized via existing `Know-Me-Tools/sycophancy-correction-skill` repo | trivial |
| 6 | Acceptance gate sweep | trivial |

Total: under 30 minutes of work.

---

## 9. Open questions for the Plan

1. **Pin choice:** match `prometheus-skill-pack`'s current pin (`01150389...` on `main`) for consistency, or pin to a release tag? Recommendation: match prometheus-skill-pack's pin for now; the two packs benefit from staying aligned. Bumps happen in lockstep.
2. **Branch tracking:** record `branch = main` in `.gitmodules` (like `prometheus-skill-pack` does for `liter-llm`) or leave bare? Recommendation: leave bare — explicit SHA pin is the contract.
3. **Path naming:** `shared/sycophancy-correction/` vs `tools/sycophancy-correction/`? Recommendation: `shared/sycophancy-correction/` — it's not a runnable tool from the user's PoV (no separate binary they install), it's a shared skill consumed by the loop. Mirrors `prometheus-skill-pack`'s `skills/imported/` slot.
4. **Should this phase also wire artifact-refiner to actually *use* sycophancy-correction's MCP server?** Recommendation: no. That is consumption work, not topology work. Keep this phase clean.

---

## 10. Honest verdict

This phase is now genuinely 30 minutes of work — three file edits, one `git submodule add`, one ADR addendum, one acceptance check. The original ADR-0001 contemplated half a session of extraction plus a session of downstream wiring. The extraction has already been done by someone (most likely the user in an earlier session). The downstream wiring for `prometheus-skill-pack` is also done. Only **our** downstream wiring remains.

**Recommendation:** proceed to `/kbd-plan phase-sc-extraction` (could be renamed to `phase-sc-wiring` to reflect reality, but the existing name is fine for trackability).

---

## 11. Assessment metadata

```yaml
assessment_complete: true
phase: phase-sc-extraction
premise_was_wrong: true
correction_applied: "Standalone repo already exists; phase is wiring, not extraction"
inputs_reviewed:
  - prometheus-skill-pack/.gitmodules
  - prometheus-skill-pack/skills/imported/sycophancy-correction/{README.md,Cargo.toml,SKILL.md}
  - prometheus-skill-pack/.git submodule status
  - https://github.com/Know-Me-Tools/sycophancy-correction-skill (HTTP 200, ls-remote successful)
  - docs/decisions/0001-sycophancy-correction-extraction.md
scope_change_from_original_adr:
  was: "extract sycophancy-correction to standalone repo + wire both packs"
  is_now: "add existing standalone repo as submodule of artifact-refiner only"
recommendation: |
  Proceed to /kbd-plan phase-sc-extraction. Six trivial sub-changes,
  ~30 minutes execute, no risk surface.
next_command: /kbd-plan phase-sc-extraction
```

Completed kbd-assess — phase-sc-extraction
