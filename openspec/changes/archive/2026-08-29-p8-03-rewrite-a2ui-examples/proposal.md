# Proposal: p8-03 — Rewrite the A2UI examples and content-type references

**Change ID**: p8-03-rewrite-a2ui-examples
**Phase**: phase-8-scaffold-a2ui-host
**Status**: specified
**Origin**: G-8 ALIGN — the breaking half
**Depends on**: p8-01, p8-02

## Summary

Rewrite both shipped examples against the real protocol and update every
in-repo reference to `direct:a2ui`.

## Why this is its own change

p8-01 and p8-02 change the contract and the validator. This change is where the
**breaking part lands**: the published examples become invalid and are replaced.
Keeping it separate makes the blast radius reviewable on its own.

## Blast radius — verified, not assumed

`grep -rln "direct:a2ui" prompts/ references/ skills/ agents/` returns six files:

| File | Why it references a2ui |
|---|---|
| `prompts/meta-controller.md` | routing table |
| `prompts/specify.md` | detection heuristics |
| `prompts/execute.md` | normalization step |
| `references/content-types.md` | taxonomy |
| `references/schemas/content-type.schema.json` | enum member |
| `references/domain/a2ui.md` | the adapter (rewritten in p8-01) |

Plus `examples/a2ui-component-refinement/` — two specs and a manifest.

## The examples must actually exercise the protocol

The current pair has a documented weakness this change fixes: assess F-2 found
the tool-call path untested in the AG-UI corpus, and the same class of hole
exists here. The new positive example must use `dataModel` + `{"path": …}` refs,
nested `children` id links, and an `action`/`event` — not just a static tree —
so a renderer that ignores data binding cannot pass.

## Scope

- `examples/a2ui-component-refinement/source.a2ui.json` (rewritten)
- `examples/a2ui-component-refinement/broken-circular.a2ui.json` (rewritten)
- `examples/a2ui-component-refinement/artifact_manifest.json`
- `examples/a2ui-component-refinement/README.md` if present
- `prompts/meta-controller.md`, `prompts/specify.md`, `prompts/execute.md`
- `references/content-types.md`
- `references/schemas/content-type.schema.json`

## Content-type identity

`direct:a2ui` keeps its name — it now means the real A2UI, which is what the
name always implied. No enum change; only the surrounding descriptions move.
