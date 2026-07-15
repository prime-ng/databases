#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Behavioural Assessment — Witness — Dusk runner (bash / WSL / macOS)
# Runs the single comprehensive suite bha_Witness_TestCas (40 methods).
#
# Witnesses are a NESTED CHILD of Incident (junction ba_incident_witnesses_jnt);
# they have NO standalone routes — they are written inside BaIncidentController
# ::store()/::update(). This suite therefore exercises the incident create/store/
# update flow plus the witness junction at the data/schema/policy layers.
#
# Prerequisites:
#   - prime_testing runner configured (MAIN_PROJECT_PATH -> prime_ai)
#   - BehaviouralAssessment module ENABLED in modules_statuses.json (else all routes 404)
#   - APP_ENV=testing ; tenant host reachable at DUSK_TENANT_URL (http://test.localhost:8000)
#   - Cross-module rows present (std_students, sch_employees) or those tests self-skip
#
# Usage:
#   ./run-Witness-tests.sh [--php <php-bin>] [--filter <method>] [--sync-db]
# ---------------------------------------------------------------------------
set -uo pipefail

PHP_BIN="php"
FILTER="bha_Witness_TestCas"
SYNC_DB=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)     PHP_BIN="$2"; shift 2 ;;
    --filter)  FILTER="$2";  shift 2 ;;
    --sync-db) SYNC_DB=1;    shift   ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Resolve the test runner root (prime_testing). Override with TEST_REPO if needed.
TEST_REPO="${TEST_REPO:-/Users/bkwork/Herd/prime_testing}"
cd "$TEST_REPO" || { echo "Cannot cd to $TEST_REPO"; exit 1; }

export APP_ENV=testing

PROOF_DIR="$SCRIPT_DIR/proof"
mkdir -p "$PROOF_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="$PROOF_DIR/Witness_${STAMP}.log"

# Clean old screenshots for this feature (suite writes witness-*.png under its own dir)
SHOT_DIR="$TEST_REPO/tests/Browser/Modules/BehaviouralAssessment/Witness/screenshots"
find "$SHOT_DIR" -name 'witness-*.png' -delete 2>/dev/null || true

if [[ "$SYNC_DB" -eq 1 ]]; then
  echo "Syncing tenant DB..." | tee -a "$PROOF_FILE"
  "$PHP_BIN" artisan migrate --database=tenant --force 2>&1 | tee -a "$PROOF_FILE" || true
fi

echo "Running Dusk filter: $FILTER" | tee -a "$PROOF_FILE"
"$PHP_BIN" artisan dusk --filter="$FILTER" 2>&1 | tee -a "$PROOF_FILE"
DUSK_EXIT=${PIPESTATUS[0]}

echo "" | tee -a "$PROOF_FILE"
echo "----- SUMMARY -----" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES" "$PROOF_FILE" | tail -n 5 | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE"
echo "Dusk exit code: $DUSK_EXIT"
exit "$DUSK_EXIT"
