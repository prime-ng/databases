#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Runner — MarksheetGeneration · Student Results & Print (Dusk, single suite)
# One comprehensive test file: msh_StudentResultsAndPrint_TestCas.php
#
# Usage:
#   ./run-StudentResultsAndPrint-tests.sh [--filter=<method>] [--php=/path/to/php]
#
# Prereqs:
#   - Run from the prime_testing runner repo root (MAIN_PROJECT_PATH set, prime_ai cloned alongside).
#   - MarksheetGeneration enabled in modules_statuses.json (else routes 404).
#   - APP_ENV=testing ; tenant seed data (active unlocked schedule + class-section + student).
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="php"
CLASS_FILTER="msh_StudentResultsAndPrint_TestCas"

for arg in "$@"; do
  case "$arg" in
    --php=*)    PHP_BIN="${arg#*=}" ;;
    --filter=*) CLASS_FILTER="${arg#*=}" ;;
    *) echo "Unknown arg: $arg" ; exit 2 ;;
  esac
done

export APP_ENV=testing

TS="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="tests/Browser/Modules/MarksheetGeneration/StudentResultsAndPrint/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="${PROOF_DIR}/proof_${TS}.log"

# Clean old screenshots
SHOT_DIR="tests/Browser/Modules/MarksheetGeneration/StudentResultsAndPrint/screenshots"
[ -d "$SHOT_DIR" ] && find "$SHOT_DIR" -name '*.png' -delete 2>/dev/null

echo "=== MarksheetGeneration / StudentResultsAndPrint — Dusk run @ ${TS} ===" | tee "$PROOF_FILE"
echo "Filter: ${CLASS_FILTER}" | tee -a "$PROOF_FILE"

"$PHP_BIN" artisan dusk --filter="$CLASS_FILTER" 2>&1 | tee -a "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo "" | tee -a "$PROOF_FILE"
echo "=== Summary ===" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|Failures:|Errors:|Skipped:|OK" "$PROOF_FILE" | tail -n 5 | tee -a "$PROOF_FILE"
echo "Proof: ${PROOF_FILE}" | tee -a "$PROOF_FILE"
echo "Exit code: ${EXIT_CODE}" | tee -a "$PROOF_FILE"

exit "$EXIT_CODE"
