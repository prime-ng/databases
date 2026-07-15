#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Subscription (Billing / Prime-central) Dusk runner — bash / WSL / macOS
# Mirrors the Billing golden runners. ONE test file per screen.
#
# Prerequisites (see Validation Report §Environment):
#   - prime_ai cloned alongside prime_testing; MAIN_PROJECT_PATH set (TEST_SETUP.md)
#   - modules_statuses.json: "Billing": true AND "Prime": true  (both are false by default → 404)
#   - Prime/central features run on http://127.0.0.1:8000 (NOT test.localhost)
#   - APP_ENV=testing (CSRF bypassed); ChromeDriver running
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER="${1:-}"
TEST_PATH="tests/Browser/Modules/Prime/Billing/Subscription/prm_Subscription_TestCas.php"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="tests/Browser/Modules/Prime/Billing/Subscription/proof"
PROOF_FILE="${PROOF_DIR}/subscription_run_${STAMP}.txt"

# Move to the prime_testing repo root (two levels up from this artifact is NOT the runner;
# the runner must be executed from the prime_testing checkout — cd there first).
if [[ -n "${PRIME_TESTING_PATH:-}" ]]; then
  cd "${PRIME_TESTING_PATH}" || { echo "Cannot cd to PRIME_TESTING_PATH=${PRIME_TESTING_PATH}"; exit 2; }
fi

mkdir -p "${PROOF_DIR}"

# Clean old screenshots for this feature.
rm -f tests/Browser/Modules/Prime/Billing/Subscription/screenshots/*.png 2>/dev/null || true

echo "== Subscription Dusk run @ ${STAMP} ==" | tee "${PROOF_FILE}"
echo "PHP: ${PHP_BIN}" | tee -a "${PROOF_FILE}"

CMD=("${PHP_BIN}" artisan dusk "${TEST_PATH}")
if [[ -n "${FILTER}" ]]; then
  CMD+=(--filter "${FILTER}")
  echo "Filter: ${FILTER}" | tee -a "${PROOF_FILE}"
fi

echo "Running: ${CMD[*]}" | tee -a "${PROOF_FILE}"
"${CMD[@]}" 2>&1 | tee -a "${PROOF_FILE}"
EXIT_CODE=${PIPESTATUS[0]}

echo "" | tee -a "${PROOF_FILE}"
SUMMARY="$(grep -Eo 'Tests:[^,]*(, Assertions:[^,]*)?(, (Failures|Errors|Skipped):[^,]*)*' "${PROOF_FILE}" | tail -1)"
echo "Summary: ${SUMMARY:-<none parsed>}" | tee -a "${PROOF_FILE}"
echo "Proof written to: ${PROOF_FILE}" | tee -a "${PROOF_FILE}"
echo "Exit code: ${EXIT_CODE}" | tee -a "${PROOF_FILE}"

exit "${EXIT_CODE}"
