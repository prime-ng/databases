param(
    [string]$PhpPath = "php",
    [string]$Filter = "",
    [switch]$SyncDB
)

# Runner for the Billing / InvoicingPayment Dusk suite (single comprehensive file).
# Target: bil_InvoicingPayment_TestCas.php
# NOTE: Billing must be enabled in prime_testing/modules_statuses.json and the
#       central app served at http://127.0.0.1:8000 (APP_ENV=testing).

$ErrorActionPreference = "Stop"
$env:APP_ENV = "testing"

$projectRoot   = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..\..")
$screenshotsDir = Join-Path $PSScriptRoot "screenshots"
$proofDir      = Join-Path $PSScriptRoot "proof"
New-Item -ItemType Directory -Force -Path $proofDir | Out-Null

if (Test-Path $screenshotsDir) {
    Remove-Item -Path "$screenshotsDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned old screenshots" -ForegroundColor Yellow
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if ($Filter) {
    $duskFilter = $Filter
} else {
    $duskFilter = "bil_InvoicingPayment_TestCas"
}

$proofFile  = Join-Path $proofDir "dusk_run_$timestamp.txt"
$latestFile = Join-Path $proofDir "dusk_run_latest.txt"

Push-Location $projectRoot
try {
    if ($SyncDB) {
        Write-Host "Detecting chrome driver..." -ForegroundColor Cyan
        & $PhpPath artisan dusk:chrome-driver --detect 2>&1 | Out-Null
    }

    Write-Host "Running: artisan dusk --filter=$duskFilter" -ForegroundColor Cyan
    & $PhpPath artisan dusk --filter=$duskFilter 2>&1 | Tee-Object -FilePath $proofFile
    $exitCode = $LASTEXITCODE
}
finally {
    Pop-Location
}

Copy-Item -Path $proofFile -Destination $latestFile -Force

$summary = Select-String -Path $proofFile -Pattern "Tests:\s+\d+" | Select-Object -Last 1
if ($summary) {
    Write-Host "`nSummary: $($summary.Line.Trim())" -ForegroundColor Green
} else {
    Write-Host "`nNo test summary line found (suite may have errored early)." -ForegroundColor Red
}

Write-Host "Proof: $proofFile"
exit $exitCode
