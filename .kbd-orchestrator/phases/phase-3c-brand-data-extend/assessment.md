# Assessment — phase-3c-brand-data-extend

- **Phase:** `phase-3c-brand-data-extend`
- **Stage:** assess
- **Date:** 2026-08-27
- **Origin:** Deferred from `polish-pass` acceptance gate 8.4 (partial, 10/11)
- **Model preflight:** `ok` — judge `k3`, critic `MiniMax-M3`, generator
  `kbd-frontier` (3 distinct models; no producer/judge collision)

---

## Phase Goal

Close `polish-pass` gate 8.4: LLM-supplied `motifs` and `tone` must survive
end-to-end from the moodboard generator into rendered HTML output. Taking
`polish-pass` from 10/11 to 11/11.

---

## Method

This assessment is **empirical, not documentary**. The inherited `polish-pass`
note was treated as a hypothesis and tested against a live render, because the
note contained a claim that turned out to be inaccurate (see *Correction* below).

Probe procedure:

1. Authored `/tmp/probe-brand.toml` — a minimal valid brand containing one
   `[[motifs]]` entry (`title = "Test Motif"`) and `tone = ["Direct", "Confident"]`.
2. Built `template-forge` with an isolated `CARGO_TARGET_DIR=/tmp/kbd-probe-target`
   (per `AGENT_RULES.md`: one writer per target directory).
3. Rendered `moodboard` against the probe brand.
4. Grepped the output for the probe values.

---

## Findings

### F-1 — CONFIRMED: `motifs` and `tone` are silently dropped (root cause)

`BrandData` (`tools/template-forge-rs/crates/template-core/src/brand.rs:11`) has
exactly five fields: `meta`, `colors`, `typography`, `logo`, `contact`. There is
no `motifs` field and no `tone` field.

Deserialization at `library.rs:52` uses `toml::from_str::<BrandData>`. Serde's
default behavior is to **ignore unknown fields**, and `#[serde(deny_unknown_fields)]`
is absent — verified:
`grep -n "deny_unknown_fields" tools/template-forge-rs/crates/template-core/src/brand.rs`
returns exit 1 (no match). So `motifs` and `tone` present in the TOML are parsed,
discarded, and never reach the template context.

**Empirical proof** (`render` exit 0, no warning emitted):

| Probe input | Expected in output | Actually in output |
|---|---|---|
| `[[motifs]] title = "Test Motif"` | `Test Motif` | **absent** (grep count 0) |
| `tone = ["Direct", "Confident"]` | 2 chips | **5 chips** — hardcoded fallback |

The render **succeeds**. Nothing fails, nothing warns.

### F-2 — CONFIRMED: the failure is invisible by construction

`templates/moodboard.html:102` and `:121` wrap both loops in
`{% if brand.motifs %}` / `{% if brand.tone %}` with `{% else %}` blocks holding
six hardcoded motifs and five hardcoded tone words.

Because the struct never populates those keys, the `{% else %}` branch is the
**only** branch that can ever execute. The output is always well-formed and
plausible-looking, so the defect produces no error, no empty section, and no
visual artifact. This is why it survived `polish-pass` verification.

Severity note: a silent-fallback path that is unreachable-by-data is worse than
a hard failure — it renders convincing but unbranded output, and a caller cannot
distinguish "LLM supplied no motifs" from "motifs were discarded."

### F-3 — ~~Producer side is already correct (no work needed)~~ **SUPERSEDED — see F-3-CORRECTION**

`scripts/refine-moodboard.mjs` is complete and requires no changes:

- `:100-107` emits `[[motifs]]` tables and a `tone` array into brand TOML.
- `:128-149` validates shape — `motifs` must be an array of objects with
  `title`/`description`; `tone` must be an array of non-empty strings.
- `:183-184` conditionally forwards both when the LLM returns them.
- `:221-224` includes both in the LLM prompt contract.

The gap is **exclusively** on the Rust consumer side.

### F-3-CORRECTION — the producer had a second, independent defect

**F-3 above was wrong**, and was found to be wrong during execute. The producer
validates `tone`'s *shape* correctly but emitted it in an *unparseable position*.

`refine-moodboard.mjs` appended `tone = [...]` after every `[table]` header,
including after `[[motifs]]`. In TOML, a bare `key = value` following a table
header belongs to **that table** — so `tone` was parsed into
`motifs[0].tone` (or `typography.tone` when no motifs existed), never at top
level. Verified with `tomllib`:

```
motifs[0] = {'title': 'M1', 'description': 'D1', 'tone': ['Direct', 'Confident']}
```

Consequence: the struct fix alone would **not** have closed gate 8.4. `motifs`
would have started rendering while `tone` silently kept falling back — a
partial fix that looked complete, since the fallback output is well-formed.

Found because the round-trip test (G-5) failed on my own fixture, which had made
the identical ordering mistake. This is the clearest argument for G-5 being in
scope rather than deferred: the test caught a defect in the *producer* that
static reading of the producer had missed.

**Fix applied:** `refine-moodboard.mjs` now emits `tone` before the first table
header, and the trailing append was removed.

### F-4 — No test coverage on `brand.rs`

`brand.rs` contains zero `#[test]` functions (86 lines, 0 tests). The only tests
in `template-core` are in `library.rs:58`. There is no round-trip test asserting
that a TOML field reaches the template context — which is precisely the class of
defect F-1 represents.

---

## Correction to inherited state

`.kbd-orchestrator/phases/polish-pass/progress.json:14` (`acceptance_notes`) states:

