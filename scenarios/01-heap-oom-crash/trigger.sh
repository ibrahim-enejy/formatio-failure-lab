#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3000}"
ENDPOINT="${TARGET_URL%/}/api/lab/scenarios/01-oom"

echo "=========================================================="
echo "💣 Triggering Scenario 01: Unbounded Heap Allocation (OOM)"
echo "🎯 Target: ${ENDPOINT}"
echo "=========================================================="

echo "Sending request to trigger memory exhaustion..."
curl -sS -X POST "${ENDPOINT}" || {
  echo ""
  echo "💥 Connection closed or container crashed as expected (SIGKILL 137)!"
}

echo ""
echo "Checking status after crash trigger..."
curl -sS "${TARGET_URL%/}/api/lab/status" || echo "⚠️ Service is currently down or restarting."
