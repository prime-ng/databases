param(
    [string]$PhpPath = "php",
    [string]$Filter = "",
    [switch]$V1Only,
    [switch]$V2Only,
    [switch]$SyncDB
)

# Payment Reconciliation (Billing) Dusk runner — prime_db central.
# Deploy at: prime_testing/tests/Browser/Modules/Prime/Billing/PaymentReconciliation/
# Prereqs: Billing enabled in modules_statuses.json; Prime host 127.0.0.1:8000; APP_ENV=testing.

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..\..\..")
$screenshotsDir = Join-Path $PSScriptRoot "screenshots"
$proofDir = Join-Path $PSScriptRoot "proof"
New-Item -ItemType Directory -Force -Path $proofDir | Out-Null

if (Test-Path $screenshotsDir) {
    Remove-Item -Path "$screenshotsDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned old screenshots" -ForegroundColor Yellow
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if ($Filter) {
    $duskFilter = $Filter
} elseif ($V1Only) {
    $duskFilter = "bil_PaymentReconciliationV1_TestCas"
} elseif ($V2Only) {
    $duskFilter = "bil_PaymentReconciliationV2_TestCas"
} else {
    $duskFilter = "bil_PaymentReconciliation"
}

$proofFile = Join-Path $proofDir "dusk_run_$timestamp.txt"
$latestFile = Join-Path $proofDir "dusk_run_latest.txt"

Push-Location $projectRoot
try {
    if ($SyncDB) {
        Write-Host "Detecting chrome driver..." -ForegroundColor Cyan
        & $PhpPath artisan dusk:chrome-driver --detect 2>&1 | Out-Null
    }

    $env:APP_ENV = "testing"
    Write-Host "Running Dusk with filter: $duskFilter" -ForegroundColor Cyan

    & $PhpPath artisan dusk --filter=$duskFilter 2>&1 | Tee-Object -FilePath $proofFile
    $exitCode = $LASTEXITCODE

    Copy-Item -Path $proofFile -Destination $latestFile -Force

    $totalCount = 0; $failCount = 0; $passCount = 0
    $content = Get-Content -Raw -Path $proofFile

    if ($content -match "Tests:\s+(\d+),\s+Assertions:\s+\d+,\s+Failures:\s+(\d+)") {
        $totalCount = [int]$Matches[1]
        $failCount = [int]$Matches[2]
        $passCount = $totalCount - $failCount
    } elseif ($content -match "OK\s+\((\d+)\s+test") {
        $totalCount = [int]$Matches[1]
        $passCount = $totalCount
    }

    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "  Payment Reconciliation RESULTS:" -ForegroundColor Cyan
    Write-Host "  Total: $totalCount, Passed: $passCount, Failed: $failCount" -ForegroundColor Cyan
    if ($failCount -eq 0 -and $totalCount -gt 0) {
        Write-Host "  STATUS: ALL PASSED!" -ForegroundColor Green
    } else {
        Write-Host "  STATUS: SEE PROOF" -ForegroundColor Yellow
    }
    Write-Host "============================================`n" -ForegroundColor Cyan
    Write-Host "Proof saved at: $proofFile"
}
finally {
    Pop-Location
}

exit $exitCode
