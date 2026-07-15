#!/usr/bin/env bash
# Runner: GlobalMaster / Activity Log Dusk suite (Prime-central, READ-ONLY viewer).
# Mirrors the golden reference: clean screenshots -> run filtered dusk -> tee proof -> parse -> summarise.
#
# Prereqs (see Validation Report §7):
#   - GlobalMaster AND Prime ENABLED in prime_testing/modules_statuses.json (else 404)
#   - Central app served on http://127.0.0.1:8000 with APP_ENV=testing
#   - sys_central_activity_logs table exists (central migration run) — else DB/render tests self-skip
#   - Test file copied to: tests/Browser/Modules/GlobalMaster/ActivityLog/sys_ActivityLog_TestCas.php
#
# Usage:
#   ./run-ActivityLog-tests.sh [--php /path/to/php] [--filter test_activitylog_60] [--sync-db]

set -uo pipefail

PHP_BIN="php"
FILTER="sys_ActivityLog_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)     PHP_BIN="$2"; shift 2 ;;
    --filter)  FILTER="$2";  shift 2 ;;
    --sync-db) SYNC_DB=1;    shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve the prime_testing runner root (override with TEST_FILE_REPO).
RUNNER_ROOT="${TEST_FILE_REPO:-/Users/bkwork/Herd/prime_testing}"
cd "$RUNNER_ROOT" || { echo "Runner root not found: $RUNNER_ROOT"; exit 2; }

export APP_ENV=testing

TS="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/activity-log_${TS}.log"

echo "== Activity Log Dusk run =="
echo "Runner root : $RUNNER_ROOT"
echo "PHP         : $PHP_BIN"
echo "Filter      : $FILTER"
echo "Proof       : $PROOF_FILE"

# Clean stale screenshots for this feature.
SHOT_DIR="$RUNNER_ROOT/tests/Browser/Modules/GlobalMaster/ActivityLog/screenshots"
if [[ -d "$SHOT_DIR" ]]; then
  rm -f "$SHOT_DIR"/*.png 2>/dev/null || true
fi

if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "-- Syncing migrations (dusk env) --"
  "$PHP_BIN" artisan migrate --env=testing --force 2>&1 | tee -a "$PROOF_FILE"
fi

echo "-- Running dusk --filter=$FILTER --"
"$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee -a "$PROOF_FILE"
DUSK_EXIT=${PIPESTATUS[0]}

SUMMARY_LINE="$(grep -E 'Tests:[[:space:]]+[0-9]+' "$PROOF_FILE" | tail -n 1)"
echo ""
echo "== Summary =="
if [[ -n "$SUMMARY_LINE" ]]; then
  echo "$SUMMARY_LINE"
else
  echo "(no PHPUnit summary line parsed — check $PROOF_FILE)"
fi
echo "Dusk exit code: $DUSK_EXIT"
echo "Proof: $PROOF_FILE"

exit "$DUSK_EXIT"