> "The moodboard.html template iterates correctly when data is present
> (verified via fallback path)"

**This claim is not supported.** "Verified via fallback path" verified only that
the `{% else %}` branch renders — the branch that runs when data is *absent*. It
did not and could not verify the `{% for %}` branch, which is unreachable while
F-1 stands. The template loops are plausibly written but have never executed.

This does not change the gate outcome (8.4 was correctly marked partial) but it
does change the risk profile: the remaining work is not "add two struct fields
and it works," it is "add two struct fields, then verify the loop branch for the
first time."

---

## Gap Report

| ID | Gap | Severity | Evidence |
|---|---|---|---|
| G-1 | `BrandData` lacks `motifs` field | BLOCKING | `brand.rs:11-19` |
| G-2 | `BrandData` lacks `tone` field | BLOCKING | `brand.rs:11-19` |
| G-3 | No `Motif` struct (`title`, `description`) exists | BLOCKING | absent from `brand.rs` |
| G-4 | Template `{% for %}` branches never executed | HIGH | F-2, empirical probe |
| G-5 | No round-trip test TOML → context → output | HIGH | F-4 |
| G-6 | Unknown TOML fields discarded without warning | MEDIUM | `library.rs:52`, no `deny_unknown_fields` |

---

## Scope Recommendation

**In scope** (closes gate 8.4):

- Add `Motif { title: String, description: String }` struct, deriving
  `Serialize`/`Deserialize` to match existing conventions in `brand.rs`.
- Add `#[serde(default)] pub motifs: Option<Vec<Motif>>` to `BrandData`.
- Add `#[serde(default)] pub tone: Option<Vec<String>>` to `BrandData`.
- Add a round-trip test proving a TOML `[[motifs]]` entry and `tone` array reach
  rendered output (closes G-5, and gives G-4 its first real execution).

Both fields must be `Option` + `#[serde(default)]` so existing brand TOMLs
without them continue to deserialize. This preserves the template's `{% else %}`
fallback as genuine behavior for brands that legitimately omit motifs.

**Out of scope** (flag, do not fix here):

- G-6 (`deny_unknown_fields`) — a serde strictness decision. Blast radius
  verified rather than assumed: `BrandData` is deserialized at exactly **one**
  site (`library.rs:52`); other references are re-exports (`lib.rs:17`), trait
  signatures (`engine/mod.rs:22`), and test fixtures
  (`minijinja_engine.rs:89-100`). So the change is smaller than "repo-wide",
  but it alters behavior for **every existing brand TOML on disk** — any file
  carrying an extra key would begin to hard-fail. That input-compatibility risk,
  not consumer count, is why it stays out of this phase. Note it and move on.
- Any change to `refine-moodboard.mjs` — F-3 shows the producer is correct.
- Template restructuring — the loops are correct; they have simply never run.

---

## Open Questions for plan/execute

1. **Fallback semantics.** Once `motifs` is populated, should a brand supplying
   *fewer* than six motifs render only its own, or top up from the hardcoded
   set? Recommendation: render only the brand's own — mixing LLM and hardcoded
   content reintroduces the "can't tell what came from where" problem.
2. **Should G-6 be filed now?** Recommend opening a follow-up change so the
   silent-discard class of defect is tracked rather than rediscovered.

---

## Verification Criteria (for the plan stage)

Gate 8.4 closes when **all** hold:

- [ ] A brand TOML with `[[motifs]]` renders those motif titles in output HTML.
- [ ] A brand TOML with `tone = [...]` renders exactly those chips — not the
      hardcoded five.
- [ ] A brand TOML *without* `motifs`/`tone` still renders the fallback blocks
      (no regression).
- [ ] `cargo test -p template-core` passes with the new round-trip test.
- [ ] `cargo check` clean on the touched crate (T0 per `AGENT_RULES.md`).

The first two criteria are the ones the inherited note assumed; neither has ever
been demonstrated.

---

## Adversarial Review

Vetted per step 8. **Verdict: PASS** (0 CRITICAL, 2 WARNING, 1 SUGGESTION) —
`review/assess/findings.json`.

Isolation was **degraded and is stated, not hidden**: the REST gateway returned
HTTP 401 `token_expired` at `http://localhost:8181/v1` (`dispatch-judge.sh`
exit 3), so review fell back to the tier-2 harness-native fresh-context
subagent. That judge received only the mandate plus the packet — no session
history — but is the same model family as the producer, a weaker guarantee than
a true cross-model call. **Action for the operator:** the gateway credential
needs renewing (`/liter-llm-bridge configure`) before the next stage, or every
subsequent review in this phase inherits the same weaker isolation.

All three findings were verified against the codebase and **all three were
correct**. Two were applied to this document:

| Finding | Disposition |
|---|---|
| W-1 acceptance_notes quote untraceable | **Fixed** — now cites `polish-pass/progress.json:14` |
| W-2 G-6 blast radius overclaimed | **Fixed** — the claim "every brand TOML consumer" was wrong; there is exactly one deserialization site. Rationale re-grounded on input compatibility. |
| S-3 `deny_unknown_fields` absence asserted, not shown | **Fixed** — F-1 now records the empty-grep result |

W-2 is worth carrying forward: the original text justified deferring G-6 with a
consumer count that the code does not support. The deferral still stands, but on
a different and verified basis.

## Estimate

The waypoint carried ~30 min. That holds for the struct change alone (G-1..G-3
are roughly 15 lines). Adding the round-trip test and re-verifying pushes it to
roughly **45–60 min**. The extra time buys the first actual execution of a code
path that has been shipping untested.
