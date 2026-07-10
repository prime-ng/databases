#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Dusk runner — GlobalMaster > Dropdown (central / prime-side)
#
# Prerequisites (see Validation Report §Environment):
#   * prime_ai cloned alongside; MAIN_PROJECT_PATH set (TEST_SETUP.md)
#   * modules_statuses.json: "GlobalMaster": true AND "Prime": true (else 404)
#   * APP_ENV=testing (bypasses CSRF; else 419 on POST)
#   * Central host reachable at http://127.0.0.1:8000 (PrimeDuskTestCase hardcodes it)
#
# Copy sys_DropdownV1_TestCas.php / sys_DropdownV2_TestCas.php into
#   prime_testing/tests/Browser/Modules/Prime/GlobalMaster/Dropdown/
# before running (this script only orchestrates the Dusk run).
#
# Usage:
#   ./run-Dropdown-tests.sh [--php <path>] [--v1-only] [--v2-only] [--filter <name>] [--sync-db]
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="php"
FILTER=""
RUN_V1=1
RUN_V2=1
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)     PHP_BIN="$2"; shift 2 ;;
    --filter)  FILTER="$2"; shift 2 ;;
    --v1-only) RUN_V2=0; shift ;;
    --v2-only) RUN_V1=0; shift ;;
    --sync-db) SYNC_DB=1; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROOF_DIR="${SCRIPT_DIR}/proof"
mkdir -p "${PROOF_DIR}"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="${PROOF_DIR}/dropdown_dusk_${STAMP}.log"

export APP_ENV=testing

echo "== GlobalMaster > Dropdown Dusk run @ ${STAMP} ==" | tee "${PROOF_FILE}"

# Clean stale screenshots.
find "${SCRIPT_DIR}" -type d -name screenshots -exec rm -f {}/*.png \; 2>/dev/null || true

if [[ "${SYNC_DB}" == "1" ]]; then
  echo "-- Refreshing test DB --" | tee -a "${PROOF_FILE}"
  "${PHP_BIN}" artisan migrate:fresh --seed --env=testing 2>&1 | tee -a "${PROOF_FILE}"
fi

run_suite () {
  local class="$1"
  local flt="--filter=${class}"
  if [[ -n "${FILTER}" ]]; then flt="--filter=${FILTER}"; fi
  echo "-- Running ${class} (${flt}) --" | tee -a "${PROOF_FILE}"
  "${PHP_BIN}" artisan dusk "${flt}" 2>&1 | tee -a "${PROOF_FILE}"
  return "${PIPESTATUS[0]}"
}

EXIT=0
[[ "${RUN_V1}" == "1" ]] && { run_suite "sys_DropdownV1_TestCas" || EXIT=$?; }
[[ "${RUN_V2}" == "1" ]] && { run_suite "sys_DropdownV2_TestCas" || EXIT=$?; }

echo "== Summary ==" | tee -a "${PROOF_FILE}"
grep -E "Tests:|Assertions:|OK|FAILURES|Failures:|Error" "${PROOF_FILE}" | tail -n 8 | tee -a "${PROOF_FILE}"
echo "Proof: ${PROOF_FILE}"
exit "${EXIT}"
