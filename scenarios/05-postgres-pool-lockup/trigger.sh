#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
CONCURRENCY="${2:-20}"
ENDPOINT="${TARGET_URL%/}/api/lab/scenarios/02-hang"

echo "=========================================================="
echo "💣 Triggering Scenario 05: Connection Pool Starvation"
echo "🎯 Concurrency: ${CONCURRENCY} simultaneous connections"
echo "🎯 Target: ${ENDPOINT}"
echo "=========================================================="

echo "Launching ${CONCURRENCY} parallel requests to exhaust connection pool..."
for i in $(seq 1 "$CONCURRENCY"); do
  curl -sS -X POST "${ENDPOINT}" > /dev/null &
done

sleep 1
echo "Checking health check response during pool exhaustion..."
curl -i -sS --max-time 5 "${TARGET_URL%/}/api/lab/status" || {
  echo ""
  echo "💥 Health check failed or timed out due to pool starvation!"
}

wait
echo ""
echo "✅ Pool starvation test completed."
