#!/usr/bin/env bash
#
# scaffold-react-vite.sh
#
# Convert a refined React TSX artifact into a buildable Vite 8 + React 19
# + TypeScript + Tailwind v4 + shadcn-on-Base-UI project, organized with
# kebab-case file names and feature-based clean architecture.
#
# Optionally chains into scaffold-react-vite-axum.sh to add a Rust + Axum
# binary that embeds the dist via rust-embed and serves the SPA.
#
# Usage:
#   bash scripts/scaffold-react-vite.sh \
#     --name <artifact-name> \
#     --source <path-to-tsx> \
#     --brand <brand-name> \
#     --target <path> \
#     [--with-axum-wrapper]
#
# See references/scaffolds/clean-architecture.md for the produced layout.
# See references/scaffolds/kebab-case-rename.md for the naming heuristic.

set -euo pipefail

# -----------------------------------------------------------------------------
# Locate self + repo root
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FORGE_BIN_CANDIDATES=(
  "${REPO_ROOT}/tools/template-forge-rs/target/release/template-forge"
  "$(command -v template-forge 2>/dev/null || true)"
)

# -----------------------------------------------------------------------------
# Logging
# -----------------------------------------------------------------------------
log()   { printf '\033[1;36m[scaffold-react-vite]\033[0m %s\n' "$*"; }
warn()  { printf '\033[1;33m[scaffold-react-vite]\033[0m %s\n' "$*" >&2; }
err()   { printf '\033[1;31m[scaffold-react-vite]\033[0m %s\n' "$*" >&2; }
ok()    { printf '\033[1;32m[scaffold-react-vite]\033[0m %s\n' "$*"; }

# -----------------------------------------------------------------------------
# Source helpers
# -----------------------------------------------------------------------------
# shellcheck source=/dev/null
. "${SCRIPT_DIR}/lib/kebab-case.sh"

# -----------------------------------------------------------------------------
# Arg parsing
# -----------------------------------------------------------------------------
NAME=""
SOURCE_TSX=""
BRAND=""
TARGET=""
WITH_AXUM=0
WITH_TAURI=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)               NAME="$2"; shift 2;;
    --source)             SOURCE_TSX="$2"; shift 2;;
    --brand)              BRAND="$2"; shift 2;;
    --target)             TARGET="$2"; shift 2;;
    --with-axum-wrapper)  WITH_AXUM=1; shift;;
    --with-tauri-wrapper) WITH_TAURI=1; shift;;
    --help|-h)
      sed -n '5,25p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
      exit 0;;
    *)
      err "unknown argument: $1"
      exit 2;;
  esac
done

for var in NAME SOURCE_TSX BRAND TARGET; do
  if [[ -z "${!var}" ]]; then
    err "missing required --${var,,}; see --help"
    exit 2
  fi
done

NAME_KEBAB="$(to_kebab "${NAME}")"

# -----------------------------------------------------------------------------
# Pre-flight
# -----------------------------------------------------------------------------
log "Pre-flight checks…"

have() { command -v "$1" >/dev/null 2>&1; }

if ! have pnpm; then
  err "pnpm is not on PATH. Install via: corepack enable pnpm"
  exit 1
fi
if ! have node; then
  err "node is not on PATH. Install Node 20+."
  exit 1
fi

# Resolve template-forge
FORGE=""
for cand in "${FORGE_BIN_CANDIDATES[@]}"; do
  if [[ -n "${cand}" && -x "${cand}" ]]; then FORGE="${cand}"; break; fi
done
if [[ -z "${FORGE}" ]]; then
  err "template-forge not found. Build it first:"
  err "  cd ${REPO_ROOT}/tools/template-forge-rs && cargo build --release"
  exit 1
fi

# Source artifact must exist; resolve to absolute path so it survives later `cd`
if [[ ! -f "${SOURCE_TSX}" ]]; then
  err "source TSX not found: ${SOURCE_TSX}"
  exit 1
fi
SOURCE_TSX="$(cd "$(dirname "${SOURCE_TSX}")" && pwd)/$(basename "${SOURCE_TSX}")"

# Brand TOML must exist
BRAND_TOML="${REPO_ROOT}/assets/library/brands/${BRAND}.toml"
if [[ ! -f "${BRAND_TOML}" ]]; then
  err "brand TOML not found: ${BRAND_TOML}"
  exit 1
fi

# Target must not exist (v1 — no overwrite)
if [[ -e "${TARGET}" ]]; then
  err "target already exists: ${TARGET}"
  err "v1 does not support idempotent re-run; remove the target and re-run."
  exit 1
fi

log "All pre-flight checks passed."
log "  Name (kebab):    ${NAME_KEBAB}"
log "  Source:          ${SOURCE_TSX}"
log "  Brand:           ${BRAND}"
log "  Target:          ${TARGET}"
log "  Axum wrapper:    $([[ ${WITH_AXUM} -eq 1 ]] && echo yes || echo no)"
log "  Tauri wrapper:   $([[ ${WITH_TAURI} -eq 1 ]] && echo yes || echo no)"

# -----------------------------------------------------------------------------
# Step 1 — shadcn init
# -----------------------------------------------------------------------------
TARGET_PARENT="$(dirname "${TARGET}")"
TARGET_BASENAME="$(basename "${TARGET}")"
mkdir -p "${TARGET_PARENT}"

log "Running shadcn init (Vite + React 19 + TS + Tailwind v4 + Base UI)…"
log "  This will take ~30-60s for pnpm install"

# pnpm dlx caches the package; first run is slower
( cd "${TARGET_PARENT}" \
  && pnpm dlx shadcn@latest init \
       --template vite \
       --base base \
       --preset nova \
       --name "${TARGET_BASENAME}" \
       --no-monorepo \
       --no-rtl \
       --no-pointer \
       --yes ) 2>&1 | sed 's/^/  /' || {
  err "shadcn init failed"
  exit 1
}

