#!/usr/bin/env bash
#
# Runner — Student Leave Management Dusk suite (std_StudentLeave_TestCas).
# Mirrors the committed StudentProfile sibling runners.
#
# Usage:
#   ./run-StudentLeave-tests.sh [--php /path/to/php] [--filter test_student_leave_20] [--sync-db]
#
# Prerequisites:
#   - StudentProfile module ENABLED in prime_testing/modules_statuses.json (else all routes 404).
#   - APP_ENV=testing (CSRF bypass for state-changing requests).
#   - Chrome/Chromedriver available; tenant server reachable at DUSK_TENANT_URL.
#
set -euo pipefail

PHP_BIN="php"
FILTER="std_StudentLeave_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --sync-db) SYNC_DB=1; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Resolve prime_testing root (MAIN_PROJECT_PATH or two dirs up from a typical layout).
TEST_REPO="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
cd "$TEST_REPO"

TS="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="tests/Browser/Modules/StudentProfile/StudentLeave/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="${PROOF_DIR}/StudentLeave_${TS}.log"

echo "== Student Leave Dusk run =="
echo "PHP    : $PHP_BIN"
echo "Filter : $FILTER"
echo "Proof  : $PROOF_FILE"

# Clean stale screenshots.
rm -f tests/Browser/console/screenshots/student-leave-fail-*.png 2>/dev/null || true

if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "== Syncing tenant DB =="
  "$PHP_BIN" artisan migrate --force || true
fi

set +e
"$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

echo "== Summary =="
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES" "$PROOF_FILE" | tail -n 5 || true

echo "Exit code: $EXIT_CODE"
exit "$EXIT_CODE"
