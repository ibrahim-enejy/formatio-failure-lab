#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
COUNT="${2:-5}"
MODE="${3:-}"
BASE="${TARGET_URL%/}"

PATH_SUFFIX="/checkout"
if [[ "${MODE}" == "--healthy" ]]; then
  PATH_SUFFIX="/checkout?healthy=1"
fi

echo "=========================================================="
echo "Scenario 17: Distributed checkout cascade (Node -> Go -> Python)"
echo "Target: ${BASE}${PATH_SUFFIX} (${COUNT}x)"
echo "=========================================================="

for i in $(seq 1 "${COUNT}"); do
  HTTP_CODE=$(curl -sk -o /tmp/formatio-s17.out -w "%{http_code}" "${BASE}${PATH_SUFFIX}" || echo "000")
  BODY=$(head -c 160 /tmp/formatio-s17.out 2>/dev/null | tr '\n' ' ')
  rm -f /tmp/formatio-s17.out
  printf "  %2s/%-2s HTTP %s  %s\n" "${i}" "${COUNT}" "${HTTP_CODE}" "${BODY}"
done

echo ""
echo "Inspect inside Formatio Dashboard:"
echo "  1. Tools > Traces -> open the trace across node-express -> go-gin -> python-fastapi."
echo "  2. Confirm the frontend 'price cart' span is flagged as origin above Python's TypeError."
