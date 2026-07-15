#!/usr/bin/env bash
#
# run-InterventionApplied-tests.sh — BehaviouralAssessment / InterventionApplied Dusk suite runner (bash / Linux / WSL / macOS)
#
# Runs the single comprehensive test file bha_InterventionApplied_TestCas.php (48 methods).
#
# Usage:
#   ./run-InterventionApplied-tests.sh [--php <php-bin>] [--filter <method-or-pattern>] [--sync-db]
#
# Options:
#   --php <path>       PHP binary to use (default: php)
#   --filter <pattern> Dusk --filter value (default: whole class bha_InterventionApplied_TestCas)
#   --sync-db          Run `artisan migrate --force` before the suite
#   -h, --help         Show this help
#
# Prerequisites (see the Validation Report):
#   * Run from the prime_testing runner root (the file must be deployed under tests/Browser/...).
#   * BehaviouralAssessment ENABLED in modules_statuses.json (else 404 on every route).
#   * APP_ENV=testing (this script sets it so Dusk bypasses CSRF).
#   * prime_ai cloned alongside; MAIN_PROJECT_PATH set.
#   * At least one ba_incidents row (or a std_students + sch_employees pair) and one active ba_interventions row.

set -u

PHP_BIN="php"
FILTER="bha_InterventionApplied_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2";  shift 2 ;;
    --sync-db) SYNC_DB=1;   shift ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 2 ;;
  esac
done

export APP_ENV=testing

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="${PROOF_DIR}/InterventionApplied_dusk_${TIMESTAMP}.log"

echo "======================================================================"
echo " BehaviouralAssessment / InterventionApplied — Dusk suite"
echo " PHP     : ${PHP_BIN}"
echo " Filter  : ${FILTER}"
echo " Proof   : ${PROOF_FILE}"
echo "======================================================================"

# Clean previously captured screenshots for this feature (best-effort).
SHOT_DIR="tests/Browser/Modules/BehaviouralAssessment/InterventionApplied/screenshots"
if [[ -d "$SHOT_DIR" ]]; then
  echo "Cleaning old screenshots in ${SHOT_DIR} ..."
  find "$SHOT_DIR" -type f -name '*.png' -delete 2>/dev/null || true
fi

if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "Syncing DB (migrate --force) ..."
  "$PHP_BIN" artisan migrate --force 2>&1 | tee -a "$PROOF_FILE"
fi

echo "Running: ${PHP_BIN} artisan dusk --filter=${FILTER}"
"$PHP_BIN" artisan dusk --filter="${FILTER}" 2>&1 | tee -a "$PROOF_FILE"
DUSK_EXIT=${PIPESTATUS[0]}

echo "----------------------------------------------------------------------"
SUMMARY_LINE="$(grep -E 'Tests:\s+[0-9]+' "$PROOF_FILE" | tail -n 1)"
if [[ -n "$SUMMARY_LINE" ]]; then
  echo " Result summary: ${SUMMARY_LINE}"
else
  echo " Result summary: (no 'Tests:' line parsed — check ${PROOF_FILE})"
fi
echo " Dusk exit code : ${DUSK_EXIT}"
echo " Proof file     : ${PROOF_FILE}"
echo "======================================================================"

exit "$DUSK_EXIT"
