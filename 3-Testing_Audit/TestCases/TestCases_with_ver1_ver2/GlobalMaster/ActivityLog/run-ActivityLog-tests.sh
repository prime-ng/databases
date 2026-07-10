#!/bin/bash
# ActivityLog (GlobalMaster / central) Dusk runner.
# Intended location: prime_testing/tests/Browser/Modules/Prime/GlobalMaster/ActivityLog/
# Prereqs:
#   - GlobalMaster AND Prime must be enabled in prime_testing/modules_statuses.json (else 404 on all routes).
#   - Prime/central tests run against http://127.0.0.1:8000 (enforced by PrimeDuskTestCase).
#   - sys_activity_logs / sys_central_activity_logs migrated; browser/seed tests self-skip otherwise.

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
R="$(cd "$D/../../../../../.." && pwd)"   # prime_testing root (Prime/GlobalMaster/ActivityLog = 6 up)
P="$D/proof"; SS="$D/screenshots"; mkdir -p "$P"
[ -d "$SS" ] && rm -rf "${SS:?}/"* 2>/dev/null

T=$(date +"%Y%m%d_%H%M%S"); L="$P/dusk_run_$T.txt"

if $V1; then FC="sys_ActivityLogV1_TestCas"
elif $V2; then FC="sys_ActivityLogV2_TestCas"
else FC="sys_ActivityLog"
fi
FF="${FC}${F:+::${F}}"

echo "=== ActivityLog Dusk Tests (filter: $FF) ==="
export APP_ENV=testing
cd "$R" || exit 1
$S && $PHP "$R/artisan" dusk:chrome-driver --detect >/dev/null 2>&1

$PHP "$R/artisan" dusk --filter="$FF" 2>&1 | tee "$L"
EXIT=${PIPESTATUS[0]}
cp "$L" "$P/dusk_run_latest.txt"

if grep -qE "Tests:[[:space:]]+[0-9]+" "$L"; then
  LINE=$(grep -E "Tests:[[:space:]]+[0-9]+" "$L" | tail -1)
  echo "============================================"
  echo "  ActivityLog RESULTS: $LINE"
  echo "============================================"
elif grep -qE "OK \([0-9]+ test" "$L"; then
  echo "============================================"
  echo "  ActivityLog RESULTS: $(grep -E 'OK \([0-9]+ test' "$L" | tail -1)"
  echo "============================================"
fi
echo "Proof saved at: $L"
exit "$EXIT"
