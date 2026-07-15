#!/usr/bin/env bash
# -----------------------------------------------------------------------------
# run-SalesPlanAndModuleMgmt-tests.sh — Prime (PRM) Sales Plan & Module Mgmt suite
# Single comprehensive suite: prm_SalesPlanAndModuleMgmt_TestCas.php (no V1/V2).
# Prime = CENTRAL. Host http://127.0.0.1:8000. APP_ENV=testing.
# Prereq: "Prime": true in prime_testing/modules_statuses.json (else 404).
# -----------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER="${FILTER:-prm_SalesPlanAndModuleMgmt_TestCas}"
SYNC_DB="${SYNC_DB:-0}"

RUNNER_DIR="${RUNNER_DIR:-/Users/bkwork/Herd/prime_testing}"
cd "$RUNNER_DIR" || { echo "ERROR: runner dir not found: $RUNNER_DIR"; exit 2; }

export APP_ENV=testing

STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="${PROOF_DIR:-$RUNNER_DIR/tests/Browser/Modules/Prime/SalesPlanAndModuleMgmt/proof}"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/salesplanandmodulemgmt_dusk_${STAMP}.log"

# Clean old screenshots for this feature.
SHOT_DIR="$RUNNER_DIR/tests/Browser/Modules/Prime/SalesPlanAndModuleMgmt/screenshots"
if [ -d "$SHOT_DIR" ]; then rm -f "$SHOT_DIR"/*.png 2>/dev/null || true; fi

if [ "$SYNC_DB" = "1" ]; then
  echo "[info] migrating test DB..." | tee -a "$PROOF_FILE"
  "$PHP_BIN" artisan migrate --force 2>&1 | tee -a "$PROOF_FILE"
fi

echo "[info] running: artisan dusk --filter=$FILTER" | tee -a "$PROOF_FILE"
"$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee -a "$PROOF_FILE"
DUSK_EXIT=${PIPESTATUS[0]}

echo "" | tee -a "$PROOF_FILE"
echo "===== SUMMARY =====" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|Failures:|Errors:|OK \(" "$PROOF_FILE" | tail -n 5 | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE"
echo "Dusk exit code: $DUSK_EXIT"
exit "$DUSK_EXIT"
