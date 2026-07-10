#!/usr/bin/env bash
#
# run-StudentCompleteProfile-tests.sh
# Runs the StudentProfile / StudentCompleteProfile Dusk suite (ONE file: std_StudentCompleteProfile_TestCas.php).
#
# Prerequisites:
#   - prime_ai cloned alongside prime_testing; MAIN_PROJECT_PATH set (see TEST_SETUP.md)
#   - STUDENT module ENABLED in prime_testing/modules_statuses.json (else all routes 404)
#   - APP_ENV=testing (bypasses CSRF for authenticated flows)
#
# Usage:
#   ./run-StudentCompleteProfile-tests.sh [--php <path>] [--filter <method>] [--sync-db]

set -euo pipefail

PHP="php"
FILTER=""
SYNC_DB=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --php)     PHP="$2"; shift 2 ;;
        --filter)  FILTER="$2"; shift 2 ;;
        --sync-db) SYNC_DB=1; shift ;;
        *) echo "Unknown arg: $1"; exit 2 ;;
    esac
done

TEST_FILE="tests/Browser/Modules/StudentProfile/Testcases/std_StudentCompleteProfile_TestCas.php"
PROOF_DIR="tests/Browser/Modules/StudentProfile/StudentCompleteProfile/proof"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="${PROOF_DIR}/std_StudentCompleteProfile_${STAMP}.txt"

mkdir -p "$PROOF_DIR"

echo "Cleaning old screenshots..."
rm -f tests/Browser/console/screenshots/*complete-profile* 2>/dev/null || true

if [[ "$SYNC_DB" -eq 1 ]]; then
    echo "Syncing tenant test DB..."
    "$PHP" artisan migrate --env=testing
fi

export APP_ENV=testing

DUSK_ARGS=(artisan dusk "$TEST_FILE")
[[ -n "$FILTER" ]] && DUSK_ARGS+=("--filter=${FILTER}")

echo "Running: $PHP ${DUSK_ARGS[*]}"
set +e
"$PHP" "${DUSK_ARGS[@]}" 2>&1 | tee "$PROOF_FILE"
EXIT_CODE=${PIPESTATUS[0]}
set -e

echo "----------------------------------------"
grep -E "Tests:\s+[0-9]+" "$PROOF_FILE" | tail -1 || echo "No test summary parsed."
echo "Proof: $PROOF_FILE"
echo "----------------------------------------"

exit "$EXIT_CODE"
