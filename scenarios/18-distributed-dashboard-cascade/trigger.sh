#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
COUNT="${2:-5}"
MODE="${3:-}"
BASE="${TARGET_URL%/}"

PATH_SUFFIX="/dashboard"
if [[ "${MODE}" == "--healthy" ]]; then
  PATH_SUFFIX="/dashboard?healthy=1"
fi

echo "=========================================================="
echo "Scenario 18: Deep rates-db outage cascade (Node -> Go -> Python -> Go)"
echo "Target: ${BASE}${PATH_SUFFIX} (${COUNT}x)"
echo "=========================================================="

for i in $(seq 1 "${COUNT}"); do
  HTTP_CODE=$(curl -sk -o /tmp/formatio-s18.out -w "%{http_code}" "${BASE}${PATH_SUFFIX}" || echo "000")
  BODY=$(head -c 160 /tmp/formatio-s18.out 2>/dev/null | tr '\n' ' ')
  rm -f /tmp/formatio-s18.out
  printf "  %2s/%-2s HTTP %s  %s\n" "${i}" "${COUNT}" "${HTTP_CODE}" "${BODY}"
done

echo ""
echo "Inspect inside Formatio Dashboard:"
echo "  1. Tools > Errors -> select the frontend TypeError and click its trace link."
echo "  2. Confirm Tools > Traces labels Go's 'query rates-db' connection refused as origin."
