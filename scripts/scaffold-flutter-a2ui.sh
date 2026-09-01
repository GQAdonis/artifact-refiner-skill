#!/usr/bin/env bash
#
# scaffold-flutter-a2ui.sh
#
# Layer an A2UI rendering host onto an existing Flutter project: the surface
# store, the widget that renders it, the v1.0->v0.9 translation, and a parity
# test that asserts the same facts the web host's browser gate asserts.
#
# WHY THIS LIVES HERE. This repository owns A2UI protocol knowledge — the v1.0
# schema, the v0.9 translation, the catalog quirks. Flutter APP generation lives
# elsewhere (hybrid-mobile-architecture-src). This wrapper layers one concern
# onto a project it did not create, exactly as scaffold-react-vite-a2ui.sh does
# for a Vite project. Forking protocol knowledge across repositories is how a
# type comes to be named A2UI without implementing A2UI.
#
# Usage:
#   bash scripts/scaffold-flutter-a2ui.sh --target <path-to-flutter-project>
#
# Pre-flight: requires flutter and an existing Flutter project (pubspec.yaml
# with a `flutter:` section).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log()  { printf '\033[0;36m[flutter-a2ui]\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m[flutter-a2ui]\033[0m %s\n' "$*"; }
warn() { printf '\033[0;33m[flutter-a2ui]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[0;31m[flutter-a2ui]\033[0m %s\n' "$*" >&2; }

TARGET=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)  TARGET="$2"; shift 2 ;;
    -h|--help) sed -n '2,22p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) err "unknown argument: $1"; exit 1 ;;
  esac
done

[[ -n "${TARGET}" ]] || { err "--target is required (path to a Flutter project)"; exit 1; }
[[ -d "${TARGET}" ]] || { err "target does not exist: ${TARGET}"; exit 1; }
TARGET="$(cd "${TARGET}" && pwd)"

# -----------------------------------------------------------------------------
# Pre-flight
# -----------------------------------------------------------------------------
log "Pre-flight checks…"
command -v flutter >/dev/null 2>&1 || { err "flutter not found on PATH"; exit 1; }

[[ -f "${TARGET}/pubspec.yaml" ]] || {
  err "no pubspec.yaml in ${TARGET} — is this a Flutter project?"; exit 1; }
grep -q '^flutter:' "${TARGET}/pubspec.yaml" || {
  err "pubspec.yaml has no 'flutter:' section — is this a Flutter APP (not a plain Dart package)?"
  exit 1; }

# The package name is needed for the parity test's imports. Reading it rather
# than assuming the directory name matches.
PKG="$(awk '/^name:/{print $2; exit}' "${TARGET}/pubspec.yaml")"
[[ -n "${PKG}" ]] || { err "could not read 'name:' from pubspec.yaml"; exit 1; }

ASSETS="${REPO_ROOT}/assets/scaffold/flutter-a2ui"
for f in a2ui_translation.dart a2ui_surface_controller.dart \
         a2ui_surface_widget.dart a2ui_parity_test.dart; do
  [[ -f "${ASSETS}/${f}" ]] || { err "missing template source: ${ASSETS}/${f}"; exit 1; }
done

DOC="${REPO_ROOT}/examples/a2ui-component-refinement/source.a2ui.json"
[[ -f "${DOC}" ]] || { err "missing shared A2UI document: ${DOC}"; exit 1; }

ok "Pre-flight passed."
log "Target:  ${TARGET}"
log "Package: ${PKG}"

# -----------------------------------------------------------------------------
# Dependencies.
#
# `genui` is the renderer; `a2ui_core` supplies the message types. Note that
# `a2ui_flutter` on pub.dev is NOT the SDK — at 0.0.1-wip002 it is an unmodified
# `dart create` template (`class Awesome { bool get isAwesome => true; }`) with
# no implementation. Do not substitute it.
# -----------------------------------------------------------------------------
log "Installing genui + a2ui_core…"
( cd "${TARGET}" && flutter pub add genui a2ui_core ) >/dev/null 2>&1 || {
  err "dependency install failed — run 'flutter pub add genui a2ui_core' in ${TARGET} to see why"
  exit 1; }
ok "Dependencies installed."

# -----------------------------------------------------------------------------
# Emit
# -----------------------------------------------------------------------------
mkdir -p "${TARGET}/lib/a2ui" "${TARGET}/assets/a2ui" "${TARGET}/test"

log "Emitting surface store, widget, and translation…"
cp "${ASSETS}/a2ui_translation.dart"        "${TARGET}/lib/a2ui/"
cp "${ASSETS}/a2ui_surface_controller.dart" "${TARGET}/lib/a2ui/"
cp "${ASSETS}/a2ui_surface_widget.dart"     "${TARGET}/lib/a2ui/"
cp "${DOC}"                                 "${TARGET}/assets/a2ui/source.a2ui.json"

# The parity test imports by package name, which is per-project.
sed "s/__PACKAGE__/${PKG}/g" "${ASSETS}/a2ui_parity_test.dart" \
  > "${TARGET}/test/a2ui_parity_test.dart"
ok "Sources emitted."

# -----------------------------------------------------------------------------
# Register the shared A2UI document as an asset. Idempotent.
# -----------------------------------------------------------------------------
log "Registering the A2UI asset…"
python3 - "${TARGET}" <<'PY'
import pathlib, re, sys
pubspec = pathlib.Path(sys.argv[1]) / "pubspec.yaml"
s = pubspec.read_text()

if "assets/a2ui/" in s:
    print("  pubspec.yaml: asset already registered (no-op)")
