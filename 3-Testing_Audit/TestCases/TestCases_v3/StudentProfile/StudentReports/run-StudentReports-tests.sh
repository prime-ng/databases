#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# StudentProfile / StudentReports — Dusk runner (bash)
# ONE test file per screen: std_StudentReports_TestCas.php
#
# Prerequisites:
#   - module STUDENT enabled in prime_testing/modules_statuses.json (else 404)
#   - APP_ENV=testing ; Chromedriver running ; tenant seeded with students
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER="${1:-}"
TEST_CLASS="std_StudentReports_TestCas"

PROJECT_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
PROOF_DIR="$(cd "$(dirname "$0")" && pwd)/proof"
mkdir -p "$PROOF_DIR"
STAMP="$(date '+%Y%m%d_%H%M%S')"
PROOF_FILE="$PROOF_DIR/StudentReports_${STAMP}.log"

cd "$PROJECT_ROOT" || { echo "Cannot cd to $PROJECT_ROOT"; exit 1; }

# Clean stale screenshots
rm -f tests/Browser/console/screenshots/student-reports-fail-*.png 2>/dev/null || true

FILTER_ARG="--filter=${TEST_CLASS}"
if [ -n "$FILTER" ]; then
  FILTER_ARG="--filter=${FILTER}"
fi

echo "Running Dusk: $TEST_CLASS ($FILTER_ARG)"
echo "Proof: $PROOF_FILE"

APP_ENV=testing "$PHP_BIN" artisan dusk "$FILTER_ARG" 2>&1 | tee "$PROOF_FILE"
DUSK_EXIT="${PIPESTATUS[0]}"

echo ""
echo "===================== SUMMARY ====================="
grep -E "Tests:|Assertions:|OK|FAILURES|Error" "$PROOF_FILE" | tail -n 5 || true
echo "Exit code: $DUSK_EXIT"
echo "==================================================="

exit "$DUSK_EXIT"
