#!/usr/bin/env bash
#
# scaffold-react-vite-mcp-ui.sh
#
# Layer an MCP-UI rendering host onto a scaffolded Vite/React project: the
# resource store, its hook and component, a sandbox proxy, a bundled A2UI guest,
# and a dev-only MCP mock. The generated app renders an A2UI surface delivered
# over MCP JSON-RPC, in a sandboxed iframe, with no second process.
#
# MCP-UI is an ENVELOPE for A2UI, not an alternative to it. An agent exposing
# MCP, HTTP, A2A, and AG-UI endpoints serves the SAME A2UI surface over each, so
# the UI is identical whichever transport a client arrives on.
#
# Usage:
#   bash scripts/scaffold-react-vite-mcp-ui.sh \
#     --target <path-to-react-project> \
#     [--feature <feature-name>]
#
# Pre-flight: requires pnpm, node, and an existing scaffold-react-vite.sh target.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# to_kebab inserts separators around digit runs: "mcp9ui" -> "mcp-9-ui". The base
# scaffolder names slices that way, so deriving from the raw basename creates a
# SECOND feature directory the app never imports.
# shellcheck source=/dev/null
. "${SCRIPT_DIR}/lib/kebab-case.sh"

log()  { printf '\033[0;36m[mcp-ui]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[mcp-ui]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[mcp-ui]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[0;31m[mcp-ui]\033[0m %s\n' "$*" >&2; }

TARGET=""
FEATURE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)  TARGET="$2"; shift 2 ;;
    --feature) FEATURE="$2"; FEATURE_EXPLICIT=1; shift 2 ;;
    -h|--help) sed -n '2,21p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) err "unknown argument: $1"; exit 1 ;;
  esac
done

[[ -n "${TARGET}" ]] || { err "--target is required (path to an existing scaffold-react-vite project)"; exit 1; }
[[ -d "${TARGET}" ]] || { err "target does not exist: ${TARGET}"; exit 1; }

TARGET="$(cd "${TARGET}" && pwd)"
FEATURE="${FEATURE:-$(to_kebab "$(basename "${TARGET}")")}"

if [[ -z "${FEATURE_EXPLICIT:-}" && ! -d "${TARGET}/src/features/${FEATURE}" ]]; then
  EXISTING="$(find "${TARGET}/src/features" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)"
  [[ -n "${EXISTING}" ]] && FEATURE="$(basename "${EXISTING}")"
fi

# -----------------------------------------------------------------------------
# Pre-flight
# -----------------------------------------------------------------------------
log "Pre-flight checks…"
command -v pnpm >/dev/null 2>&1 || { err "pnpm not found on PATH"; exit 1; }
command -v node >/dev/null 2>&1 || { err "node not found on PATH"; exit 1; }
[[ -f "${TARGET}/package.json" ]] || {
  err "no package.json in ${TARGET} — is this a scaffold-react-vite target?"; exit 1; }

ASSETS="${REPO_ROOT}/assets/scaffold/mcp-ui"
for f in resource-store.ts use-mcp-ui.ts mcp-ui-surface.tsx trust-boundary.test.ts \
         vite-plugin-mcp-mock.ts sandbox-proxy.html \
         guest/a2ui-guest.tsx guest/build-guest.mjs; do
  [[ -f "${ASSETS}/${f}" ]] || { err "missing template source: ${ASSETS}/${f}"; exit 1; }
done

FIXTURES="${REPO_ROOT}/examples/mcp-ui-refinement"
for f in rawhtml-resource.json broken-scheme.json; do
  [[ -f "${FIXTURES}/${f}" ]] || { err "missing fixture: ${FIXTURES}/${f}"; exit 1; }
done

ok "Pre-flight passed."
log "Target:  ${TARGET}"
log "Feature: ${FEATURE}"

