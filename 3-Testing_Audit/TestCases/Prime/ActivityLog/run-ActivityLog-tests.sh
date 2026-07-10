#!/usr/bin/env bash
# Runner: Prime / ActivityLog (central, read-only) Dusk suite.
# One comprehensive test file: sys_ActivityLog_TestCas.php
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER="${1:-sys_ActivityLog_TestCas}"

# Locate the Dusk runner repo (prime_testing).
RUNNER_DIR="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
TEST_REL="tests/Browser/Modules/Prime/ActivityLog/sys_ActivityLog_TestCas.php"

echo "== Prime/ActivityLog Dusk run =="
echo "Runner:  $RUNNER_DIR"
echo "Filter:  $FILTER"

cd "$RUNNER_DIR" || { echo "Runner dir not found: $RUNNER_DIR"; exit 2; }

# Prerequisite reminders (central feature):
echo "-- prerequisites: APP_ENV=testing, Chrome driver up, app served at http://127.0.0.1:8000, prime_db migrated (sys_central_activity_logs)."

# Clean old screenshots for this feature.
SHOTS="tests/Browser/Modules/Prime/ActivityLog/screenshots"
[ -d "$SHOTS" ] && rm -f "$SHOTS"/*.png 2>/dev/null

# Proof capture.
PROOF_DIR="tests/Browser/Modules/Prime/ActivityLog/proof"
mkdir -p "$PROOF_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="$PROOF_DIR/activitylog_${STAMP}.log"

APP_ENV=testing "$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee "$PROOF_FILE"
EXIT=${PIPESTATUS[0]}

echo ""
echo "== Summary =="
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES" "$PROOF_FILE" | tail -5
echo "Proof: $PROOF_FILE"
echo "Exit:  $EXIT"
exit "$EXIT"
