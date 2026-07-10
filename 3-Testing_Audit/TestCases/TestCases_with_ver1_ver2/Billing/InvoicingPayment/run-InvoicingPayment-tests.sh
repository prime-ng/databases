#!/usr/bin/env bash
# =============================================================================
# Invoice Payments (Billing / InvoicingPayment) — Dusk runner (bash)
#
# Central prime_db feature. Mirrors the committed BillingDuskTestCase siblings.
# Requires: Billing module ENABLED in modules_statuses.json; APP_ENV=testing;
#           app served at http://127.0.0.1:8000 (Prime tests enforce this host).
#
# Usage:
#   ./run-InvoicingPayment-tests.sh [--php <path>] [--filter <name>]
#                                   [--v1-only] [--v2-only] [--sync-db]
# =============================================================================
set -uo pipefail

PHP_BIN="php"
FILTER=""
V1_ONLY=0
V2_ONLY=0
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php) PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --v1-only) V1_ONLY=1; shift ;;
    --v2-only) V2_ONLY=1; shift ;;
    --sync-db) SYNC_DB=1; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Resolve the prime_testing project root (override with MAIN_PROJECT_PATH).
PROJECT_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
cd "$PROJECT_ROOT" || { echo "Cannot cd to $PROJECT_ROOT"; exit 1; }

TEST_DIR="tests/Browser/Modules/Prime/Billing/InvoicingPayment"
PROOF_DIR="$TEST_DIR/proof"
mkdir -p "$PROOF_DIR" "$TEST_DIR/screenshots" "$TEST_DIR/report"

# Clean stale screenshots.
rm -f "$TEST_DIR/screenshots/"*.png 2>/dev/null

export APP_ENV=testing

if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "==> Syncing test DB (migrate)…"
  "$PHP_BIN" artisan migrate --force >/dev/null 2>&1 || echo "   (migrate skipped/failed — continuing)"
fi

TS="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="$PROOF_DIR/invoicing_payment_run_${TS}.log"

build_filter() {
  if [[ -n "$FILTER" ]]; then echo "--filter=$FILTER"; return; fi
  if [[ "$V1_ONLY" -eq 1 ]]; then echo "--filter=bil_InvoicingPaymentV1_TestCas"; return; fi
  if [[ "$V2_ONLY" -eq 1 ]]; then echo "--filter=bil_InvoicingPaymentV2_TestCas"; return; fi
  echo "--filter=InvoicingPayment"
}

FILTER_ARG="$(build_filter)"
echo "==> Running: artisan dusk $FILTER_ARG"
echo "    Proof:   $PROOF_FILE"

"$PHP_BIN" artisan dusk "$FILTER_ARG" 2>&1 | tee "$PROOF_FILE"
DUSK_EXIT=${PIPESTATUS[0]}

echo ""
echo "==> Summary"
grep -E "Tests:|Assertions:|OK|FAIL" "$PROOF_FILE" | tail -n 5 || true

echo "==> Dusk exit code: $DUSK_EXIT"
exit "$DUSK_EXIT"
