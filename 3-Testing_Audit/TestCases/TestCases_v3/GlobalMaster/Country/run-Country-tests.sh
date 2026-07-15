#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# GlobalMaster Country — Dusk test runner (bash / Linux / WSL / macOS)
# CENTRAL prime-side feature. Mirrors the golden-reference runner idiom.
# ONE comprehensive test class — no V1/V2 split.
#
# Usage:
#   ./run-Country-tests.sh [--php <path>] [--filter <name>] [--sync-db]
#
# Prerequisites (env, NOT code fixes):
#   * GlobalMaster AND Prime modules ENABLED in modules_statuses.json
#     (both default false -> 404 on all /global-master/country routes).
#   * APP_ENV=testing  (CSRF bypass for toggle-status AJAX / JSON asserts)
#   * Central dev server reachable on http://127.0.0.1:8000
#   * global_master_mysql connection reachable; glb_countries.deleted_at present
# ---------------------------------------------------------------------------
set -u

PHP_BIN="php"
FILTER=""
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)     PHP_BIN="$2"; shift 2 ;;
    --filter)  FILTER="$2"; shift 2 ;;
    --sync-db) SYNC_DB=1; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Resolve the prime_testing runner root (MAIN_PROJECT_PATH or a sensible default).
RUNNER_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
if [[ ! -d "$RUNNER_ROOT" ]]; then
  echo "ERROR: runner root not found at $RUNNER_ROOT (set MAIN_PROJECT_PATH)."
  exit 1
fi
cd "$RUNNER_ROOT" || exit 1

export APP_ENV=testing

TS="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="tests/Browser/Modules/GlobalMaster/Country/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/glb_country_dusk_${TS}.log"

# Clean stale screenshots.
SHOT_DIR="tests/Browser/Modules/GlobalMaster/Country/screenshots"
[[ -d "$SHOT_DIR" ]] && find "$SHOT_DIR" -type f -name '*.png' -delete 2>/dev/null

# Optional: refresh the central schema before running.
if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "Syncing central schema (migrate) ..."
  "$PHP_BIN" artisan migrate --force 2>&1 | tee -a "$PROOF_FILE"
fi

# Build the --filter argument (defaults to the single Country class).
if [[ -n "$FILTER" ]]; then
  FILTER_ARG="--filter=$FILTER"
else
  FILTER_ARG="--filter=glb_Country_TestCas"
fi

echo "==================================================================="
echo " GlobalMaster Country Dusk run (CENTRAL / http://127.0.0.1:8000)"
echo " Runner : $RUNNER_ROOT"
echo " PHP    : $PHP_BIN"
echo " Filter : $FILTER_ARG"
echo " Proof  : $PROOF_FILE"
echo "==================================================================="

"$PHP_BIN" artisan dusk "$FILTER_ARG" 2>&1 | tee -a "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "------------------------- SUMMARY -------------------------"
grep -E "Tests:|Assertions:|OK|FAILURES|Failed|Error" "$PROOF_FILE" | tail -n 10
echo "-----------------------------------------------------------"
echo "Dusk exit code: $EXIT_CODE  (proof: $PROOF_FILE)"

exit "$EXIT_CODE"