# -----------------------------------------------------------------------------
# Dependencies — exact pins.
#
# @a2ui/web_core is pinned 0.10.6, NOT 0.10.2: @a2ui/react@0.10.2 requires
# ^0.10.5, so a lower pin makes pnpm install a SECOND copy and `tsc` fails on
# incompatible private types. The browser still works in that state because the
# bundler picks one copy — which is why the type-check gate matters.
#
# vitest and esbuild are dev deps the base scaffolder does not provide:
# vitest runs the trust-boundary tests, esbuild bundles the A2UI guest.
# -----------------------------------------------------------------------------
log "Installing @mcp-ui/client + ext-apps + @a2ui/* (exact pins)…"
( cd "${TARGET}" && CI=true pnpm add \
    @mcp-ui/client@7.1.1 @modelcontextprotocol/ext-apps@1.7.5 \
    @a2ui/react@0.10.2 @a2ui/web_core@0.10.6 --save-exact ) \
  >/dev/null 2>&1 || { err "dependency install failed"; exit 1; }

log "Installing dev dependencies (vitest, esbuild)…"
( cd "${TARGET}" && CI=true pnpm add -D vitest esbuild ) \
  >/dev/null 2>&1 || { err "dev dependency install failed"; exit 1; }

if ! node -e "
  const d=require('${TARGET}/package.json').dependencies||{};
  process.exit(d.zustand ? 0 : 1);
" 2>/dev/null; then
  log "Installing zustand (not present in target)…"
  ( cd "${TARGET}" && CI=true pnpm add zustand ) >/dev/null 2>&1 || {
    err "zustand install failed"; exit 1; }
fi
ok "Dependencies installed."

# -----------------------------------------------------------------------------
# Emit. Layering per references/scaffolds/state-architecture.md:
#   stores/ owns I/O · hooks/ read stores · components/ read hooks
# -----------------------------------------------------------------------------
FEATURE_DIR="${TARGET}/src/features/${FEATURE}"
mkdir -p "${FEATURE_DIR}/stores" "${FEATURE_DIR}/hooks" "${FEATURE_DIR}/components"
mkdir -p "${TARGET}/src/dev/fixtures" "${TARGET}/src/dev/guest" "${TARGET}/public"

log "Emitting store, hook, component, and tests…"
cp "${ASSETS}/resource-store.ts"      "${FEATURE_DIR}/stores/resource-store.ts"
cp "${ASSETS}/use-mcp-ui.ts"          "${FEATURE_DIR}/hooks/use-mcp-ui.ts"
cp "${ASSETS}/mcp-ui-surface.tsx"     "${FEATURE_DIR}/components/mcp-ui-surface.tsx"
cp "${ASSETS}/trust-boundary.test.ts" "${FEATURE_DIR}/hooks/trust-boundary.test.ts"
cp "${ASSETS}/vite-plugin-mcp-mock.ts" "${TARGET}/src/dev/vite-plugin-mcp-mock.ts"
cp "${ASSETS}/sandbox-proxy.html"      "${TARGET}/public/mcp-ui-sandbox-proxy.html"
cp "${ASSETS}/guest/a2ui-guest.tsx"    "${TARGET}/src/dev/guest/a2ui-guest.tsx"
cp "${ASSETS}/guest/build-guest.mjs"   "${TARGET}/src/dev/guest/build-guest.mjs"
cp "${FIXTURES}/rawhtml-resource.json" "${TARGET}/src/dev/fixtures/"
cp "${FIXTURES}/broken-scheme.json"    "${TARGET}/src/dev/fixtures/"
ok "Sources emitted."

# -----------------------------------------------------------------------------
# Build the A2UI guest. The sandbox is opaque-origin with `connect-src: none`,
# so the guest cannot fetch a script — the renderer must be INLINE.
# -----------------------------------------------------------------------------
log "Bundling the A2UI guest page…"
( cd "${TARGET}" && node src/dev/guest/build-guest.mjs \
    --out src/dev/guest/a2ui-guest.html ) || {
  err "guest bundle failed"; exit 1; }
ok "Guest bundled."

