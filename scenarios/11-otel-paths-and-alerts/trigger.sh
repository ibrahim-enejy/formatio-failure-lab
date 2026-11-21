#!/usr/bin/env bash
set -euo pipefail

TARGET_URL="${1:-http://localhost:3001}"
BASE="${TARGET_URL%/}"

echo "=========================================================="
echo "Scenario 11: OTel SDK path (Next.js 15) & alert trigger"
echo "Target: ${BASE}"
echo "=========================================================="

echo "1. Recording a healthy traced Route Handler span (?healthy=1)..."
curl -fsS -X POST "${BASE}/api/lab/scenarios/11-otel-sdk-error?healthy=1"
echo ""

echo ""
echo "2. Triggering a traced Route Handler exception (captures stack + fires New error alert)..."
curl -sS -i -X POST "${BASE}/api/lab/scenarios/11-otel-sdk-error" || true
echo ""

echo ""
echo "3. Triggering a Next.js Server Component render error via onRequestError..."
curl -sS -i "${BASE}/ssr-crash?trigger=1" | head -n 20 || true
echo ""
echo "Check Tools > Traces, Tools > Errors, and Tools > Alerts in Formatio Dashboard."
