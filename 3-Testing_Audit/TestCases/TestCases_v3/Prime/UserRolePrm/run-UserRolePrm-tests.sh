#!/bin/bash
# UserRolePrm (Prime / central) Dusk runner.
# Placement: prime_testing/tests/Browser/Modules/Prime/UserRolePrm/.
# Prereqs: dev server on http://127.0.0.1:8000 ; APP_ENV=testing ; Prime area reachable ;
#          admin root@tenant.com verified. Central feature — NO tenant scaffolding.

F=""; S=false; PHP=$(which php 2>/dev/null || echo "/usr/bin/php")
while [[ $# -gt 0 ]]; do
  case "$1" in
    --filter) F="$2"; shift 2;;
    --sync-db) S=true; shift;;
    --php-path) PHP="$2"; shift 2;;
    *) echo "Unknown: $1"; exit 1;;
  esac
done

D="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
R="$(cd "$D/../../../../.." && pwd)"   # prime_testing root
P="$D/proof"; SS="$D/screenshots"; mkdir -p "$P"
[ -d "$SS" ] && rm -rf "${SS:?}/"* 2>/dev/null

T=$(date +"%Y%m%d_%H%M%S"); L="$P/dusk_run_$T.txt"

FC="sys_UserRolePrm_TestCas"
FF="${FC}${F:+::${F}}"

echo "=== UserRolePrm Dusk Tests (filter: $FF) ==="
export APP_ENV=testing
cd "$R" || exit 1
$S && $PHP "$R/artisan" dusk:chrome-driver --detect >/dev/null 2>&1

$PHP "$R/artisan" dusk --filter="$FF" 2>&1 | tee "$L"
EXIT=${PIPESTATUS[0]}
cp "$L" "$P/dusk_run_latest.txt"

if grep -qE "Tests:[[:space:]]+[0-9]+" "$L"; then
  LINE=$(grep -E "Tests:[[:space:]]+[0-9]+" "$L" | tail -1)
  echo "============================================"
  echo "  UserRolePrm RESULTS: $LINE"
  echo "============================================"
fi
echo "Proof saved at: $L"
exit "$EXIT"
