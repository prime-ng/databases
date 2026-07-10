#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Runner: Billing / GatewayIntegration Dusk suite (PLANNING-STAGE STUB SET)
# ---------------------------------------------------------------------------
# NOTE: This feature is NOT IMPLEMENTED (planning stage). The suite is designed
# to be GREEN: test_01 asserts the current reality (the gap); every planned
# behavioural test is markTestSkipped(). Expect: 1 passing, 38 skipped.
#
# Prerequisites:
#   - prime_ai cloned alongside prime_testing; MAIN_PROJECT_PATH set (TEST_SETUP.md).
#   - The Billing module ENABLED in prime_testing/modules_statuses.json (disabled
#     module => 404 on all routes). [E19]
#   - APP_ENV=testing (bypasses CSRF for Dusk). [E20]
#   - Central/prime host reachable at http://127.0.0.1:8000 (BillingDuskTestCase
#     hard-requires the 127.0.0.1 host). [E21]
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER="${1:-bil_GatewayIntegration_TestCas}"
TEST_PATH="tests/Browser/Modules/Prime/Billing/GatewayIntegration/bil_GatewayIntegration_TestCas.php"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROOF_DIR="${SCRIPT_DIR}/proof"
mkdir -p "${PROOF_DIR}"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="${PROOF_DIR}/GatewayIntegration_${STAMP}.log"

# Locate the prime_testing runner root (default Herd path; override via TEST_REPO).
TEST_REPO="${TEST_REPO:-/Users/bkwork/Herd/prime_testing}"

echo "== Billing/GatewayIntegration Dusk run (planning-stage) =="
echo "Runner repo : ${TEST_REPO}"
echo "Filter      : ${FILTER}"
echo "Proof file  : ${PROOF_FILE}"
echo "Expectation : 1 passed, 38 skipped (feature not implemented)."
echo

if [ ! -f "${TEST_REPO}/${TEST_PATH}" ]; then
  echo "WARN: ${TEST_PATH} not found under ${TEST_REPO}."
  echo "      This artifact set lives in the knowledge base; copy the .php into the"
  echo "      runner (or point TEST_REPO at it) before executing. Skipping run."
  exit 0
fi

# Clean old screenshots for this feature.
rm -f "${TEST_REPO}/tests/Browser/Modules/Prime/Billing/GatewayIntegration/screenshots/"*.png 2>/dev/null || true

pushd "${TEST_REPO}" >/dev/null || exit 1
APP_ENV=testing "${PHP_BIN}" artisan dusk --filter="${FILTER}" 2>&1 | tee "${PROOF_FILE}"
DUSK_EXIT=${PIPESTATUS[0]}
popd >/dev/null || true

echo
echo "== Summary =="
grep -E 'Tests:|OK|FAIL|Skipped|Risky' "${PROOF_FILE}" | tail -5 || true
echo "Dusk exit code: ${DUSK_EXIT}"
exit "${DUSK_EXIT}"
