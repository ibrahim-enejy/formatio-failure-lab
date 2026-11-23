#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
BASE="${TARGET_URL%/}"

echo "=========================================================="
echo "Scenario 12: 1-line checkout & shipping regressions -> Automatic fix PRs"
echo "Node target: ${BASE}"
echo "=========================================================="

echo "1) Healthy cart total (expect 200 {\"totalCents\":250}):"
curl -sS -i "${BASE}/ai-sre/cart-total" || true
echo ""

echo "2) Empty cart regression -> discount.js (expect 500 TypeError):"
curl -sS -i "${BASE}/ai-sre/cart-total?empty=1" || true
echo ""

echo "3) Missing coupon regression -> discount.js (expect 500 TypeError):"
curl -sS -i -X POST \
  -H "Content-Type: application/json" \
  -d '{"amountCents":4900}' \
  "${BASE}/api/lab/scenarios/12-regression" || true
echo ""

if [[ -n "${GO_TARGET:-}" ]]; then
  GO_BASE="${GO_TARGET%/}"
  echo ""
  echo "4) Go shipping pickup panic -> shipping_total.go (${GO_BASE}/ai-sre/shipping-total?pickup=1):"
  curl -sS -i "${GO_BASE}/ai-sre/shipping-total?pickup=1" || true
  echo ""
fi

echo ""
echo "Next steps in Formatio Dashboard:"
echo "  1. Open Tools > Errors on this application."
echo "  2. Inspect suspect commit attribution, built-in AI error advisor diagnosis,"
echo "     and the ready-to-review fix PR opened on your GitHub repository (or click Fix)."
