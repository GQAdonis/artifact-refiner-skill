#!/usr/bin/env bash
#
# scaffold-react-vite-agui.sh
#
# Layer an AG-UI agent host onto a scaffolded Vite/React project: the client
# store, its hook and panel, and a dev-server SSE endpoint backed by a mock
# agent. The generated app streams agent responses under `pnpm dev` with no
# second process.
#
# This is a thin wrapper in the shape of scaffold-react-vite-tauri.sh — it
# layers one concern onto an existing target rather than forking the 1160-line
# base scaffolder.
#
# Usage:
#   bash scripts/scaffold-react-vite-agui.sh \
#     --target <path-to-react-project> \
#     [--feature <feature-name>] \
#     [--route /api/agent/run]
#
# Pre-flight: requires pnpm and an existing scaffold-react-vite.sh target.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# The base scaffolder names feature slices with to_kebab(), which inserts
# separators around digit runs: "agui-demo" -> "agui-demo", but
# "a2ui-smoke" -> "a-2-ui-smoke". Deriving the feature name from the raw
# directory basename creates a SECOND feature directory the app never imports.
# shellcheck source=/dev/null
. "${SCRIPT_DIR}/lib/kebab-case.sh"

log()  { printf '\033[0;36m[agui]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[agui]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[agui]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[0;31m[agui]\033[0m %s\n' "$*" >&2; }

# -----------------------------------------------------------------------------
# Args
# -----------------------------------------------------------------------------
TARGET=""
FEATURE=""
ROUTE="/api/agent/run"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)  TARGET="$2"; shift 2 ;;
    --feature) FEATURE="$2"; FEATURE_EXPLICIT=1; shift 2 ;;
    --route)   ROUTE="$2"; shift 2 ;;
    -h|--help) sed -n '2,20p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) err "unknown argument: $1"; exit 1 ;;
  esac
done

if [[ -z "${TARGET}" ]]; then
  err "--target is required (path to an existing scaffold-react-vite project)"
  exit 1
fi
if [[ ! -d "${TARGET}" ]]; then
  err "target does not exist: ${TARGET}"
  exit 1
fi

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

VITE_CONFIG=""
for candidate in vite.config.ts vite.config.js vite.config.mts; do
  [[ -f "${TARGET}/${candidate}" ]] && { VITE_CONFIG="${TARGET}/${candidate}"; break; }
done
[[ -n "${VITE_CONFIG}" ]] || { err "no vite config found in ${TARGET}"; exit 1; }

ASSETS="${REPO_ROOT}/assets/scaffold/agui"
for f in agent-store.ts use-agent.ts agent-panel.tsx mock-agent.ts vite-plugin-agui-mock.ts; do
  [[ -f "${ASSETS}/${f}" ]] || { err "missing template source: ${ASSETS}/${f}"; exit 1; }
done

ok "Pre-flight passed."
log "Target:  ${TARGET}"
log "Feature: ${FEATURE}"
log "Route:   ${ROUTE}"

# -----------------------------------------------------------------------------
# Dependencies — exact pins. @ag-ui/* is pre-1.0; a caret range would allow a
# breaking change in a patch bump.
# -----------------------------------------------------------------------------
log "Installing @ag-ui/client + @ag-ui/encoder (exact 0.0.59)…"
( cd "${TARGET}" && CI=true pnpm add @ag-ui/client@0.0.59 @ag-ui/encoder@0.0.59 ) \
  >/dev/null 2>&1 || { err "dependency install failed"; exit 1; }

# zustand/immer come from the base scaffolder; add them only if absent so a
# re-run against a hand-modified target still works.
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
# Emit source into the layer directories the base scaffolder establishes.
# Layering per references/scaffolds/state-architecture.md:
#   stores/ owns I/O · hooks/ read stores · components/ read hooks
# -----------------------------------------------------------------------------
FEATURE_DIR="${TARGET}/src/features/${FEATURE}"
mkdir -p "${FEATURE_DIR}/stores" "${FEATURE_DIR}/hooks" "${FEATURE_DIR}/components"
mkdir -p "${TARGET}/src/dev"

