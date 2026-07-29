#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

required_files=(
  ".claude-plugin/plugin.json"
  ".claude-plugin/marketplace.json"
  "skills/artifact-refiner/SKILL.md"
  "SKILL.md"
)

for file in "${required_files[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo "Missing required file: $file" >&2
    exit 1
  fi
done

jq empty .claude-plugin/plugin.json
jq empty .claude-plugin/marketplace.json
jq empty hooks/hooks.json
jq empty .mcp.optional.json.example

plugin_version="$(jq -r '.version' .claude-plugin/plugin.json)"
marketplace_version="$(jq -r '.plugins[] | select(.name == "artifact-refiner") | .version' .claude-plugin/marketplace.json)"
if [[ "$plugin_version" != "$marketplace_version" ]]; then
  echo "Version mismatch: plugin.json=$plugin_version marketplace.json=$marketplace_version" >&2
  exit 1
fi

if command -v claude >/dev/null 2>&1; then
  claude plugin validate . --strict
else
  echo "Warning: 'claude' CLI not found; skipped 'claude plugin validate . --strict'" >&2
fi

echo "Marketplace and plugin validation passed."
