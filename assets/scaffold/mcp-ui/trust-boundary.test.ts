/**
 * Trust-boundary tests for the MCP-UI host.
 *
 * These ship with the scaffolded app rather than living only in the change that
 * wrote them, so a generated project inherits the checks instead of trusting
 * that they once passed somewhere else.
 *
 * They call the exported predicates directly. Driving a browser to assert that
 * a `javascript:` URL is refused would be slower and would prove less: the unit
 * under test is the predicate, and the browser gate covers the wiring.
 */

import { describe, it, expect } from 'vitest';
import { isSafeLink, isTrustedGuestMessage, isMcpUiResource } from './use-mcp-ui';

describe('isSafeLink — link-scheme validation', () => {
  it('allows http and https', () => {
    expect(isSafeLink('https://example.com/x')).toBe(true);
    expect(isSafeLink('http://example.com/x')).toBe(true);
  });

  it('refuses javascript:, data:, and file:', () => {
    // Guest content is server-supplied; an unchecked scheme here is script
    // execution in the host's context.
    expect(isSafeLink('javascript:alert(1)')).toBe(false);
    expect(isSafeLink('data:text/html,<script>alert(1)</script>')).toBe(false);
    expect(isSafeLink('file:///etc/passwd')).toBe(false);
  });

  it('refuses input that is not a URL at all', () => {
    expect(isSafeLink('not a url')).toBe(false);
    expect(isSafeLink('')).toBe(false);
  });
});

describe('isTrustedGuestMessage — sender validation', () => {
  const frame = { name: 'guest-frame' } as unknown as Window;
  const expected = { origin: 'null', source: frame };

  it('accepts a message from the mounted frame', () => {
    expect(isTrustedGuestMessage({ origin: 'null', source: frame }, expected)).toBe(true);
  });

  it('refuses a foreign origin', () => {
    expect(
      isTrustedGuestMessage({ origin: 'https://evil.example', source: frame }, expected),
    ).toBe(false);
  });

  it('refuses the right origin from the wrong source', () => {
    // THE CASE THAT MATTERS. The sandbox drops `allow-same-origin`, so the
    // guest is opaque and posts with origin "null" — a value ANY opaque frame
    // can present. Origin alone would accept a forged sender; the source check
    // is what actually identifies our frame.
    const impostor = { name: 'impostor' } as unknown as Window;
    expect(isTrustedGuestMessage({ origin: 'null', source: impostor }, expected)).toBe(false);
  });

  it('refuses when no frame is mounted', () => {
    expect(
      isTrustedGuestMessage({ origin: 'null', source: frame }, { origin: 'null', source: null }),
    ).toBe(false);
  });
});

describe('isMcpUiResource — ui:// discrimination', () => {
  const html = { uri: 'ui://demo/widget', mimeType: 'text/html;profile=mcp-app', text: '<p>x</p>' };

  it('accepts an embedded resource with a ui:// uri', () => {
    expect(isMcpUiResource({ type: 'resource', resource: html })).toBe(true);
  });

  it('refuses a resource whose uri is not ui://', () => {
    // isUIResource alone would accept this: it narrows `type === "resource"`
    // and says nothing about the scheme.
    expect(
      isMcpUiResource({ type: 'resource', resource: { ...html, uri: 'https://example.com/w' } }),
    ).toBe(false);
  });

  it('refuses non-resource content blocks', () => {
    expect(isMcpUiResource({ type: 'text', text: 'hello' })).toBe(false);
    expect(isMcpUiResource(null)).toBe(false);
    expect(isMcpUiResource(undefined)).toBe(false);
  });
});
