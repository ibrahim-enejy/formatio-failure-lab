#!/usr/bin/env bash
set -euo pipefail

FORMATIO_URL="${FORMATIO_URL:-${1:-https://formatio.cloud}}"
API_BASE="${FORMATIO_URL%/}"

echo "=========================================================="
echo "Scenario 16: Project boundaries, SSO & REST API check"
echo "Control plane: ${API_BASE}"
echo "=========================================================="

if [ -z "${FORMATIO_ACCESS_TOKEN:-}" ]; then
  echo "FORMATIO_ACCESS_TOKEN is not set (printing REST API verification examples)."
  echo ""
  echo "1. Authenticate to obtain access + refresh tokens:"
  echo "   POST ${API_BASE}/api/user/authenticate/"
  echo "2. Query profile & explicitly scoped apps:"
  echo "   GET  ${API_BASE}/api/user/me/"
  echo "   GET  ${API_BASE}/api/application/?organization=<ORG_UUID>&limit=20"
  echo "3. Submit idempotent build request (preventing duplicate builds on network retry):"
  echo "   POST ${API_BASE}/api/application/<APP_UUID>/build/  -H 'Idempotency-Key: <UUID>'"
  exit 0
fi

echo "1. Checking GET /api/user/me/..."
curl -fsS -H "Authorization: Bearer ${FORMATIO_ACCESS_TOKEN}" \
  "${API_BASE}/api/user/me/"
echo ""

if [ -n "${ORGANIZATION_ID:-}" ]; then
  echo ""
  echo "2. Checking explicit organization scoping on GET /api/application/..."
  curl -fsS --get \
    -H "Authorization: Bearer ${FORMATIO_ACCESS_TOKEN}" \
    --data-urlencode "organization=${ORGANIZATION_ID}" \
    --data-urlencode "limit=20" \
    "${API_BASE}/api/application/"
  echo ""
else
  echo ""
  echo "Set ORGANIZATION_ID=<uuid> to verify explicit GET /api/application/ scoping."
fi
