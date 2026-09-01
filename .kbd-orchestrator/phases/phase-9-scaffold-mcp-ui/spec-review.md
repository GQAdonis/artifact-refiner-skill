# Spec-stage Adversarial Review — phase-9-scaffold-mcp-ui

Judge `kbd-judge` vs producer `claude-opus-5`, `verified-distinct`,
isolation `rest-gateway`. **13 rounds, 30 findings (24 CRITICAL, 6 WARNING),
30/30 accepted.** Final verdict **PASS** with one WARNING, fixed after.

The packet was assembled by hand: `build-review-packet.sh` supports only the
native-kbd spec layout and errors on an OpenSpec change set. All five changes
were reviewed **together** each round, since a spec is only coherent against its
siblings — and most findings here were cross-change.

## The five findings that changed the deliverable

| # | Round | Finding | Consequence |
|---|---|---|---|
| 1 | 1 | The `oneOf` exclusivity fixture was **unbuildable** — a single `mimeType` string cannot hold two values | Redesigned the schema as `oneOf` over *branches*, and replaced the test with a transient duplicate-branch probe (p9-01 1.5b), the only construction that distinguishes real `oneOf` from first-match-wins |
| 2 | 3 | p9-05 copied the surface but never **mounted** it | Gate 5.8 would have failed on a blank page. Added task 2.8 (and, at round 12, the same fix for p9-04's hand-built workspace) |
| 3 | 6 | No task named the actual **mimeType literal** | Grepping the installed packages found `text/html;profile=mcp-app`, and **no `text/uri-list` anywhere**. My two schema branches were both wrong for the path this phase uses |
| 4 | 6→7 | *(consequence of 3)* `externalUrl` has no wire format in the shipped packages | **Dropped from scope.** Analyze's Q3 presumed it was a mimeType variant; upstream models it as a distinct content shape. Supporting it would have meant inventing a format — the exact failure phases 7 and 8 spent themselves correcting |
| 5 | 8→10 | postMessage origin validation was **circular**, then **unverified** | Dropping `allow-same-origin` makes the frame opaque, so messages arrive with `origin: "null"` — the obvious check would reject every legitimate message. Split into observe (2.8a) / enforce (2.8b), added a source check, then added gate 6.5b when the first fix let the handshake pass against code that would be replaced |

## What this cost, and whether it was worth it

Eleven rounds past the two-round cap. The justification is in the finding
distribution: rounds 1–8 were still surfacing **CRITICALs at 3–5 per round**, and
they were not cosmetic — an unbuildable fixture, a gate that would fail on a
blank page, a schema whose literals no shipped package emits.

Rounds 9–12 shifted character: most findings were defects **my own fixes had
introduced** (a circular ordering, a stale violation name, a gate verifying
replaced code). That is the honest cost of iterating this way — each repair
touches siblings, and siblings are where this review looks.

Round 13 returned PASS with a single WARNING, which is the convergence signal
the extra rounds were for.

## Recurring pattern, now three phases running

**Coverage claimed over the wrong path.** Round 2 caught it twice — p9-01 and
p9-05 both asserted the `no-hardcoded-secrets` gate covered files under
`SKILL.md` and `skills/`, which it does not scan. I wrote those claims *in tasks
that cite phase-8's identical failure*. Knowing the lesson did not prevent
repeating it; only the check did.

Every constraint claim now names the uncovered files explicitly and carries a
runnable grep.

## Tooling gaps for the reflection

1. `build-review-packet.sh` handles only the native-kbd spec layout — OpenSpec
   change sets must be assembled by hand. Flagged in phase-8; still open.
2. The packet includes neither `decision-log.md` nor a phase `evidence/`
   directory, so operator decisions and vendored upstream artifacts are
   invisible to the judge (raised as a CRITICAL during analyze).
