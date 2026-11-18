#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:8080}"
COUNT="${2:-50000}"
ENDPOINT="${TARGET_URL%/}/api/lab/scenarios/06-goroutine-leak?count=${COUNT}"

echo "=========================================================="
echo "💣 Triggering Scenario 06: Goroutine Leak (${COUNT} goroutines)"
echo "🎯 Target: ${ENDPOINT}"
echo "=========================================================="

echo "Before trigger: querying active goroutines..."
curl -sS "${TARGET_URL%/}/api/lab/status" || true
echo ""

echo "Triggering leak..."
curl -sS -X POST "${ENDPOINT}"
echo ""

echo "After trigger: querying active goroutines..."
curl -sS "${TARGET_URL%/}/api/lab/status"
echo ""
