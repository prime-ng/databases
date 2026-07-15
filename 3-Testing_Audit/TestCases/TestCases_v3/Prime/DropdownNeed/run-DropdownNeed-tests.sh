#!/usr/bin/env bash
# =============================================================================
# DropdownNeed (Prime / PRM — CENTRAL) Dusk test runner
# Single comprehensive suite: sys_DropdownNeed_TestCas.php
# =============================================================================
# Prerequisites (see Validation Report §Environment):
#   * Prime module ENABLED in prime_testing/modules_statuses.json  (currently false → routes 404)
#   * APP_ENV=testing  (bypasses CSRF; else 419 on state-changing requests)
#   * Central app served at http://127.0.0.1:8000  (Prime tests hard-require 127.0.0.1)
#   * ChromeDriver running for the browser-tagged methods
# =============================================================================
set -u

PHP_BIN="${PHP_BIN:-php}"
FILTER="${1:-}"
TEST_CLASS="sys_DropdownNeed_TestCas"
TEST_PATH="tests/Browser/Modules/Prime/DropdownNeed/${TEST_CLASS}.php"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROOF_DIR="${SCRIPT_DIR}/proof"
mkdir -p "${PROOF_DIR}"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="${PROOF_DIR}/dropdownneed_dusk_${STAMP}.log"

# Clean stale screenshots for this feature (best-effort).
SHOT_DIR="tests/Browser/Modules/Prime/DropdownNeed/screenshots"
[ -d "${SHOT_DIR}" ] && rm -f "${SHOT_DIR}"/*.png 2>/dev/null

echo "==============================================================="
echo " DropdownNeed (PRM central) — Dusk suite"
echo " File   : ${TEST_PATH}"
echo " Filter : ${FILTER:-<all methods>}"
echo " Proof  : ${PROOF_FILE}"
echo "==============================================================="

ARGS=(artisan dusk "${TEST_PATH}")
if [ -n "${FILTER}" ]; then
  ARGS+=(--filter "${FILTER}")
fi

APP_ENV=testing "${PHP_BIN}" "${ARGS[@]}" 2>&1 | tee "${PROOF_FILE}"
EXIT_CODE="${PIPESTATUS[0]}"

echo "---------------------------------------------------------------"
grep -E "Tests:|Assertions:|OK|FAILURES|Skipped|Error" "${PROOF_FILE}" | tail -n 5
echo "---------------------------------------------------------------"
echo "Exit code: ${EXIT_CODE}"
exit "${EXIT_CODE}"
