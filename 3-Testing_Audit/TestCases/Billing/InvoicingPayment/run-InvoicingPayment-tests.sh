#!/usr/bin/env bash
#
# Runner for the Billing / InvoicingPayment Dusk suite (single comprehensive file).
# Target: bil_InvoicingPayment_TestCas.php
#
# Prerequisites:
#   - Billing enabled in prime_testing/modules_statuses.json (else 404 on billing routes)
#   - Central app served at http://127.0.0.1:8000, APP_ENV=testing
#
# Usage: ./run-InvoicingPayment-tests.sh [--php <path>] [--filter <pattern>] [--sync-db]

set -uo pipefail

PHP_BIN="php"
FILTER="bil_InvoicingPayment_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --php)     PHP_BIN="$2"; shift 2 ;;
        --filter)  FILTER="$2"; shift 2 ;;
        --sync-db) SYNC_DB=1; shift ;;
        *) echo "Unknown option: $1"; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
SCREENSHOTS_DIR="$SCRIPT_DIR/screenshots"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"

if [[ -d "$SCREENSHOTS_DIR" ]]; then
    rm -rf "${SCREENSHOTS_DIR:?}/"* 2>/dev/null || true
    echo "Cleaned old screenshots"
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="$PROOF_DIR/dusk_run_${TIMESTAMP}.txt"
LATEST_FILE="$PROOF_DIR/dusk_run_latest.txt"

export APP_ENV=testing

cd "$PROJECT_ROOT" || exit 1

if [[ "$SYNC_DB" -eq 1 ]]; then
    echo "Detecting chrome driver..."
    "$PHP_BIN" artisan dusk:chrome-driver --detect >/dev/null 2>&1 || true
fi

echo "Running: artisan dusk --filter=${FILTER}"
"$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE="${PIPESTATUS[0]}"

cp -f "$PROOF_FILE" "$LATEST_FILE"

SUMMARY="$(grep -E 'Tests:[[:space:]]+[0-9]+' "$PROOF_FILE" | tail -n 1 || true)"
if [[ -n "$SUMMARY" ]]; then
    echo ""
    echo "Summary: ${SUMMARY}"
else
    echo ""
    echo "No test summary line found (suite may have errored early)."
fi

echo "Proof: $PROOF_FILE"
exit "$EXIT_CODE"
