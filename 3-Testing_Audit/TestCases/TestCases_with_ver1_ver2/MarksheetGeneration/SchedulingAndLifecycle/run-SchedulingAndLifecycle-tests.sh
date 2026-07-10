#!/usr/bin/env bash
set -uo pipefail

# Runs the MarksheetGeneration / Scheduling & Lifecycle Dusk suites.
# Prereq: MarksheetGeneration enabled in modules_statuses.json; APP_ENV=testing; tenant seed data.
#
# Usage: ./run-SchedulingAndLifecycle-tests.sh [--v1|--v2] [--filter <name>] [--php <path>] [--sync-db]

PHP_PATH="php"
FILTER=""
V1_ONLY=0
V2_ONLY=0
SYNC_DB=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --v1) V1_ONLY=1; shift ;;
        --v2) V2_ONLY=1; shift ;;
        --filter) FILTER="$2"; shift 2 ;;
        --php) PHP_PATH="$2"; shift 2 ;;
        --sync-db) SYNC_DB=1; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"

if [[ -n "$FILTER" ]]; then
    DUSK_FILTER="$FILTER"
elif [[ "$V1_ONLY" -eq 1 ]]; then
    DUSK_FILTER="msh_SchedulingAndLifecycleV1_TestCas"
elif [[ "$V2_ONLY" -eq 1 ]]; then
    DUSK_FILTER="msh_SchedulingAndLifecycleV2_TestCas"
else
    DUSK_FILTER="msh_SchedulingAndLifecycle"
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="$PROOF_DIR/dusk_run_$TIMESTAMP.txt"
LATEST_FILE="$PROOF_DIR/dusk_run_latest.txt"

cd "$PROJECT_ROOT" || exit 1

if [[ "$SYNC_DB" -eq 1 ]]; then
    echo "Detecting chrome driver..."
    "$PHP_PATH" artisan dusk:chrome-driver --detect >/dev/null 2>&1 || true
fi

export APP_ENV=testing
echo "Running Dusk with filter: $DUSK_FILTER"

"$PHP_PATH" artisan dusk --filter="$DUSK_FILTER" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}

cp -f "$PROOF_FILE" "$LATEST_FILE"

SUMMARY_LINE="$(grep -Eo 'Tests: [0-9]+, Assertions: [0-9]+, Failures: [0-9]+' "$PROOF_FILE" | tail -1 || true)"
echo ""
echo "============================================"
if [[ -n "$SUMMARY_LINE" ]]; then
    echo "  $SUMMARY_LINE"
else
    echo "  (see proof file for full results)"
fi
echo "  Proof: $PROOF_FILE"
echo "============================================"

unset APP_ENV
exit "$EXIT_CODE"
