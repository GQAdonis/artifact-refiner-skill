#!/usr/bin/env bash
#
# scaffold-react-vite-a2ui.sh
#
# Layer an A2UI rendering host onto a scaffolded Vite/React project: the surface
# store, its hook and component, and a mock message source. The generated app
# renders an agent-described UI under `pnpm dev` with no second process.
#
# Thin wrapper in the shape of scaffold-react-vite-tauri.sh and
# scaffold-react-vite-agui.sh — layers one concern onto an existing target
# rather than forking the 1160-line base scaffolder.
#
# Usage:
#   bash scripts/scaffold-react-vite-a2ui.sh \
#     --target <path-to-react-project> \
#     [--feature <feature-name>]
#
# Pre-flight: requires pnpm and an existing scaffold-react-vite.sh target.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# The base scaffolder names feature slices with to_kebab(), which inserts
# separators around digit runs: "a2ui-smoke" -> "a-2-ui-smoke". Deriving the
# feature name from the raw directory basename creates a SECOND feature
# directory the app never imports.
# shellcheck source=/dev/null
. "${SCRIPT_DIR}/lib/kebab-case.sh"

log()  { printf '\033[0;36m[a2ui]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[a2ui]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[a2ui]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[0;31m[a2ui]\033[0m %s\n' "$*" >&2; }

# -----------------------------------------------------------------------------
# Args
# -----------------------------------------------------------------------------
TARGET=""
FEATURE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)  TARGET="$2"; shift 2 ;;
    --feature) FEATURE="$2"; FEATURE_EXPLICIT=1; shift 2 ;;
    -h|--help) sed -n '2,19p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) err "unknown argument: $1"; exit 1 ;;
  esac
done

[[ -n "${TARGET}" ]] || { err "--target is required (path to an existing scaffold-react-vite project)"; exit 1; }
[[ -d "${TARGET}" ]] || { err "target does not exist: ${TARGET}"; exit 1; }

TARGET="$(cd "${TARGET}" && pwd)"
FEATURE="${FEATURE:-$(to_kebab "$(basename "${TARGET}")")}"

# Prefer an existing slice when one is already present: a target scaffolded
# under a different naming rule should still be layered onto, not duplicated.
if [[ -z "${FEATURE_EXPLICIT:-}" && ! -d "${TARGET}/src/features/${FEATURE}" ]]; then
  EXISTING="$(find "${TARGET}/src/features" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)"
  if [[ -n "${EXISTING}" ]]; then
    FEATURE="$(basename "${EXISTING}")"
  fi
fi

# -----------------------------------------------------------------------------
# Pre-flight
# -----------------------------------------------------------------------------
log "Pre-flight checks…"

command -v pnpm >/dev/null 2>&1 || { err "pnpm not found on PATH"; exit 1; }

[[ -f "${TARGET}/package.json" ]] || {
  err "no package.json in ${TARGET} — is this a scaffold-react-vite target?"
  exit 1
}

ASSETS="${REPO_ROOT}/assets/scaffold/a2ui"
for f in surface-store.ts use-surface.ts a2ui-surface.tsx mock-surface-source.ts; do
  [[ -f "${ASSETS}/${f}" ]] || { err "missing template source: ${ASSETS}/${f}"; exit 1; }
done

ok "Pre-flight passed."
log "Target:  ${TARGET}"
log "Feature: ${FEATURE}"

# -----------------------------------------------------------------------------
# Dependencies — exact pins. @a2ui/* is pre-1.0; a caret range would allow a
# breaking change in a patch bump.
#
# BOTH packages are required. a2ui-surface.tsx imports MessageProcessor from
# @a2ui/web_core/v0_9, and @a2ui/react does NOT re-export it — under pnpm's
# strict isolation, installing only @a2ui/react leaves that import unresolvable.
# -----------------------------------------------------------------------------
log "Installing @a2ui/react + @a2ui/web_core (exact pins)…"
( cd "${TARGET}" && CI=true pnpm add @a2ui/react@0.10.2 @a2ui/web_core@0.10.6 ) \
  >/dev/null 2>&1 || { err "dependency install failed"; exit 1; }

if ! node -e "
  const d=require('${TARGET}/package.json').dependencies||{};
  process.exit(d.zustand && d.immer ? 0 : 1);
