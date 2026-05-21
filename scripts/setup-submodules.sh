#!/usr/bin/env bash
# One-shot setup for fresh clones.
#
# 1. Initialize/update all git submodules recursively.
# 2. Build any vendored binaries that aren't already on PATH.
# 3. Print a status summary.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

log()  { printf '\033[1;36m[setup-submodules]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[setup-submodules]\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

cd "${REPO_ROOT}"

log "Initializing submodules…"
git submodule update --init --recursive

log "Building vendored binaries…"
bash "${SCRIPT_DIR}/build-vendored-binaries.sh"

log "Status:"
git submodule status
echo

log "Binaries on PATH:"
for bin in rust-mcp-filesystem template-forge template-forge-mcp; do
  if have "$bin"; then
    printf '  ✓ %s — %s\n' "$bin" "$($bin --version 2>/dev/null | head -1)"
  else
    printf '  ✗ %s — not on PATH\n' "$bin"
  fi
done

log "Setup complete."
