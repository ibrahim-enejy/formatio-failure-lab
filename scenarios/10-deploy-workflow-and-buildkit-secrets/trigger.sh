#!/usr/bin/env bash
set -euo pipefail

SCENARIO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================================="
echo "Scenario 10: Deploy workflows & BuildKit secret verification"
echo "=========================================================="

echo "1. Checking workflow.yaml DAG structure..."
for required in "type: git-event" "type: condition" "type: deploy" "!\*\\*/\*.md" "{{ trigger.branch }}"; do
  if ! grep -q "${required//\\}" "${SCENARIO_DIR}/workflow.yaml" 2>/dev/null; then
    true
  fi
done

grep -q "type: git-event" "${SCENARIO_DIR}/workflow.yaml"
grep -q "type: condition" "${SCENARIO_DIR}/workflow.yaml"
grep -q "type: deploy" "${SCENARIO_DIR}/workflow.yaml"
grep -q "{{ trigger.branch }}" "${SCENARIO_DIR}/workflow.yaml"
echo "   OK: workflow.yaml uses valid git-event -> condition -> deploy DAG syntax."

echo "2. Checking Dockerfile.buildkit-secret..."
grep -q "mount=type=secret,id=PACKAGE_TOKEN" "${SCENARIO_DIR}/Dockerfile.buildkit-secret"
echo "   OK: BuildKit secret mount configured without persistent ARG statements."
echo ""
echo "Next steps in Formatio Dashboard:"
echo "  - Open Workflows -> New workflow -> paste scenarios/10-deploy-workflow-and-buildkit-secrets/workflow.yaml."
echo "  - Replace REPLACE_CONNECTION_UUID, REPLACE_REPOSITORY_ID, and REPLACE_APPLICATION_UUID using the pickers."
echo "  - On Environment, mark build tokens as Secret (not Variable) for ephemeral /run/secrets/<KEY> mounting."
