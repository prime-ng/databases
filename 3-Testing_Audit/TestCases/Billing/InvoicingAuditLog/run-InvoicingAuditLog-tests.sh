#!/usr/bin/env bash
# Runner: Invoice Audit Log Dusk suite (bil_InvoicingAuditLog_TestCas)
# Central/PRIME feature — runs on http://127.0.0.1:8000. Billing module must be ENABLED.
set -u

PHP_BIN="${PHP_BIN:-php}"
FILTER="${FILTER:-}"
CLASS="bil_InvoicingAuditLog_TestCas"
STAMP="$(date +%Y%m%d_%H%M%S)"
PROOF_DIR="${PROOF_DIR:-proof}"
PROOF_FILE="${PROOF_DIR}/InvoicingAuditLog_${STAMP}.log"

usage() { echo "Usage: $0 [--php <path>] [--filter <method>]"; exit 1; }
while [[ $# -gt 0 ]]; do
  case "$1" in
    --php) PHP_BIN="$2"; shift 2;;
    --filter) FILTER="$2"; shift 2;;
    -h|--help) usage;;
    *) echo "Unknown arg: $1"; usage;;
  esac
done

mkdir -p "$PROOF_DIR"
export APP_ENV=testing

echo "== Invoice Audit Log Dusk suite =="
echo "PHP: $PHP_BIN | Class: $CLASS | Filter: ${FILTER:-<all>}"
echo "Base URL: http://127.0.0.1:8000 (central/prime) | proof: $PROOF_FILE"

# Clean old screenshots for this feature (best-effort)
SHOT_DIR="tests/Browser/Modules/Prime/Billing/InvoicingAuditLog/screenshots"
[[ -d "$SHOT_DIR" ]] && rm -f "$SHOT_DIR"/*.png 2>/dev/null

if [[ -n "$FILTER" ]]; then
  DUSK_FILTER="${CLASS}::${FILTER}"
else
  DUSK_FILTER="$CLASS"
fi

"$PHP_BIN" artisan dusk --filter="$DUSK_FILTER" 2>&1 | tee "$PROOF_FILE"
EXIT=${PIPESTATUS[0]}

echo ""
echo "== Summary =="
grep -E "Tests:|Assertions:|Failures:|OK \(" "$PROOF_FILE" | tail -n 5 || echo "(no summary line parsed)"
echo "Exit code: $EXIT"
exit "$EXIT"