if [[ ! -d "${TARGET}" ]]; then
  err "shadcn init claimed success but target dir was not created: ${TARGET}"
  exit 1
fi

ok "shadcn init complete."

# -----------------------------------------------------------------------------
# Step 1b — Install zustand + immer for the architectural baseline
# -----------------------------------------------------------------------------
log "Installing zustand + immer (state architecture baseline)…"
( cd "${TARGET}" && pnpm add zustand immer --silent ) 2>&1 | sed 's/^/  /' || {
  warn "zustand/immer install failed; continuing — pnpm build may break later"
}
ok "State architecture deps installed."

# -----------------------------------------------------------------------------
# Step 1c — Install vite-plugin-pwa for the hybrid web/PWA target
# -----------------------------------------------------------------------------
log "Installing vite-plugin-pwa…"
( cd "${TARGET}" && pnpm add -D vite-plugin-pwa --silent ) 2>&1 | sed 's/^/  /' || {
  warn "vite-plugin-pwa install failed; PWA manifest will not be wired"
}
ok "PWA plugin installed."

# -----------------------------------------------------------------------------
# Step 2 — Render brand CSS over default index.css
# -----------------------------------------------------------------------------
log "Rendering brand-tokens CSS via template-forge…"
INDEX_CSS_TARGET=""
for candidate in "${TARGET}/src/index.css" "${TARGET}/src/styles/globals.css" "${TARGET}/src/app.css"; do
  if [[ -f "${candidate}" ]]; then INDEX_CSS_TARGET="${candidate}"; break; fi
done

if [[ -z "${INDEX_CSS_TARGET}" ]]; then
  err "could not locate the index.css/globals.css produced by shadcn init"
  exit 1
fi
log "  Replacing: ${INDEX_CSS_TARGET}"

"${FORGE}" render \
  --brand "${BRAND}" \
  --template vite-shell-css \
  --engine minijinja \
  --library "${REPO_ROOT}/assets/library" \
  --templates-base "${REPO_ROOT}/tools/template-forge-rs/templates" \
  --output "${INDEX_CSS_TARGET}"

ok "Brand CSS rendered."

# -----------------------------------------------------------------------------
# Step 3 — Reorganize into clean architecture
# -----------------------------------------------------------------------------
log "Reorganizing into feature-based clean architecture…"

cd "${TARGET}"

# Create new layout dirs (clean architecture + state architecture)
mkdir -p src/app
mkdir -p src/app/stores
mkdir -p "src/features/${NAME_KEBAB}/components"
mkdir -p "src/features/${NAME_KEBAB}/hooks"
mkdir -p "src/features/${NAME_KEBAB}/stores"
mkdir -p src/shared/components/ui
mkdir -p src/shared/hooks
mkdir -p src/shared/lib
mkdir -p src/shared/types

# Move shadcn's default lib/utils.ts → src/shared/lib/utils.ts
if [[ -f src/lib/utils.ts ]]; then
  mv src/lib/utils.ts src/shared/lib/utils.ts
  rmdir src/lib 2>/dev/null || true
fi

