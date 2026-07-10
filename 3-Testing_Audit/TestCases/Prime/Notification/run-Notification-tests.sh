#!/usr/bin/env bash
# Prime (PRM) — Notification Dusk runner (central; host http://127.0.0.1:8000)
# Single comprehensive suite: prm_Notification_TestCas.php
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER="${1:-prm_Notification_TestCas}"
TEST_REPO="${TEST_REPO:-/Users/bkwork/Herd/prime_testing}"
TEST_PATH="tests/Browser/Modules/Prime/Notification/prm_Notification_TestCas.php"

cd "$TEST_REPO" || { echo "Cannot cd to $TEST_REPO"; exit 1; }

# Prime/central tests must run on 127.0.0.1:8000 and under APP_ENV=testing (CSRF bypass).
export APP_ENV=testing

STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="$TEST_REPO/tests/Browser/Modules/Prime/Notification/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/notification_dusk_${STAMP}.log"

# Clean old screenshots
rm -f "$TEST_REPO/tests/Browser/Modules/Prime/Notification/screenshots/"*.png 2>/dev/null || true

echo "== Prime Notification Dusk run =="
echo "Filter : $FILTER"
echo "Proof  : $PROOF_FILE"
echo "Host   : http://127.0.0.1:8000  (ensure the app is served here)"
echo "Prereq : Prime module enabled in modules_statuses.json"
echo "================================="

"$PHP_BIN" artisan dusk --filter="$FILTER" "$TEST_PATH" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "== Summary =="
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES|Errors:" "$PROOF_FILE" | tail -5 || true
echo "Exit code: $EXIT_CODE"
exit "$EXIT_CODE"
