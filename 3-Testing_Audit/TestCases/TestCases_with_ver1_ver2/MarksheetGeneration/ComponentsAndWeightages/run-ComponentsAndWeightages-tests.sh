#!/usr/bin/env bash
# =============================================================================
# Runner — MarksheetGeneration / Components & Weightages Dusk tests (bash/WSL)
# Mirrors the golden reference runner. Runs V1 then V2 (or filtered), tees the
# output to a timestamped proof file, parses the summary and exits with the
# dusk exit code.
#
# Prerequisites:
#   - MarksheetGeneration ENABLED in prime_testing/modules_statuses.json (else 404).
#   - APP_ENV=testing (bypasses CSRF/419).
#   - prime_ai cloned alongside; MAIN_PROJECT_PATH set (see TEST_SETUP.md).
#   - MSH permissions granted (suite grants them in setUp / D39-MSH).
#
# Usage:
#   ./run-ComponentsAndWeightages-tests.sh [--php <path>] [--filter <name>]
#                                          [--v1-only] [--v2-only]
# =============================================================================
set -uo pipefail

PHP_BIN="php"
FILTER=""
V1_ONLY=false
V2_ONLY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)     PHP_BIN="$2"; shift 2 ;;
    --filter)  FILTER="$2";  shift 2 ;;
    --v1-only) V1_ONLY=true; shift ;;
    --v2-only) V2_ONLY=true; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
PROOF_DIR="${SCRIPT_DIR}/proof"
mkdir -p "${PROOF_DIR}"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="${PROOF_DIR}/components-and-weightages-${STAMP}.log"

V1_CLASS="msh_ComponentsAndWeightagesV1_TestCas"
V2_CLASS="msh_ComponentsAndWeightagesV2_TestCas"

# Clean stale screenshots.
SHOT_DIR="${PROJECT_ROOT}/tests/Browser/Modules/MarksheetGeneration/ComponentsAndWeightages/screenshots"
[[ -d "${SHOT_DIR}" ]] && rm -f "${SHOT_DIR}"/*.png 2>/dev/null

run_suite() {
  local filter="$1"
  echo "=== Running: --filter=${filter} ===" | tee -a "${PROOF_FILE}"
  ( cd "${PROJECT_ROOT}" && "${PHP_BIN}" artisan dusk --filter="${filter}" ) 2>&1 | tee -a "${PROOF_FILE}"
  return "${PIPESTATUS[0]}"
}

EXIT_CODE=0
if [[ -n "${FILTER}" ]]; then
  run_suite "${FILTER}"; EXIT_CODE=$?
elif [[ "${V1_ONLY}" == true ]]; then
  run_suite "${V1_CLASS}"; EXIT_CODE=$?
elif [[ "${V2_ONLY}" == true ]]; then
  run_suite "${V2_CLASS}"; EXIT_CODE=$?
else
  run_suite "${V1_CLASS}"; RC1=$?
  run_suite "${V2_CLASS}"; RC2=$?
  EXIT_CODE=$(( RC1 != 0 ? RC1 : RC2 ))
fi

echo "" | tee -a "${PROOF_FILE}"
echo "=== Summary ===" | tee -a "${PROOF_FILE}"
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES|Errors:" "${PROOF_FILE}" | tail -n 6 | tee -a "${PROOF_FILE}"
echo "Proof: ${PROOF_FILE}" | tee -a "${PROOF_FILE}"
echo "Exit code: ${EXIT_CODE}" | tee -a "${PROOF_FILE}"
exit "${EXIT_CODE}"
