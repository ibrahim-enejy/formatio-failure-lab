#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
BASE="${TARGET_URL%/}"

echo "=========================================================="
echo "Scenario 08: Healthcheck gate & 1-click Git rollback"
echo "Target: ${BASE}/healthz"
echo "=========================================================="

HTTP_CODE=$(curl -sS -o /tmp/formatio-healthz.json -w "%{http_code}" "${BASE}/healthz" || echo "000")
BODY=$(cat /tmp/formatio-healthz.json 2>/dev/null || echo "{}")
rm -f /tmp/formatio-healthz.json

echo "HTTP status: ${HTTP_CODE}"
echo "Response body: ${BODY}"
echo ""

if [ "${HTTP_CODE}" = "200" ]; then
  echo "Service is currently healthy (HTTP 200)."
  echo "To simulate a broken release inside Formatio:"
  echo "  1. Ensure at least one Successful deployment exists under Deployments."
  echo "  2. Set SIMULATE_BAD_HEALTHCHECK=true on the Environment tab and click Deploy / Redeploy."
  echo "  3. Re-run this script to verify HTTP 503 gating."
  echo "  4. Remove SIMULATE_BAD_HEALTHCHECK=true and click Rollback on your prior Successful commit."
elif [ "${HTTP_CODE}" = "503" ]; then
  echo "Readiness failure detected (HTTP 503). Formatio blocks broken traffic during start-first cutover."
  echo "Next step: open Deployments in Formatio Dashboard and click Rollback on your last Successful commit."
else
  echo "Container unreachable (HTTP ${HTTP_CODE}) — matches binding 127.0.0.1 instead of 0.0.0.0 or startup crash."
  echo "Next step: inspect Logs > Runtime and click Rollback on your last Successful commit."
fi
