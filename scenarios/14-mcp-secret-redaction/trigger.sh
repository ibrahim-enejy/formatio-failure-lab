#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
BASE="${TARGET_URL%/}"
FORMATIO_URL="${FORMATIO_URL:-https://formatio.cloud}"

echo "=========================================================="
echo "Scenario 14: /mcp secret redaction & safe agent triage"
echo "App target: ${BASE}"
echo "=========================================================="

echo "1. Triggering PaymentGatewayConfigError (logs boolean presence only, never secret values)..."
curl -sS -i -X POST "${BASE}/api/lab/scenarios/14-secret-crash" || true
echo ""

if [ -n "${FORMATIO_MCP_TOKEN:-}" ]; then
  echo ""
  echo "2. Querying Formatio MCP (${FORMATIO_URL%/}/mcp) for available tools and redacted metadata..."
  curl -fsS -X POST "${FORMATIO_URL%/}/mcp" \
    -H "Authorization: Bearer ${FORMATIO_MCP_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
  echo ""
  echo ""
  curl -fsS -X POST "${FORMATIO_URL%/}/mcp" \
    -H "Authorization: Bearer ${FORMATIO_MCP_TOKEN}" \
    -H "Content-Type: application/json" \
    --data '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"list_applications","arguments":{}}}'
  echo ""
else
  echo ""
  echo "Tip: export FORMATIO_MCP_TOKEN and re-run this script to test live"
  echo "POST ${FORMATIO_URL%/}/mcp redaction with get_application / list_issues."
fi
