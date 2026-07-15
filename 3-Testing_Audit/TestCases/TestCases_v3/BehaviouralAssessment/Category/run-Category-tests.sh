#!/usr/bin/env bash
# Runner for the BehaviouralAssessment › Categories & Criteria Dusk suite.
# Single comprehensive test file: bha_Category_TestCas.php (55 methods, class bha_Category_TestCas).
#
# These artifacts live OUTSIDE the test repo, so the runner resolves prime_testing
# via PRIME_TESTING_PATH (env) with a sensible default. Override as needed:
#   PRIME_TESTING_PATH=/path/to/prime_testing ./run-Category-tests.sh
set -euo pipefail

FILTER="bha_Category_TestCas"     # default: the whole Category suite
SYNC_DB=false
PHP_PATH="$(which php 2>/dev/null || echo "/usr/bin/php")"
PROJECT_ROOT="${PRIME_TESTING_PATH:-/Users/bkwork/Herd/prime_testing}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --filter)   FILTER="$2"; shift 2 ;;        # e.g. --filter test_category_10
        --sync-db)  SYNC_DB=true; shift ;;
        --php-path) PHP_PATH="$2"; shift 2 ;;
        --project)  PROJECT_ROOT="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

if [ ! -f "$PROJECT_ROOT/artisan" ]; then
    echo "ERROR: artisan not found at $PROJECT_ROOT. Set PRIME_TESTING_PATH or pass --project."
    exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$PROOF_DIR/dusk_run_${TIMESTAMP}.txt"
LATEST_LINK="$PROOF_DIR/dusk_run_latest.txt"

# Prerequisite reminder: the module must be enabled in modules_statuses.json,
# else every /behavioural-assessment route returns 404.
echo "== Prereq: ensure \"BehaviouralAssessment\": true in $PROJECT_ROOT/modules_statuses.json =="

export APP_ENV=testing

if [ "$SYNC_DB" = true ]; then
    "$PHP_PATH" "$PROJECT_ROOT/artisan" migrate:fresh --seed --force
fi

FILTER_ARG=""
if [ -n "$FILTER" ]; then
    FILTER_ARG="--filter=$FILTER"
fi

set +e
"$PHP_PATH" "$PROJECT_ROOT/artisan" dusk $FILTER_ARG 2>&1 | tee "$OUTPUT_FILE"
DUSK_EXIT=${PIPESTATUS[0]}
set -e
cp "$OUTPUT_FILE" "$LATEST_LINK"

echo ""
echo "=== Test Run Complete ==="
echo "Output: $OUTPUT_FILE"
SUMMARY=$(grep -E "Tests:\s+[0-9]" "$OUTPUT_FILE" | tail -1 || true)
if [ -n "$SUMMARY" ]; then
    echo "Result: $SUMMARY"
fi
echo "Dusk exit code: $DUSK_EXIT"
exit "$DUSK_EXIT"
