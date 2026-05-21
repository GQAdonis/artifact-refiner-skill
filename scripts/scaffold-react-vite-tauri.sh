#!/usr/bin/env bash
#
# scaffold-react-vite-tauri.sh
#
# Wrap a scaffolded Vite/React project in a Tauri 2 shell. Tauri 2 supports
# desktop + iOS + Android from the same source. Desktop targets are default;
# iOS/Android are opt-in via --mobile.
#
# Usage:
#   bash scripts/scaffold-react-vite-tauri.sh \
#     --target <path-to-react-project> \
#     [--bundle-id com.example.<kebab-name>] \
#     [--mobile]
#
# Pre-flight: requires cargo, rustup, pnpm. --mobile additionally requires
# Xcode (iOS) and a configured Android SDK (Android).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log()  { printf '\033[1;36m[scaffold-tauri]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[scaffold-tauri]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[scaffold-tauri]\033[0m %s\n' "$*" >&2; }
ok()   { printf '\033[1;32m[scaffold-tauri]\033[0m %s\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

# -----------------------------------------------------------------------------
# Args
# -----------------------------------------------------------------------------
TARGET=""
BUNDLE_ID=""
MOBILE=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)    TARGET="$2"; shift 2;;
    --bundle-id) BUNDLE_ID="$2"; shift 2;;
    --mobile)    MOBILE=1; shift;;
    --help|-h)
      sed -n '5,18p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0;;
    *) err "unknown argument: $1"; exit 2;;
  esac
done
if [[ -z "${TARGET}" ]]; then err "missing --target"; exit 2; fi
if [[ ! -f "${TARGET}/package.json" ]]; then
  err "expected scaffolded React project at ${TARGET}; missing package.json"
  exit 1
fi

KEBAB_NAME="$(basename "${TARGET}")"
if [[ -z "${BUNDLE_ID}" ]]; then
  # Convert kebab to dot-segments (com.example.my-app → com.example.myapp)
  STRIPPED="$(echo "${KEBAB_NAME}" | tr -d -)"
  BUNDLE_ID="com.example.${STRIPPED}"
fi

# -----------------------------------------------------------------------------
# Pre-flight
# -----------------------------------------------------------------------------
log "Pre-flight checks…"
for tool in cargo rustup pnpm; do
  if ! have "${tool}"; then
    err "${tool} not on PATH. Install Rust (rustup.rs) + pnpm (corepack enable pnpm)."
    exit 1
  fi
done
if [[ "${MOBILE}" -eq 1 ]]; then
  if ! have xcrun; then warn "xcrun absent — iOS init will be skipped"; fi
  if [[ -z "${ANDROID_HOME:-}" && -z "${ANDROID_SDK_ROOT:-}" ]]; then
    warn "ANDROID_HOME / ANDROID_SDK_ROOT unset — Android init will be skipped"
  fi
fi
ok "Pre-flight checks passed."

log "Target:        ${TARGET}"
log "Bundle ID:     ${BUNDLE_ID}"
log "Mobile targets: $([[ ${MOBILE} -eq 1 ]] && echo yes || echo no)"

# -----------------------------------------------------------------------------
# Tauri init
# -----------------------------------------------------------------------------
log "Installing @tauri-apps/cli + @tauri-apps/api…"
( cd "${TARGET}" && pnpm add -D @tauri-apps/cli@latest --silent && pnpm add @tauri-apps/api@latest --silent ) 2>&1 | sed 's/^/  /'

log "Running pnpm tauri init (non-interactive)…"
# Tauri 2 init flags: --ci enables non-interactive mode, --app-name sets the
# crate name, --window-title sets the window title, --frontend-dist points at
# the vite build output, --dev-url points at the vite dev server.
( cd "${TARGET}" && pnpm tauri init --ci \
    --app-name "${KEBAB_NAME}" \
    --window-title "${KEBAB_NAME}" \
    --frontend-dist "../dist" \
    --dev-url "http://localhost:5173" ) 2>&1 | sed 's/^/  /' || {
  err "tauri init failed"
  exit 1
}

if [[ ! -d "${TARGET}/src-tauri" ]]; then
  err "tauri init claimed success but src-tauri/ was not created"
  exit 1
fi
ok "Tauri init complete."

