#!/usr/bin/env bash
# Kimi Code (Moonshot) installer for artifact-refiner
#
# Kimi Code is an MCP host configured via ~/.kimi-code/config.toml with
# [mcp_servers.<name>] tables. This installer appends a marker-delimited
# [mcp_servers.template-forge] block. rust-mcp-filesystem is commonly already
# present in Kimi's config; this installer does not touch it.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

ENV_NAME="Kimi Code"

kimi_config() {
  echo "$HOME/.kimi-code/config.toml"
}

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Register the template-forge MCP server for Kimi Code (Moonshot).

Kimi Code consumes MCP servers via [mcp_servers.*] tables in:
  ~/.kimi-code/config.toml

Options:
  --uninstall   Remove the template-forge MCP block
  --help, -h    Show this help message

The config is backed up (.bak.<timestamp>) before every change.
Restart Kimi Code after installing.
EOF
}

main() {
  UNINSTALL=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --uninstall) UNINSTALL=true; shift ;;
      --global|--project) shift ;;
      --help|-h) show_help; exit 0 ;;
      *) error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  print_banner "$ENV_NAME"

  local repo_root config_path
  repo_root="$(resolve_repo_root)"
  config_path="$(kimi_config)"

  if [ "$UNINSTALL" = true ]; then
    info "Removing template-forge MCP block from Kimi Code..."
    unmerge_mcp_toml "$config_path"
    info "Restart Kimi Code to apply."
    return
  fi

  info "Registering template-forge MCP server for ${ENV_NAME}..."
  merge_mcp_toml "$config_path" "$repo_root"

  echo ""
  success "Done. Config: ${config_path}"
  info "Verify with:"
  echo "  grep -A2 'mcp_servers.template-forge' ${config_path}"
  echo ""
  warn "Restart Kimi Code for the new MCP server to load."
  echo ""
}

main "$@"