" 2>/dev/null; then
  log "Installing zustand + immer (not present in target)…"
  ( cd "${TARGET}" && CI=true pnpm add zustand immer ) >/dev/null 2>&1 || {
    err "zustand/immer install failed"; exit 1; }
fi
ok "Dependencies installed."

# -----------------------------------------------------------------------------
# Emit into the layer directories the base scaffolder establishes.
# Layering per references/scaffolds/state-architecture.md:
#   stores/ owns I/O · hooks/ read stores · components/ read hooks
# -----------------------------------------------------------------------------
FEATURE_DIR="${TARGET}/src/features/${FEATURE}"
mkdir -p "${FEATURE_DIR}/stores" "${FEATURE_DIR}/hooks" "${FEATURE_DIR}/components"
mkdir -p "${TARGET}/src/dev"

log "Emitting surface store, hook, and component…"
cp "${ASSETS}/surface-store.ts"  "${FEATURE_DIR}/stores/surface-store.ts"
cp "${ASSETS}/use-surface.ts"    "${FEATURE_DIR}/hooks/use-surface.ts"
cp "${ASSETS}/a2ui-surface.tsx"  "${FEATURE_DIR}/components/a2ui-surface.tsx"
cp "${ASSETS}/mock-surface-source.ts" "${TARGET}/src/dev/mock-surface-source.ts"

# The templates import siblings by the layout they will live in; the mock source
# sits under src/dev/, so the component's import of it needs rewriting.
python3 - "${FEATURE_DIR}" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
mock = root / "stores" / "surface-store.ts"
# mock-surface-source imports the store type from a sibling path in assets/;
# after emit it lives in src/dev/, two levels away from the feature slice.
src = root.parent.parent / "dev" / "mock-surface-source.ts"
if src.exists():
    feature = root.name
    src.write_text(src.read_text().replace(
        "from './surface-store'",
        f"from '../features/{feature}/stores/surface-store'"))
PY
ok "Sources emitted."

# -----------------------------------------------------------------------------
# README — the generated app looks production-shaped; say plainly that it is not.
# -----------------------------------------------------------------------------
log "Writing A2UI README section…"
README="${TARGET}/README.md"
[[ -f "${README}" ]] || printf '# %s\n' "$(basename "${TARGET}")" > "${README}"

if grep -q "## A2UI rendering host" "${README}" 2>/dev/null; then
  warn "README already documents the A2UI host — leaving as-is."
else
  cat >> "${README}" <<EOF

## A2UI rendering host

This app renders agent-described UI over the
[A2UI protocol](https://github.com/a2ui-project/a2ui).

- \`src/features/${FEATURE}/stores/surface-store.ts\` — reduces the message
  stream into surface state. All A2UI I/O lives here.
- \`src/features/${FEATURE}/hooks/use-surface.ts\` — reads the store.
- \`src/features/${FEATURE}/components/a2ui-surface.tsx\` — renders via
  \`@a2ui/react\`.

### Development only

\`src/dev/mock-surface-source.ts\` replays a canned message sequence so the host
runs without an agent. **Replace it with a real message source** — a WebSocket,
SSE stream, or fetch — before deploying. A production agent sends:

\`\`\`
{ "version": "v1.0", "createSurface":    { "surfaceId": "…", "catalogId": "…", "components": [] } }
{ "version": "v1.0", "updateDataModel":  { "surfaceId": "…", "dataModel": { … } } }
{ "version": "v1.0", "updateComponents": { "surfaceId": "…", "components": [ … ] } }
\`\`\`

Pass any \`AsyncIterable\` of those messages to \`useSurface({ source })\`.

### Protocol version

The message shape above is A2UI **v1.0**, which
\`references/schemas/a2ui-component.schema.json\` validates. The pinned renderer
\`@a2ui/react@0.10.2\` implements **v0.9** and supports \`createSurface\`,
\`updateComponents\`, and \`updateDataModel\`. The component translates between
them at one boundary.

\`deleteSurface\`, \`callFunction\`, and \`actionResponse\` are reduced into store
state but **not rendered** — the pinned renderer does not implement them. The
surface reports any it receives rather than ignoring them silently.
EOF
  ok "README section written."
fi

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
ok "A2UI host layered onto ${TARGET}"
log "Next: cd ${TARGET} && pnpm dev — then render <A2uiSurface /> from your app."
