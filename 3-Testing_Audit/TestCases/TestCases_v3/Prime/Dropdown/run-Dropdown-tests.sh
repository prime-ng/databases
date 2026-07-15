#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Dropdown (PRM / Prime, central) — Dusk runner (bash / macOS / Linux / WSL)
# Runs the single comprehensive suite: sys_Dropdown_TestCas.php
#
# Prerequisites:
#   - Prime module ENABLED in prime_testing/modules_statuses.json
#   - App served at http://127.0.0.1:8000 (APP_ENV=testing)
#   - Test file copied into: tests/Browser/Modules/Prime/Dropdown/sys_Dropdown_TestCas.php
# Usage:
#   ./run-Dropdown-tests.sh [--php /path/to/php] [--filter test_dropdown_01] [--sync-db]
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="php"
FILTER="sys_Dropdown_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2";  shift 2 ;;
    --sync-db) SYNC_DB=1;   shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROOF_DIR="${SCRIPT_DIR}/proof"
mkdir -p "${PROOF_DIR}"
STAMP="$(date '+%Y%m%d_%H%M%S')"
PROOF_FILE="${PROOF_DIR}/dropdown_dusk_${STAMP}.log"

# Resolve the prime_testing runner root (override via MAIN_PROJECT_PATH).
RUNNER_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
cd "${RUNNER_ROOT}" || { echo "Cannot cd to runner root ${RUNNER_ROOT}"; exit 3; }

echo "== Dropdown Dusk run ==" | tee "${PROOF_FILE}"
echo "Runner root : ${RUNNER_ROOT}" | tee -a "${PROOF_FILE}"
echo "PHP         : $(${PHP_BIN} -v | head -n1)" | tee -a "${PROOF_FILE}"
echo "Filter      : ${FILTER}" | tee -a "${PROOF_FILE}"

# Clean old per-feature screenshots.
SHOT_DIR="${RUNNER_ROOT}/tests/Browser/Modules/Prime/Dropdown/screenshots"
[[ -d "${SHOT_DIR}" ]] && rm -f "${SHOT_DIR}"/*.png 2>/dev/null

if [[ "${SYNC_DB}" -eq 1 ]]; then
  echo "-- migrating central DB --" | tee -a "${PROOF_FILE}"
  ${PHP_BIN} artisan migrate --force 2>&1 | tee -a "${PROOF_FILE}"
fi

echo "-- running dusk --" | tee -a "${PROOF_FILE}"
APP_ENV=testing ${PHP_BIN} artisan dusk --filter="${FILTER}" 2>&1 | tee -a "${PROOF_FILE}"
DUSK_EXIT=${PIPESTATUS[0]}

echo "" | tee -a "${PROOF_FILE}"
SUMMARY="$(grep -E 'Tests:|Assertions:|OK \(|FAILURES!' "${PROOF_FILE}" | tail -n 3)"
echo "== Summary ==" | tee -a "${PROOF_FILE}"
echo "${SUMMARY:-<no summary line parsed>}" | tee -a "${PROOF_FILE}"
echo "Dusk exit code: ${DUSK_EXIT}" | tee -a "${PROOF_FILE}"
echo "Proof: ${PROOF_FILE}"

exit "${DUSK_EXIT}"
