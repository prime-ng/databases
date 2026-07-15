#!/usr/bin/env bash
# Runner: Prime (central) Academic Session Dusk suite (bash).
# One comprehensive file: glb_AcademicSession_TestCas.php
set -u

PHP_BIN="${PHP_BIN:-php}"
FILTER="${1:-glb_AcademicSession_TestCas}"
SYNC_DB="${SYNC_DB:-0}"

# Resolve prime_testing runner root (test file lives under tests/Browser/Modules/Prime/AcademicSession).
RUNNER_ROOT="${TEST_FILE_REPO:-/Users/bkwork/Herd/prime_testing}"
TEST_PATH="tests/Browser/Modules/Prime/AcademicSession/glb_AcademicSession_TestCas.php"
PROOF_DIR="${RUNNER_ROOT}/tests/Browser/Modules/Prime/AcademicSession/proof"
SHOT_DIR="${RUNNER_ROOT}/tests/Browser/Modules/Prime/AcademicSession/screenshots"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_FILE="${PROOF_DIR}/academicsession_dusk_${STAMP}.log"

mkdir -p "${PROOF_DIR}"
echo "[i] Cleaning old screenshots in ${SHOT_DIR}"
rm -f "${SHOT_DIR}"/*.png 2>/dev/null || true

echo "[i] Academic Session is CENTRAL (global_master DB) — expects host http://127.0.0.1:8000 and APP_ENV=testing."
echo "[i] Ensure the Prime module is ENABLED in modules_statuses.json (else all /prime/* routes 404)."
echo "[i] Ensure the global_master_mysql connection is configured and glb_academic_sessions exists."

if [ "${SYNC_DB}" = "1" ]; then
  echo "[i] Syncing DB (migrate) ..."
  ( cd "${RUNNER_ROOT}" && APP_ENV=testing "${PHP_BIN}" artisan migrate --force ) || true
fi

echo "[i] Running: artisan dusk --filter=${FILTER}"
( cd "${RUNNER_ROOT}" && APP_ENV=testing "${PHP_BIN}" artisan dusk "${TEST_PATH}" --filter="${FILTER}" ) 2>&1 | tee "${PROOF_FILE}"
DUSK_EXIT=${PIPESTATUS[0]}

echo ""
echo "==================== SUMMARY ===================="
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES" "${PROOF_FILE}" | tail -5 || true
echo "Proof: ${PROOF_FILE}"
echo "Exit code: ${DUSK_EXIT}"
echo "================================================="
exit "${DUSK_EXIT}"
