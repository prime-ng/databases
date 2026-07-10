#!/usr/bin/env bash
# Runner for MarksheetGeneration -> Dashboard & Navigation Dusk tests.
# PREREQ: MarksheetGeneration must be ENABLED in prime_testing/modules_statuses.json
#         (a disabled module returns 404 on every route).
#
# Usage: ./run-Dashboard-tests.sh [--php <path>] [--filter <f>] [--v1] [--v2] [--sync-db]

set -uo pipefail

PHP_PATH="php"
FILTER=""
V1_ONLY=0
V2_ONLY=0
SYNC_DB=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --php)      PHP_PATH="$2"; shift 2 ;;
        --filter)   FILTER="$2"; shift 2 ;;
        --v1)       V1_ONLY=1; shift ;;
        --v2)       V2_ONLY=1; shift ;;
        --sync-db)  SYNC_DB=1; shift ;;
        *) echo "Unknown option: $1"; exit 2 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
SCREENSHOTS_DIR="$SCRIPT_DIR/screenshots"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"

if [[ -d "$SCREENSHOTS_DIR" ]]; then
    rm -rf "${SCREENSHOTS_DIR:?}/"* 2>/dev/null || true
    echo "Cleaned old screenshots"
fi

if [[ -n "$FILTER" ]]; then
    DUSK_FILTER="$FILTER"
elif [[ "$V1_ONLY" -eq 1 ]]; then
    DUSK_FILTER="msh_DashboardV1_TestCas"
elif [[ "$V2_ONLY" -eq 1 ]]; then
    DUSK_FILTER="msh_DashboardV2_TestCas"
else
    DUSK_FILTER="msh_Dashboard"
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
EXIT_CODE="${PIPESTATUS[0]}"

cp -f "$PROOF_FILE" "$LATEST_FILE"

SUMMARY_LINE="$(grep -Eo 'Tests:[[:space:]]+[0-9]+, Assertions:[[:space:]]+[0-9]+, Failures:[[:space:]]+[0-9]+' "$PROOF_FILE" | tail -1 || true)"
if [[ -z "$SUMMARY_LINE" ]]; then
    SUMMARY_LINE="$(grep -Eo 'OK \([0-9]+ test[s]?' "$PROOF_FILE" | tail -1 || true)"
fi

echo ""
echo "============================================"
echo "  RESULTS: ${SUMMARY_LINE:-see proof file}"
if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo "  STATUS: ALL PASSED!"
else
    echo "  STATUS: SOME FAILED (exit $EXIT_CODE)"
fi
echo "============================================"
echo "Proof saved at: $PROOF_FILE"

unset APP_ENV
exit "$EXIT_CODE"
