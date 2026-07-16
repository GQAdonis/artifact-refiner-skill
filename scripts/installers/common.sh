#!/usr/bin/env bash
# common.sh — Shared helper functions for artifact-refiner installer scripts
# Source this file from individual installer scripts.
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/GQAdonis/artifact-refiner-skill"
SKILL_NAME="artifact-refiner"

info()    { echo -e "${BLUE}ℹ${NC}  $*"; }
success() { echo -e "${GREEN}✅${NC} $*"; }
warn()    { echo -e "${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "${RED}❌${NC} $*" >&2; }

# Resolve the absolute path of the artifact-refiner repo root.
# Works whether called from the repo directly or via a symlink.
resolve_repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  # Walk up from scripts/installers/<env>/ to repo root
  echo "$(cd "${script_dir}/../../.." && pwd)"
}

# Create a symlink, handling existing links/directories gracefully.
# Usage: create_symlink <source> <target>
create_symlink() {
  local source="$1"
  local target="$2"

  if [ -L "$target" ]; then
    local existing
    existing="$(readlink "$target")"
    if [ "$existing" = "$source" ]; then
      info "Symlink already exists: $target → $source"
      return 0
    else
      warn "Updating existing symlink: $target"
      warn "  Old: $existing"
      warn "  New: $source"
      rm "$target"
    fi
  elif [ -e "$target" ]; then
    error "Target already exists and is not a symlink: $target"
    error "Please remove or rename it first, then re-run this script."
    exit 1
  fi

  ln -s "$source" "$target"
  success "Created symlink: $target → $source"
}

# Remove a symlink if it exists and points to our repo.
# Usage: remove_symlink <target> <expected_source>
remove_symlink() {
  local target="$1"
  local expected_source="$2"

  if [ -L "$target" ]; then
    local existing
    existing="$(readlink "$target")"
    if [ "$existing" = "$expected_source" ]; then
      rm "$target"
      success "Removed symlink: $target"
    else
      warn "Symlink exists but points elsewhere: $target → $existing"
      warn "Skipping removal (not ours)."
    fi
  elif [ -e "$target" ]; then
    warn "Target is not a symlink: $target — skipping."
  else
    info "Nothing to remove: $target does not exist."
  fi
}

# Parse common flags: --global, --project, --uninstall, --help
parse_flags() {
  INSTALL_SCOPE="global"
  UNINSTALL=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --global)  INSTALL_SCOPE="global"; shift ;;
      --project) INSTALL_SCOPE="project"; shift ;;
      --uninstall) UNINSTALL=true; shift ;;
      --help|-h) show_help; exit 0 ;;
      *) error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done
}

