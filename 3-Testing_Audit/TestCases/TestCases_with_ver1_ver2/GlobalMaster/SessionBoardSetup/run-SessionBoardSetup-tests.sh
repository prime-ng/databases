#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Runner — GlobalMaster :: Session & Board Setup (CENTRAL / prime-side Dusk)
#
# Prerequisites:
#   * GlobalMaster AND Prime must be "true" in prime_testing/modules_statuses.json
#     (both currently false → 404 on all routes).
#   * APP_ENV=testing (bypasses CSRF; else 419 on state-changing requests).
#   * Chrome + ChromeDriver running; app served at http://127.0.0.1:8000.
#   * MAIN_PROJECT_PATH pointing at the prime_ai checkout (for source-shape asserts).
#
# Usage:
#   ./run-SessionBoardSetup-tests.sh [--php <path>] [--v1-only] [--v2-only] [--filter <name>]
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="php"
FILTER=""
RUN_V1=1
RUN_V2=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php) PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --v1-only) RUN_V2=0; shift ;;
    --v2-only) RUN_V1=0; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNNER_ROOT="${TEST_FILE_REPO:-/Users/bkwork/Herd/prime_testing}"
PROOF_DIR="${SCRIPT_DIR}/proof"
mkdir -p "${PROOF_DIR}"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="${PROOF_DIR}/SessionBoardSetup_${STAMP}.log"

V1_CLASS="glb_SessionBoardSetupV1_TestCas"
V2_CLASS="glb_SessionBoardSetupV2_TestCas"

echo "== Session & Board Setup Dusk run @ ${STAMP} ==" | tee "${PROOF_FILE}"
echo "Runner root: ${RUNNER_ROOT}" | tee -a "${PROOF_FILE}"

# Clean stale screenshots (best-effort).
rm -f "${RUNNER_ROOT}"/tests/Browser/screenshots/*.png 2>/dev/null || true

cd "${RUNNER_ROOT}" || { echo "Cannot cd to runner root"; exit 1; }

run_suite() {
  local cls="$1"
  local flt="$cls"
  if [[ -n "${FILTER}" ]]; then flt="${FILTER}"; fi
  echo "" | tee -a "${PROOF_FILE}"
  echo "--- Running ${cls} (filter=${flt}) ---" | tee -a "${PROOF_FILE}"
  APP_ENV=testing "${PHP_BIN}" artisan dusk --filter="${flt}" 2>&1 | tee -a "${PROOF_FILE}"
  return "${PIPESTATUS[0]}"
}

EXIT=0
if [[ "${RUN_V1}" -eq 1 ]]; then run_suite "${V1_CLASS}" || EXIT=$?; fi
if [[ "${RUN_V2}" -eq 1 ]]; then run_suite "${V2_CLASS}" || EXIT=$?; fi

echo "" | tee -a "${PROOF_FILE}"
echo "== Summary ==" | tee -a "${PROOF_FILE}"
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES|Skipped" "${PROOF_FILE}" | tail -n 8 | tee -a "${PROOF_FILE}"
echo "Proof: ${PROOF_FILE}" | tee -a "${PROOF_FILE}"
echo "Exit code: ${EXIT}" | tee -a "${PROOF_FILE}"
exit "${EXIT}"
