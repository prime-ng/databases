#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Subscription (Billing / prime-side) Dusk runner — bash
# Mirrors the golden-reference runner: filter, V1/V2 toggles, proof capture,
# result parsing, dusk exit code passthrough.
#
# Prereqs:
#   - Billing module ENABLED in prime_testing/modules_statuses.json (else 404)
#   - App reachable at http://127.0.0.1:8000 (central), APP_ENV=testing
#   - ChromeDriver running for Dusk
# Usage:
#   ./run-Subscription-tests.sh [--php <path>] [--filter <name>] [--v1-only] [--v2-only]
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="php"
FILTER=""
RUN_V1=1
RUN_V2=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)     PHP_BIN="$2"; shift 2 ;;
    --filter)  FILTER="$2"; shift 2 ;;
    --v1-only) RUN_V2=0; shift ;;
    --v2-only) RUN_V1=0; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${MAIN_PROJECT_PATH:-$SCRIPT_DIR}"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"
TS="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="$PROOF_DIR/subscription_dusk_${TS}.log"

export APP_ENV=testing

CLASSES=()
[[ $RUN_V1 -eq 1 ]] && CLASSES+=("prm_SubscriptionV1_TestCas")
[[ $RUN_V2 -eq 1 ]] && CLASSES+=("prm_SubscriptionV2_TestCas")

echo "== Subscription Dusk run @ $TS ==" | tee "$PROOF_FILE"
echo "PHP: $PHP_BIN | project: $PROJECT_ROOT" | tee -a "$PROOF_FILE"

# Clean old screenshots
rm -f "$SCRIPT_DIR/screenshots/"*.png 2>/dev/null || true

EXIT_CODE=0
for CLS in "${CLASSES[@]}"; do
  echo "--- Running $CLS ---" | tee -a "$PROOF_FILE"
  FILTER_ARG="$CLS"
  [[ -n "$FILTER" ]] && FILTER_ARG="${CLS}::${FILTER}"
  ( cd "$PROJECT_ROOT" && "$PHP_BIN" artisan dusk --filter="$FILTER_ARG" ) 2>&1 | tee -a "$PROOF_FILE"
  RC=${PIPESTATUS[0]}
  [[ $RC -ne 0 ]] && EXIT_CODE=$RC
done

echo "== Summary ==" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES|Error" "$PROOF_FILE" | tail -n 20 | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE"
exit $EXIT_CODE
