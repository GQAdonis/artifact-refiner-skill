#!/usr/bin/env bash
# Probe the openai-proxy /health endpoint.
#
# Exit 0 with `READY: <body>`     when reachable + 2xx.
# Exit 1 with `NOT_READY: <reason>` otherwise.
#
# Configurable URL via env var:
#   OPENAI_PROXY_HEALTH_URL (default: http://localhost:8181/health)
#
# No retry — the consumer decides retry policy. 2-second timeout.
set -uo pipefail

URL="${OPENAI_PROXY_HEALTH_URL:-http://localhost:8181/health}"

if ! command -v curl >/dev/null 2>&1; then
  echo "NOT_READY: curl not installed"
  exit 1
fi

# -s silent, -S show errors, -f fail on >=400, -L follow redirects,
# -m 2 max time 2s, -w write status code on success
response=$(curl -sS -L -m 2 -w '\n__HTTP_STATUS__:%{http_code}' "${URL}" 2>&1)
rc=$?

if [[ $rc -ne 0 ]]; then
  # curl error path — connection refused, timeout, DNS, etc.
  reason=$(echo "${response}" | tr '\n' ' ' | sed 's/  */ /g' | head -c 160)
  echo "NOT_READY: ${reason}"
  exit 1
fi

status=$(echo "${response}" | grep __HTTP_STATUS__ | tail -1 | cut -d: -f2)
body=$(echo "${response}" | sed '$d' | tr '\n' ' ' | sed 's/  */ /g' | head -c 160)

if [[ "${status}" =~ ^2[0-9][0-9]$ ]]; then
  # Fingerprint check: openai-proxy /health returns a JSON object with at least
  # one of these keys. HTML responses or other apps on the same port are
  # NOT_READY even though they returned 200.
  if echo "${body}" | grep -qE '"(status|version|ok|healthy|service)"[[:space:]]*:'; then
    echo "READY: ${body}"
    exit 0
  fi
  echo "NOT_READY: HTTP 200 but body did not match openai-proxy fingerprint — ${body}"
  exit 1
fi

echo "NOT_READY: HTTP ${status} — ${body}"
exit 1
