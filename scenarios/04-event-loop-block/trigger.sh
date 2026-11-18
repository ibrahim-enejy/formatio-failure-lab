#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
BLOCK_MS="${2:-5000}"
ENDPOINT="${TARGET_URL%/}/api/lab/scenarios/04-event-loop-block?ms=${BLOCK_MS}"

echo "=========================================================="
echo "💣 Triggering Scenario 04: Event Loop Starvation (${BLOCK_MS}ms)"
echo "🎯 Target: ${ENDPOINT}"
echo "=========================================================="

echo "Launching blocking request in background..."
curl -sS -X POST "${ENDPOINT}" &
CURL_PID=$!

sleep 0.5
echo "Simulating concurrent user / health-check probe during block..."
START_PROBE=$(date +%s)
curl -sS --max-time 10 "${TARGET_URL%/}/api/lab/status" > /dev/null && {
  END_PROBE=$(date +%s)
  ELAPSED=$((END_PROBE - START_PROBE))
  echo "⚠️ Probe completed only after waiting ${ELAPSED}s (queued behind blocked event loop)!"
} || {
  echo "💥 Probe timed out or rejected!"
}

wait $CURL_PID
echo ""
echo "✅ Scenario completed."
