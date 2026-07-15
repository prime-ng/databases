#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Billing Cycle — Dusk test runner (bash / Linux / WSL / macOS)
#
# Prereqs:
#   - Copy prm_BillingCycle_TestCas.php into:
#       prime_testing/tests/Browser/Modules/Prime/Billing/BillingCycle/
#   - Billing module ENABLED in prime_testing/modules_statuses.json
#   - Central app served at http://127.0.0.1:8000 ; ChromeDriver running
#   - prm_billing_cycles.deleted_at column present (see MIG-BIL-001)
#
# Usage:
#   ./run-BillingCycle-tests.sh [--php <php-bin>] [--filter <method-or-pattern>]
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="php"
FILTER="prm_BillingCycle_TestCas"
TEST_REPO="${TEST_FILE_REPO:-/Users/bkwork/Herd/prime_testing}"
TEST_PATH="tests/Browser/Modules/Prime/Billing/BillingCycle/prm_BillingCycle_TestCas.php"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php) PHP_BIN="$2"; shift 2;;
    --filter) FILTER="$2"; shift 2;;
    --repo) TEST_REPO="$2"; shift 2;;
    *) echo "Unknown arg: $1"; exit 2;;
  esac
done

export APP_ENV=testing

cd "$TEST_REPO" || { echo "Cannot cd to $TEST_REPO"; exit 1; }

STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="$TEST_REPO/tests/Browser/Modules/Prime/Billing/BillingCycle/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/billing_cycle_run_${STAMP}.log"

# Clean old screenshots
SHOT_DIR="$TEST_REPO/tests/Browser/Modules/Prime/Billing/BillingCycle/screenshots"
if [[ -d "$SHOT_DIR" ]]; then
  rm -f "$SHOT_DIR"/*.png 2>/dev/null || true
fi

echo "=== Billing Cycle Dusk run ${STAMP} ===" | tee "$PROOF_FILE"
echo "PHP:    $PHP_BIN" | tee -a "$PROOF_FILE"
echo "Filter: $FILTER"  | tee -a "$PROOF_FILE"
echo "Path:   $TEST_PATH" | tee -a "$PROOF_FILE"
echo "" | tee -a "$PROOF_FILE"

"$PHP_BIN" artisan dusk --filter="$FILTER" "$TEST_PATH" 2>&1 | tee -a "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo "" | tee -a "$PROOF_FILE"
SUMMARY="$(grep -E 'Tests:|Assertions:|OK \(|FAILURES|Errors:' "$PROOF_FILE" | tail -n 5)"
echo "----- Summary -----" | tee -a "$PROOF_FILE"
echo "${SUMMARY:-<no summary line parsed>}" | tee -a "$PROOF_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE"

exit "$EXIT_CODE"
