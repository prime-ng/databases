# ---------------------------------------------------------------------------
# Runner — MarksheetGeneration / Student Results & Print (Dusk, single suite)
# One comprehensive test file: msh_StudentResultsAndPrint_TestCas.php
#
# Usage:
#   ./run-StudentResultsAndPrint-tests.ps1 [-Filter <method>] [-Php <path>]
#
# Prereqs:
#   - Run from the prime_testing runner repo root (MAIN_PROJECT_PATH set, prime_ai cloned alongside).
#   - MarksheetGeneration enabled in modules_statuses.json (else routes 404).
#   - APP_ENV=testing ; tenant seed data (active unlocked schedule + class-section + student).
# ---------------------------------------------------------------------------
param(
    [string]$Php    = "php",
    [string]$Filter = "msh_StudentResultsAndPrint_TestCas"
)

$env:APP_ENV = "testing"

$ts        = Get-Date -Format "yyyyMMdd_HHmmss"
$proofDir  = "tests/Browser/Modules/MarksheetGeneration/StudentResultsAndPrint/proof"
$shotDir   = "tests/Browser/Modules/MarksheetGeneration/StudentResultsAndPrint/screenshots"
New-Item -ItemType Directory -Force -Path $proofDir | Out-Null
$proofFile = Join-Path $proofDir "proof_$ts.log"

# Clean old screenshots
if (Test-Path $shotDir) {
    Get-ChildItem -Path $shotDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

"=== MarksheetGeneration / StudentResultsAndPrint — Dusk run @ $ts ===" | Tee-Object -FilePath $proofFile
"Filter: $Filter" | Tee-Object -FilePath $proofFile -Append

& $Php artisan dusk --filter=$Filter 2>&1 | Tee-Object -FilePath $proofFile -Append
$exitCode = $LASTEXITCODE

"" | Tee-Object -FilePath $proofFile -Append
"=== Summary ===" | Tee-Object -FilePath $proofFile -Append
Select-String -Path $proofFile -Pattern "Tests:|Assertions:|Failures:|Errors:|Skipped:|OK" |
    Select-Object -Last 5 | ForEach-Object { $_.Line } | Tee-Object -FilePath $proofFile -Append
"Proof: $proofFile"      | Tee-Object -FilePath $proofFile -Append
"Exit code: $exitCode"   | Tee-Object -FilePath $proofFile -Append

exit $exitCode
