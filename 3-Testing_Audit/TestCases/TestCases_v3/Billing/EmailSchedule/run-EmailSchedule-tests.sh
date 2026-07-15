#!/usr/bin/env bash
# Runner for the central Billing "Email Schedule" Dusk suite (single test file).
# Intended install path: prime_testing/tests/Browser/Modules/Prime/Billing/EmailSchedule/
set -euo pipefail

FILTER="bil_EmailSchedule"
SYNC_DB=false
PHP_PATH=$(which php 2>/dev/null || echo "/usr/bin/php")

while [[ $# -gt 0 ]]; do
    case "$1" in
        --filter) FILTER="$2"; shift 2 ;;
        --sync-db) SYNC_DB=true; shift ;;
        --php-path) PHP_PATH="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Walk up until we find artisan (robust to install depth).
PROJECT_ROOT="$SCRIPT_DIR"
while [[ "$PROJECT_ROOT" != "/" && ! -f "$PROJECT_ROOT/artisan" ]]; do
    PROJECT_ROOT="$(dirname "$PROJECT_ROOT")"
done
if [[ ! -f "$PROJECT_ROOT/artisan" ]]; then
    echo "ERROR: could not locate artisan above $SCRIPT_DIR"; exit 1
fi

PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
OUTPUT_FILE="$PROOF_DIR/dusk_run_${TIMESTAMP}.txt"
LATEST_LINK="$PROOF_DIR/dusk_run_latest.txt"

# Clean prior screenshots for a fresh proof set.
rm -f "$SCRIPT_DIR/screenshots/"*.png 2>/dev/null || true

if [ "$SYNC_DB" = true ]; then
    "$PHP_PATH" "$PROJECT_ROOT/artisan" migrate:fresh --seed --force
fi

FILTER_ARG=""
if [ -n "$FILTER" ]; then FILTER_ARG="--filter=$FILTER"; fi

set +e
APP_ENV=testing "$PHP_PATH" "$PROJECT_ROOT/artisan" dusk $FILTER_ARG 2>&1 | tee "$OUTPUT_FILE"
DUSK_EXIT=${PIPESTATUS[0]}
set -e
cp "$OUTPUT_FILE" "$LATEST_LINK"

echo ""
echo "=== Email Schedule Test Run Complete ==="
grep -E "Tests:|Assertions:|Failures:|OK \(" "$OUTPUT_FILE" | tail -n 3 || true
echo "Output: $OUTPUT_FILE"
exit "$DUSK_EXIT"
