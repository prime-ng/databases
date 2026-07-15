#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Runner: Prime → TenantManagement Dusk suite (read/composite dashboard)
# Single test file: prm_TenantManagement_TestCas.php  (24 methods)
# Central feature — runs on http://127.0.0.1:8000. Prime module must be enabled.
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER="${FILTER:-prm_TenantManagement_TestCas}"
SYNC_DB="${SYNC_DB:-0}"
TEST_PATH="tests/Browser/Modules/Prime/TenantManagement/prm_TenantManagement_TestCas.php"

# Resolve prime_testing project root (assumes runner invoked from there or MAIN set)
PROJECT_ROOT="${MAIN_PROJECT_PATH:-$(pwd)}"
cd "$PROJECT_ROOT" || { echo "Cannot cd to $PROJECT_ROOT"; exit 2; }

STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="tests/Browser/Modules/Prime/TenantManagement/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/tenantmanagement_${STAMP}.log"

echo "=== Prime/TenantManagement Dusk run @ ${STAMP} ===" | tee "$PROOF_FILE"
echo "PHP: $($PHP_BIN -v | head -n1)"                     | tee -a "$PROOF_FILE"
echo "Filter: $FILTER"                                    | tee -a "$PROOF_FILE"

# Clean old screenshots for this feature
find "tests/Browser/Modules/Prime/TenantManagement/screenshots" -type f -name '*.png' -delete 2>/dev/null || true

if [ "$SYNC_DB" = "1" ]; then
  echo "Syncing test DB..." | tee -a "$PROOF_FILE"
  APP_ENV=testing "$PHP_BIN" artisan migrate --force 2>&1 | tee -a "$PROOF_FILE"
fi

echo "--- artisan dusk ---" | tee -a "$PROOF_FILE"
APP_ENV=testing "$PHP_BIN" artisan dusk --filter="$FILTER" "$TEST_PATH" 2>&1 | tee -a "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo "--- summary ---" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|Failures:|Errors:|OK \(" "$PROOF_FILE" | tail -n 5 | tee -a "$PROOF_FILE"

echo "Exit code: $EXIT_CODE" | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE"
exit "$EXIT_CODE"
