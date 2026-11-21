#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
MODE="${2:-write}"
BASE="${TARGET_URL%/}"

echo "=========================================================="
echo "Scenario 09: Persistent volume survival check (${MODE})"
echo "Target: ${BASE}/api/lab/storage"
echo "=========================================================="

if [ "${MODE}" = "verify" ]; then
  echo "Reading markers after container restart or redeploy..."
  curl -fsS "${BASE}/api/lab/storage"
  echo ""
  echo ""
  echo "Expected after redeploy with named volume mounted at /data:"
  echo "  - ephemeral_present: false (/tmp resets on container replacement)"
  echo "  - persistent_present: true (/data survives across redeploys)"
  exit 0
fi

echo "Writing ephemeral (/tmp) and persistent (/data) markers..."
curl -fsS -X POST -H "Content-Type: application/json" \
  -d "{\"marker_id\":\"run-$(date +%s)\"}" \
  "${BASE}/api/lab/storage"
echo ""
echo ""
echo "Next steps:"
echo "  1. On Formatio, attach volume name 'lab-data' at mount path '/data' (Volumes tab)."
echo "  2. Run Deploy / Redeploy in the dashboard (or 'docker compose up -d --force-recreate node-express')."
echo "  3. Verify persistence with:"
echo "     ./scenarios/09-persistent-volume-and-terminal/trigger.sh ${BASE} verify"
