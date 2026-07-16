#!/usr/bin/env bash
# MiniMax Code installer for artifact-refiner
#
# MiniMax Code supports BOTH Agent Skills (SKILL.md) and MCP servers:
#   - Skills live in   ~/.minimax/skills/<name>/
#   - MCP servers in    ~/.minimax/mcp/mcp.json  (an "mcpServers" object)
# This installer symlinks the skill and registers the template-forge MCP server.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../common.sh"

ENV_NAME="MiniMax Code"

minimax_skills_dir() { echo "$HOME/.minimax/skills"; }
minimax_mcp_config()  { echo "$HOME/.minimax/mcp/mcp.json"; }

show_help() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Install the Artifact Refiner for MiniMax Code as a skill AND MCP server.

  Skill: symlink into ~/.minimax/skills/artifact-refiner
  MCP:   template-forge (+ rust-mcp-filesystem) into ~/.minimax/mcp/mcp.json

Options:
  --skill-only  Install only the skill symlink (no MCP changes)
  --mcp-only    Register only the MCP server (no skill symlink)
  --uninstall   Remove both the skill symlink and the MCP servers
  --help, -h    Show this help message

The mcp.json is backed up (.bak.<timestamp>) before every change.
Restart MiniMax Code after installing.
EOF
}

main() {
  UNINSTALL=false
  DO_SKILL=true
  DO_MCP=true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --uninstall) UNINSTALL=true; shift ;;
      --skill-only) DO_MCP=false; shift ;;
      --mcp-only) DO_SKILL=false; shift ;;
      --global|--project) shift ;;
      --help|-h) show_help; exit 0 ;;
      *) error "Unknown option: $1"; show_help; exit 1 ;;
    esac
  done

  print_banner "$ENV_NAME"

  local repo_root skills_dir skill_link mcp_config
  repo_root="$(resolve_repo_root)"
  skills_dir="$(minimax_skills_dir)"
  skill_link="${skills_dir}/${SKILL_NAME}"
  mcp_config="$(minimax_mcp_config)"

  if [ "$UNINSTALL" = true ]; then
    info "Uninstalling from MiniMax Code..."
    remove_symlink "$skill_link" "$repo_root"
    unmerge_mcp_json "$mcp_config"
    info "Restart MiniMax Code to apply."
    return
  fi

  if [ "$DO_SKILL" = true ]; then
    info "Installing ${SKILL_NAME} skill for ${ENV_NAME}..."
    mkdir -p "$skills_dir"
    create_symlink "$repo_root" "$skill_link"
  fi

  if [ "$DO_MCP" = true ]; then
    info "Registering artifact-refiner MCP servers for ${ENV_NAME}..."
    merge_mcp_json "$mcp_config" "$repo_root"
  fi

  echo ""
  success "Done."
  info "Verify with:"
  [ "$DO_SKILL" = true ] && echo "  ls -la ${skill_link}"
  [ "$DO_MCP" = true ] && echo "  python3 -c 'import json;print(list(json.load(open(\"${mcp_config}\"))[\"mcpServers\"]))'"
  echo ""
  warn "Restart MiniMax Code for the skill and MCP servers to load."
  echo ""
}

main "$@"
