# Tasks: p9-02 — `normalize-mcp-ui.mjs`

**Scope** (files this change may edit):

```
scripts/normalize-mcp-ui.mjs
```

**That is the complete list.** Two boundaries this change must not cross:

- `references/schemas/mcp-ui-resource.schema.json` is a **read-only input**. Any
  test needing a modified schema (2.3, 4.5) operates on a **copy in the
  scratchpad**, passed via the normalizer's schema path argument or an env
  override. The repo file is never mutated, not even transiently — a
  "corrupt then restore" step leaves the tree broken if the run aborts between
  the two.
- `examples/mcp-ui-refinement/` is **owned by p9-03**. This change creates no
  fixtures there. Its own test inputs live in the scratchpad; the durable corpus
  is p9-03's, and §4 below is written to run against scratchpad fixtures so this
  change is verifiable before p9-03 exists.

---

## 1. Structure

- [x] 1.1 Create `scripts/normalize-mcp-ui.mjs` following the CLI contract of
      `scripts/normalize-a2ui.mjs`: read a JSON file, exit 0 on valid, exit 1
      with named violations on invalid.
- [x] 1.2 Load `references/schemas/mcp-ui-resource.schema.json` at runtime,
      **with the path overridable** (`--schema <path>` or
      `MCP_UI_SCHEMA` env var), defaulting to the repo copy. This is what lets
      2.3 and 4.5 exercise modified schemas from the scratchpad without ever
      mutating the repo file.
- [x] 1.3 **Derive** the accepted mimeTypes and the `ui://` pattern from the
      loaded schema. Do not restate them as literals — that is the exact defect
      phase-7 corrected in `normalize-agui.mjs`.

## 2. Validator

- [x] 2.1 **Decide and record**: reuse the validator from `normalize-a2ui.mjs`
      (which has real `oneOf`/`anyOf`/`not` after phase-8) or implement one
      here. If reusing, import it rather than copying. If implementing, §2.2
      applies and is not optional.
- [x] 2.2 If a new validator: it MUST implement `oneOf` as genuine exclusivity
      (exactly one branch matches), plus `anyOf` and `not`. Phase-8's validator
      stopped at the first match, silently converting `oneOf` into `anyOf` and
      rendering every guard inert.
- [x] 2.3 Prove it with the **duplicate-branch probe**, not a two-mode fixture.
      A single `mimeType` field cannot hold two values, so "both modes present"
      is not constructible — and a fixture matching zero branches is rejected by
      correct and broken implementations alike, proving nothing.
      Instead: temporarily add a duplicate of branch A to a **local copy** of the
      schema, validate a conformant `rawHtml` fixture against that copy, and
      confirm it is **rejected** (two branches match). A first-match-wins
      implementation accepts it. **This is the only discriminating test.**

## 3. Violations, each named

- [x] 3.1 `uri_scheme` — `uri` does not start with `ui://`.
- [x] 3.2 `unsupported_mime` — a mimeType outside the two admitted spellings
      (`text/html;profile=mcp-app`, `text/html`). **Not** `remoteDom`: p9-01 task
      1.3b establishes there is no `remoteDom` mimeType, and that shape is
      `unsupported_content_shape` (3.5).
- [x] 3.3 **Precedence rule.** Several violations can be true of one document.
      Check in this order and report the **first** match, so a fixture's expected
      violation is deterministic:
      `uri_scheme` → `unsupported_mime` → `missing_content` →
      `unsupported_content_shape` → `schema_violation`.
      `schema_violation` is deliberately **last**: it is the catch-all, and
      without this ordering a fixture written to test `missing_content` could
      legitimately report the generic error instead, failing gate 4.3 for a
      non-diagnostic reason.
- [x] 3.4 `missing_content` — `text` absent. (`blob` is not admitted by the
      schema; see p9-01 task 1.1.)
- [x] 3.4b `schema_violation` — the residual: the document fails the schema for
      a reason none of 3.1–3.5 names. Report the raw validator error.
      **Renamed from `mode_exclusivity`**, which promised something no fixture
      can trigger: with one `mimeType` field and the earlier checks catching
      every constructible case, a "matched the wrong number of branches" state is
      not independently reachable. A violation name no input can produce is dead
      code that reads as coverage. Genuine `oneOf` exclusivity is proven by
      p9-01 task 1.5b's transient duplicate-branch probe, not by a fixture.
- [x] 3.5 `unsupported_content_shape` — the resource carries `script`,
      `framework`, or `iframeUrl`, i.e. a `remoteDom` or `externalUrl` payload
      that p9-01 task 1.3b/1.3c places out of scope. Report which key was found.
      (D-006's link-scheme validation lives in the host at runtime — p9-04 task
      2.7 — since with `externalUrl` out of scope there is no URL in the
      normalizer's input to validate.)
- [x] 3.6 Each violation reports the offending value, not just a type name.

## 4. Verification

- [x] 4.1 A conformant `rawHtml` resource exits 0.
- [x] 4.2 A conformant resource using the bare `text/html` spelling exits 0,
      proving both admitted mimeType branches work.
- [x] 4.3 Each violation in §3 exits 1 **and names the violation**, run against
      scratchpad fixtures so this change is verifiable before p9-03 lands. The
      four *named* violations (3.1, 3.2, 3.4, 3.5) each get their own fixture and
      assertion. `schema_violation` (3.4b) is the residual and is exercised only
      if a case arises that the four do not name — **do not manufacture a fixture
      for it**; a catch-all with a bespoke fixture is no longer a catch-all.
      Each asserted separately — a single "it fails" assertion cannot tell a
      correct rejection from an incidental crash.
- [x] 4.4 `node --check scripts/normalize-mcp-ui.mjs` passes.
- [x] 4.5 Copy the schema to the scratchpad, alter its `ui://` pattern there,
      run the normalizer against that copy via the 1.2 override, and confirm the
      `uri_scheme` behaviour **changes**. This proves 1.3's derivation is live
      rather than shadowed by a literal. **The repo schema is never modified** —
      p9-01 owns it, and a corrupt-then-restore sequence would leave the tree
      broken if the run aborted mid-way.
- [x] 4.6 Constraint `no-hardcoded-secrets` — the gate scans
      `scripts/ prompts/ references/`; this change edits `scripts/`, which is
      covered.