# -----------------------------------------------------------------------------
# Customize tauri.conf.json (bundle id, security CSP, withGlobalTauri=false)
# -----------------------------------------------------------------------------
log "Customizing tauri.conf.json…"
( cd "${TARGET}" && node -e "
  const fs = require('fs');
  const p = 'src-tauri/tauri.conf.json';
  const c = JSON.parse(fs.readFileSync(p, 'utf8'));
  c.identifier = '${BUNDLE_ID}';
  c.app = c.app || {};
  c.app.withGlobalTauri = false;
  c.app.security = c.app.security || {};
  // Conservative CSP. Users will customize for their API endpoints.
  if (!c.app.security.csp) {
    c.app.security.csp = \"default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; connect-src 'self' http://localhost:* ws://localhost:* https:\";
  }
  fs.writeFileSync(p, JSON.stringify(c, null, 2) + '\n');
" )
ok "tauri.conf.json customized (identifier=${BUNDLE_ID}, withGlobalTauri=false, CSP set)."

# -----------------------------------------------------------------------------
# Default menu in lib.rs (Tauri 2 convention — run() and setup live in lib.rs,
# not main.rs). Add a minimal native menu (File → Quit, Edit → Copy/Paste,
# Help → About) so desktop builds get a real menu bar out of the box. The menu
# only attaches on desktop targets (cfg(desktop)).
# -----------------------------------------------------------------------------
LIB_RS="${TARGET}/src-tauri/src/lib.rs"
if [[ -f "${LIB_RS}" ]]; then
  log "Patching src-tauri/src/lib.rs with default desktop menu…"
  if grep -q "MenuBuilder" "${LIB_RS}"; then
    warn "lib.rs already contains a menu definition — leaving as-is."
  else
    # We splice a setup hook into the .setup(...) chain, or add one if missing.
    # Strategy: replace the line containing `tauri::Builder::default()` with
    # a builder chain that includes a setup closure.
    python3 - "${LIB_RS}" <<'PY'
import sys, re
path = sys.argv[1]
with open(path, "r") as f:
    src = f.read()

setup_block = '''        .setup(|app| {
            #[cfg(desktop)]
            {
                use tauri::menu::{MenuBuilder, SubmenuBuilder, PredefinedMenuItem};
                let file = SubmenuBuilder::new(app, "File")
                    .item(&PredefinedMenuItem::quit(app, None)?)
                    .build()?;
                let edit = SubmenuBuilder::new(app, "Edit")
                    .item(&PredefinedMenuItem::copy(app, None)?)
                    .item(&PredefinedMenuItem::paste(app, None)?)
                    .item(&PredefinedMenuItem::select_all(app, None)?)
                    .build()?;
                let help = SubmenuBuilder::new(app, "Help")
                    .item(&PredefinedMenuItem::about(app, None, None)?)
                    .build()?;
                let menu = MenuBuilder::new(app).items(&[&file, &edit, &help]).build()?;
                app.set_menu(menu)?;
            }
            Ok(())
        })
'''

if ".setup(" in src:
    # Already has a .setup — leave alone (user may have customized).
    sys.stderr.write("[scaffold-tauri] lib.rs already has .setup(); skipping menu insertion\n")
    sys.exit(0)

# Insert the setup block right after `tauri::Builder::default()`.
pattern = re.compile(r"(tauri::Builder::default\(\))")
new, n = pattern.subn(r"\1\n" + setup_block, src, count=1)
if n == 0:
    sys.stderr.write("[scaffold-tauri] could not locate tauri::Builder::default() — leaving lib.rs unchanged\n")
    sys.exit(0)
with open(path, "w") as f:
    f.write(new)
PY
    ok "lib.rs menu inserted."
  fi
else
  warn "src-tauri/src/lib.rs not found — skipping menu insertion."
fi

# -----------------------------------------------------------------------------
# Mobile targets (opt-in)
# -----------------------------------------------------------------------------
if [[ "${MOBILE}" -eq 1 ]]; then
  if have xcrun; then
    log "Initializing iOS target…"
    ( cd "${TARGET}" && pnpm tauri ios init ) 2>&1 | sed 's/^/  /' || warn "iOS init failed; continuing"
  fi
  if [[ -n "${ANDROID_HOME:-}${ANDROID_SDK_ROOT:-}" ]]; then
    log "Initializing Android target…"
    ( cd "${TARGET}" && pnpm tauri android init ) 2>&1 | sed 's/^/  /' || warn "Android init failed; continuing"
  fi
fi

# -----------------------------------------------------------------------------
# Add tauri script entries to package.json
# -----------------------------------------------------------------------------
log "Adding tauri scripts to package.json…"
( cd "${TARGET}" && node -e "
  const fs = require('fs');
  const p = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  p.scripts = p.scripts || {};
  if (!p.scripts.tauri) p.scripts.tauri = 'tauri';
  fs.writeFileSync('package.json', JSON.stringify(p, null, 2) + '\n');
" )

# -----------------------------------------------------------------------------
# Verify with tauri info
# -----------------------------------------------------------------------------
log "Verifying with pnpm tauri info…"
( cd "${TARGET}" && pnpm tauri info ) 2>&1 | sed 's/^/  /' | head -20 || {
  warn "pnpm tauri info returned non-zero; continuing"
}

ok "Tauri hybrid shell scaffolded."
echo "  Path:         ${TARGET}/src-tauri/"
echo "  Bundle ID:    ${BUNDLE_ID}"
echo "  Run desktop:  cd ${TARGET} && pnpm tauri dev"
echo "  Build:        cd ${TARGET} && pnpm tauri build"
if [[ "${MOBILE}" -eq 1 ]]; then
  echo "  iOS dev:      cd ${TARGET} && pnpm tauri ios dev"
  echo "  Android dev:  cd ${TARGET} && pnpm tauri android dev"
fi
