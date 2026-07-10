#!/usr/bin/env bash
# Run the StudentProfile / Attendance Dusk suite (single comprehensive file).
# Usage: ./run-Attendance-tests.sh [--php /path/to/php] [--filter test_attendance_14] [--sync-db]
set -euo pipefail

PHP_BIN="php"
FILTER="std_Attendance_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --sync-db) SYNC_DB=1; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Resolve the prime_testing runner root (this suite copies into tests/Browser/Modules/StudentProfile/Testcases/).
RUNNER_ROOT="${MAIN_TEST_PATH:-/Users/bkwork/Herd/prime_testing}"
cd "$RUNNER_ROOT"

export APP_ENV=testing

STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/attendance_${STAMP}.log"

echo "== StudentProfile / Attendance Dusk run =="
echo "Runner : $RUNNER_ROOT"
echo "PHP    : $($PHP_BIN -v | head -n1)"
echo "Filter : $FILTER"
echo "Proof  : $PROOF_FILE"

# Clean stale failure screenshots for this feature.
find tests/Browser/console/screenshots -name 'std-att-fail-*.png' -delete 2>/dev/null || true

if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "Syncing tenant DB (migrate)..."
  $PHP_BIN artisan migrate --force || true
fi

set +e
$PHP_BIN artisan dusk --filter="$FILTER" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

echo ""
echo "== Summary =="
grep -E 'Tests:|Assertions:|Failures:|OK \(' "$PROOF_FILE" | tail -n 5 || echo "(no summary line parsed)"
echo "Exit code: $EXIT_CODE"
exit "$EXIT_CODE"
