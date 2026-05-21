#!/usr/bin/env bash
# Build and install vendored MCP server binaries.
#
# Currently:
#   - rust-mcp-filesystem (submodule at tools/rust-mcp-filesystem)
#
# Probe order:
#   1. Binary already on PATH                       → skip
#   2. Package-manager install (Homebrew, npm)      → if available
#   3. cargo-binstall from upstream releases        → if available
#   4. Build from submodule via cargo install       → fallback
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
FS_SUBMODULE="${REPO_ROOT}/tools/rust-mcp-filesystem"

log()  { printf '\033[1;36m[build-vendored]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[build-vendored]\033[0m %s\n' "$*" >&2; }
err()  { printf '\033[1;31m[build-vendored]\033[0m %s\n' "$*" >&2; }
have() { command -v "$1" >/dev/null 2>&1; }

###############
# rust-mcp-filesystem
###############
install_rust_mcp_filesystem() {
  if have rust-mcp-filesystem; then
    log "rust-mcp-filesystem already on PATH"
    rust-mcp-filesystem --version || true
    return 0
  fi

  if have brew; then
    log "Trying Homebrew install…"
    if brew install rust-mcp-stack/tap/rust-mcp-filesystem 2>/dev/null; then
      log "Homebrew install succeeded"
      return 0
    fi
    warn "Homebrew install failed; trying next fallback"
  fi

  if have cargo-binstall; then
    log "Trying cargo-binstall…"
    if cargo binstall --no-confirm --quiet rust-mcp-filesystem 2>/dev/null; then
      log "cargo-binstall succeeded"
      return 0
    fi
    warn "cargo-binstall failed; trying source build"
  fi

  if [[ ! -d "${FS_SUBMODULE}" ]] || [[ -z "$(ls -A "${FS_SUBMODULE}" 2>/dev/null)" ]]; then
    err "Submodule ${FS_SUBMODULE} not initialized. Run: git submodule update --init --recursive"
    return 1
  fi

  if ! have cargo; then
    err "cargo not found. Install Rust from https://rustup.rs/ then re-run."
    return 1
  fi

  log "Building rust-mcp-filesystem from submodule…"
  cargo install --path "${FS_SUBMODULE}" --locked
}

install_rust_mcp_filesystem

log "All vendored binaries available:"
rust-mcp-filesystem --version 2>/dev/null || warn "rust-mcp-filesystem missing"