# -----------------------------------------------------------------------------
# Register the mock plugin and mount the surface. Both idempotent: a second run
# must not add a duplicate. Copying a component is not rendering it.
# -----------------------------------------------------------------------------
log "Registering the dev MCP mock and mounting the surface…"
python3 - "${TARGET}" "${FEATURE}" <<'PY'
import pathlib, re, sys
target, feature = pathlib.Path(sys.argv[1]), sys.argv[2]

# vite.config.ts — plugin registration
cfg = target / "vite.config.ts"
s = cfg.read_text()
if "mcpMockPlugin" not in s:
    s = ('import { mcpMockPlugin } from "./src/dev/vite-plugin-mcp-mock";\n' + s)
    # Match the opening bracket only; nested brackets inside existing plugin
    # calls must not terminate the match early.
    m = re.search(r"plugins\s*:\s*\[", s)
    if not m:
        raise SystemExit("could not find a plugins: [ array in vite.config.ts")
    ins = ('\n    mcpMockPlugin({\n'
           '      fixturesDir: path.resolve(__dirname, "./src/dev/fixtures"),\n'
           '      guestTemplatePath: path.resolve(__dirname, "./src/dev/guest/a2ui-guest.html"),\n'
           '    }),')
    s = s[:m.end()] + ins + s[m.end():]
    cfg.write_text(s)
    print("  vite.config.ts: mock registered")
else:
    print("  vite.config.ts: already registered (no-op)")

# eslint.config.js — Node globals for the guest builder. Without this the shared
# browser config applies and `process` fails no-undef.
es = target / "eslint.config.js"
if es.exists():
    s = es.read_text()
    if 'src/dev/**/*.mjs' not in s:
        block = ('  // Build scripts under src/dev/ run in Node, not the browser.\n'
                 '  {\n'
                 '    files: ["src/dev/**/*.mjs"],\n'
                 '    languageOptions: { globals: { process: "readonly", console: "readonly" } },\n'
                 '    rules: { "no-undef": "off" },\n'
                 '  },\n')
        m = re.search(r"^\s*\{\s*ignores:", s, re.M)
        if m:
            s = s[:m.start()] + block + s[m.start():]
            es.write_text(s)
            print("  eslint.config.js: node scope added for src/dev/**/*.mjs")

# feature index — export the surface
idx = target / "src" / "features" / feature / "index.ts"
if idx.exists():
    s = idx.read_text()
    if "McpUiSurface" not in s:
        s += 'export { McpUiSurface } from "./components/mcp-ui-surface";\n'
        idx.write_text(s)
        print("  feature index: McpUiSurface exported")

# main.tsx — MOUNT it. Copying files is not rendering them.
main = target / "src" / "main.tsx"
if main.exists():
    s = main.read_text()
    if "McpUiSurface" not in s:
        m = re.search(r'import \{([^}]*)\} from "@/features/' + re.escape(feature) + r'";', s)
        if m:
            names = m.group(1).strip().rstrip(',')
            s = s[:m.start()] + f'import {{ {names}, McpUiSurface }} from "@/features/{feature}";' + s[m.end():]
        else:
            s = f'import {{ McpUiSurface }} from "@/features/{feature}";\n' + s
        # Render it alongside whatever the app already renders.
        m2 = re.search(r"(\n\s*)<(\w+) />(\s*\n\s*</React\.StrictMode>)", s)
        if m2:
            ind = m2.group(1)
            s = (s[:m2.start()] + f"{ind}<>{ind}  <{m2.group(2)} />{ind}  <McpUiSurface />{ind}</>"
                 + m2.group(3) + s[m2.end():])
        main.write_text(s)
        print("  main.tsx: McpUiSurface mounted")
    else:
        print("  main.tsx: already mounted (no-op)")

# package.json — a `test` script, since the base scaffolder ships none.
import json
pkg = target / "package.json"
d = json.loads(pkg.read_text())
if "test" not in d.get("scripts", {}):
    d.setdefault("scripts", {})["test"] = "vitest run"
    pkg.write_text(json.dumps(d, indent=2) + "\n")
    print("  package.json: test script added")
PY
ok "Registered and mounted."

