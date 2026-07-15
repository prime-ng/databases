#!/usr/bin/env bash
#
# Runner — BehaviouralAssessment / PeriodProgress Dusk suite (single comprehensive file).
# Class name = bha_PeriodProgress_TestCas (no V1/V2 split).
#
# Usage:
#   ./run-PeriodProgress-tests.sh [--php <php-bin>] [--filter <pattern>] [--sync-db]
#
# Prerequisites:
#   - prime_ai cloned alongside prime_testing; MAIN_PROJECT_PATH set (see TEST_SETUP.md)
#   - BehaviouralAssessment ENABLED in prime_testing/modules_statuses.json (else 404 on all routes)
#   - APP_ENV=testing (set below so state-changing requests bypass CSRF)

set -uo pipefail

PHP_BIN="php"
FILTER="bha_PeriodProgress_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --sync-db) SYNC_DB=1; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
SCREENSHOTS_DIR="$SCRIPT_DIR/screenshots"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"

# Clean old screenshots
if [[ -d "$SCREENSHOTS_DIR" ]]; then
  rm -f "$SCREENSHOTS_DIR"/*.png 2>/dev/null || true
  echo "Cleaned old screenshots"
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="$PROOF_DIR/dusk_run_$TIMESTAMP.txt"
LATEST_FILE="$PROOF_DIR/dusk_run_latest.txt"

cd "$PROJECT_ROOT" || exit 1

if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "Detecting matching ChromeDriver..."
  "$PHP_BIN" artisan dusk:chrome-driver --detect >/dev/null 2>&1 || true
fi

export APP_ENV=testing
echo "Running Dusk with filter: $FILTER"
echo "Prerequisite: BehaviouralAssessment must be enabled in modules_statuses.json"

"$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE="${PIPESTATUS[0]}"

cp -f "$PROOF_FILE" "$LATEST_FILE"

# Parse results
SUMMARY_LINE="$(grep -Eo 'Tests:[[:space:]]+[0-9]+,[[:space:]]+Assertions:[[:space:]]+[0-9]+,[[:space:]]+Failures:[[:space:]]+[0-9]+' "$PROOF_FILE" | tail -1 || true)"
if [[ -n "$SUMMARY_LINE" ]]; then
  TOTAL="$(echo "$SUMMARY_LINE" | grep -Eo 'Tests:[[:space:]]+[0-9]+' | grep -Eo '[0-9]+')"
  FAILS="$(echo "$SUMMARY_LINE" | grep -Eo 'Failures:[[:space:]]+[0-9]+' | grep -Eo '[0-9]+')"
  PASSED=$(( TOTAL - FAILS ))
  echo ""
  echo "============================================"
  echo "  RESULTS (PeriodProgress):"
  echo "  Total: $TOTAL, Passed: $PASSED, Failed: $FAILS"
  if [[ "$FAILS" -eq 0 ]]; then
    echo "  STATUS: ALL PASSED!"
  else
    echo "  STATUS: SOME FAILED"
  fi
  echo "============================================"
elif grep -q "OK (" "$PROOF_FILE"; then
  echo "STATUS: ALL PASSED (see proof)."
fi

echo "Proof saved at: $PROOF_FILE"
exit "$EXIT_CODE"
