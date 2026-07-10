#!/usr/bin/env bash
# Runner for the Prime > TenantGroup Dusk suite (single file: prm_TenantGroup_TestCas.php).
# Central feature — runs against http://127.0.0.1:8000 (prime_db). Requires the Prime module ENABLED
# in modules_statuses.json and APP_ENV=testing.
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER="${1:-}"                       # optional: a single test_* method name
TEST_FILE="tests/Browser/Modules/Prime/TenantGroup/prm_TenantGroup_TestCas.php"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="tests/Browser/Modules/Prime/TenantGroup/proof"
PROOF_FILE="${PROOF_DIR}/tenantgroup_run_${STAMP}.log"

# Move to the prime_testing runner root (this script assumes it is executed there,
# or set RUNNER_ROOT to the prime_testing path).
RUNNER_ROOT="${RUNNER_ROOT:-/Users/bkwork/Herd/prime_testing}"
cd "$RUNNER_ROOT" || { echo "Cannot cd to runner root $RUNNER_ROOT"; exit 2; }

mkdir -p "$PROOF_DIR"

# Clean old screenshots for this feature.
rm -rf tests/Browser/Modules/Prime/TenantGroup/screenshots/* 2>/dev/null || true

export APP_ENV=testing

CMD=("$PHP_BIN" artisan dusk "$TEST_FILE")
if [[ -n "$FILTER" ]]; then
  CMD+=(--filter "$FILTER")
fi

echo "Running: ${CMD[*]}"
"${CMD[@]}" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE="${PIPESTATUS[0]}"

echo ""
echo "==================== SUMMARY ===================="
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES|Errors:" "$PROOF_FILE" | tail -n 5
echo "Proof: $PROOF_FILE"
echo "Exit code: $EXIT_CODE"
echo "================================================="

exit "$EXIT_CODE"
