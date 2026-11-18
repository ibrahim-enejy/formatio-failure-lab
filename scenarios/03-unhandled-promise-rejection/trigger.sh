#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
ENDPOINT="${TARGET_URL%/}/api/lab/scenarios/03-unhandled-rejection"

echo "=========================================================="
echo "💣 Triggering Scenario 03: Detached Async Unhandled Promise Rejection"
echo "🎯 Target: ${ENDPOINT}"
echo "=========================================================="

echo "Sending trigger request..."
curl -i -sS -X POST "${ENDPOINT}" || true

echo ""
echo "Waiting 500ms for detached promise to reject and terminate process..."
sleep 1

echo "Checking if service crashed and restarted..."
curl -i -sS --max-time 3 "${TARGET_URL%/}/api/lab/status" || {
  echo ""
  echo "💥 Service process crashed or restarting from unhandled rejection!"
}
