#!/bin/bash
# MarksheetGeneration / StudentResultsAndPrint Dusk Test Runner (Bash)
# Usage: ./run-StudentResultsAndPrint-tests.sh [--v1|--v2|--filter <name>] [--sync-db]
#
# Copy the two PHP files into:
#   prime_testing/tests/Browser/Modules/MarksheetGeneration/StudentResultsAndPrint/
# PREREQUISITES (see Validation Report):
#   - modules_statuses.json => "MarksheetGeneration": true  (disabled module = 404 on all routes)
#   - APP_ENV=testing (bypasses CSRF; else 419)
#   - Tenant DB seeded with an active UNLOCKED msh_marksheet_schedule, a sch_class_section_jnt, std_students rows

set -euo pipefail

PHP_BIN="${PHP_BIN:-php}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
SCREENSHOT_DIR="$SCRIPT_DIR/screenshots"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"

FILTER="StudentResultsAndPrint"
SYNC_DB="0"

while [ "$#" -gt 0 ]; do
    case "$1" in
        --v1) FILTER="msh_StudentResultsAndPrintV1_TestCas"; shift ;;
        --v2) FILTER="msh_StudentResultsAndPrintV2_TestCas"; shift ;;
        --filter) FILTER="$2"; shift 2 ;;
        --sync-db) SYNC_DB="1"; shift ;;
        *) echo "Unknown arg: $1"; exit 2 ;;
    esac
done

if [ -d "$SCREENSHOT_DIR" ]; then
    rm -f "$SCREENSHOT_DIR"/*.png 2>/dev/null || true
    echo "Cleaned old screenshots"
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="$PROOF_DIR/dusk_run_$TIMESTAMP.txt"
LATEST_FILE="$PROOF_DIR/dusk_run_latest.txt"

cd "$PROJECT_ROOT"

if [ "$SYNC_DB" = "1" ]; then
    echo "Detecting chrome driver..."
    "$PHP_BIN" artisan dusk:chrome-driver --detect >/dev/null 2>&1 || true
fi

export APP_ENV=testing
echo "Running Dusk with filter: $FILTER"

set +e
"$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE="${PIPESTATUS[0]}"
set -e

cp -f "$PROOF_FILE" "$LATEST_FILE"

SUMMARY="$(grep -E 'Tests:\s+[0-9]+,\s+Assertions:' "$PROOF_FILE" | tail -1 || true)"
if [ -z "$SUMMARY" ]; then
    SUMMARY="$(grep -E 'OK \([0-9]+ test' "$PROOF_FILE" | tail -1 || true)"
fi

echo "============================================"
echo "  RESULTS: ${SUMMARY:-see proof file}"
if [ "$EXIT_CODE" = "0" ]; then echo "  STATUS: ALL PASSED"; else echo "  STATUS: SOME FAILED"; fi
echo "============================================"
echo "Proof saved at: $PROOF_FILE"

exit "$EXIT_CODE"
