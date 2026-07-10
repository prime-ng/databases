#!/usr/bin/env bash
# Runner: StudentProfile / StudentCreate Dusk suite (single file: std_StudentCreate_TestCas.php)
# Usage: ./run-StudentCreate-tests.sh [--php /path/to/php] [--filter methodName] [--sync-db]
set -euo pipefail

PHP_BIN="php"
FILTER="std_StudentCreate_TestCas"
SYNC_DB="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --sync-db) SYNC_DB="1"; shift ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

# Locate the prime_testing runner root (test file must be copied/symlinked into tests/Browser).
RUNNER_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
cd "$RUNNER_ROOT"

export APP_ENV=testing

echo "== StudentCreate Dusk run =="
echo "PHP:     $PHP_BIN"
echo "Filter:  $FILTER"
echo "Runner:  $RUNNER_ROOT"
echo "NOTE: STUDENT module must be enabled in modules_statuses.json (else 404)."

# Clean old screenshots for this feature
rm -f tests/Browser/console/screenshots/student-create-*.png 2>/dev/null || true

if [[ "$SYNC_DB" == "1" ]]; then
  echo "-- Syncing tenant DB --"
  "$PHP_BIN" artisan migrate --database=tenant --force || true
fi

PROOF_DIR="proof"
mkdir -p "$PROOF_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="$PROOF_DIR/StudentCreate_${STAMP}.log"

set +e
"$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

echo ""
echo "== Summary =="
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES" "$PROOF_FILE" | tail -n 5 || true
echo "Proof: $PROOF_FILE"
echo "Exit:  $EXIT_CODE"
exit "$EXIT_CODE"