# Move shadcn's default components/ui/* → src/shared/components/ui/
if [[ -d src/components/ui ]]; then
  # mv contents to preserve any already-installed components
  shopt -s nullglob dotglob
  for item in src/components/ui/*; do
    mv "${item}" src/shared/components/ui/
  done
  shopt -u nullglob dotglob
  rmdir src/components/ui 2>/dev/null || true
fi

# Move shadcn nova preset's theme-provider (and any other app-shell shims that
# land in src/components/) → src/app/. These belong with the app shell, not
# in feature/shared layers. The downstream import-rewrite pass already
# rewrites `@/components/theme-provider` → `@/app/theme-provider`.
if [[ -d src/components ]]; then
  shopt -s nullglob dotglob
  for item in src/components/*; do
    [[ -e "${item}" ]] && mv "${item}" src/app/
  done
  shopt -u nullglob dotglob
  rmdir src/components 2>/dev/null || true
fi

# Rewrite import paths in moved shadcn components: @/lib/utils → @/shared/lib/utils
log "Rewriting shadcn-default import paths for clean architecture…"
if [[ -d src/shared/components/ui ]]; then
  find src/shared/components/ui -name '*.tsx' -o -name '*.ts' | while read -r f; do
    # POSIX sed in-place: use -i '' on macOS, plain -i on GNU. Pipe through a
    # tmp file for portability.
    sed -e 's|@/lib/utils|@/shared/lib/utils|g' \
        -e 's|@/components/ui/|@/shared/components/ui/|g' \
        -e 's|@/hooks/|@/shared/hooks/|g' \
        "${f}" > "${f}.tmp" && mv "${f}.tmp" "${f}"
  done
fi

# Project-wide: rewrite non-ui @/components/<name> → @/app/<name>. This catches
# imports of the theme-provider (and any other shell-level shim from nova) that
# were moved to src/app/ above. Runs AFTER the ui-specific rewrite so that
# @/components/ui/* is already handled.
if [[ -d src ]]; then
  find src -name '*.tsx' -o -name '*.ts' | while read -r f; do
    sed -E 's|@/components/([a-zA-Z0-9_-]+)|@/app/\1|g' "${f}" > "${f}.tmp" && mv "${f}.tmp" "${f}"
  done
fi

# Move existing App.tsx (shadcn default) → src/app/app.tsx (will be replaced
# with feature import next)
if [[ -f src/App.tsx ]]; then
  rm src/App.tsx  # we'll rewrite from scratch via main.tsx
fi
if [[ -f src/App.css ]]; then
  rm src/App.css
fi

# -----------------------------------------------------------------------------
# Step 4 — Patch source TSX into features/<name>/
# -----------------------------------------------------------------------------
log "Patching source artifact into src/features/${NAME_KEBAB}/…"

FEATURE_DIR="src/features/${NAME_KEBAB}"
COMPONENT_FILE="${FEATURE_DIR}/components/${NAME_KEBAB}.tsx"

# Copy source verbatim, then split out named hooks
cp "${SOURCE_TSX}" "${COMPONENT_FILE}"

# Detect named exported hooks AND named exported stores.
# Hooks match ^use[A-Z]... (e.g., useCounter, useCart).
# Stores match ^use[A-Z]...Store$ (e.g., useCounterStore) — these come from
# zustand `create(...)` calls and belong in `stores/`, not `hooks/`.
HOOK_NAMES=()
while IFS= read -r hook_name; do
  [[ -n "${hook_name}" ]] && HOOK_NAMES+=("${hook_name}")
done < <(grep -oE '^export[[:space:]]+(function|const)[[:space:]]+use[A-Z][A-Za-z0-9]*' "${COMPONENT_FILE}" 2>/dev/null \
         | awk '{print $NF}' || true)

# Extract each detected export into hooks/use-<kebab>.ts OR stores/<kebab>.ts
# depending on whether its name ends in "Store". Strip from the component file.
HOOK_PATHS=()
for hook in "${HOOK_NAMES[@]}"; do
  hook_kebab="$(to_kebab "${hook}")"
  # Route: useXxxStore → stores/<kebab>.ts; everything else → hooks/<kebab>.ts
  if [[ "${hook}" =~ Store$ ]]; then
    hook_file="${FEATURE_DIR}/stores/${hook_kebab}.ts"
    log "  Routing ${hook} → stores/${hook_kebab}.ts (zustand store)"
  else
    hook_file="${FEATURE_DIR}/hooks/${hook_kebab}.ts"
  fi

  # Extract the hook block, then filter imports to only those the hook body
  # actually references. This avoids "unused import" errors in strict TS.
  # Extract via Python — track both brace and paren depth so zustand's
  # `create<T>()(...)` shape is handled correctly (the awk version counted
  # only braces and truncated mid-store).
  python3 - "${COMPONENT_FILE}" "${hook}" "${hook_file}.full" <<'PYEOF'
import re, sys
src, target, dst = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src) as f:
    lines = f.readlines()
imports = [l for l in lines if l.lstrip().startswith("import ")]
out_lines = []
in_decl = False
brace = 0
paren = 0
declaration_re = re.compile(r"^export\s+(function|const)\s+" + re.escape(target) + r"\b")
for line in lines:
    if not in_decl:
        if declaration_re.match(line):
            in_decl = True
            out_lines.append(line)
            brace += line.count("{") - line.count("}")
            paren += line.count("(") - line.count(")")
            # Single-line const with trailing `;` and balanced parens/braces
            if brace == 0 and paren == 0 and line.rstrip().endswith(";"):
                break
        continue
    out_lines.append(line)
    brace += line.count("{") - line.count("}")
    paren += line.count("(") - line.count(")")
    if brace == 0 and paren == 0:
        # Done when we close back to depth 0. For `const X = create(...);`
        # the trailing `;` is on the closing line so we capture it.
        break
with open(dst, "w") as f:
    f.writelines(imports + ["\n"] + out_lines)
PYEOF

  # Now filter the imports block: keep only imports whose imported identifiers
  # appear in the hook body.
  python3 - "${hook_file}.full" "${hook_file}" <<'PYEOF'
import re, sys
src_path, dst_path = sys.argv[1], sys.argv[2]
with open(src_path) as f:
    text = f.read()
# Split imports from body
lines = text.split("\n")
imports, body = [], []
in_imports = True
for line in lines:
    if in_imports and line.startswith("import "):
        imports.append(line)
    else:
        if line.startswith("import "):
            imports.append(line)
        else:
            in_imports = False
            body.append(line)
body_text = "\n".join(body)
# For each import line, extract the names being imported and keep only if used.
import_re = re.compile(r"^import\s+(?:(\w+)\s*,\s*)?\{?\s*([^}]+?)\s*\}?\s+from\s+['\"]([^'\"]+)['\"]")
import_default_only = re.compile(r"^import\s+(\w+)\s+from\s+['\"]([^'\"]+)['\"]")
kept = []
for imp in imports:
    # Default-only: `import X from "..."`
    m = import_default_only.match(imp)
    if m:
        name = m.group(1)
        if re.search(r"\b" + re.escape(name) + r"\b", body_text):
            kept.append(imp)
        continue
    # Named: `import { A, B } from "..."` or `import X, { A, B } from "..."`
    m = import_re.match(imp)
    if m:
        default_name = m.group(1)
        named = [n.strip() for n in m.group(2).split(",") if n.strip()]
        # Strip `as` aliases — keep the alias as the used name
        used_named = []
        for n in named:
            alias = n.split(" as ")[-1].strip()
            if re.search(r"\b" + re.escape(alias) + r"\b", body_text):
                used_named.append(n)
        used_default = default_name and re.search(r"\b" + re.escape(default_name) + r"\b", body_text)
        if used_default and used_named:
            kept.append(f"import {default_name}, {{ {', '.join(used_named)} }} from \"{m.group(3)}\";")
        elif used_default:
            kept.append(f"import {default_name} from \"{m.group(3)}\";")
        elif used_named:
            kept.append(f"import {{ {', '.join(used_named)} }} from \"{m.group(3)}\";")
        # else: drop entirely
        continue
    # Fallback: keep as-is if we can't parse
    kept.append(imp)
out = "\n".join(kept) + ("\n\n" if kept else "") + body_text
with open(dst_path, "w") as f:
    f.write(out)
PYEOF
  rm -f "${hook_file}.full"

  # Remove the hook/store block from the component file — Python walker that
  # tracks both brace AND paren depth so zustand `create()()` shape is handled.
  python3 - "${COMPONENT_FILE}" "${hook}" "${COMPONENT_FILE}.tmp" <<'PYEOF'
import re, sys
src, target, dst = sys.argv[1], sys.argv[2], sys.argv[3]
with open(src) as f:
    lines = f.readlines()
out = []
in_decl = False
brace = 0
paren = 0
decl_re = re.compile(r"^export\s+(function|const)\s+" + re.escape(target) + r"\b")
for line in lines:
    if not in_decl:
        if decl_re.match(line):
            in_decl = True
            brace += line.count("{") - line.count("}")
            paren += line.count("(") - line.count(")")
            if brace == 0 and paren == 0 and line.rstrip().endswith(";"):
                in_decl = False
            continue
        out.append(line)
    else:
        brace += line.count("{") - line.count("}")
        paren += line.count("(") - line.count(")")
        if brace == 0 and paren == 0:
            in_decl = False
        continue
with open(dst, "w") as f:
    f.writelines(out)
PYEOF
  mv "${COMPONENT_FILE}.tmp" "${COMPONENT_FILE}"

  # If this extraction is a STORE (ends with "Store"), do NOT inject its import
  # into the component file. Per state-architecture, components consume state
  # only through hooks. The store is private to the feature; only its hook
  # neighbor imports it.
  if [[ "${hook}" =~ Store$ ]]; then
    log "  (skipping component-side import for ${hook} — store is consumed via hooks only)"
  else
    # Inject hook import at the top of the component file.
    hook_import_path="@/features/${NAME_KEBAB}/hooks/${hook_kebab}"
    awk -v hook="${hook}" -v path="${hook_import_path}" '
      BEGIN { inserted=0; in_imports=0 }
      /^import / { in_imports=1; print; next }
      {
        if (in_imports && !inserted) {
          printf("import { %s } from \"%s\";\n", hook, path)
          inserted=1
          in_imports=0
        }
        print
      }
    ' "${COMPONENT_FILE}" > "${COMPONENT_FILE}.tmp"
    mv "${COMPONENT_FILE}.tmp" "${COMPONENT_FILE}"
  fi

  HOOK_PATHS+=("${hook_file}")
  log "  Extracted hook ${hook} → ${hook_file}"
done

# Inject cross-imports: if an extracted file (hook or store) references another
# extracted symbol from the same source, add the corresponding import. This
# handles the case where a hook uses a store that lived alongside it in the
# source file (e.g., `useCounter` uses `useCounterStore`).
if [[ ${#HOOK_NAMES[@]} -gt 0 ]]; then
  log "  Injecting cross-imports between extracted hooks/stores…"
  # Build name → import-path map
  declare -a SYM_NAMES=()
  declare -a SYM_PATHS=()
  for sym in "${HOOK_NAMES[@]}"; do
    sym_kebab="$(to_kebab "${sym}")"
    if [[ "${sym}" =~ Store$ ]]; then
      SYM_NAMES+=("${sym}")
      SYM_PATHS+=("@/features/${NAME_KEBAB}/stores/${sym_kebab}")
    else
      SYM_NAMES+=("${sym}")
      SYM_PATHS+=("@/features/${NAME_KEBAB}/hooks/${sym_kebab}")
    fi
  done

  # For each extracted file, scan body for references to other extracted symbols
  for f in "${HOOK_PATHS[@]}"; do
    for idx in "${!SYM_NAMES[@]}"; do
      sym="${SYM_NAMES[$idx]}"
      path="${SYM_PATHS[$idx]}"
      # Skip self
      if grep -q "export \(function\|const\) ${sym}\b" "${f}" 2>/dev/null; then
        continue
      fi
      # If the file body references the symbol AND doesn't already import it, inject
      if grep -q "\b${sym}\b" "${f}" 2>/dev/null && ! grep -q "import.*\b${sym}\b" "${f}" 2>/dev/null; then
        # Insert import after the last existing import (or at top if none)
        python3 - "${f}" "${sym}" "${path}" <<'PYEOF'
import sys
path, sym, imp_path = sys.argv[1], sys.argv[2], sys.argv[3]
with open(path) as fp:
    lines = fp.readlines()
last_import = -1
for i, line in enumerate(lines):
    if line.lstrip().startswith("import "):
        last_import = i
new_import = f'import {{ {sym} }} from "{imp_path}";\n'
if last_import >= 0:
    lines.insert(last_import + 1, new_import)
else:
    lines.insert(0, new_import)
with open(path, "w") as fp:
    fp.writelines(lines)
PYEOF
      fi
    done
  done
fi

# Strip unused imports from the component file (now that hooks are extracted).
log "  Stripping unused imports from component file…"
python3 - "${COMPONENT_FILE}" <<'PYEOF'
import re, sys
path = sys.argv[1]
with open(path) as f:
    text = f.read()
lines = text.split("\n")
imports, body, trailing = [], [], []
state = "imports"
for line in lines:
    if state == "imports":
        if line.startswith("import ") or line.strip() == "":
            imports.append(line)
        else:
            state = "body"
            body.append(line)
    else:
        body.append(line)
body_text_raw = "\n".join(body)
# For unused-import detection, strip comments and string literals so we don't
# false-positive on identifiers that only appear in docs or copy.
def strip_comments_and_strings(t):
    # Block comments
    t = re.sub(r"/\*[\s\S]*?\*/", "", t)
    # Line comments
    t = re.sub(r"//[^\n]*", "", t)
    # String literals (single, double, backtick — naive but safe enough)
    t = re.sub(r'"(?:[^"\\]|\\.)*"', '""', t)
    t = re.sub(r"'(?:[^'\\]|\\.)*'", "''", t)
    t = re.sub(r"`(?:[^`\\]|\\.)*`", "``", t)
    return t
