#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# MarksheetGeneration — Scheduling & Lifecycle — Dusk runner (bash/WSL/macOS)
# Runs the single comprehensive suite msh_SchedulingAndLifecycle_TestCas.
#
# Usage:
#   ./run-SchedulingAndLifecycle-tests.sh [--php <php-bin>] [--filter <method>] [--sync-db]
#
# Prereqs (see Validation Report §7):
#   * MarksheetGeneration: true in prime_testing/modules_statuses.json
#   * APP_ENV=testing (bypasses CSRF)
#   * tenant DB seeded with a config template, an academic session, and the
#     5 status dropdown rows on sys_dropdown_table (key msh_marksheet_schedules.status_id)
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="php"
FILTER="msh_SchedulingAndLifecycle_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)    PHP_BIN="$2"; shift 2 ;;
    --filter) FILTER="$2"; shift 2 ;;
    --sync-db) SYNC_DB=1; shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

# Resolve the prime_testing runner root (env override or default).
PROJECT_ROOT="${MAIN_PROJECT_PATH:-/Users/bkwork/Herd/prime_testing}"
cd "$PROJECT_ROOT" || { echo "Cannot cd to $PROJECT_ROOT"; exit 1; }

TS="$(date +%Y%m%d-%H%M%S)"
PROOF_DIR="$(dirname "$0")/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="$PROOF_DIR/SchedulingAndLifecycle-$TS.log"

# Clean old screenshots for this feature.
SHOTS="tests/Browser/Modules/MarksheetGeneration/SchedulingAndLifecycle/screenshots"
[[ -d "$SHOTS" ]] && rm -f "$SHOTS"/*.png 2>/dev/null

echo "=== MarksheetGeneration / SchedulingAndLifecycle Dusk run ($TS) ===" | tee "$PROOF_FILE"
echo "PHP:    $($PHP_BIN -v | head -1)" | tee -a "$PROOF_FILE"
echo "Filter: $FILTER" | tee -a "$PROOF_FILE"

if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "--- migrating test DB ---" | tee -a "$PROOF_FILE"
  APP_ENV=testing "$PHP_BIN" artisan migrate --force 2>&1 | tee -a "$PROOF_FILE"
fi

echo "--- running dusk ---" | tee -a "$PROOF_FILE"
APP_ENV=testing "$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee -a "$PROOF_FILE"
DUSK_EXIT=${PIPESTATUS[0]}

echo "--- summary ---" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|OK|FAILURES|Errors" "$PROOF_FILE" | tail -5 | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE"
echo "Dusk exit code: $DUSK_EXIT"
exit "$DUSK_EXIT"
