#!/usr/bin/env bash
# =============================================================================
# Invoicing Audit Log (Billing) — Dusk runner (Linux / WSL / macOS)
# Mirrors the golden reference runner. Runs the mirrored test classes that live
# under prime_testing:
#   tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/bil_InvoicingAuditLogV1_TestCas.php
#   tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/bil_InvoicingAuditLogV2_TestCas.php
#
# PREREQUISITES
#   - Run from the prime_testing repo root (Dusk runner).
#   - prime_ai cloned alongside; MAIN_PROJECT_PATH exported (source-truth asserts read it).
#   - APP_ENV=testing (bypasses CSRF/419).
#   - Billing module ENABLED in modules_statuses.json (else every route 404s).
#   - Prime tests run on http://127.0.0.1:8000 (central / prime_db — no tenant init).
#
# USAGE
#   ./run-InvoicingAuditLog-tests.sh [--php <path>] [--v1-only] [--v2-only] [--filter <method>]
# =============================================================================
set -uo pipefail

PHP_BIN="php"
FILTER=""
V1_CLASS="bil_InvoicingAuditLogV1_TestCas"
V2_CLASS="bil_InvoicingAuditLogV2_TestCas"
RUN_V1=1
RUN_V2=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --php)     PHP_BIN="$2"; shift 2 ;;
    --filter)  FILTER="$2";  shift 2 ;;
    --v1-only) RUN_V2=0;     shift ;;
    --v2-only) RUN_V1=0;     shift ;;
    *) echo "Unknown option: $1"; exit 2 ;;
  esac
done

export APP_ENV=testing

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/proof"
mkdir -p "$PROOF_DIR"
PROOF_FILE="${PROOF_DIR}/invoicing_audit_log_run_${TIMESTAMP}.log"

# Clean old screenshots
find "tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/screenshots" -type f -name '*.png' -delete 2>/dev/null || true

run_class () {
  local CLASS="$1"
  local F="$CLASS"
  if [[ -n "$FILTER" ]]; then F="${CLASS}::${FILTER}"; fi
  echo "=== Running ${F} ===" | tee -a "$PROOF_FILE"
  "$PHP_BIN" artisan dusk --filter="$F" 2>&1 | tee -a "$PROOF_FILE"
  return "${PIPESTATUS[0]}"
}

EXIT=0
if [[ $RUN_V1 -eq 1 ]]; then run_class "$V1_CLASS" || EXIT=$?; fi
if [[ $RUN_V2 -eq 1 ]]; then run_class "$V2_CLASS" || EXIT=$?; fi

echo "" | tee -a "$PROOF_FILE"
echo "=== SUMMARY ===" | tee -a "$PROOF_FILE"
grep -E "Tests:|Assertions:|Failures:|OK|FAILURES|Skipped" "$PROOF_FILE" | tail -n 20 | tee -a "$PROOF_FILE"
echo "Proof: $PROOF_FILE"
exit "$EXIT"
