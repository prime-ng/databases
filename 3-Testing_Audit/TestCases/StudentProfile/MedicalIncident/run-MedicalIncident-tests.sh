#!/usr/bin/env bash
#
# Runner — StudentProfile / MedicalIncident Dusk suite (single file std_MedicalIncident_TestCas.php)
#
# Usage:
#   ./run-MedicalIncident-tests.sh [--php /path/to/php] [--filter test_medical_incident_10] [--sync-db]
#
# Prerequisites:
#   - Module STUDENT enabled in prime_testing/modules_statuses.json (disabled => 404 on all routes)
#   - APP_ENV=testing, Chrome + Dusk driver, MAIN_PROJECT_PATH set, prime_ai cloned alongside
#
set -uo pipefail

PHP_BIN="php"
FILTER=""
SYNC_DB="0"
TEST_CLASS="std_MedicalIncident_TestCas"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)     PHP_BIN="$2"; shift 2 ;;
    --filter)  FILTER="$2"; shift 2 ;;
    --sync-db) SYNC_DB="1"; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Resolve the prime_testing project root (env override wins).
PROJECT_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
cd "$PROJECT_ROOT" || { echo "Cannot cd to $PROJECT_ROOT"; exit 1; }

export APP_ENV=testing

STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="$PROJECT_ROOT/tests/Browser/Modules/StudentProfile/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/MedicalIncident_${STAMP}.log"

# Clean old screenshots.
rm -f "$PROJECT_ROOT"/tests/Browser/console/screenshots/medical-incident-fail-*.png 2>/dev/null || true

if [[ "$SYNC_DB" == "1" ]]; then
  echo "Syncing tenant DB (migrate:fresh via dusk env)..." | tee -a "$PROOF_FILE"
  "$PHP_BIN" artisan migrate --force 2>&1 | tee -a "$PROOF_FILE"
fi

DUSK_FILTER="$TEST_CLASS"
if [[ -n "$FILTER" ]]; then
  DUSK_FILTER="$FILTER"
fi

echo "Running: $PHP_BIN artisan dusk --filter=$DUSK_FILTER" | tee -a "$PROOF_FILE"
"$PHP_BIN" artisan dusk --filter="$DUSK_FILTER" 2>&1 | tee -a "$PROOF_FILE"
EXIT_CODE="${PIPESTATUS[0]}"

echo "" | tee -a "$PROOF_FILE"
echo "===== SUMMARY =====" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|Failures:|Errors:|OK|FAILURES" "$PROOF_FILE" | tail -n 5 | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE" | tee -a "$PROOF_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$PROOF_FILE"

exit "$EXIT_CODE"
