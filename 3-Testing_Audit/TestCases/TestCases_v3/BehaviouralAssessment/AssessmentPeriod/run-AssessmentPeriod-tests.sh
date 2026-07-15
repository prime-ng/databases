#!/usr/bin/env bash
#
# Runner — BehaviouralAssessment / AssessmentPeriod Dusk suite
# One comprehensive test file: bha_AssessmentPeriod_TestCas.php (59 methods).
#
# Usage:
#   ./run-AssessmentPeriod-tests.sh [--php <php-bin>] [--filter <method>] [--sync-db]
#
# Examples:
#   ./run-AssessmentPeriod-tests.sh
#   ./run-AssessmentPeriod-tests.sh --filter test_period_29
#   ./run-AssessmentPeriod-tests.sh --php /usr/bin/php --sync-db
#
set -uo pipefail

# --- Config -----------------------------------------------------------------
APP_REPO="${APP_REPO:-/Users/bkwork/Herd/prime_testing}"
TEST_CLASS="bha_AssessmentPeriod_TestCas"
PHP_BIN="php"
FILTER=""
SYNC_DB=0

# --- Args -------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)     PHP_BIN="$2"; shift 2 ;;
    --filter)  FILTER="$2";  shift 2 ;;
    --sync-db) SYNC_DB=1;    shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

if [[ ! -d "$APP_REPO" ]]; then
  echo "ERROR: APP_REPO not found: $APP_REPO" >&2
  exit 2
fi
cd "$APP_REPO" || exit 2

# --- Proof dir + screenshots ------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"
STAMP="$(date '+%Y%m%d_%H%M%S')"
PROOF_FILE="$PROOF_DIR/AssessmentPeriod_${STAMP}.log"

SHOT_DIR="$APP_REPO/tests/Browser/Modules/BehaviouralAssessment/AssessmentPeriod/screenshots"
if [[ -d "$SHOT_DIR" ]]; then
  echo "Cleaning old screenshots in $SHOT_DIR"
  rm -f "$SHOT_DIR"/*.png 2>/dev/null || true
fi

# --- Optional DB sync -------------------------------------------------------
if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "Syncing tenant migrations..."
  "$PHP_BIN" artisan tenants:migrate --force 2>&1 | tee -a "$PROOF_FILE" || true
fi

# --- Build dusk command -----------------------------------------------------
DUSK_FILTER="$TEST_CLASS"
if [[ -n "$FILTER" ]]; then
  DUSK_FILTER="$FILTER"
fi

echo "======================================================================"
echo " AssessmentPeriod Dusk suite"
echo " php     : $PHP_BIN"
echo " filter  : $DUSK_FILTER"
echo " proof   : $PROOF_FILE"
echo "======================================================================"

"$PHP_BIN" artisan dusk --filter="$DUSK_FILTER" 2>&1 | tee -a "$PROOF_FILE"
DUSK_EXIT="${PIPESTATUS[0]}"

# --- Parse summary ----------------------------------------------------------
echo ""
echo "---------------------------- SUMMARY ---------------------------------"
SUMMARY_LINE="$(grep -Ei 'Tests:.*Assertions:' "$PROOF_FILE" | tail -1)"
if [[ -n "$SUMMARY_LINE" ]]; then
  echo "$SUMMARY_LINE"
else
  echo "No PHPUnit summary line found (see $PROOF_FILE)."
fi
echo "Dusk exit code: $DUSK_EXIT"
echo "Proof: $PROOF_FILE"
echo "----------------------------------------------------------------------"

exit "$DUSK_EXIT"