body_text = strip_comments_and_strings(body_text_raw)
import_re = re.compile(r"^import\s+(?:(\w+)\s*,\s*)?\{?\s*([^}]+?)\s*\}?\s+from\s+['\"]([^'\"]+)['\"]")
import_default_only = re.compile(r"^import\s+(\w+)\s+from\s+['\"]([^'\"]+)['\"]")
kept = []
for imp in imports:
    if imp.strip() == "":
        kept.append(imp); continue
    m = import_default_only.match(imp)
    if m:
        name = m.group(1)
        if re.search(r"\b" + re.escape(name) + r"\b", body_text):
            kept.append(imp)
        continue
    m = import_re.match(imp)
    if m:
        default_name = m.group(1)
        named = [n.strip() for n in m.group(2).split(",") if n.strip()]
        used_named = []
        for n in named:
            alias = n.split(" as ")[-1].strip()
            if re.search(r"\b" + re.escape(alias) + r"\b", body_text):
                used_named.append(n)
        used_default = default_name and re.search(r"\b" + re.escape(default_name) + r"\b", body_text)
        if used_default and used_named:
            kept.append(f"import {default_name}, {{ {', '.join(used_named)} }} from \"{m.group(3)}\";")
        elif used_default:
            kept.append(f"import {default_name} from \"{m.group(3)}\";")
        elif used_named:
            kept.append(f"import {{ {', '.join(used_named)} }} from \"{m.group(3)}\";")
        continue
    kept.append(imp)