# Print the repo banner
print_banner() {
  local env_name="$1"
  echo ""
  echo -e "${BLUE}╔══════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC}  Artifact Refiner — ${env_name} Installer           ${BLUE}║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════╝${NC}"
  echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# MCP server registration helpers
#
# The artifact-refiner ships local MCP servers. For MCP-host environments
# (Claude Desktop, MiniMax Code, Kimi Code) we register them in the host's
# config. Every server object we add carries a marker so uninstall can remove
# exactly what we added and nothing else.
# ─────────────────────────────────────────────────────────────────────────────

MCP_MARKER="artifact-refiner"

# Resolve the template-forge MCP binary (installed to ~/.cargo/bin, or on PATH).
resolve_forge_mcp_bin() {
  if [ -x "$HOME/.cargo/bin/template-forge-mcp" ]; then
    echo "$HOME/.cargo/bin/template-forge-mcp"
  elif command -v template-forge-mcp >/dev/null 2>&1; then
    command -v template-forge-mcp
  else
    echo ""
  fi
}

# Resolve the rust-mcp-filesystem binary if present.
resolve_fs_mcp_bin() {
  if command -v rust-mcp-filesystem >/dev/null 2>&1; then
    command -v rust-mcp-filesystem
  elif [ -x "$HOME/.cargo/bin/rust-mcp-filesystem" ]; then
    echo "$HOME/.cargo/bin/rust-mcp-filesystem"
  else
    echo ""
  fi
}

# Merge our MCP servers into a JSON config file with an "mcpServers" object.
# Creates the file and/or key if missing. Backs up first. Idempotent.
# Usage: merge_mcp_json <config_path> <repo_root>
merge_mcp_json() {
  local config_path="$1"
  local repo_root="$2"
  local forge_bin fs_bin
  forge_bin="$(resolve_forge_mcp_bin)"
  fs_bin="$(resolve_fs_mcp_bin)"

  if [ -z "$forge_bin" ]; then
    error "template-forge-mcp binary not found. Run: scripts/build-vendored-binaries.sh and cargo install --path tools/template-forge-rs/crates/template-mcp"
    return 1
  fi

  mkdir -p "$(dirname "$config_path")"
  [ -f "$config_path" ] && cp "$config_path" "${config_path}.bak.$(date +%Y%m%d%H%M%S)"

  REPO_ROOT="$repo_root" FORGE_BIN="$forge_bin" FS_BIN="$fs_bin" MARKER="$MCP_MARKER" \
  python3 - "$config_path" <<'PYEOF'
import json, os, sys

path = sys.argv[1]
repo = os.environ["REPO_ROOT"]
forge = os.environ["FORGE_BIN"]
fs = os.environ.get("FS_BIN", "")
marker = os.environ["MARKER"]

try:
    with open(path) as f:
        cfg = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    cfg = {}

servers = cfg.setdefault("mcpServers", {})

servers["template-forge"] = {
    "command": forge,
    "args": [
        "--library", os.path.join(repo, "assets", "library"),
        "--templates-base", os.path.join(repo, "tools", "template-forge-rs", "templates"),
    ],
    "_managedBy": marker,
}

if fs:
    servers["rust-mcp-filesystem"] = {
        "command": fs,
        "args": [repo],
        "_managedBy": marker,
    }

with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")

print("registered: template-forge" + (", rust-mcp-filesystem" if fs else ""))
PYEOF
}

# Remove our marked MCP servers from a JSON config file. Idempotent.
# Usage: unmerge_mcp_json <config_path>
unmerge_mcp_json() {
  local config_path="$1"
  [ -f "$config_path" ] || { info "Nothing to remove: $config_path does not exist."; return 0; }
  cp "$config_path" "${config_path}.bak.$(date +%Y%m%d%H%M%S)"

  MARKER="$MCP_MARKER" python3 - "$config_path" <<'PYEOF'
import json, os, sys
path = sys.argv[1]
marker = os.environ["MARKER"]
try:
    with open(path) as f:
        cfg = json.load(f)
except (FileNotFoundError, json.JSONDecodeError):
    sys.exit(0)
servers = cfg.get("mcpServers", {})
removed = [k for k, v in list(servers.items())
           if isinstance(v, dict) and v.get("_managedBy") == marker]
for k in removed:
    del servers[k]
with open(path, "w") as f:
    json.dump(cfg, f, indent=2)
    f.write("\n")
print("removed: " + (", ".join(removed) if removed else "(none)"))
PYEOF
}

# Append our MCP server as a marker-delimited TOML block. Idempotent.
# Usage: merge_mcp_toml <config_path> <repo_root>
merge_mcp_toml() {
  local config_path="$1"
  local repo_root="$2"
  local forge_bin
  forge_bin="$(resolve_forge_mcp_bin)"

  if [ -z "$forge_bin" ]; then
    error "template-forge-mcp binary not found. Build + cargo install it first."
    return 1
  fi

  mkdir -p "$(dirname "$config_path")"
  touch "$config_path"

  local begin="# >>> ${MCP_MARKER} (template-forge) >>>"
  local end="# <<< ${MCP_MARKER} (template-forge) <<<"

  if grep -qF "$begin" "$config_path" 2>/dev/null; then
    info "config.toml already contains the template-forge block — skipping."
    return 0
  fi

  cp "$config_path" "${config_path}.bak.$(date +%Y%m%d%H%M%S)"
  {
    echo ""
    echo "$begin"
    echo "[mcp_servers.template-forge]"
    echo "command = \"${forge_bin}\""
    printf 'args = [ "--library", "%s/assets/library", "--templates-base", "%s/tools/template-forge-rs/templates" ]\n' "$repo_root" "$repo_root"
    echo "$end"
  } >> "$config_path"
  success "Added [mcp_servers.template-forge] to ${config_path}"
}

# Remove our marker-delimited TOML block. Idempotent.
# Usage: unmerge_mcp_toml <config_path>
unmerge_mcp_toml() {
  local config_path="$1"
  [ -f "$config_path" ] || { info "Nothing to remove: $config_path does not exist."; return 0; }
  local begin="# >>> ${MCP_MARKER} (template-forge) >>>"
  local end="# <<< ${MCP_MARKER} (template-forge) <<<"
  if ! grep -qF "$begin" "$config_path" 2>/dev/null; then
    info "No template-forge block found in ${config_path}."
    return 0
  fi
  cp "$config_path" "${config_path}.bak.$(date +%Y%m%d%H%M%S)"
  BEGIN="$begin" END="$end" python3 - "$config_path" <<'PYEOF'
import os, sys
path = sys.argv[1]
begin, end = os.environ["BEGIN"], os.environ["END"]
with open(path) as f:
    lines = f.readlines()
out, skip = [], False
for ln in lines:
    if ln.strip() == begin:
        skip = True
        continue
    if ln.strip() == end:
        skip = False
        continue
    if not skip:
        out.append(ln)
# drop a trailing blank line left by the block
while out and out[-1].strip() == "":
    out.pop()
out.append("\n")
with open(path, "w") as f:
    f.writelines(out)
print("removed template-forge block")
PYEOF
  success "Removed template-forge block from ${config_path}"
}
