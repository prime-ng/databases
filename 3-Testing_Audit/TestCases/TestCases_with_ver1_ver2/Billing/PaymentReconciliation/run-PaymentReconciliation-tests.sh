#!/bin/bash
# Payment Reconciliation (Billing) Dusk runner — prime_db central.
# Deploy this file at:
#   prime_testing/tests/Browser/Modules/Prime/Billing/PaymentReconciliation/
# Prereqs:
#   - Billing enabled in prime_testing/modules_statuses.json (disabled → 404 on all routes).
#   - Prime tests run on http://127.0.0.1:8000 (base class asserts host 127.0.0.1).
#   - APP_ENV=testing (set below) so state-changing requests bypass CSRF.

F=""; V1=false; V2=false; S=false; PHP=$(which php 2>/dev/null || echo "/usr/bin/php")
while [[ $# -gt 0 ]]; do
  case "$1" in
    --filter) F="$2"; shift 2;;
    --v1-only) V1=true; shift;;
    --v2-only) V2=true; shift;;
    --sync-db) S=true; shift;;
    --php-path) PHP="$2"; shift 2;;
    *) echo "Unknown: $1"; exit 1;;
  esac
done

D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R="$(cd "$D/../../../../../.." && pwd)"   # prime_testing root
P="$D/proof"; SS="$D/screenshots"; mkdir -p "$P"
[ -d "$SS" ] && rm -rf "${SS:?}/"* 2>/dev/null

T=$(date +"%Y%m%d_%H%M%S"); L="$P/dusk_run_$T.txt"

if $V1; then FC="bil_PaymentReconciliationV1_TestCas"
elif $V2; then FC="bil_PaymentReconciliationV2_TestCas"
else FC="bil_PaymentReconciliation"
fi
FF="${FC}${F:+::${F}}"

echo "=== Payment Reconciliation Dusk Tests (filter: $FF) ==="
export APP_ENV=testing
cd "$R" || exit 1
$S && $PHP "$R/artisan" dusk:chrome-driver --detect >/dev/null 2>&1

$PHP "$R/artisan" dusk --filter="$FF" 2>&1 | tee "$L"
EXIT=${PIPESTATUS[0]}
cp "$L" "$P/dusk_run_latest.txt"

if grep -qE "Tests:[[:space:]]+[0-9]+" "$L"; then
  LINE=$(grep -E "Tests:[[:space:]]+[0-9]+" "$L" | tail -1)
  echo "============================================"
  echo "  Payment Reconciliation RESULTS: $LINE"
  echo "============================================"
fi
echo "Proof saved at: $L"
exit "$EXIT"
