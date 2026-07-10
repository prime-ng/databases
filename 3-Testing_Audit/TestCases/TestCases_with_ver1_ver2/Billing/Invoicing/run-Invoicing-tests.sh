#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Invoicing (Invoice Generation) — Dusk test runner (bash / Linux / WSL / macOS)
# Central prime_db feature (Invoicing tab of Billing Management).
# Mirrors the golden-reference runner idiom.
#
# Usage:
#   ./run-Invoicing-tests.sh [--php <path>] [--filter <name>] [--v1|--v2]
#
# Prerequisites:
#   * Billing module ENABLED in modules_statuses.json (else 404 on all routes)
#   * APP_ENV=testing  (CSRF bypass for generate / remarks AJAX posts)
#   * Central dev server reachable on http://127.0.0.1:8000
#   * bil_tenant_invoices.deleted_at present (MIG-BIL-001 dev patch)
# ---------------------------------------------------------------------------
set -u

PHP_BIN="php"
FILTER=""
CLASS_FILTER=""
V1_CLASS="bil_InvoicingV1_TestCas"
V2_CLASS="bil_InvoicingV2_TestCas"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --v1)     CLASS_FILTER="$V1_CLASS"; shift ;;
    --v2)     CLASS_FILTER="$V2_CLASS"; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Resolve the prime_testing runner root (MAIN_PROJECT_PATH or a sensible default).
RUNNER_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
if [[ ! -d "$RUNNER_ROOT" ]]; then
  echo "ERROR: runner root not found at $RUNNER_ROOT (set MAIN_PROJECT_PATH)."
  exit 1
fi
cd "$RUNNER_ROOT" || exit 1

export APP_ENV=testing

TS="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="tests/Browser/Modules/Prime/Billing/Invoicing/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/billing_invoicing_dusk_${TS}.log"

# Clean stale screenshots.
SHOT_DIR="tests/Browser/Modules/Prime/Billing/Invoicing/screenshots"
[[ -d "$SHOT_DIR" ]] && find "$SHOT_DIR" -type f -name '*.png' -delete 2>/dev/null

# Build the --filter argument.
FILTER_ARG=""
if [[ -n "$FILTER" ]]; then
  FILTER_ARG="--filter=$FILTER"
elif [[ -n "$CLASS_FILTER" ]]; then
  FILTER_ARG="--filter=$CLASS_FILTER"
else
  FILTER_ARG="--filter=Invoicing(V1|V2)_TestCas"
fi

echo "==================================================================="
echo " Invoicing (Invoice Generation) Dusk run"
echo " Runner : $RUNNER_ROOT"
echo " PHP    : $PHP_BIN"
echo " Filter : $FILTER_ARG"
echo " Proof  : $PROOF_FILE"
echo "==================================================================="

"$PHP_BIN" artisan dusk "$FILTER_ARG" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "------------------------- SUMMARY -------------------------"
grep -E "Tests:|Assertions:|OK|FAILURES|Failed|Error" "$PROOF_FILE" | tail -n 10
echo "-----------------------------------------------------------"
echo "Dusk exit code: $EXIT_CODE  (proof: $PROOF_FILE)"

exit "$EXIT_CODE"
