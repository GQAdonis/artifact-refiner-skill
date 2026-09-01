/**
 * AG-UI agent panel.
 *
 * Presentational. Talks to the `useAgent` hook and nothing else — no store
 * import, no network calls. Streaming text appears here because the store
 * appends each delta and this component re-renders on every update.
 */

import { useState, type FormEvent, type ReactElement } from 'react';
import { useAgent } from './use-agent';

export function AgentPanel(): ReactElement {
  const { messages, status, error, isRunning, runAgent, abort } = useAgent();
  const [draft, setDraft] = useState('');

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    const prompt = draft.trim();
    if (!prompt || isRunning) return;
    setDraft('');
    void runAgent(prompt);
  };

  return (
    <section className="agent-panel" aria-label="Agent conversation">
      <ol className="agent-panel__messages">
        {messages.map((m) => (
          <li
            key={m.id}
            className="agent-panel__message"
            data-role={m.role}
            data-complete={m.complete}
          >
            {/* `aria-live` so assistive tech announces streamed text as it
                arrives rather than only on completion. */}
            <p aria-live={m.complete ? 'off' : 'polite'}>{m.content}</p>
          </li>
        ))}
      </ol>

      {status === 'error' && error ? (
        <p className="agent-panel__error" role="alert">
          {error}
        </p>
      ) : null}

      <form className="agent-panel__composer" onSubmit={onSubmit}>
        <label className="agent-panel__label" htmlFor="agent-prompt">
          Message
        </label>
        <input
          id="agent-prompt"
          name="prompt"
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          placeholder="Ask the agent…"
          disabled={isRunning}
          autoComplete="off"
        />
        <button type="submit" disabled={isRunning || draft.trim().length === 0}>
          Send
        </button>
        {isRunning ? (
          <button type="button" onClick={abort}>
            Stop
          </button>
        ) : null}
      </form>
    </section>
  );
}

export default AgentPanel;
