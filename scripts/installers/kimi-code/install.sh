#!/usr/bin/env bash
# Kimi Code (Moonshot) installer for artifact-refiner
#
# Kimi Code is both a skill runner and an MCP host:
#   - Skills live in    ~/.kimi-code/skills/<name>/   (SKILL.md format)
#   - MCP servers in    ~/.kimi-code/config.toml      ([mcp_servers.<name>] tables)
#
# By default this installer symlinks the skill. MCP registration is opt-in via
# --with-mcp, because template-forge is frequently already reachable through an
# existing SSE registration (commonly [mcp_servers.forge-rs]) and registering it
# a second time over stdio gives the host two routes to the same tools.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

ENV_NAME="Kimi Code"

kimi_skills_dir() { echo "$HOME/.kimi-code/skills"; }
kimi_config()     { echo "$HOME/.kimi-code/config.toml"; }

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install the Artifact Refiner skill for Kimi Code (Moonshot).

  Skill: symlink into ~/.kimi-code/skills/artifact-refiner   (default)
  MCP:   template-forge into ~/.kimi-code/config.toml        (--with-mcp)

Options:
  --with-mcp    Also register the template-forge MCP server
  --mcp-only    Register only the MCP server (no skill symlink)
  --uninstall   Remove the skill symlink and the MCP block
  --help, -h    Show this help message

Before using --with-mcp, check for an existing template-forge registration:
  grep -n 'mcp_servers' ~/.kimi-code/config.toml

The config is backed up (.bak.<timestamp>) before every change.
Restart Kimi Code after installing.
EOF
}

main() {
  UNINSTALL=false
  DO_SKILL=true
  DO_MCP=false
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --uninstall) UNINSTALL=true; DO_MCP=true; shift ;;
      --with-mcp)  DO_MCP=true; shift ;;
      --mcp-only)  DO_MCP=true; DO_SKILL=false; shift ;;
      --skill-only) DO_MCP=false; shift ;;
      --global|--project) shift ;;
      --help|-h) show_help; exit 0 ;;
      *) error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  print_banner "$ENV_NAME"

  local repo_root skills_dir skill_link config_path
  repo_root="$(resolve_repo_root)"
  skills_dir="$(kimi_skills_dir)"
  skill_link="${skills_dir}/${SKILL_NAME}"
  config_path="$(kimi_config)"

  if [ "$UNINSTALL" = true ]; then
    info "Uninstalling from ${ENV_NAME}..."
    remove_symlink "$skill_link" "$repo_root"
    unmerge_mcp_toml "$config_path"
    info "Restart Kimi Code to apply."
    return
  fi

  if [ "$DO_SKILL" = true ]; then
    info "Installing ${SKILL_NAME} skill for ${ENV_NAME}..."
    mkdir -p "$skills_dir"
    create_symlink "$repo_root" "$skill_link"
  fi

  if [ "$DO_MCP" = true ]; then
    info "Registering template-forge MCP server for ${ENV_NAME}..."
    merge_mcp_toml "$config_path" "$repo_root"
  else
    info "Skipping MCP registration (pass --with-mcp to enable)."
  fi

  echo ""
  success "Done."
  info "Verify with:"
  [ "$DO_SKILL" = true ] && echo "  ls -la ${skill_link}"
  [ "$DO_MCP" = true ] && echo "  grep -A2 'mcp_servers.template-forge' ${config_path}"
  echo ""
  warn "Restart Kimi Code so it reloads its skill and MCP configuration."
  echo ""
}

main "$@"
