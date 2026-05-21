---
title: Sample Markdown Document
document-type: article
---

# Sample Markdown Document

A small sample exercising **GFM** features for the `convert-md-to-htmx` smoke test.

## Introduction

This document tests:

1. Ordered and unordered lists
2. **Bold** and *italic* emphasis
3. Inline `code` spans
4. [Links to external resources](https://example.com)

### Task lists

- [x] First task complete
- [ ] Second task pending
- [ ] Third task pending

## Table

| Feature | Status | Notes |
|---|---|---|
| Headings | ✓ | h1-h3 |
| Tables | ✓ | GFM-style |
| Code blocks | ✓ | with language class |

## Code example

```ts
export function greet(name: string): string {
  return `Hello, ${name}!`;
}
```

## Conclusion

The renderer should produce semantic HTML with `<article>`, `<header>`, `<main>` wrapping and brand tokens applied via `:root` CSS variables.
