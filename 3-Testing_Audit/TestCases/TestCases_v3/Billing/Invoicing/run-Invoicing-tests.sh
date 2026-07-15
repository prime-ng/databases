#!/usr/bin/env bash
# Runner: Billing → Invoicing Dusk suite (bil_Invoicing_TestCas.php)
# Central/prime feature — requires prime_ai served on http://127.0.0.1:8000, Billing module ENABLED
# in modules_statuses.json, APP_ENV=testing, and a reachable prime_db.
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER="${1:-}"                     # optional: a single test method or pattern
TEST_CLASS="bil_Invoicing_TestCas"
TEST_PATH="tests/Browser/Modules/Prime/Billing/Invoicing/${TEST_CLASS}.php"

# Resolve the prime_testing runner root (override with TEST_REPO=...)
TEST_REPO="${TEST_REPO:-/Users/bkwork/Herd/prime_testing}"
cd "$TEST_REPO" || { echo "ERROR: cannot cd to TEST_REPO=$TEST_REPO"; exit 2; }

STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="$TEST_REPO/tests/Browser/Modules/Prime/Billing/Invoicing/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/invoicing_run_${STAMP}.log"

# Clean old screenshots for this feature
SHOTS="$TEST_REPO/tests/Browser/Modules/Prime/Billing/Invoicing/screenshots"
if [ -d "$SHOTS" ]; then rm -f "$SHOTS"/*.png 2>/dev/null || true; fi

echo "== Billing Invoicing Dusk run @ ${STAMP} ==" | tee "$PROOF_FILE"

CMD=("$PHP_BIN" artisan dusk "$TEST_PATH")
if [ -n "$FILTER" ]; then CMD+=("--filter=${FILTER}"); fi
echo "> ${CMD[*]}" | tee -a "$PROOF_FILE"

APP_ENV=testing "${CMD[@]}" 2>&1 | tee -a "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo "" | tee -a "$PROOF_FILE"
echo "== Summary ==" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|Failures:|Errors:|OK|FAILURES|Skipped" "$PROOF_FILE" | tail -n 6 | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE" | tee -a "$PROOF_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$PROOF_FILE"
exit "$EXIT_CODE"