else:
    if re.search(r"^\s+assets:\s*$", s, re.M):
        # An assets: block exists — append to it rather than adding a second.
        s = re.sub(r"(^\s+assets:\s*$)", r"\1\n    - assets/a2ui/source.a2ui.json",
                   s, count=1, flags=re.M)
    else:
        m = re.search(r"^(\s+)uses-material-design:.*$", s, re.M)
        if not m:
            raise SystemExit(
                "could not find 'uses-material-design:' in pubspec.yaml — add "
                "an assets: entry for assets/a2ui/source.a2ui.json by hand")
        indent = m.group(1)
        s = (s[:m.end()] + f"\n{indent}assets:\n{indent}  - assets/a2ui/source.a2ui.json"
             + s[m.end():])
    pubspec.write_text(s)
    print("  pubspec.yaml: asset registered")
PY
( cd "${TARGET}" && flutter pub get ) >/dev/null 2>&1 || warn "flutter pub get reported a problem"
ok "Asset registered."

# -----------------------------------------------------------------------------
# Verify: the parity test must actually pass in the generated project.
# A scaffolder that emits code it never runs is a scaffolder that ships broken
# code.
# -----------------------------------------------------------------------------
log "Running the parity test…"
if ( cd "${TARGET}" && flutter test test/a2ui_parity_test.dart ) >/dev/null 2>&1; then
  ok "Parity test PASSED — this surface renders the shared document like the web host."
else
  err "Parity test FAILED. The emitted host does not render the shared A2UI"
  err "document the way the web host does. Run it directly to see why:"
  err "  cd ${TARGET} && flutter test test/a2ui_parity_test.dart"
  exit 1
fi

# -----------------------------------------------------------------------------
# README
# -----------------------------------------------------------------------------
log "Writing A2UI-FLUTTER.md…"
cat > "${TARGET}/A2UI-FLUTTER.md" <<EOF
# A2UI surface (Flutter)

Renders agent-described UI over the
[A2UI protocol](https://github.com/a2ui-project/a2ui), using the same protocol
and the same shared document as the web and MCP-UI hosts.

## Cross-platform parity

\`test/a2ui_parity_test.dart\` drives \`assets/a2ui/source.a2ui.json\` — the
**same document the web host renders** — and asserts the **same observable
facts** the web browser gate asserts: a heading, body text, and two labelled
buttons.

\`\`\`
flutter test test/a2ui_parity_test.dart
\`\`\`

If it fails after a dependency bump, the surfaces have drifted apart. **Fix the
drift; do not relax the assertion** — this test is the parity guarantee.

## Layout

- \`lib/a2ui/a2ui_surface_controller.dart\` — owns message intake. No \`material\`
  import, so it is testable headlessly.
- \`lib/a2ui/a2ui_surface_widget.dart\` — reads the store, renders \`Surface\`.
- \`lib/a2ui/a2ui_translation.dart\` — the v1.0 -> v0.9 seam.

## Use it

\`\`\`dart
final store = A2uiSurfaceStore();
A2uiSurfaceView(store: store, messages: [yourA2uiDocument]);
\`\`\`

For a live agent, call \`store.ingest(messages)\` as messages arrive instead of
passing \`messages\`.

## Protocol version

The schema validates A2UI **v1.0**; \`genui@0.10.2\` implements **v0.9**.
\`a2ui_translation.dart\` bridges them: it retargets \`catalogId\` to the
renderer's own catalog and splits v1.0's inline \`components\`/\`dataModel\` into
separate v0.9 messages.

**Both halves are required.** Without the retarget the renderer raises
"Catalog not found"; without the split the surface is created but never
populated and renders empty with no error. The identical translation exists in
the web host and the MCP-UI guest — all three must agree.

## Testing constraints — two real ones, both found by hitting them

These are properties of \`genui\`, not of this scaffold. Neither affects a running
app; both affect how you write tests.

### 1. Do not use a bare \`pumpAndSettle()\`

\`SurfaceController\` holds a **one-minute \`pendingUpdateTimeout\`** timer for
updates buffered ahead of their surface. \`pumpAndSettle()\` waits for every
pending timer, so it either spends a real minute or exceeds its own budget and
reports:

\`\`\`
pumpAndSettle timed out
\`\`\`

That reads like a rendering failure and is not one. Pump a bounded number of
frames instead:

\`\`\`dart
for (var i = 0; i < 5; i++) {
  await tester.pump(const Duration(milliseconds: 50));
}
\`\`\`

### 2. One A2UI screen mount per test file

A second \`pumpWidget()\` of an A2UI-bearing screen in the same file renders
**nothing** — no surface, no error, no loading state. A silently empty screen.

The store is not at fault: two independent \`A2uiSurfaceStore\`s each ingest the
same document and both report \`ready\` with a non-null definition. The leak is
\`BasicCatalogItems\`, which exposes its \`CatalogItem\`s as \`static final\` —
catalog state is process-global and shared by every \`SurfaceController\` in a
test run.

A test that mounts the screen once passes. A second mount in the same file does
not. Split them across files, or mark the second \`skip: true\` **with this
reason recorded** — a bare skip looks like a flaky test, and this is not flaky.

An app mounts once, so shipped behaviour is unaffected.

## A note on \`a2ui_flutter\`

The \`a2ui_flutter\` package on pub.dev is **not** the SDK. At \`0.0.1-wip002\` it
is an unmodified \`dart create\` template with no implementation. The renderer is
\`genui\`; the message types are \`a2ui_core\`.
EOF
ok "README written."

ok "A2UI Flutter host layered onto ${TARGET}"
log "Next: flutter test test/a2ui_parity_test.dart"
