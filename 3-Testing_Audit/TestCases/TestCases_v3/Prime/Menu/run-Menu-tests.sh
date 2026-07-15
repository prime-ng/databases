#!/usr/bin/env bash
#
# Menu (PRM / Central) Dusk runner — glb_Menu_TestCas.
# Central feature: runs against http://127.0.0.1:8000 (NOT test.localhost).
#
# Usage:
#   ./run-Menu-tests.sh [--php /path/to/php] [--filter test_menu_20] [--sync-db]
#
set -uo pipefail

PHP_BIN="php"
FILTER=""
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --sync-db) SYNC_DB=1; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Locate the prime_testing runner root (test file must be copied under tests/Browser/Modules/Prime/Menu/).
RUNNER_ROOT="${MAIN_PROJECT_PATH:-$HOME/Herd/prime_testing}"
if [[ ! -f "$RUNNER_ROOT/artisan" ]]; then
  echo "ERROR: prime_testing runner not found at $RUNNER_ROOT. Set MAIN_PROJECT_PATH."
  exit 1
fi
cd "$RUNNER_ROOT" || exit 1

export APP_ENV=testing

CLASS="glb_Menu_TestCas"
FILTER_ARG="$CLASS"
if [[ -n "$FILTER" ]]; then
  FILTER_ARG="$FILTER"
fi

# Clean previous screenshots for this feature.
SHOT_DIR="tests/Browser/Modules/Prime/Menu/screenshots"
[[ -d "$SHOT_DIR" ]] && rm -f "$SHOT_DIR"/*.png 2>/dev/null

if [[ "$SYNC_DB" == "1" ]]; then
  echo "[sync-db] refreshing central/global_master schema..."
  "$PHP_BIN" artisan migrate --force >/dev/null 2>&1 || true
fi

PROOF_DIR="tests/Browser/Modules/Prime/Menu/proof"
mkdir -p "$PROOF_DIR"
STAMP="$(date '+%Y%m%d_%H%M%S')"
PROOF_FILE="$PROOF_DIR/menu_dusk_${STAMP}.log"

echo "Running Menu Dusk tests (filter: $FILTER_ARG) ..."
"$PHP_BIN" artisan dusk --filter="$FILTER_ARG" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo ""
echo "==================== SUMMARY ===================="
grep -E "Tests:|Assertions:|Failures:|Errors:|OK|FAILURES|Skipped:" "$PROOF_FILE" | tail -n 5
echo "Proof: $PROOF_FILE"
echo "Exit code: $EXIT_CODE"
echo "================================================="

exit "$EXIT_CODE"
