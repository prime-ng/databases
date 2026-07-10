#!/usr/bin/env bash
#
# Payment Reconciliation — Dusk runner (bash / macOS / Linux / WSL)
# Runs the single comprehensive suite: bil_PaymentReconciliation_TestCas.php
#
# Prerequisites:
#   - prime_ai cloned alongside; MAIN_PROJECT_PATH set (see TEST_SETUP.md)
#   - Billing module ENABLED in prime_testing/modules_statuses.json
#   - APP_ENV=testing ; central host reachable at http://127.0.0.1:8000
#
# Usage:
#   ./run-PaymentReconciliation-tests.sh [--php /path/to/php] [--filter test_paymentreconciliation_10]
#
set -euo pipefail

PHP_BIN="php"
FILTER="bil_PaymentReconciliation_TestCas"
TEST_PATH="tests/Browser/Modules/Prime/Billing/PaymentReconciliation/bil_PaymentReconciliation_TestCas.php"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2";  shift 2 ;;
    --path)   TEST_PATH="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Resolve prime_testing root (this script is copied into the runner tree when executed).
PROJECT_ROOT="${PRIME_TESTING_PATH:-$(pwd)}"
cd "$PROJECT_ROOT"

REPORT_DIR="tests/Browser/Modules/Prime/Billing/PaymentReconciliation/proof"
mkdir -p "$REPORT_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="${REPORT_DIR}/reconciliation_${STAMP}.log"

# Clean old screenshots
SHOTS="tests/Browser/Modules/Prime/Billing/PaymentReconciliation/screenshots"
if [[ -d "$SHOTS" ]]; then
  rm -f "$SHOTS"/*.png 2>/dev/null || true
fi

echo "== Payment Reconciliation Dusk run =="
echo "PHP:     $PHP_BIN"
echo "Filter:  $FILTER"
echo "Proof:   $PROOF_FILE"
echo "======================================"

set +e
APP_ENV=testing "$PHP_BIN" artisan dusk --filter="$FILTER" "$TEST_PATH" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

echo "--------------------------------------"
SUMMARY="$(grep -E 'Tests:|Assertions:|Failures:|OK ' "$PROOF_FILE" | tail -n 3 || true)"
echo "Summary:"
echo "${SUMMARY:-  (no PHPUnit summary line parsed)}"
echo "Exit code: $EXIT_CODE"

exit "$EXIT_CODE"