log "Emitting agent store, hook, and panel…"
cp "${ASSETS}/agent-store.ts"  "${FEATURE_DIR}/stores/agent-store.ts"
cp "${ASSETS}/use-agent.ts"    "${FEATURE_DIR}/hooks/use-agent.ts"
cp "${ASSETS}/agent-panel.tsx" "${FEATURE_DIR}/components/agent-panel.tsx"

# The hook and panel import siblings by relative path; rewrite for the layout.
python3 - "${FEATURE_DIR}" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
hook = root / "hooks" / "use-agent.ts"
hook.write_text(hook.read_text().replace(
    "from './agent-store'", "from '../stores/agent-store'"))
panel = root / "components" / "agent-panel.tsx"
panel.write_text(panel.read_text().replace(
    "from './use-agent'", "from '../hooks/use-agent'"))
PY

log "Emitting mock agent and dev-server plugin…"
cp "${ASSETS}/mock-agent.ts"             "${TARGET}/src/dev/mock-agent.ts"
cp "${ASSETS}/vite-plugin-agui-mock.ts"  "${TARGET}/src/dev/vite-plugin-agui-mock.ts"
ok "Sources emitted."

# -----------------------------------------------------------------------------
# Register the plugin in the vite config. Idempotent: a second run is a no-op.
# -----------------------------------------------------------------------------
log "Registering aguiMockPlugin in $(basename "${VITE_CONFIG}")…"
python3 - "${VITE_CONFIG}" "${ROUTE}" <<'PY'
import pathlib, re, sys
path, route = pathlib.Path(sys.argv[1]), sys.argv[2]
src = path.read_text()

if "aguiMockPlugin" in src:
    print("  already registered — leaving as-is")
    raise SystemExit(0)

imp = "import { aguiMockPlugin } from './src/dev/vite-plugin-agui-mock.ts';\n"
lines = src.splitlines(keepends=True)
last_import = max((i for i, l in enumerate(lines) if l.startswith("import ")), default=-1)
lines.insert(last_import + 1, imp)
src = "".join(lines)

# Append to the plugins array. Matching the opening bracket only, so nested
# brackets inside existing plugin calls cannot terminate the match early.
m = re.search(r"plugins\s*:\s*\[", src)
if not m:
    raise SystemExit("could not find a plugins: [ array in the vite config")
src = src[:m.end()] + f"\n    aguiMockPlugin({{ path: '{route}' }})," + src[m.end():]
path.write_text(src)
print("  plugin registered")
PY
ok "Vite config patched."

# -----------------------------------------------------------------------------
# README — the generated app looks production-shaped; say plainly that it is not.
# -----------------------------------------------------------------------------
log "Writing AG-UI README section…"
README="${TARGET}/README.md"
[[ -f "${README}" ]] || printf '# %s\n' "$(basename "${TARGET}")" > "${README}"

if grep -q "## AG-UI agent host" "${README}" 2>/dev/null; then
  warn "README already documents the AG-UI host — leaving as-is."
else
  cat >> "${README}" <<EOF

## AG-UI agent host

This app streams agent responses over the [AG-UI protocol](https://github.com/ag-ui-protocol/ag-ui).

- \`src/features/${FEATURE}/stores/agent-store.ts\` — owns the connection and
  reduces streamed events into state. All agent I/O lives here.
- \`src/features/${FEATURE}/hooks/use-agent.ts\` — reads the store.
- \`src/features/${FEATURE}/components/agent-panel.tsx\` — renders messages.

### Development only

\`src/dev/vite-plugin-agui-mock.ts\` answers \`${ROUTE}\` from a **mock agent**
(\`src/dev/mock-agent.ts\`) that replays a canned response as protocol events.

**This runs in the Vite dev server only.** \`vite build\` does not include it, so
a deployed build has no agent endpoint. Production requires a real backend
implementing the same contract:

\`\`\`
POST ${ROUTE}
  Content-Type: application/json      body: RunAgentInput
  Accept: text/event-stream
→ Content-Type: text/event-stream
  data: {"type":"RUN_STARTED",…}

  data: {"type":"TEXT_MESSAGE_CONTENT","delta":"…"}

  data: {"type":"RUN_FINISHED",…}
\`\`\`

Point the store at it by passing \`{ url }\` to \`useAgent\`.
EOF
  ok "README section written."
fi

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
ok "AG-UI host layered onto ${TARGET}"
log "Next: cd ${TARGET} && pnpm dev — then render <AgentPanel /> from your app."
