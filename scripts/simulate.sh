#!/usr/bin/env bash
# ==============================================================================
# Formatio Failure Lab — 4-Track Scenario & Golden Loop Runner (18 Scenarios)
# ==============================================================================
# Usage:
#   ./scripts/simulate.sh --golden-loop --target http://localhost:3000
#   ./scripts/simulate.sh --otel-all --target http://localhost:3000
#   ./scripts/simulate.sh --track idp
#   ./scripts/simulate.sh --scenario 17-distributed-checkout-origin --target http://localhost:3000
#   ./scripts/simulate.sh --list
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(dirname "$SCRIPT_DIR")"
SCENARIOS_DIR="${LAB_ROOT}/scenarios"

TARGET_URL="http://localhost:3000"
SELECTED_SCENARIO=""
SELECTED_TRACK=""
GOLDEN_LOOP=0
OTEL_ALL=0

show_help() {
  cat <<'EOF'
Formatio Open-Source Failure Lab — Scenario & Golden Loop Runner

Usage:
  ./scripts/simulate.sh [OPTIONS]

Options:
  -g, --golden-loop         Run the 5-minute 4-product Golden Loop (IDP -> Observe -> AI SRE -> Govern)
      --otel-all            Trigger every OTel span/error grouping fixture (/ok, /slow, /exception, /not-found, /status-500, /crash, /downstream)
      --track <name>        Filter scenario listing by track: idp | observability | ai-sre | govern
  -s, --scenario <name>     Run a specific scenario by number or folder name (01..18)
  -t, --target <url>        Target base URL (default: http://localhost:3000)
  -l, --list                List all scenarios grouped across Formatio's 4 product tracks
  -h, --help                Show this help message
EOF
}

list_scenarios() {
  local track_filter="${1:-all}"
  case "$track_filter" in
    all|idp|observability|ai-sre|govern) ;;
    *)
      echo "Unknown track '$track_filter'. Choose one of: idp, observability, ai-sre, govern"
      exit 1
      ;;
  esac

  echo "Formatio Failure Lab scenario catalog (18 scenarios, 4 tracks)"
  echo "=================================================================="
  if [[ "$track_filter" == "all" || "$track_filter" == "idp" ]]; then
    echo "Track 1 — IDP (deploy, roll back, persist and automate):"
    echo "  - 08-bad-release-healthcheck-rollback"
    echo "  - 09-persistent-volume-and-terminal"
    echo "  - 10-deploy-workflow-and-buildkit-secrets"
    echo ""
  fi
  if [[ "$track_filter" == "all" || "$track_filter" == "observability" ]]; then
    echo "Track 2 — Observability (lightweight OpenTelemetry, distributed traces and alerts):"
    echo "  - 01-heap-oom-crash"
    echo "  - 02-connection-starvation-hang"
    echo "  - 03-unhandled-promise-rejection"
    echo "  - 04-event-loop-block"
    echo "  - 05-postgres-pool-lockup"
    echo "  - 06-unbounded-goroutine-leak"
    echo "  - 07-asyncio-cpu-starvation"
    echo "  - 11-otel-paths-and-alerts"
    echo "  - 17-distributed-checkout-origin"
    echo "  - 18-distributed-dashboard-cascade"
    echo ""
  fi
  if [[ "$track_filter" == "all" || "$track_filter" == "ai-sre" ]]; then
    echo "Track 3 — AI SRE (built-in error advisor, automatic fix PRs and runtime CVEs):"
    echo "  - 12-regression-suspect-commit-pr"
    echo "  - 13-runtime-cve-vs-noise"
    echo ""
  fi
  if [[ "$track_filter" == "all" || "$track_filter" == "govern" ]]; then
    echo "Track 4 — Govern (/mcp secret redaction, scopes, kill switch and SSO):"
    echo "  - 14-mcp-secret-redaction"
    echo "  - 15-mcp-scopes-and-kill-switch"
    echo "  - 16-org-boundaries-sso-and-api"
    echo ""
  fi
  echo "=================================================================="
}

run_otel_all() {
  local base="${TARGET_URL%/}"
  echo "=================================================================="
  echo "Formatio Failure Lab — Stock OTel Grouping & Trace Matrix (3x each)"
  echo "Target service: ${base}"
  echo "=================================================================="
  for route in "/ok" "/slow?ms=1500" "/exception" "/not-found/user-42" "/not-found/user-99" "/status-500" "/crash" "/downstream?path=/exception"; do
    echo "== ${route}"
    for i in 1 2 3; do
      code=$(curl -sk -o /dev/null -w "%{http_code}" "${base}${route}" || echo "000")
      printf "  %d/3 HTTP %s %s\n" "${i}" "${code}" "${route}"
    done
  done
  echo ""
  echo "Expect in Formatio Tools > Errors: one group each for exception, not-found (same stack across user IDs),"
  echo "status-500, crash, and downstream origin. Tools > Traces -> Errors only shows failing requests."
}

