#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Configuration Templates (MarksheetGeneration) — Dusk runner (bash / WSL / Linux)
#
# Copy the two PHP suites into the runner before executing:
#   prime_testing/tests/Browser/msh_ConfigurationTemplatesV1_TestCas.php
#   prime_testing/tests/Browser/msh_ConfigurationTemplatesV2_TestCas.php
#
# Prerequisites:
#   - MarksheetGeneration enabled in prime_testing/modules_statuses.json
#   - MSH permissions seeded/granted for the Dusk admin (D39-MSH)
#   - APP_ENV=testing ; ChromeDriver running ; tenant reachable at DUSK_TENANT_URL
#
# Usage:
#   ./run-ConfigurationTemplates-tests.sh              # both suites
#   ./run-ConfigurationTemplates-tests.sh --v1         # V1 only
#   ./run-ConfigurationTemplates-tests.sh --v2         # V2 only
#   ./run-ConfigurationTemplates-tests.sh --filter test_config_template_10_create_persists_with_activity_stored
#   PHP_BIN=/usr/bin/php ./run-ConfigurationTemplates-tests.sh
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER=""
SUITES=("msh_ConfigurationTemplatesV1_TestCas" "msh_ConfigurationTemplatesV2_TestCas")

while [[ $# -gt 0 ]]; do
  case "$1" in
    --v1) SUITES=("msh_ConfigurationTemplatesV1_TestCas"); shift ;;
    --v2) SUITES=("msh_ConfigurationTemplatesV2_TestCas"); shift ;;
    --filter) FILTER="${2:-}"; shift 2 ;;
    --php) PHP_BIN="${2:-php}"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROOF_DIR="${SCRIPT_DIR}/proof"
mkdir -p "${PROOF_DIR}"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="${PROOF_DIR}/ConfigurationTemplates_${STAMP}.log"

# Clean stale screenshots for this feature (best effort)
find . -type d -path "*MarksheetGeneration/ConfigurationTemplates/screenshots" 2>/dev/null \
  | while read -r d; do rm -f "${d}"/*.png 2>/dev/null; done

EXIT_CODE=0
for SUITE in "${SUITES[@]}"; do
  ARG="${SUITE}"
  [[ -n "${FILTER}" ]] && ARG="${SUITE}::${FILTER}"
  echo "===== Running ${SUITE} =====" | tee -a "${PROOF_FILE}"
  "${PHP_BIN}" artisan dusk --filter="${ARG}" 2>&1 | tee -a "${PROOF_FILE}"
  RC=${PIPESTATUS[0]}
  [[ ${RC} -ne 0 ]] && EXIT_CODE=${RC}
done

echo "" | tee -a "${PROOF_FILE}"
echo "===== Summary =====" | tee -a "${PROOF_FILE}"
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES|Error" "${PROOF_FILE}" | tail -n 20
echo "Proof written to: ${PROOF_FILE}"
exit ${EXIT_CODE}