out = "\n".join(kept).rstrip() + "\n\n" + body_text_raw
with open(path, "w") as f:
    f.write(out)
PYEOF

# Generate the feature index.ts
INDEX_TS="${FEATURE_DIR}/index.ts"
{
  # Find the default export name from the component file
  default_name="$(grep -oE 'export[[:space:]]+default[[:space:]]+function[[:space:]]+[A-Z][A-Za-z0-9]*' "${COMPONENT_FILE}" \
                  | awk '{print $NF}' \
                  | head -1)"
  if [[ -z "${default_name}" ]]; then
    default_name="App"  # fallback
  fi
  echo "// Public surface for feature: ${NAME_KEBAB}"
  echo "export { default as ${default_name} } from \"./components/${NAME_KEBAB}\";"
  # Public surface re-exports only the hooks (not stores).
  # Stores are private to the feature; only hooks expose state.
  for hook in "${HOOK_NAMES[@]}"; do
    hook_kebab="$(to_kebab "${hook}")"
    if [[ "${hook}" =~ Store$ ]]; then
      # Stores are not re-exported from the feature's public surface.
      # Internal consumers (the feature's own hooks) import directly from ./stores.
      continue
    fi
    echo "export { ${hook} } from \"./hooks/${hook_kebab}\";"
  done
} > "${INDEX_TS}"
log "  Wrote feature index: ${INDEX_TS}"

# -----------------------------------------------------------------------------
# Step 5 — Auto-install any shadcn ui components the source uses
# -----------------------------------------------------------------------------
log "Scanning for shadcn UI imports…"
# Match imports from @/components/ui/<name> OR @/shared/components/ui/<name>
NEEDED_SHADCN=()
while IFS= read -r ui_name; do
  [[ -n "${ui_name}" ]] && NEEDED_SHADCN+=("${ui_name}")
