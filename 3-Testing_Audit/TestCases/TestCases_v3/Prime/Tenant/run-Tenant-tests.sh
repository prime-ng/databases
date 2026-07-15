#!/usr/bin/env bash
# Run the Prime "Tenant" Dusk suite (central prime_db scope, host 127.0.0.1:8000).
#
# Usage:
#   ./run-Tenant-tests.sh [--php /path/to/php] [--filter test_tenant_10] [--sync-db]
#
# Prerequisites:
#   - Prime module ENABLED in prime_testing/modules_statuses.json (else /prime/* → 404)
#   - App served at http://127.0.0.1:8000 (`php artisan serve`)
#   - APP_ENV=testing ; central super-admin present
set -euo pipefail

PHP_BIN="php"
FILTER="prm_Tenant_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --sync-db) SYNC_DB=1; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Resolve the prime_testing runner root (this script lives in the OLD_REPO tree).
RUNNER_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
TEST_PATH="tests/Browser/Modules/Prime/Tenant/prm_Tenant_TestCas.php"
PROOF_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/proof"
mkdir -p "$PROOF_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="$PROOF_DIR/tenant_dusk_${STAMP}.log"

cd "$RUNNER_ROOT"

if [[ "$SYNC_DB" == "1" ]]; then
  echo "==> Syncing test DB (migrate:fresh on central)…" | tee -a "$PROOF_FILE"
  "$PHP_BIN" artisan migrate --force 2>&1 | tee -a "$PROOF_FILE" || true
fi

echo "==> Cleaning old screenshots…" | tee -a "$PROOF_FILE"
rm -f tests/Browser/Modules/Prime/Tenant/screenshots/*.png 2>/dev/null || true

echo "==> Running Dusk: --filter=$FILTER" | tee -a "$PROOF_FILE"
set +e
APP_ENV=testing "$PHP_BIN" artisan dusk "$TEST_PATH" --filter="$FILTER" 2>&1 | tee -a "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

echo "" | tee -a "$PROOF_FILE"
echo "==> Summary" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|OK|FAILURES|Error" "$PROOF_FILE" | tail -n 5 | tee -a "$PROOF_FILE" || true
echo "Proof: $PROOF_FILE"
exit "$EXIT_CODE"
