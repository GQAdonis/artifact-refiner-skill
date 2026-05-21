#!/usr/bin/env bash
# Pure-bash helpers for converting identifiers to kebab-case.
#
# Sourced by other scripts:
#   . scripts/lib/kebab-case.sh
#   to_kebab "HeroSection"     # → hero-section
#   to_kebab "useDarkMode"     # → use-dark-mode
#   to_kebab "APIClient"       # → api-client
#   to_kebab "OAuth2Client"    # → o-auth-2-client
#
# Heuristics (see references/scaffolds/kebab-case-rename.md):
#   1. Insert `-` between word groups (PascalCase, camelCase)
#   2. Collapse consecutive uppercase letters as acronyms
#   3. Treat digits as word boundaries
#   4. Lowercase final result
#   5. Trim leading/trailing dashes; collapse repeated dashes

to_kebab() {
  local input="$1"
  # Use sed in a pipe; portable across macOS BSD sed and GNU sed.
  printf '%s' "$input" \
    | sed -E 's/([A-Z]+)([A-Z][a-z])/\1-\2/g' \
    | sed -E 's/([a-z])([A-Z])/\1-\2/g' \
    | sed -E 's/([A-Za-z])([0-9])/\1-\2/g' \
    | sed -E 's/([0-9])([A-Za-z])/\1-\2/g' \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/--+/-/g; s/^-//; s/-$//'
}

# rename_file_kebab <path>
# Renames the *basename* of <path> to kebab-case, preserving the directory and
# the extension chain (.types.ts, .test.tsx, etc.). Echoes the new path.
rename_file_kebab() {
  local path="$1"
  local dir base name ext_chain

  dir="$(dirname "$path")"
  base="$(basename "$path")"

  # Split off ALL trailing dot-extensions (.tsx, .types.ts, .test.tsx, etc.)
  # Strategy: find the first `.` after position 0 and call everything after it
  # the extension chain.
  if [[ "$base" == *.* ]]; then
    name="${base%%.*}"
    ext_chain=".${base#*.}"
  else
    name="$base"
    ext_chain=""
  fi

  local kebab
  kebab="$(to_kebab "$name")"
  printf '%s/%s%s\n' "$dir" "$kebab" "$ext_chain"
}

# Self-test mode: run `bash scripts/lib/kebab-case.sh --test` to verify.
if [[ "${1:-}" == "--test" ]]; then
  fail=0
  expect() {
    local actual="$1" expected="$2" label="$3"
    if [[ "$actual" == "$expected" ]]; then
      printf '  OK   %-30s = %s\n' "$label" "$actual"
    else
      printf '  FAIL %-30s expected=%s actual=%s\n' "$label" "$expected" "$actual"
      fail=1
    fi
  }

  expect "$(to_kebab "HeroSection")"        "hero-section"        "to_kebab PascalCase"
  expect "$(to_kebab "useDarkMode")"        "use-dark-mode"       "to_kebab camelCase"
  expect "$(to_kebab "APIClient")"          "api-client"          "to_kebab acronym"
  expect "$(to_kebab "useURLState")"        "use-url-state"       "to_kebab acronym in hook"
  expect "$(to_kebab "OAuth2Client")"       "o-auth-2-client"     "to_kebab digit"
  expect "$(to_kebab "Component2")"         "component-2"         "to_kebab trailing digit"
  expect "$(to_kebab "alreadyKebab")"       "already-kebab"       "to_kebab simple camel"
  expect "$(to_kebab "App")"                "app"                 "to_kebab single word"
  expect "$(to_kebab "lowercase")"          "lowercase"           "to_kebab already lowercase"

  expect "$(rename_file_kebab "src/HeroSection.tsx")"           "src/hero-section.tsx"      "rename .tsx"
  expect "$(rename_file_kebab "src/useDarkMode.ts")"            "src/use-dark-mode.ts"      "rename .ts"
  expect "$(rename_file_kebab "src/UserProfile.types.ts")"      "src/user-profile.types.ts" "rename .types.ts"
  expect "$(rename_file_kebab "src/components/AuthService.ts")" "src/components/auth-service.ts" "rename nested"

  exit "$fail"
fi
