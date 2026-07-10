#!/usr/bin/env bash
# glb_Language Dusk runner (central / prime-side).
# Runs on http://127.0.0.1:8000 (PrimeDuskTestCase enforces this host).
# Prerequisites: Prime + GlobalMaster enabled in modules_statuses.json; APP_ENV=testing.
#
# Usage:
#   ./run-Language-tests.sh                 # full suite (V1 + V2)
#   ./run-Language-tests.sh --v1-only
#   ./run-Language-tests.sh --v2-only
#   ./run-Language-tests.sh --filter=test_language_17_force_delete_logs_stored_event_bug
#   PHP_PATH=/usr/bin/php ./run-Language-tests.sh

set -u

PHP_PATH="${PHP_PATH:-php}"
FILTER=""
V1_ONLY=0
V2_ONLY=0
SYNC_DB=0

for arg in "$@"; do
    case "$arg" in
        --v1-only) V1_ONLY=1 ;;
        --v2-only) V2_ONLY=1 ;;
        --sync-db) SYNC_DB=1 ;;
        --filter=*) FILTER="${arg#*=}" ;;
        *) echo "Unknown arg: $arg" ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"
SCREENSHOTS_DIR="$SCRIPT_DIR/screenshots"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"

if [ -d "$SCREENSHOTS_DIR" ]; then
    rm -rf "${SCREENSHOTS_DIR:?}"/* 2>/dev/null || true
    echo "Cleaned old screenshots"
fi

if [ -n "$FILTER" ]; then
    DUSK_FILTER="$FILTER"
elif [ "$V1_ONLY" -eq 1 ]; then
    DUSK_FILTER="glb_LanguageV1_TestCas"
elif [ "$V2_ONLY" -eq 1 ]; then
    DUSK_FILTER="glb_LanguageV2_TestCas"
else
    DUSK_FILTER="glb_Language"
fi

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="$PROOF_DIR/dusk_run_$TIMESTAMP.txt"
LATEST_FILE="$PROOF_DIR/dusk_run_latest.txt"

cd "$PROJECT_ROOT" || exit 1

if [ "$SYNC_DB" -eq 1 ]; then
    echo "Detecting chrome driver..."
    "$PHP_PATH" artisan dusk:chrome-driver --detect >/dev/null 2>&1 || true
fi

export APP_ENV=testing
echo "Running Dusk with filter: $DUSK_FILTER"

"$PHP_PATH" artisan dusk --filter="$DUSK_FILTER" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE="${PIPESTATUS[0]}"

cp -f "$PROOF_FILE" "$LATEST_FILE"

SUMMARY="$(grep -Eo 'Tests:[[:space:]]+[0-9]+,[[:space:]]+Assertions:[[:space:]]+[0-9]+,[[:space:]]+Failures:[[:space:]]+[0-9]+' "$PROOF_FILE" | tail -1)"
if [ -z "$SUMMARY" ]; then
    SUMMARY="$(grep -Eo 'OK \([0-9]+ test' "$PROOF_FILE" | tail -1)"
fi

echo ""
echo "============================================"
echo "  RESULTS (glb_Language):"
echo "  ${SUMMARY:-no parseable summary}"
echo "============================================"
echo "Proof saved at: $PROOF_FILE"

unset APP_ENV
exit "$EXIT_CODE"
