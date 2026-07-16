#!/usr/bin/env bash
# Claude Desktop installer for artifact-refiner
#
# Claude Desktop is an MCP host (not a skill runner), so this installer
# registers the artifact-refiner's local MCP servers — template-forge and
# rust-mcp-filesystem — in claude_desktop_config.json. Restart Claude Desktop
# after installing for the servers to be picked up.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

ENV_NAME="Claude Desktop"

claude_desktop_config() {
  echo "$HOME/Library/Application Support/Claude/claude_desktop_config.json"
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Register the Artifact Refiner MCP servers for Claude Desktop.

Claude Desktop consumes MCP servers, not Agent Skills, so this installer adds
the template-forge (and rust-mcp-filesystem, if available) MCP servers to:
  ~/Library/Application Support/Claude/claude_desktop_config.json

Options:
  --uninstall   Remove the artifact-refiner MCP servers
  --help, -h    Show this help message

The config is backed up (.bak.<timestamp>) before every change.
Restart Claude Desktop after installing.
EOF
}

main() {
  UNINSTALL=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --uninstall) UNINSTALL=true; shift ;;
      --global|--project) shift ;; # accepted for symmetry; Claude Desktop is user-global only
      --help|-h) show_help; exit 0 ;;
      *) error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  print_banner "$ENV_NAME"

  local repo_root config_path
  repo_root="$(resolve_repo_root)"
  config_path="$(claude_desktop_config)"

  if [ "$UNINSTALL" = true ]; then
    info "Removing artifact-refiner MCP servers from Claude Desktop..."
    unmerge_mcp_json "$config_path"
    info "Restart Claude Desktop to apply."
    return
  fi

  info "Registering artifact-refiner MCP servers for ${ENV_NAME}..."
  merge_mcp_json "$config_path" "$repo_root"

  echo ""
  success "Done. Config: ${config_path}"
  info "Verify with:"
  echo "  python3 -c 'import json;print(list(json.load(open(\"${config_path}\"))[\"mcpServers\"]))'"
  echo ""
  warn "Restart Claude Desktop for the new MCP servers to load."
  echo ""
}

main "$@"
