# Tasks: p7-03-agui-server-surface

**scope**:
- `assets/scaffold/agui/vite-plugin-agui-mock.ts` (new)
- `assets/scaffold/agui/mock-agent.ts` (new)
- `package.json` (devDependency: `@ag-ui/encoder` pinned exact)

Note: these are template sources the scaffolder copies in p7-05. This change
builds and tests them standalone; p7-05 wires them into the emitted app.

**Path contract (consumed downstream).** The exact paths under
`assets/scaffold/agui/` are a contract p7-05 tasks 1.4/1.5 read by name.
Renaming or relocating a file here silently breaks p7-05, and no gate in that
change would catch it. If a path must change, update p7-05's tasks in the same
commit.

**Shared-file note.** `package.json` is also in p7-04's scope (it adds
`@ag-ui/client`). p7-04 depends on this change, so p7-03 lands first and p7-04
edits the file afterwards. Do not run the two in parallel worktrees — the
dependency edge is what makes the shared file safe.

## Dependency

- [x] 1.1 Add `@ag-ui/encoder` at **exact** `0.0.59` — no caret. Pre-1.0 packages
      may ship breaking changes in a patch bump (analyze D-001).
- [x] 1.2 Record the pinned version and the reason in the change's design notes.

## Mock agent

- [x] 2.1 `mock-agent.ts` exports an async generator yielding `BaseEvent` objects
      for a canned response, chunked so `TEXT_MESSAGE_CONTENT` arrives as
      multiple deltas — a single-delta stream would not exercise incremental
      rendering, which is the phase's real acceptance criterion.
- [x] 2.2 Emit in `ValidateSequence` order: `RUN_STARTED` → `TEXT_MESSAGE_START`
      → `TEXT_MESSAGE_CONTENT`×N → `TEXT_MESSAGE_END` → `RUN_FINISHED`.
- [x] 2.3 Insert a small delay between content deltas so streaming is observable
      rather than arriving as one flush.

## Vite middleware plugin

- [x] 3.1 `vite-plugin-agui-mock.ts` exports a Vite plugin registering a
      `configureServer` middleware on the agent route.
- [x] 3.2 Reject non-`application/json` content types with **415**.
- [x] 3.3 Parse and validate the body as `RunAgentInput`; respond **400** with
      the validation issues when it does not conform.
- [x] 3.4 Set `Content-Type: text/event-stream`, `Cache-Control: no-cache`,
      `Connection: keep-alive`, then flush headers before the first frame.
- [x] 3.5 Encode every frame with `EventEncoder.encodeSSE` — do not hand-format
      `data: …\n\n`; the encoder is the adopted contract.
- [x] 3.6 Handle client disconnect: stop emitting when the response is destroyed
      or ended, so an aborted run does not keep the generator alive.

## Verification

- [x] 4.1 `curl -N -X POST <route> -H 'Content-Type: application/json'
      -H 'Accept: text/event-stream' -d '{...}'` returns
      `Content-Type: text/event-stream`.
- [x] 4.2 The response body contains `RUN_STARTED` first and `RUN_FINISHED` last.
- [x] 4.3 At least two distinct `TEXT_MESSAGE_CONTENT` frames appear — proves
      chunking, not a single flush.
- [x] 4.4 Every frame parses as JSON after stripping the `data: ` prefix.
- [x] 4.5 A request with `Content-Type: text/plain` returns 415.
- [x] 4.6 A request with a malformed `RunAgentInput` returns 400, not a stream.
- [x] 4.7 Event order satisfies the upstream `ValidateSequence` rules:
      no content before its `TEXT_MESSAGE_START`, no `RUN_FINISHED` without
      `RUN_STARTED`, no duplicate starts.

## Gate

- [x] 5.1 All of 4.1–4.7 pass. **Harness note:** this repo is a skill pack with
      no Vite install, so 4.1–4.7 ran against the *same exported middleware*
      mounted on a bare Node http server, not a `pnpm dev` process. The code
      under test is the shipped plugin verbatim; what is unproven here is the
      Vite `configureServer` wiring itself, which p7-05 gate 3.4/3.5 exercises
      on a real scaffolded app.
- [x] 5.2 No second process is required to satisfy them.
