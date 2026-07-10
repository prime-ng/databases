#!/usr/bin/env bash
# Run the MarksheetGeneration — Components & Weightages Dusk suite (single file).
# Usage: ./run-ComponentsAndWeightages-tests.sh [--filter <pattern>] [--php <php>] [--sync-db]
set -uo pipefail

PHP_BIN="php"
FILTER="msh_ComponentsAndWeightages_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --filter) FILTER="$2"; shift 2 ;;
    --php)    PHP_BIN="$2"; shift 2 ;;
    --sync-db) SYNC_DB=1; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Resolve the prime_testing runner root (this script may live in the OLD_REPO TestCases tree).
RUNNER_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
cd "$RUNNER_ROOT" || { echo "Runner root not found: $RUNNER_ROOT"; exit 1; }

export APP_ENV=testing

TS="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="$RUNNER_ROOT/tests/Browser/Modules/MarksheetGeneration/ComponentsAndWeightages/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/run_${TS}.log"

# Clean old screenshots.
SHOT_DIR="$RUNNER_ROOT/tests/Browser/Modules/MarksheetGeneration/ComponentsAndWeightages/screenshots"
[[ -d "$SHOT_DIR" ]] && find "$SHOT_DIR" -name '*.png' -delete 2>/dev/null

if [[ "$SYNC_DB" == "1" ]]; then
  echo "Refreshing tenant test DB..." | tee -a "$PROOF_FILE"
  "$PHP_BIN" artisan migrate:fresh --seed 2>&1 | tee -a "$PROOF_FILE"
fi

echo "Running dusk --filter=$FILTER" | tee -a "$PROOF_FILE"
"$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee -a "$PROOF_FILE"
DUSK_EXIT=${PIPESTATUS[0]}

echo "" | tee -a "$PROOF_FILE"
echo "===== SUMMARY =====" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|Failures:|Errors:|OK \(" "$PROOF_FILE" | tail -n 5 | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE"
echo "Dusk exit code: $DUSK_EXIT"
exit "$DUSK_EXIT"
