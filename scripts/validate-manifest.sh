#!/usr/bin/env bash
# validate-manifest.sh — PostToolUse hook for artifact manifest validation
# Runs after Write/Edit operations to ensure manifest stays valid
set -euo pipefail

MANIFEST="artifact_manifest.json"
SCHEMA="references/schemas/artifact-manifest.schema.json"

# Only run if manifest exists (skip during initial setup)
if [ ! -f "$MANIFEST" ]; then
  echo "ℹ️  No manifest yet — skipping validation"
  exit 0
fi

# Check valid JSON
if ! python3 -c "import json; json.load(open('$MANIFEST'))" 2>/dev/null; then
  echo "❌ artifact_manifest.json is not valid JSON" >&2
  exit 2
fi

# Check required fields if schema exists
if [ -f "$SCHEMA" ]; then
  python3 -c "
import json, sys
with open('$MANIFEST') as f:
    manifest = json.load(f)
with open('$SCHEMA') as f:
    schema = json.load(f)
required = schema.get('required', [])
missing = [k for k in required if k not in manifest]
if missing:
    print(f'❌ Missing required fields: {missing}', file=sys.stderr)
    sys.exit(2)
print('✅ Manifest structure valid')
" 2>&1
fi

# Check file references
python3 -c "
import json, os, sys
with open('$MANIFEST') as f:
    manifest = json.load(f)
missing = []
for variant in manifest.get('variants', []):
    path = variant.get('path', variant.get('file', ''))
    if path and not os.path.exists(path):
        missing.append(path)
if missing:
    print(f'⚠️  Missing referenced files: {missing}', file=sys.stderr)
print('✅ Manifest file references checked')
" 2>&1

exit 0
