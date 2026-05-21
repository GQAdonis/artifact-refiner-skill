# Plan: polish-pass

**Backend:** OpenSpec (`openspec/changes/polish-pass/`)
**Tasks:** `openspec/changes/polish-pass/tasks.md`
**Proposal:** `openspec/changes/polish-pass/proposal.md`

## Decisions baked in

- **Scope is bounded by prior reflections** — only fix things explicitly flagged
- **No new features** — AG-UI, streaming, tool-calling, etc. all rejected
- **Doc work is real polish** — README + AGENTS.md updates are highest-leverage
- **Version bump: 1.1.0 → 1.3.0** — semver minor for 11-phase delta
- **Tauri menu generation in `lib.rs` not `main.rs`** — Tauri 2 convention
- **WCAG report appended via post-render string insertion** — simpler than extending template; avoids serializing the report into TOML
- **theme-provider patcher fix is a 3-line bash addition** — surgical, low-risk
- **Regression smoke is the critical closing gate** — polish that breaks anything is a failed polish

## Ordered change list

| # | Block | Change | Effort |
|---|---|---|---|
| 1 | docs | README.md "Pipeline Capabilities" section | medium |
| 2 | docs | AGENTS.md "Architecture Reference" section | small |
| 3 | docs | CHANGELOG.md v1.3.0 entry listing 11 phases | small |
| 4 | template | moodboard.html motifs/tone iteration + fallbacks | small |
| 5 | script | refine-moodboard.mjs `@iarna/toml` direct import + validator extension + TOML emitter for motifs/tone | small-medium |
| 6 | script | refine-moodboard.mjs WCAG report post-render insertion | small |
| 7 | script | scaffold-react-vite-tauri.sh default menu in lib.rs | medium |
| 8 | script | scaffold-react-vite.sh theme-provider patcher move | small |
| 9 | manifest | plugin.json + marketplace.json version 1.1.0 → 1.3.0 | trivial |
| 10 | gate | regression smoke: full scaffold + build + cargo check + moodboard placeholder + LLM | medium (network) |
| 11 | gate | 11-gate acceptance sweep | small |

## Sequencing

```
Docs (1, 2, 3) — parallel-safe, no script dependencies
        │
        ▼
Template + script extensions (4, 5, 6) — must complete before regression smoke
        │
        ▼
Scaffolder patches (7, 8) — must complete before regression smoke
        │
        ▼
Manifest bumps (9) — trivial, parallel-safe
        │
        ▼
Regression smoke (10) — verifies nothing broken
        │
        ▼
Acceptance sweep (11)
```

In practice, the docs can be authored at any point during the session; placing them first is a low-risk warmup.

## Risk register

| Risk | Mitigation |
|---|---|
| README drifts from current behavior | Cite explicit file paths; grep-verify each claim |
| Minijinja iteration syntax wrong | Smoke render against existing knowme.toml (fallback path) + tmp brand TOML with motifs (iteration path) |
| LLM motifs/tone shape mismatch | validateSpec() rejects non-array; falls back to placeholder which provides static defaults |
| Tauri 2 menu API drift | API has been stable since 2.0 launch; smoke via `cargo check` |
| theme-provider move breaks downstream import | Existing rewrite block already handles `@/components/theme-provider` → `@/app/theme-provider` |
| Plugin version bump breaks marketplace listings | Pure metadata; semver minor is non-breaking by convention |

## Estimated effort

One focused session. Doc-heavy with small script extensions and Tauri menu Rust. The regression smoke + acceptance sweep are the time-bounded closers.

## Reuse from prior phases

| Reused | Source |
|---|---|
| `culori` + `report()` from `scripts/lib/wcag-contrast.mjs` | phase-3 |
| `@iarna/toml` import pattern | phase-3 (already in convert-htmx-react ambig path) |
| Tauri 2 scaffolder structure | phase-4 C |
| Patcher reorganize block in scaffold-react-vite.sh | phase-2 / phase-4 A |

Net new: zero new scripts, zero new templates, zero new dependencies. Pure polish.
