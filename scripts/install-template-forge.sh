#!/usr/bin/env bash
# Install template-forge and template-forge-mcp into PATH.
#
# Probe order:
#   1. Both binaries already on PATH       → skip
#   2. cargo-binstall (releases not yet published) → may fail; that is OK
#   3. cargo install --path from source    → fallback
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WORKSPACE="${REPO_ROOT}/tools/template-forge-rs"

log()  { printf '\033[1;36m[install-template-forge]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[install-template-forge]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[install-template-forge]\033[0m %s\n' "$*" >&2; }

have() { command -v "$1" >/dev/null 2>&1; }

if have template-forge && have template-forge-mcp; then
  log "Both binaries already on PATH; nothing to install."
  template-forge --version
  template-forge-mcp --version
  exit 0
fi

if [[ ! -d "${WORKSPACE}" ]]; then
  err "Workspace not found at ${WORKSPACE}"
  exit 1
fi

if ! have cargo; then
  err "cargo not found. Install Rust from https://rustup.rs/ then re-run."
  exit 1
fi

# Try cargo-binstall first if available (will fail until releases exist).
if have cargo-binstall; then
  log "Attempting cargo-binstall (may fail if releases not yet published)…"
  if cargo binstall --no-confirm --quiet template-cli template-mcp 2>/dev/null; then
    log "binstall succeeded"
  else
    warn "cargo-binstall not yet usable; falling back to cargo install --path."
  fi
fi

# Source-install fallback.
if ! have template-forge; then
  log "Installing template-forge from ${WORKSPACE}/crates/template-cli …"
  cargo install --path "${WORKSPACE}/crates/template-cli" --locked
fi

if ! have template-forge-mcp; then
  log "Installing template-forge-mcp from ${WORKSPACE}/crates/template-mcp …"
  cargo install --path "${WORKSPACE}/crates/template-mcp" --locked
fi

log "Installed:"
template-forge --version
template-forge-mcp --version
