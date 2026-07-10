#!/usr/bin/env bash
# Runner: GlobalMaster -> SessionBoardSetup Dusk suite (glb_SessionBoardSetup_TestCas.php)
# READ-ONLY composite screen served by Prime at /prime/session-board-setup.
# Requires prime_ai served on http://127.0.0.1:8000, GlobalMaster AND Prime modules ENABLED
# in modules_statuses.json, APP_ENV=testing, and a reachable global_master_mysql / prime_db.
set -uo pipefail

PHP_BIN="${PHP_BIN:-php}"
FILTER="${1:-}"                     # optional: a single test method or pattern
TEST_CLASS="glb_SessionBoardSetup_TestCas"
TEST_PATH="tests/Browser/Modules/GlobalMaster/SessionBoardSetup/${TEST_CLASS}.php"

# Resolve the prime_testing runner root (override with TEST_REPO=...)
TEST_REPO="${TEST_REPO:-/Users/bkwork/Herd/prime_testing}"
cd "$TEST_REPO" || { echo "ERROR: cannot cd to TEST_REPO=$TEST_REPO"; exit 2; }

STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="$TEST_REPO/tests/Browser/Modules/GlobalMaster/SessionBoardSetup/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/session_board_setup_run_${STAMP}.log"

# Clean old screenshots for this feature
SHOTS="$TEST_REPO/tests/Browser/Modules/GlobalMaster/SessionBoardSetup/screenshots"
if [ -d "$SHOTS" ]; then rm -f "$SHOTS"/*.png 2>/dev/null || true; fi

echo "== GlobalMaster SessionBoardSetup Dusk run @ ${STAMP} ==" | tee "$PROOF_FILE"

# Default filter targets the whole class; a positional arg narrows to a method/pattern.
CMD=("$PHP_BIN" artisan dusk "$TEST_PATH")
if [ -n "$FILTER" ]; then
  CMD+=("--filter=${FILTER}")
else
  CMD+=("--filter=${TEST_CLASS}")
fi
echo "> ${CMD[*]}" | tee -a "$PROOF_FILE"

APP_ENV=testing "${CMD[@]}" 2>&1 | tee -a "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}

echo "" | tee -a "$PROOF_FILE"
echo "== Summary ==" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|Failures:|Errors:|OK|FAILURES|Skipped" "$PROOF_FILE" | tail -n 6 | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE" | tee -a "$PROOF_FILE"
echo "Exit code: $EXIT_CODE" | tee -a "$PROOF_FILE"
exit "$EXIT_CODE"
