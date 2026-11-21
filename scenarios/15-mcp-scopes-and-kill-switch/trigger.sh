#!/usr/bin/env bash
set -euo pipefail

FORMATIO_URL="${FORMATIO_URL:-${1:-https://formatio.cloud}}"
MCP_URL="${FORMATIO_URL%/}/mcp"

echo "=========================================================="
echo "Scenario 15: /mcp scope check & agent_access kill switch"
echo "MCP endpoint: ${MCP_URL}"
echo "=========================================================="

if [ -z "${FORMATIO_MCP_TOKEN:-}" ]; then
  echo "FORMATIO_MCP_TOKEN is not set (printing verification guide)."
  echo ""
  echo "To run live scope & kill-switch checks:"
  echo "  1. Create a read-only token under Settings > Access tokens."
  echo "  2. Run: FORMATIO_MCP_TOKEN=... ./scenarios/15-mcp-scopes-and-kill-switch/trigger.sh"
  echo "  3. Confirm tools/list passes, write actions are denied, then toggle organization"
  echo "     agent_access OFF and re-run to confirm immediate HTTP 401/403 block."
  exit 0
fi

echo "1. Testing tools/list with current token..."
STATUS_LIST=$(curl -sS -o /tmp/mcp-tools.json -w "%{http_code}" -X POST "${MCP_URL}" \
  -H "Authorization: Bearer ${FORMATIO_MCP_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' || echo "000")
echo "   HTTP ${STATUS_LIST}"
cat /tmp/mcp-tools.json 2>/dev/null | head -c 400 || true
echo ""
rm -f /tmp/mcp-tools.json

echo ""
echo "2. Testing write boundary (calling deploy_application with dummy ID)..."
STATUS_WRITE=$(curl -sS -o /tmp/mcp-write.json -w "%{http_code}" -X POST "${MCP_URL}" \
  -H "Authorization: Bearer ${FORMATIO_MCP_TOKEN}" \
  -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"deploy_application","arguments":{"application":"00000000-0000-0000-0000-000000000000"}}}' || echo "000")
echo "   HTTP ${STATUS_WRITE}"
cat /tmp/mcp-write.json 2>/dev/null | head -c 400 || true
echo ""
rm -f /tmp/mcp-write.json

echo ""
echo "Next: turn organization agent_access OFF inside Formatio and re-run this script"
echo "to verify instant kill-switch blocking before restoring agent_access ON."
