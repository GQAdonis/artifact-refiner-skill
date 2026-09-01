# Proposal: p7-02 — Fix AG-UI event-kind enum drift

**Change ID**: p7-02-fix-agui-event-enum
**Phase**: phase-7-scaffold-ag-ui-host
**Status**: specified
**Origin**: assess G-4 (WARNING) → analyze upgraded to BLOCKING
**Depends on**: p7-01

## Summary

Our AG-UI event-kind enum declares one event with the **wrong name** and is
missing **ten** others. Fix both before any host is generated against the
contract.

## The live defect

We declare `TOOL_CALL_ARGS_DELTA`. The shipped `@ag-ui/core@0.0.59` declares
`TOOL_CALL_ARGS`. Upstream's field is named `delta`; the *event kind* is not:

```typescript
export const ToolCallArgsEventSchema = BaseEventSchema.extend({
  type: z.literal(EventType.TOOL_CALL_ARGS),
  toolCallId: z.string(),
  delta: z.string(),
});
```

**A protocol-conformant AG-UI spec using `TOOL_CALL_ARGS` is rejected by our
validator today.** This is a correctness defect in already-shipped code
(PR #2), not a forward-looking gap.

It went unnoticed because the only specs ever validated are our own two examples
— and `grep TOOL_CALL_ARGS examples/` returns nothing, so neither example
exercises the tool-call path at all. The bug is invisible to our entire test
corpus.

## Evidence — reproducible offline

```bash
npm pack @ag-ui/core@0.0.59
tar -xzf ag-ui-core-0.0.59.tgz
grep -oE '"(RUN|STEP|TEXT_MESSAGE|TOOL_CALL|REASONING_MESSAGE|STATE|MESSAGES|RAW|CUSTOM)[A-Z_]*"' \
  package/dist/index.js | tr -d '"' | sort -u
```

Local enum: **14** kinds. Shipped `@ag-ui/core@0.0.59`: **23**.

Missing ten: `RAW`, `REASONING_MESSAGE_START`, `REASONING_MESSAGE_CONTENT`,
`REASONING_MESSAGE_END`, `REASONING_MESSAGE_CHUNK`, `STEP_STARTED`,
`STEP_FINISHED`, `TOOL_CALL_ARGS`, `TOOL_CALL_CHUNK`, `TOOL_CALL_RESULT`.

## Files Modified

| File | Line | Change |
|---|---|---|
| `references/schemas/ag-ui-spec.schema.json` | 76 | rename + add 10 |
| `scripts/normalize-agui.mjs` | 35 | rename + add 10 |
| `references/domain/ag-ui.md` | 79 | rename + document new kinds |
| `references/domain/ag-ui-spike.md` | 16 | rename |

## Compatibility

Renaming is **breaking** for any spec authored against our wrong name. Nothing
in-repo uses it (`grep TOOL_CALL_ARGS examples/` is empty), so blast radius
inside this repo is zero. External specs written against our published schema
would break — but they were already non-conformant with the real protocol, so
the rename moves them toward correctness rather than away from it.

## Verification

Adding an example that exercises the tool-call path is **in scope** — without
one, the same class of defect stays invisible to the corpus.
