#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
ENDPOINT="${TARGET_URL%/}/api/lab/scenarios/02-hang"

echo "================================================================="
echo "💣 Triggering Scenario 02: 15-Second Hanging Webhook Starvation"
echo "🎯 Target: ${ENDPOINT}"
echo "================================================================="

echo "Firing hanging request in background..."
curl -sS -w "\nHTTP Status: %{http_code} | Total Time: %{time_total}s\n" -X POST "${ENDPOINT}" &
PID=$!

echo "Simulating simultaneous client request to healthy endpoint..."
sleep 1
curl -sS -w "Health check response time: %{time_total}s\n" "${TARGET_URL%/}/api/lab/status"

wait $PID
