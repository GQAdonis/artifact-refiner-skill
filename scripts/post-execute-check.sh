#!/usr/bin/env bash
# post-execute-check.sh — SubagentStop hook for pmpo-executor
# Verifies that expected output files were created during execution
set -euo pipefail

MANIFEST="artifact_manifest.json"
LOG="refinement_log.md"

echo "🔍 Post-execution check..."

# Check manifest was updated
if [ ! -f "$MANIFEST" ]; then
  echo "⚠️  artifact_manifest.json not found after execution" >&2
fi

# Check dist/ has content
if [ ! -d "dist" ] || [ -z "$(ls -A dist 2>/dev/null)" ]; then
  echo "⚠️  dist/ directory is empty after execution" >&2
fi

# Check log was updated
if [ ! -f "$LOG" ]; then
  echo "⚠️  refinement_log.md not found" >&2
fi

echo "✅ Post-execution check complete"
exit 0
