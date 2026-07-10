#!/usr/bin/env bash
# Run the Prime RolePermission Dusk suite (central / 127.0.0.1:8000).
# Usage: ./run-RolePermission-tests.sh [--php /path/to/php] [--filter test_name] [--sync-db]
set -uo pipefail

PHP_BIN="php"
FILTER="sys_RolePermission_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --sync-db) SYNC_DB=1; shift ;;
    *) echo "Unknown arg: $1"; exit 2 ;;
  esac
done

# Locate the prime_testing runner root (this script may live in the artifacts tree).
RUNNER_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
cd "$RUNNER_ROOT" || { echo "Runner root not found: $RUNNER_ROOT"; exit 1; }

export APP_ENV=testing
TS="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="tests/Browser/Modules/Prime/RolePermission/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/rolepermission_${TS}.log"

# Clean stale screenshots.
find tests/Browser/Modules/Prime/RolePermission -type d -name screenshots -exec rm -f {}/*.png \; 2>/dev/null || true

if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "Syncing test DB..." | tee -a "$PROOF_FILE"
  "$PHP_BIN" artisan migrate --env=testing 2>&1 | tee -a "$PROOF_FILE"
fi

echo "Running: $PHP_BIN artisan dusk --filter=$FILTER" | tee -a "$PROOF_FILE"
"$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee -a "$PROOF_FILE"
DUSK_EXIT=${PIPESTATUS[0]}

echo "" | tee -a "$PROOF_FILE"
echo "==== Summary ====" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|OK|FAIL|Error" "$PROOF_FILE" | tail -n 5
echo "Proof written to: $PROOF_FILE"
echo "Exit code: $DUSK_EXIT"
exit "$DUSK_EXIT"
