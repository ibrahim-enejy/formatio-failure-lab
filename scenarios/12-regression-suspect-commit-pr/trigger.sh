#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
BASE="${TARGET_URL%/}"

echo "=========================================================="
echo "Scenario 12: 1-line checkout regression -> AI advisor & fix PR"
echo "Target: ${BASE}/api/lab/scenarios/12-regression"
echo "=========================================================="

echo "Posting { amountCents: 4900 } without coupon object..."
curl -sS -i -X POST \
  -H "Content-Type: application/json" \
  -d '{"amountCents":4900}' \
  "${BASE}/api/lab/scenarios/12-regression" || true
echo ""
echo ""
echo "Next steps in Formatio Dashboard:"
echo "  1. Open Tools > Errors on this application."
echo "  2. Inspect suspect commit ranking, the built-in AI error advisor diagnosis (works out of the box),"
echo "     and the human-reviewed autonomous fix PR opened on your Git repository."
