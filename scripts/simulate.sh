#!/usr/bin/env bash
# ==============================================================================
# Formatio Failure Lab — 4-Track Scenario & Golden Loop Runner
# ==============================================================================
# Usage:
#   ./scripts/simulate.sh --golden-loop --target http://localhost:3000
#   ./scripts/simulate.sh --track idp
#   ./scripts/simulate.sh --scenario 12-regression-suspect-commit-pr --target http://localhost:3000
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

show_help() {
  cat <<'EOF'
Formatio Open-Source Failure Lab — Scenario & Golden Loop Runner

Usage:
  ./scripts/simulate.sh [OPTIONS]

Options:
  -g, --golden-loop         Run the 5-minute 4-product Golden Loop (IDP -> Observe -> AI SRE -> Govern)
      --track <name>        Filter scenario listing by track: idp | observability | ai-sre | govern
  -s, --scenario <name>     Run a specific scenario by number or folder name (01..16)
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

  echo "Formatio Failure Lab scenario catalog"
  echo "=================================================================="
  if [[ "$track_filter" == "all" || "$track_filter" == "idp" ]]; then
    echo "Track 1 — IDP (deploy, roll back, persist and automate):"
    echo "  - 08-bad-release-healthcheck-rollback"
    echo "  - 09-persistent-volume-and-terminal"
    echo "  - 10-deploy-workflow-and-buildkit-secrets"
    echo ""
  fi
  if [[ "$track_filter" == "all" || "$track_filter" == "observability" ]]; then
    echo "Track 2 — Observability (lightweight OpenTelemetry, traces and alerts):"
    echo "  - 01-heap-oom-crash"
    echo "  - 02-connection-starvation-hang"
    echo "  - 03-unhandled-promise-rejection"
    echo "  - 04-event-loop-block"
    echo "  - 05-postgres-pool-lockup"
    echo "  - 06-unbounded-goroutine-leak"
    echo "  - 07-asyncio-cpu-starvation"
    echo "  - 11-otel-paths-and-alerts"
    echo ""
  fi
  if [[ "$track_filter" == "all" || "$track_filter" == "ai-sre" ]]; then
    echo "Track 3 — AI SRE (built-in error advisor, fix PRs and runtime CVEs):"
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

  echo "[Step 2/4 — Observability] Firing traced latency & exception telemetry..."
  curl -sS -m 5 "${base}/api/lab/status" || echo "(Status probe timed out or unavailable)"
  echo ""
  "${SCENARIOS_DIR}/03-unhandled-promise-rejection/trigger.sh" "${base}" || true
  echo ""

  echo "[Step 3/4 — AI SRE] Triggering deterministic 1-line checkout regression (Scenario 12)..."
  "${SCENARIOS_DIR}/12-regression-suspect-commit-pr/trigger.sh" "${base}" || true
  echo ""

  echo "[Step 4/4 — Govern] Triggering secret-redaction check & optional /mcp verification (Scenario 14)..."
  "${SCENARIOS_DIR}/14-mcp-secret-redaction/trigger.sh" "${base}" || true
  echo ""

  echo "=================================================================="
  echo "Golden Loop trigger sequence complete."
  echo "Inspect inside https://formatio.cloud/dashboard (or https://playground.formatio.cloud):"
  echo "  1. Deployments + Volumes + Terminal -> healthcheck gate & persistent /data"
  echo "  2. Tools > Traces & Tools > Errors  -> OpenTelemetry waterfall & suspect commit"
  echo "  3. Organization > AI (Automatic)    -> built-in AI error advisor + autonomous fix PR"
  echo "  4. Settings > Access tokens + /mcp  -> names-only secret redaction & agent_access switch"
  echo "=================================================================="
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -g|--golden-loop)
      GOLDEN_LOOP=1
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

if [[ -n "$SELECTED_TRACK" ]]; then
  list_scenarios "$SELECTED_TRACK"
  exit 0
fi

if [[ -z "$SELECTED_SCENARIO" ]]; then
  echo "No scenario or flag specified. Use --golden-loop, --track <name>, -s <scenario>, or --list."
  echo ""
  list_scenarios "all"
  exit 1
fi

# Match scenario by exact prefix or substring
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
