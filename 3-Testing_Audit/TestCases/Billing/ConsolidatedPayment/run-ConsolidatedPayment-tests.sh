#!/usr/bin/env bash
# Runner: Billing / Consolidated Payment Dusk suite (Prime-central).
# Mirrors the golden reference: clean screenshots -> run filtered dusk -> tee proof -> parse -> summarise.
#
# Prereqs (see Validation Report §7):
#   - Billing module ENABLED in prime_testing/modules_statuses.json (else 404 / E19)
#   - Central app served on http://127.0.0.1:8000 with APP_ENV=testing
#   - Test file copied to: tests/Browser/Modules/Prime/Billing/ConsolidatedPayment/bil_ConsolidatedPayment_TestCas.php
#
# Usage:
#   ./run-ConsolidatedPayment-tests.sh [--php /path/to/php] [--filter test_consolidated_payment_30] [--sync-db]

set -uo pipefail

PHP_BIN="php"
FILTER="bil_ConsolidatedPayment_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2";  shift 2 ;;
    --sync-db) SYNC_DB=1;   shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve the prime_testing runner root (override with TEST_FILE_REPO).
RUNNER_ROOT="${TEST_FILE_REPO:-/Users/bkwork/Herd/prime_testing}"
cd "$RUNNER_ROOT" || { echo "Runner root not found: $RUNNER_ROOT"; exit 2; }

export APP_ENV=testing

TS="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/consolidated-payment_${TS}.log"

echo "== Consolidated Payment Dusk run =="
echo "Runner root : $RUNNER_ROOT"
echo "PHP         : $PHP_BIN"
echo "Filter      : $FILTER"
echo "Proof       : $PROOF_FILE"

# Clean stale screenshots for this feature.
SHOT_DIR="$RUNNER_ROOT/tests/Browser/Modules/Prime/Billing/ConsolidatedPayment/screenshots"
if [[ -d "$SHOT_DIR" ]]; then
  rm -f "$SHOT_DIR"/*.png 2>/dev/null || true
fi

if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "-- Syncing migrations (dusk env) --"
  "$PHP_BIN" artisan migrate --env=testing --force 2>&1 | tee -a "$PROOF_FILE"
fi

echo "-- Running dusk --filter=$FILTER --"
"$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee -a "$PROOF_FILE"
DUSK_EXIT=${PIPESTATUS[0]}

SUMMARY_LINE="$(grep -E 'Tests:[[:space:]]+[0-9]+' "$PROOF_FILE" | tail -n 1)"
echo ""
echo "== Summary =="
if [[ -n "$SUMMARY_LINE" ]]; then
  echo "$SUMMARY_LINE"
else
  echo "(no PHPUnit summary line parsed — check $PROOF_FILE)"
fi
echo "Dusk exit code: $DUSK_EXIT"
echo "Proof: $PROOF_FILE"

exit "$DUSK_EXIT"
