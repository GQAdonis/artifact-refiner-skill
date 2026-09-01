# Tasks: p7-04-agui-client-store

**scope**:
- `assets/scaffold/agui/agent-store.ts` (new)
- `assets/scaffold/agui/use-agent.ts` (new)
- `assets/scaffold/agui/agent-panel.tsx` (new)
- `package.json` (dependency: `@ag-ui/client` pinned exact)

Template sources; p7-05 wires them into the emitted app.

**Path contract (consumed downstream).** The exact paths under
`assets/scaffold/agui/` are a contract p7-05 task 1.4 reads by name. Renaming or
relocating a file here silently breaks p7-05, and no gate in that change would
catch it. If a path must change, update p7-05's tasks in the same commit.

**Shared-file note:** `package.json` is also in p7-03's scope (it adds
`@ag-ui/encoder`). p7-04 depends on p7-03, so p7-03 lands first and p7-04 adds
`@ag-ui/client` to the file p7-03 already touched. Do not run these two changes
in parallel worktrees — the dependency edge is what makes the shared file safe.

## Dependency

- [x] 1.1 Add `@ag-ui/client` at **exact** `0.0.59` — no caret (analyze D-001).
      Verify p7-03's `@ag-ui/encoder` pin is still present and unmodified after
      this edit; both must end at the same exact version.
- [x] 1.2 Record in design notes that this transitively pulls rxjs 7.8.2, zod,
      uuid, fast-json-patch, untruncate-json, compare-versions, `@ag-ui/core`,
      `@ag-ui/proto`, `@ag-ui/encoder`, so a reader knows the real cost.

## Store (owns all I/O)

- [x] 2.1 `agent-store.ts` — a zustand+immer store holding
      `{ status, runId, messages: Record<messageId, {content, complete}>, error }`.
- [x] 2.2 Expose `initRealtime()` per `state-architecture.md:185`. Subscribing
      anywhere else violates line 210.
- [x] 2.3 `runAgent(input)` constructs `HttpAgent`, subscribes to the returned
      `Observable<BaseEvent>`, and reduces per the proposal's table.
- [x] 2.4 `TEXT_MESSAGE_CONTENT` **appends** `delta` to the message keyed by
      `messageId` — never replaces. Replacing would render only the final
      fragment and still look plausible, so assert this in a test rather than
      trusting inspection.
- [x] 2.5 Drop events whose `messageId` has no open message, logging a warning.
      Silently creating one would mask an ordering violation.
- [x] 2.6 `abort()` calls the client's `AbortController` and returns status to
      `idle` without leaving a half-open message.
- [x] 2.7 The store must not import `react` — enforced by the architectural
      ESLint config.

## Hook + component

- [x] 3.1 `use-agent.ts` selects store state and exposes `runAgent`/`abort`.
      No `fetch`, no `EventSource`, no subscription logic (layering rule).
- [x] 3.2 `agent-panel.tsx` renders messages and a send control, talking only to
      the hook.

## Verification

- [x] 4.1 Unit: feeding a scripted event sequence through the reducer yields the
      concatenated message content — proves append-not-replace.
- [x] 4.2 Unit: two interleaved `messageId`s accumulate independently.
- [x] 4.3 Unit: a `TEXT_MESSAGE_CONTENT` with an unknown `messageId` is dropped
      and warns.
- [x] 4.4 Unit: `RUN_ERROR` sets `status: 'error'` and surfaces the message.
- [x] 4.5 Integration against p7-03: content renders **incrementally** — assert
      the rendered text grows across at least two frames, not that it merely
      ends correct. A non-streaming stub passes the weaker assertion.
- [x] 4.6 **Harness note:** this repo has no `lint` script and no ESLint config —
      it is a skill pack, and the architectural ESLint config ships to
      *scaffolded apps*. Verified here by the checks the rules encode:
      the store imports no `react` (grep, exit 1); the hook and component
      contain no `fetch(`/`EventSource` in code with comments stripped;
      `new HttpAgent` appears only in the store. All four files compile
      clean under esbuild. The ESLint run itself happens in p7-05 gate 3.3
      on a real scaffolded app.

## Gate

- [x] 5.1 4.1–4.6 pass.
- [x] 5.2 `grep -n "EventSource\|fetch(" ` over the hook and component returns
      nothing — I/O stayed in the store.