done < <(grep -hoE '@/(shared/)?components/ui/[a-z][a-z0-9-]*' "${FEATURE_DIR}"/components/*.tsx 2>/dev/null \
         | awk -F/ '{print $NF}' \
         | sort -u || true)

if [[ ${#NEEDED_SHADCN[@]} -gt 0 ]]; then
  log "  Found needed shadcn components: ${NEEDED_SHADCN[*]}"
  for comp in "${NEEDED_SHADCN[@]}"; do
    if [[ ! -f "src/shared/components/ui/${comp}.tsx" ]]; then
      log "  Adding shadcn component: ${comp}"
      pnpm dlx shadcn@latest add "${comp}" --yes --base base 2>&1 | sed 's/^/    /' || {
        warn "shadcn add ${comp} failed; continuing"
      }
      # shadcn add lands at src/components/ui by default; move to shared
      if [[ -f "src/components/ui/${comp}.tsx" ]]; then
        mv "src/components/ui/${comp}.tsx" "src/shared/components/ui/${comp}.tsx"
        rmdir src/components/ui 2>/dev/null || true
        rmdir src/components 2>/dev/null || true
      fi
    else
      log "  Already present: ${comp}"
    fi
  done
fi

# -----------------------------------------------------------------------------
# Step 6 — Update components.json + tsconfig aliases for the new layout
# -----------------------------------------------------------------------------
log "Updating components.json aliases…"
if [[ -f components.json ]]; then
  # Use node to do JSON edits portably
  node -e '
    const fs = require("fs");
    const path = "components.json";
    const c = JSON.parse(fs.readFileSync(path, "utf8"));
    c.aliases = c.aliases || {};
    c.aliases.components = "@/shared/components";
    c.aliases.utils = "@/shared/lib/utils";
    c.aliases.ui = "@/shared/components/ui";
    c.aliases.lib = "@/shared/lib";
    c.aliases.hooks = "@/shared/hooks";
    fs.writeFileSync(path, JSON.stringify(c, null, 2) + "\n");
  '
fi

log "Updating tsconfig.json path aliases…"
# Locate tsconfig that owns the paths (could be tsconfig.app.json in modern Vite templates)
TSCONFIG=""
for cand in tsconfig.app.json tsconfig.json; do
  if [[ -f "${cand}" ]] && grep -q '"paths"' "${cand}"; then TSCONFIG="${cand}"; break; fi
done
if [[ -z "${TSCONFIG}" ]]; then
  # Default to tsconfig.json
  TSCONFIG="tsconfig.json"
fi

# Ensure path aliases include the clean-architecture roots. We use node for
# safe JSON edits.
node -e '
  const fs = require("fs");
  const path = process.argv[1];
  let raw = fs.readFileSync(path, "utf8");
  // Strip simple // comments + /* */ comments so JSON.parse can handle tsconfig (which allows comments)
  raw = raw.replace(/\/\*[\s\S]*?\*\//g, "").replace(/^\s*\/\/.*$/gm, "");
  const c = JSON.parse(raw);
  c.compilerOptions = c.compilerOptions || {};
  c.compilerOptions.baseUrl = c.compilerOptions.baseUrl || ".";
  c.compilerOptions.paths = {
    "@/app/*":      ["./src/app/*"],
    "@/features/*": ["./src/features/*"],
    "@/shared/*":   ["./src/shared/*"],
    "@/*":          ["./src/*"]
  };
  fs.writeFileSync(path, JSON.stringify(c, null, 2) + "\n");
' "${TSCONFIG}"
log "  Updated ${TSCONFIG}"

# -----------------------------------------------------------------------------
# Step 7 — Rewrite src/main.tsx to consume the feature
# -----------------------------------------------------------------------------
log "Rewriting src/main.tsx…"
# Find default export name from the component file
DEFAULT_NAME="$(grep -oE 'export[[:space:]]+default[[:space:]]+function[[:space:]]+[A-Z][A-Za-z0-9]*' "${COMPONENT_FILE}" \
                | awk '{print $NF}' | head -1)"
if [[ -z "${DEFAULT_NAME}" ]]; then DEFAULT_NAME="App"; fi

cat > src/main.tsx <<EOF
import React from "react";
import ReactDOM from "react-dom/client";
import { ${DEFAULT_NAME} } from "@/features/${NAME_KEBAB}";
import "./index.css";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <${DEFAULT_NAME} />
  </React.StrictMode>,
);
EOF

# -----------------------------------------------------------------------------
# Step 7b — Architectural substrate (app store + responsive primitives + lint)
# -----------------------------------------------------------------------------
log "Emitting architectural substrate (app store, responsive primitives, lint config)…"

# 7b.1 — Empty app-level store with a theme slice as a starter
cat > src/app/stores/app-store.ts <<'APPSTORE'
import { create } from "zustand";
import { immer } from "zustand/middleware/immer";

// App-level store. Holds cross-cutting concerns (theme, locale, session
// pointers, feature flags). Feature-specific state lives in feature stores.
//
// Per state-architecture.md:
//   - This file MUST NOT import React.
//   - Hooks in src/app/hooks/ or src/shared/hooks/ are the React adapter.
//   - Components NEVER import this file directly.

export type Theme = "light" | "dark" | "system";

interface AppState {
  theme: Theme;
  setTheme: (theme: Theme) => void;
}

export const useAppStore = create<AppState>()(
  immer((set) => ({
    theme: "system",
    setTheme: (theme) => set((s) => { s.theme = theme; }),
  })),
);
APPSTORE

# 7b.2 — useBreakpoint + useIsMobile (responsive primitives)
cat > src/shared/hooks/use-breakpoint.ts <<'USEBP'
import { useEffect, useState } from "react";

export type Breakpoint = "mobile" | "tablet" | "desktop";

const BREAKPOINTS = { mobile: 0, tablet: 768, desktop: 1024 } as const;

function classify(width: number): Breakpoint {
  if (width >= BREAKPOINTS.desktop) return "desktop";
  if (width >= BREAKPOINTS.tablet) return "tablet";
  return "mobile";
}

export function useBreakpoint(): Breakpoint {
  const [bp, setBp] = useState<Breakpoint>(() =>
    typeof window === "undefined" ? "desktop" : classify(window.innerWidth)
  );
  useEffect(() => {
    const onResize = () => setBp(classify(window.innerWidth));
    window.addEventListener("resize", onResize, { passive: true });
    return () => window.removeEventListener("resize", onResize);
  }, []);
  return bp;
}
USEBP

cat > src/shared/hooks/use-is-mobile.ts <<'USEIM'
import { useBreakpoint } from "./use-breakpoint";

export function useIsMobile(): boolean {
  return useBreakpoint() === "mobile";
}
USEIM

# 7b.3 — Runtime helper (isTauri)
cat > src/shared/lib/runtime.ts <<'RUNTIME'
/**
 * Runtime introspection. Use sparingly — most code should be runtime-agnostic.
 * Prefer `useBreakpoint()` for form-factor decisions over `isTauri()`.
 */
export function isTauri(): boolean {
  return typeof window !== "undefined" && "__TAURI_INTERNALS__" in window;
}
RUNTIME

# 7b.4 — ResponsiveShell (desktop sidebar vs mobile bottom-nav, viewport-based)
cat > src/app/responsive-shell.tsx <<'RSHELL'
import type { ReactNode } from "react";
import { useBreakpoint } from "@/shared/hooks/use-breakpoint";

interface Props {
  children: ReactNode;
}

/**
 * ResponsiveShell — selects desktop vs mobile layout from viewport.
 *
 * Desktop: optional sidebar + main content area
 * Mobile:  main content + bottom navigation
 *
 * Resizing a Tauri desktop window to a narrow width triggers the mobile
 * layout — the shell is viewport-driven, not runtime-driven.
 */
export function ResponsiveShell({ children }: Props) {
  const bp = useBreakpoint();
  const isMobile = bp === "mobile";

  if (isMobile) {
    return (
      <div
        style={{
          minHeight: "100dvh",
          display: "grid",
          gridTemplateRows: "1fr auto",
          paddingTop: "var(--safe-top, 0)",
        }}
      >
        <main style={{ overflowY: "auto" }}>{children}</main>
        <nav
          aria-label="Primary"
          style={{
            display: "flex",
            justifyContent: "space-around",
            padding: "0.5rem",
            background: "var(--color-surface)",
            borderTop: "1px solid var(--color-border)",
            paddingBottom: "calc(var(--safe-bottom, 0) + 0.5rem)",
          }}
        >
          {/* Replace with real nav buttons via your router or context */}
          <span style={{ color: "var(--color-muted)" }}>Nav placeholder</span>
        </nav>
      </div>
    );
  }

  return (
    <div style={{ minHeight: "100dvh", display: "grid", gridTemplateColumns: "auto 1fr" }}>
      <aside
        aria-label="Primary"
        style={{
          width: "220px",
          background: "var(--color-surface)",
          borderRight: "1px solid var(--color-border)",
          padding: "1rem",
        }}
      >
        {/* Replace with sidebar nav */}
        <span style={{ color: "var(--color-muted)" }}>Sidebar placeholder</span>
      </aside>
      <main style={{ overflowY: "auto" }}>{children}</main>
    </div>
  );
}
RSHELL

# 7b.5 — ESLint architectural config (flat config)
# Install ESLint + typescript-eslint if not already present.
if ! [[ -f eslint.config.mjs || -f eslint.config.js ]]; then
  log "  Installing eslint + typescript-eslint…"
  pnpm add -D eslint typescript-eslint @eslint/js --silent 2>&1 | sed 's/^/    /' || true
fi
cat > eslint.config.mjs <<'ESLINT'
// Architectural ESLint config — enforces state-architecture.md layering.
// Customize per project; the defaults are the strict three-layer rule.
import js from "@eslint/js";
import tseslint from "typescript-eslint";

export default tseslint.config(
  { ignores: ["dist/**", "node_modules/**", "src-tauri/target/**", "server/target/**"] },
  js.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["src/**/components/**/*.{ts,tsx}", "src/app/*.tsx"],
    rules: {
      "no-restricted-imports": ["error", {
        patterns: [
          { group: ["**/stores/*", "**/stores/**"], message: "Components must consume state via a hook." },
          { group: ["**/services/*", "**/services/**", "axios", "ky"], message: "Components must not perform I/O." },
          { group: ["@supabase/*", "socket.io-client", "partysocket"], message: "Components must not create realtime subscriptions." },
        ],
      }],
    },
  },
  {
    files: ["src/**/hooks/**/*.{ts,tsx}"],
    rules: {
      "no-restricted-imports": ["error", {
        patterns: [
          { group: ["**/services/*", "**/services/**", "axios", "ky"], message: "Hooks must not perform I/O." },
          { group: ["@supabase/*", "socket.io-client", "partysocket"], message: "Hooks must not create realtime subscriptions." },
        ],
      }],
    },
  },
  {
    files: ["src/**/stores/**/*.{ts,tsx}"],
    rules: {
      "no-restricted-imports": ["error", {
        paths: [
          { name: "react", message: "Stores must be framework-agnostic." },
          { name: "react-dom", message: "Stores must be framework-agnostic." },
        ],
        patterns: [{ group: ["**/components/**"], message: "Stores must not import from components." }],
      }],
    },
  },
);
ESLINT

