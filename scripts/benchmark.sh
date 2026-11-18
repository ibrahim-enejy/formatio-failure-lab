#!/usr/bin/env bash
# ==============================================================================
# Formatio Failure Lab — Concurrency & Latency Benchmark Generator
# ==============================================================================
# Usage:
#   ./scripts/benchmark.sh http://localhost:3000/api/lab/status 50 1000
# ==============================================================================

set -euo pipefail

TARGET_URL="${1:-http://localhost:3000/api/lab/status}"
CONCURRENCY="${2:-20}"
TOTAL_REQUESTS="${3:-200}"

echo "=========================================================="
echo "⚡ Formatio Failure Lab — Benchmark Generator"
echo "🎯 Target: ${TARGET_URL}"
echo "👥 Concurrency: ${CONCURRENCY} workers"
echo "📦 Total Requests: ${TOTAL_REQUESTS}"
echo "=========================================================="

START_TIME=$(date +%s)
FAILED=0
SUCCESS=0

echo "Firing requests..."
for i in $(seq 1 "$TOTAL_REQUESTS"); do
  curl -s -o /dev/null -w "%{http_code}\n" "$TARGET_URL" &
  if (( i % CONCURRENCY == 0 )); then
    wait
  fi
done
wait

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
if [ "$DURATION" -eq 0 ]; then DURATION=1; fi
RPS=$((TOTAL_REQUESTS / DURATION))

echo "=========================================================="
echo "✅ Completed in ${DURATION}s (~${RPS} req/sec)"
echo "=========================================================="