# -----------------------------------------------------------------------------
# README
# -----------------------------------------------------------------------------
log "Writing MCP-UI README…"
README="${TARGET}/MCP-UI.md"
cat > "${README}" <<EOF
# MCP-UI host

This app renders agent-described UI delivered over the
[Model Context Protocol](https://modelcontextprotocol.io) as an
[MCP-UI](https://github.com/MCP-UI-Org/mcp-ui) \`ui://\` resource.

## MCP-UI is an envelope for A2UI

The rendered surface is **A2UI** — the same protocol the AG-UI web host renders.
An agent exposing MCP, HTTP, A2A, and AG-UI endpoints serves the same A2UI
surface over each, so the UI is identical whichever transport a client uses.

A \`ui://\` resource therefore **must** carry an \`a2ui\` array. Validate one with:

\`\`\`
node scripts/normalize-mcp-ui.mjs --input <resource.json>
\`\`\`

## Layout

- \`src/features/${FEATURE}/stores/resource-store.ts\` — all MCP I/O.
- \`src/features/${FEATURE}/hooks/use-mcp-ui.ts\` — reads the store; also exports
  the trust-boundary predicates.
- \`src/features/${FEATURE}/components/mcp-ui-surface.tsx\` — renders via
  \`AppRenderer\` from \`@mcp-ui/client\`.
- \`public/mcp-ui-sandbox-proxy.html\` — the sandbox proxy.
- \`src/dev/guest/\` — the A2UI guest and its bundler.

## Development only

\`src/dev/vite-plugin-mcp-mock.ts\` answers \`POST /api/mcp\` with JSON-RPC.
**Replace it with a real MCP server before deploying.** A conformant server
implements \`initialize\`, \`tools/list\`, and \`tools/call\`, returning:

\`\`\`json
{ "content": [
    { "type": "text", "text": "…" },
    { "type": "resource",
      "resource": { "uri": "ui://…", "mimeType": "text/html;profile=mcp-app",
                    "text": "<the A2UI guest page>", "a2ui": [ … ] } } ] }
\`\`\`

\`resources/read\` is **not** required: the resource rides inside the tool result.

## Security — read before changing the sandbox

The guest runs in an iframe whose sandbox **deliberately omits
\`allow-same-origin\`**, making it an opaque origin with no access to this app's
storage or cookies. \`@mcp-ui/client\`'s default is
\`allow-scripts allow-same-origin allow-forms\`, which is only safe when the
sandbox proxy is served from a **separate origin**. This scaffold serves the
proxy same-origin to avoid a second process, so dropping \`allow-same-origin\` is
what keeps the boundary real.

**Moving the proxy to another origin, or restoring the default permissions, is a
security change — not a deployment detail.**

Because the guest is opaque, its messages arrive with \`origin: "null"\` — a value
any opaque frame can present. The host therefore pairs the origin check with
\`event.source === iframe.contentWindow\`. See \`trust-boundary.test.ts\`.

## Guest bundle

The guest is a single self-contained page: it renders under \`connect-src: none\`
and cannot fetch a script, so \`@a2ui/react\` is inlined. Rebuild after changing
\`src/dev/guest/a2ui-guest.tsx\`:

\`\`\`
node src/dev/guest/build-guest.mjs --out src/dev/guest/a2ui-guest.html
\`\`\`

## Protocol version

The schema validates A2UI **v1.0**; \`@a2ui/react@0.10.2\` implements **v0.9**.
The guest translates at one boundary (\`toV09Messages\`): it retargets
\`catalogId\` to the renderer's own catalog and splits v1.0's inline
\`components\`/\`dataModel\` into separate v0.9 messages. Without either, the
surface silently fails to populate.

\`remoteDom\` and \`externalUrl\` are out of scope — upstream models both as
distinct content shapes, and neither shipped package exposes a \`text/uri-list\`
mimeType.
EOF
ok "README written."

ok "MCP-UI host layered onto ${TARGET}"
log "Next: cd ${TARGET} && pnpm dev"