# Add lint script to package.json
node -e '
  const fs = require("fs");
  const p = JSON.parse(fs.readFileSync("package.json", "utf8"));
  p.scripts = p.scripts || {};
  if (!p.scripts.lint) p.scripts.lint = "eslint src --max-warnings 0";
  fs.writeFileSync("package.json", JSON.stringify(p, null, 2) + "\n");
'

ok "Architectural substrate emitted (app-store, responsive primitives, ESLint config)."

# -----------------------------------------------------------------------------
# Step 7c — Wire vite-plugin-pwa with brand-resolved manifest
# -----------------------------------------------------------------------------
log "Wiring vite-plugin-pwa with brand-resolved manifest…"

# Resolve theme/background/initial from the brand TOML via Node (@iarna/toml).
# Falls back to grep if @iarna/toml isn't resolvable from the artifact-refiner root.
BRAND_TOML_PATH="${REPO_ROOT}/assets/library/brands/${BRAND}.toml"
BRAND_RESOLVED="$(cd "${REPO_ROOT}" && node -e "
const toml = require('@iarna/toml');
const fs = require('fs');
const d = toml.parse(fs.readFileSync('${BRAND_TOML_PATH}', 'utf8'));
const ember = d.colors?.dark?.ember || '#000000';
const bg = d.colors?.dark?.bg || '#0B0F14';
const initial = (d.meta?.name || '?').charAt(0).toUpperCase();
console.log(ember + '|' + bg + '|' + initial);
" 2>/dev/null || echo "#E04E28|#0B0F14|?")"
THEME_COLOR="$(echo "${BRAND_RESOLVED}" | cut -d'|' -f1)"
BG_COLOR="$(echo "${BRAND_RESOLVED}" | cut -d'|' -f2)"
INITIAL="$(echo "${BRAND_RESOLVED}" | cut -d'|' -f3)"
log "  theme_color=${THEME_COLOR} background_color=${BG_COLOR} initial=${INITIAL}"

# Patch vite.config.ts to add the VitePWA plugin
VITE_CFG="vite.config.ts"
if [[ ! -f "${VITE_CFG}" ]]; then VITE_CFG="vite.config.js"; fi
if [[ -f "${VITE_CFG}" ]]; then
  python3 - "${VITE_CFG}" "${NAME_KEBAB}" "${THEME_COLOR}" "${BG_COLOR}" <<'PYEOF'
import sys, re
path, name, theme, bg = sys.argv[1:5]
with open(path) as f:
    src = f.read()
# Skip if already wired
if "VitePWA" in src or "vite-plugin-pwa" in src:
    print(f"  vite.config already has PWA wiring; skipping")
    sys.exit(0)

# Insert import after the last existing import
imp_lines = re.findall(r'^import .+$', src, re.MULTILINE)
if imp_lines:
    last_imp = imp_lines[-1]
    new_imp = 'import { VitePWA } from "vite-plugin-pwa";'
    src = src.replace(last_imp, last_imp + "\n" + new_imp, 1)

