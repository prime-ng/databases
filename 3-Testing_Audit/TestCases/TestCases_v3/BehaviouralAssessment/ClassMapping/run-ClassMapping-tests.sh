#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# Runner — BehaviouralAssessment / Class-Mapping (single comprehensive suite)
# Test file: tests/Browser/Modules/BehaviouralAssessment/ClassMapping/bha_ClassMapping_TestCas.php
# Class     : bha_ClassMapping_TestCas  (44 Dusk methods, ONE file per screen — no V1/V2 split)
# ---------------------------------------------------------------------------

FILTER=""
SYNC_DB=false
PHP_PATH=$(which php 2>/dev/null || echo "/usr/bin/php")

while [[ $# -gt 0 ]]; do
    case "$1" in
        --filter)   FILTER="$2"; shift 2 ;;
        --sync-db)  SYNC_DB=true; shift ;;
        --php-path) PHP_PATH="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; echo "Usage: $0 [--filter <name>] [--sync-db] [--php-path <php>]"; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(realpath "$SCRIPT_DIR/../../../../../..")"
PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$PROOF_DIR/dusk_run_${TIMESTAMP}.txt"
LATEST_LINK="$PROOF_DIR/dusk_run_latest.txt"

# There is exactly ONE test file for this screen; default the filter to its class.
TEST_CLASS="bha_ClassMapping_TestCas"
if [ -z "$FILTER" ]; then FILTER="$TEST_CLASS"; fi

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
echo "=== Class-Mapping Test Run Complete ==="
SUMMARY=$(grep -E "Tests:|Assertions:|Failures:|OK \(" "$OUTPUT_FILE" | tail -3 || true)
if [ -n "$SUMMARY" ]; then
    echo "$SUMMARY"
fi
echo "Output    : $OUTPUT_FILE"
echo "Exit code : $DUSK_EXIT"

exit "$DUSK_EXIT"
