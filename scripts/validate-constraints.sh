#!/usr/bin/env bash
# validate-constraints.sh — Validate consumer constraints against this skill's schema.
# Usage: validate-constraints.sh [constraints.json]
# Requires Python 3 with jsonschema; missing validation support fails closed.
set -euo pipefail

CONSTRAINTS="${1:-constraints.json}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCHEMA="$SCRIPT_DIR/../references/schemas/constraints.schema.json"

if [ ! -f "$CONSTRAINTS" ]; then
  if [ $# -eq 0 ]; then
    echo "ℹ️  No constraints file yet — skipping validation"
    exit 0
  fi
  echo "❌ Constraints file not found: $CONSTRAINTS" >&2
  exit 2
fi

python3 - "$CONSTRAINTS" "$SCHEMA" <<'PY'
import json
import sys

try:
    from jsonschema import Draft7Validator
except ImportError:
    print("❌ Constraint validation requires Python package jsonschema", file=sys.stderr)
    sys.exit(2)

try:
    with open(sys.argv[1], encoding="utf-8") as handle:
        constraints = json.load(handle)
    with open(sys.argv[2], encoding="utf-8") as handle:
        schema = json.load(handle)
    Draft7Validator.check_schema(schema)
except (OSError, ValueError) as error:
    print(f"❌ Cannot read constraint input/schema: {error}", file=sys.stderr)
    sys.exit(2)

errors = sorted(Draft7Validator(schema).iter_errors(constraints),
                key=lambda error: tuple(str(part) for part in error.absolute_path))
if errors:
    for error in errors:
        path = "/" + "/".join(str(part) for part in error.absolute_path)
        print(f"❌ Constraint schema violation at {path} ({error.validator})", file=sys.stderr)
    sys.exit(2)

# A hook is optional in the schema; retain the existing advisory for blocking items.
for constraint in constraints["constraints"]:
    if constraint["severity"] == "blocking" and not constraint.get("validation"):
        print(f"⚠️  Blocking constraint '{constraint['id']}' has no validation hook",
              file=sys.stderr)
print("✅ Constraints schema valid")
PY
