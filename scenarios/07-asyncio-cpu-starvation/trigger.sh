#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:8000}"
BLOCK_MS="${2:-5000}"
ENDPOINT="${TARGET_URL%/}/api/lab/scenarios/07-asyncio-cpu-starvation?ms=${BLOCK_MS}"

echo "=========================================================="
echo "💣 Triggering Scenario 07: Python Asyncio Starvation (${BLOCK_MS}ms)"
echo "🎯 Target: ${ENDPOINT}"
echo "=========================================================="

echo "Launching blocking request in background..."
curl -sS -X POST "${ENDPOINT}" &
CURL_PID=$!

sleep 0.5
echo "Simulating concurrent user probe during event loop stall..."
START_PROBE=$(date +%s)
curl -sS --max-time 10 "${TARGET_URL%/}/api/lab/status" > /dev/null && {
  END_PROBE=$(date +%s)
  ELAPSED=$((END_PROBE - START_PROBE))
  echo "⚠️ Probe completed only after waiting ${ELAPSED}s (queued behind blocked ASGI loop)!"
} || {
  echo "💥 Probe timed out or rejected!"
}

wait $CURL_PID
echo ""
echo "✅ Scenario completed."