# Insert plugin in the plugins array (with leading comma to keep array syntax valid)
pwa_plugin = (
    f',\n    VitePWA({{\n'
    f'      registerType: "autoUpdate",\n'
    f'      manifest: {{\n'
    f'        name: "{name}",\n'
    f'        short_name: "{name}",\n'
    f'        theme_color: "{theme}",\n'
    f'        background_color: "{bg}",\n'
    f'        display: "standalone",\n'
    f'        start_url: "/",\n'
    f'        icons: [\n'
    f'          {{ src: "/icons/icon-192.png", sizes: "192x192", type: "image/png" }},\n'
    f'          {{ src: "/icons/icon-512.png", sizes: "512x512", type: "image/png" }},\n'
    f'        ],\n'
    f'      }},\n'
    f'      workbox: {{ globPatterns: ["**/*.{{js,css,html,svg,png,ico,woff2}}"] }},\n'
    f'    }}),'
)
# Find the plugins array and inject before its closing bracket
m = re.search(r'plugins:\s*\[', src)
if m:
    # Walk to find matching closing bracket
    start = m.end()
    depth = 1
    i = start
    while i < len(src) and depth > 0:
        if src[i] == "[": depth += 1
        elif src[i] == "]": depth -= 1
        if depth == 0:
            break
        i += 1
    if depth == 0:
        src = src[:i] + pwa_plugin + "\n  " + src[i:]
with open(path, "w") as f:
    f.write(src)
print(f"  Wired VitePWA into {path}")
PYEOF
fi

# Generate PWA icon placeholders (SVG → PNG fallback: ship SVG if rasterizer absent)
log "  Generating PWA icon placeholders (initial=${INITIAL})…"
mkdir -p public/icons
for size in 192 512; do
  cat > "public/icons/icon-${size}.svg" <<EOSVG
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${size} ${size}" width="${size}" height="${size}">
  <rect width="${size}" height="${size}" fill="${THEME_COLOR}" rx="$((size / 8))"/>
  <text x="50%" y="50%" font-family="-apple-system, system-ui, sans-serif" font-size="$((size * 5 / 8))" font-weight="700" fill="#ffffff" text-anchor="middle" dominant-baseline="central">${INITIAL}</text>
</svg>
EOSVG
done
# Also emit fallback PNG copies if a rasterizer is available; otherwise warn.
if command -v rsvg-convert >/dev/null 2>&1; then
  for size in 192 512; do
    rsvg-convert -w "${size}" -h "${size}" "public/icons/icon-${size}.svg" -o "public/icons/icon-${size}.png" 2>/dev/null
  done
  log "  Rasterized icons via rsvg-convert."
else
  # Copy SVG to .png filename so the manifest reference resolves; warn the user
  for size in 192 512; do
    cp "public/icons/icon-${size}.svg" "public/icons/icon-${size}.png"
  done
  warn "  No SVG→PNG rasterizer found; icon-*.png is an SVG copy. Replace with a real PNG before production."
fi

ok "PWA wiring complete."

# -----------------------------------------------------------------------------
# Step 8 — Write README.md recording provenance
# -----------------------------------------------------------------------------
log "Writing README.md…"
cat > README.md <<EOF
# ${NAME_KEBAB}

Scaffolded by \`scripts/scaffold-react-vite.sh\` from artifact-refiner.

## Source

- **Refined artifact:** \`${SOURCE_TSX}\`
- **Brand:** \`${BRAND}\` (\`assets/library/brands/${BRAND}.toml\`)
- **Generated:** $(date -u +"%Y-%m-%dT%H:%M:%SZ")

## Stack

- React 19 + Vite 8 + TypeScript
- Tailwind v4 (CSS-first, no PostCSS)
- shadcn/ui on Base UI (\`--base base\`)
- Feature-based clean architecture (\`src/features/\`, \`src/shared/\`, \`src/app/\`)
- Kebab-case file naming throughout

## Run

\`\`\`bash
pnpm install
pnpm dev    # http://localhost:5173
pnpm build  # production build to dist/
\`\`\`

## Layout

See \`references/scaffolds/clean-architecture.md\` in the parent repo for
the full dependency rules.

\`\`\`
src/
├── app/                          # shell
├── features/${NAME_KEBAB}/          # this feature
└── shared/                       # shadcn components, utils, hooks
\`\`\`
EOF

# -----------------------------------------------------------------------------
# Step 9 — Verify build
# -----------------------------------------------------------------------------
log "Running pnpm install (in case shadcn add brought new deps)…"
pnpm install --silent 2>&1 | sed 's/^/  /' || {
  err "pnpm install failed"
  exit 1
}

log "Running pnpm build…"
pnpm build 2>&1 | sed 's/^/  /' || {
  err "pnpm build failed"
  err "Partial scaffold left for inspection at: ${TARGET}"
  exit 1
}

ok "Build successful."

# -----------------------------------------------------------------------------
# Step 10 — Optional Axum wrapper
# -----------------------------------------------------------------------------
if [[ ${WITH_AXUM} -eq 1 ]]; then
  log "Chaining into scaffold-react-vite-axum.sh…"
  bash "${SCRIPT_DIR}/scaffold-react-vite-axum.sh" --target "${TARGET}"
fi

if [[ ${WITH_TAURI} -eq 1 ]]; then
  log "Chaining into scaffold-react-vite-tauri.sh…"
  bash "${SCRIPT_DIR}/scaffold-react-vite-tauri.sh" --target "${TARGET}"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo
ok "Scaffold complete."
echo "  Path:        ${TARGET}"
echo "  Feature:     src/features/${NAME_KEBAB}/"
echo "  Brand:       ${BRAND}"
echo "  Run:         cd ${TARGET} && pnpm dev"
echo "  Build:       cd ${TARGET} && pnpm build"
if [[ ${WITH_AXUM} -eq 1 ]]; then
  echo "  Serve (Rust): cd ${TARGET}/server && cargo run --release"
fi
if [[ ${WITH_TAURI} -eq 1 ]]; then
  echo "  Tauri dev:    cd ${TARGET} && pnpm tauri dev"
  echo "  Tauri build:  cd ${TARGET} && pnpm tauri build"
fi