run_golden_loop() {
  local base="${TARGET_URL%/}"
  echo "=================================================================="
  echo "Formatio Failure Lab — 5-minute Golden Loop (all 4 products)"
  echo "Target service: ${base}"
  echo "=================================================================="
  echo ""

  echo "[Step 1/4 — IDP] Checking live readiness (/healthz) and writing persistent marker..."
  "${SCENARIOS_DIR}/08-bad-release-healthcheck-rollback/trigger.sh" "${base}" || true
  echo ""
  "${SCENARIOS_DIR}/09-persistent-volume-and-terminal/trigger.sh" "${base}" || true
  echo ""

  echo "[Step 2/4 — Observability] Firing traced latency spike & CPU stall telemetry (Scenario 04)..."
  curl -sS -m 5 "${base}/api/lab/status" || echo "(Status probe timed out or unavailable)"
  echo ""
  "${SCENARIOS_DIR}/04-event-loop-block/trigger.sh" "${base}" 1500 || true
  echo ""

  echo "[Step 3/4 — AI SRE] Triggering deterministic 1-line regression fixtures (Scenario 12)..."
  "${SCENARIOS_DIR}/12-regression-suspect-commit-pr/trigger.sh" "${base}" || true
  echo ""

  echo "[Step 4/4 — Govern] Triggering secret-redaction check & optional /mcp verification (Scenario 14)..."
  "${SCENARIOS_DIR}/14-mcp-secret-redaction/trigger.sh" "${base}" || true
  echo ""

  echo "=================================================================="
  echo "Golden Loop trigger sequence complete (service remains healthy)."
  echo "Want to test multi-service cascades or destructive process crashes too?"
  echo "  ./scripts/simulate.sh -s 17 --target ${base}   # Distributed Checkout Origin (Node->Go->Python)"
  echo "  ./scripts/simulate.sh -s 18 --target ${base}   # Distributed Dashboard Cascade (Go DB->Frontend)"
  echo "  ./scripts/simulate.sh -s 01 --target ${base}   # Heap OOM (SIGKILL 137)"
  echo "  ./scripts/simulate.sh -s 03 --target ${base}   # Detached Promise Rejection"
  echo "Inspect inside https://formatio.cloud/dashboard:"
  echo "  1. Deployments + Volumes + Terminal -> healthcheck gate, /data & exact-image Roll back"
  echo "  2. Tools > Traces & Tools > Errors  -> OpenTelemetry waterfall, release metadata & suspect commit"
  echo "  3. Organization > AI (Automatic)    -> built-in AI error advisor + automatic fix PRs"
  echo "  4. Settings > Access tokens + /mcp  -> 22 tools, names-only secret redaction & agent_access switch"
  echo "=================================================================="
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--golden-loop)
      GOLDEN_LOOP=1
      shift
      ;;
    --otel-all)
      OTEL_ALL=1
      shift
      ;;
    --track)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --track"
        exit 1
      fi
      SELECTED_TRACK="$2"
      shift 2
      ;;
    -s|--scenario)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --scenario"
        exit 1
      fi
      SELECTED_SCENARIO="$2"
      shift 2
      ;;
    -t|--target)
      if [[ $# -lt 2 ]]; then
        echo "Missing value for --target"
        exit 1
      fi
      TARGET_URL="$2"
      shift 2
      ;;
    -l|--list)
      list_scenarios "all"
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

if [[ "$GOLDEN_LOOP" -eq 1 ]]; then
  run_golden_loop
  exit 0
fi

if [[ "$OTEL_ALL" -eq 1 ]]; then
  run_otel_all
  exit 0
fi

if [[ -n "$SELECTED_TRACK" ]]; then
  list_scenarios "$SELECTED_TRACK"
  exit 0
fi

if [[ -z "$SELECTED_SCENARIO" ]]; then
  echo "No scenario or flag specified. Use --golden-loop, --otel-all, --track <name>, -s <scenario>, or --list."
  echo ""
  list_scenarios "all"
  exit 1
fi

MATCH=""
for d in "$SCENARIOS_DIR"/*/; do
  if [ -d "$d" ]; then
    b="$(basename "$d")"
    if [[ "$b" == "$SELECTED_SCENARIO"* ]] || [[ "$b" == *"$SELECTED_SCENARIO"* ]]; then
      MATCH="$b"
      break
    fi
  fi
done

if [[ -z "$MATCH" ]]; then
  echo "Error: Could not find scenario matching '$SELECTED_SCENARIO'."
  list_scenarios "all"
  exit 1
fi

TRIGGER_SCRIPT="${SCENARIOS_DIR}/${MATCH}/trigger.sh"
if [[ ! -f "$TRIGGER_SCRIPT" ]]; then
  echo "Error: Trigger script not found at ${TRIGGER_SCRIPT}"
  exit 1
fi

echo "Executing scenario: ${MATCH}"
exec "$TRIGGER_SCRIPT" "$TARGET_URL"
