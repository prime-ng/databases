#!/usr/bin/env bash
#
# Runner for the PRIME (central) TenantDomain Dusk suite.
# Feature runs on http://127.0.0.1:8000 (central) — NO tenant init.
#
# Usage:
#   ./run-TenantDomain-tests.sh [--php /path/to/php] [--filter test_tenantdomain_11]
#
set -uo pipefail

PHP_BIN="php"
FILTER=""
TEST_CLASS="prm_TenantDomain_TestCas"
# Adjust if your runner clone lives elsewhere.
TEST_REPO="${TEST_FILE_REPO:-/Users/bkwork/Herd/prime_testing}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2";  shift 2 ;;
    --repo)   TEST_REPO="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

cd "$TEST_REPO" || { echo "Cannot cd to $TEST_REPO"; exit 1; }

export APP_ENV=testing

STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="tests/Browser/Modules/Prime/TenantDomain/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/tenantdomain_${STAMP}.log"

# Clean prior screenshots.
SHOTS="tests/Browser/Modules/Prime/TenantDomain/screenshots"
[[ -d "$SHOTS" ]] && rm -f "$SHOTS"/*.png 2>/dev/null

echo "=== TenantDomain (PRIME/central) Dusk run @ ${STAMP} ===" | tee "$PROOF_FILE"
echo "Host: http://127.0.0.1:8000 | Repo: $TEST_REPO" | tee -a "$PROOF_FILE"
echo "NOTE: Ensure Prime module is ENABLED in modules_statuses.json." | tee -a "$PROOF_FILE"

DUSK_FILTER="$TEST_CLASS"
[[ -n "$FILTER" ]] && DUSK_FILTER="$FILTER"

"$PHP_BIN" artisan dusk --filter="$DUSK_FILTER" 2>&1 | tee -a "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo "" | tee -a "$PROOF_FILE"
echo "=== Summary ===" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|Failures:|Errors:|OK" "$PROOF_FILE" | tail -5 | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE"
echo "Exit code: $EXIT_CODE"
exit "$EXIT_CODE"
