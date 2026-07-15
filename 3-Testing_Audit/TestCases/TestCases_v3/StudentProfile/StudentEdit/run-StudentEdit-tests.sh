#!/usr/bin/env bash
# =============================================================================
# StudentEdit (StudentProfile) — Dusk runner (bash / Linux / WSL / macOS)
# ONE test file per screen: std_StudentEdit_TestCas.php
#
# Prerequisites:
#   - StudentProfile ENABLED in prime_testing/modules_statuses.json (else 404 on all routes)
#   - APP_ENV=testing (bypasses CSRF; else 419 on state-changing requests)
#   - Chromedriver running; tenant seeded at DUSK_TENANT_URL
# =============================================================================
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER="${1:-}"
TEST_CLASS="std_StudentEdit_TestCas"
PROOF_DIR="proof"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="${PROOF_DIR}/StudentEdit_${STAMP}.log"

mkdir -p "${PROOF_DIR}"

echo "== Cleaning old screenshots =="
rm -f tests/Browser/console/screenshots/student-edit-*.png 2>/dev/null || true

echo "== Running ${TEST_CLASS} =="
if [[ -n "${FILTER}" ]]; then
  "${PHP_BIN}" artisan dusk --filter="${FILTER}" 2>&1 | tee "${PROOF_FILE}"
else
  "${PHP_BIN}" artisan dusk --filter="${TEST_CLASS}" 2>&1 | tee "${PROOF_FILE}"
fi
DUSK_EXIT=${PIPESTATUS[0]}

echo ""
echo "== Summary =="
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES|Error" "${PROOF_FILE}" | tail -n 5 || true
echo "Proof saved to: ${PROOF_FILE}"
echo "Dusk exit code: ${DUSK_EXIT}"
exit "${DUSK_EXIT}"
