#!/usr/bin/env bash
# ==============================================================================
# Formatio Failure Lab — Universal Scenario Runner
# ==============================================================================
# Usage:
#   ./scripts/simulate.sh --scenario 01-heap-oom-crash --target http://localhost:3000
#   ./scripts/simulate.sh --scenario 06-unbounded-goroutine-leak --target http://localhost:8080
#   ./scripts/simulate.sh --list
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(dirname "$SCRIPT_DIR")"
SCENARIOS_DIR="${LAB_ROOT}/scenarios"

TARGET_URL="http://localhost:3000"
SELECTED_SCENARIO=""

show_help() {
  echo "Formatio Open-Source Failure Lab — Simulation Runner"
  echo ""
  echo "Usage:"
  echo "  ./scripts/simulate.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  -s, --scenario <name>     Scenario name or number (e.g. 01, 01-heap-oom-crash)"
  echo "  -t, --target <url>        Target URL (default: http://localhost:3000)"
  echo "  -l, --list                List all available failure scenarios"
  echo "  -h, --help                Show this help message"
  echo ""
}

list_scenarios() {
  echo "Available Failure Scenarios:"
  echo "------------------------------------------------------------------"
  for d in "$SCENARIOS_DIR"/*/; do
    if [ -d "$d" ]; then
      base="$(basename "$d")"
      echo "  • $base"
    fi
  done
  echo "------------------------------------------------------------------"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -s|--scenario)
      SELECTED_SCENARIO="$2"
      shift 2
      ;;
    -t|--target)
      TARGET_URL="$2"
      shift 2
      ;;
    -l|--list)
      list_scenarios
      exit 0
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      show_help
      exit 1
      ;;
  esac
done

if [[ -z "$SELECTED_SCENARIO" ]]; then
  echo "⚠️ No scenario specified. Use -s <scenario> or --list to see options."
  list_scenarios
  exit 1
fi

# Match scenario by prefix or full name
MATCH=""
for d in "$SCENARIOS_DIR"/*/; do
  b="$(basename "$d")"
  if [[ "$b" == "$SELECTED_SCENARIO"* ]] || [[ "$b" == *"$SELECTED_SCENARIO"* ]]; then
    MATCH="$b"
    break
  fi
done

if [[ -z "$MATCH" ]]; then
  echo "❌ Error: Could not find scenario matching '$SELECTED_SCENARIO'."
  list_scenarios
  exit 1
fi

TRIGGER_SCRIPT="${SCENARIOS_DIR}/${MATCH}/trigger.sh"
if [[ ! -f "$TRIGGER_SCRIPT" ]]; then
  echo "❌ Error: Trigger script not found at ${TRIGGER_SCRIPT}"
  exit 1
fi

echo "🚀 Executing scenario: ${MATCH}"
exec "$TRIGGER_SCRIPT" "$TARGET_URL"
