#!/usr/bin/env node
/**
 * Bundle the A2UI guest into ONE self-contained HTML page.
 *
 * The guest runs in an opaque-origin iframe under `connect-src: none`. It cannot
 * fetch a script or a stylesheet, so everything must be inline. This produces a
 * template with a single placeholder the server substitutes per resource:
 *
 *     __A2UI_MESSAGES__   →  JSON array of A2UI messages
 *
 * Usage: node build-guest.mjs --out <path/to/a2ui-guest.html>
 */
import { build } from 'esbuild';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const outIdx = process.argv.indexOf('--out');
const out = outIdx > 0 ? process.argv[outIdx + 1] : resolve(here, 'a2ui-guest.html');

const result = await build({
  entryPoints: [resolve(here, 'a2ui-guest.tsx')],
  bundle: true,
  minify: true,
  format: 'iife',
  platform: 'browser',
  target: ['es2020'],
  jsx: 'automatic',
  write: false,
  define: { 'process.env.NODE_ENV': '"production"' },
  logLevel: 'warning',
});

// esbuild names in-memory outputs `<stdout>`, not `*.js` — match on content
// kind rather than extension, and fail loudly if the bundle is empty. A silent
// 0-byte bundle produces a page that loads and renders nothing.
const js = result.outputFiles.find((f) => !f.path.endsWith('.css'))?.text ?? '';
const css = result.outputFiles.find((f) => f.path.endsWith('.css'))?.text ?? '';
if (js.length < 1024) {
  throw new Error(
    `Guest bundle is ${js.length} bytes — that is not a working renderer. ` +
    `Check the esbuild entry point and outputFiles naming.`,
  );
}

// `__A2UI_MESSAGES__` sits inside a JSON script tag, not in JS source, so a
// payload containing `</script>` cannot break out of the bundle.
const html = `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<title>A2UI surface</title>
${css ? `<style>${css}</style>` : ''}
</head>
<body>
<div id="a2ui-root"></div>
<script type="application/json" id="a2ui-messages">__A2UI_MESSAGES__</script>
<script>${js}</script>
</body>
</html>
`;

mkdirSync(dirname(out), { recursive: true });
writeFileSync(out, html);
process.stdout.write(`${out}  ${(html.length / 1024).toFixed(0)} KB\n`);
