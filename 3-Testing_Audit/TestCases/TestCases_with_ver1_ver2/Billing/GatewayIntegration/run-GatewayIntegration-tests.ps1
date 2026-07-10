param(
    [string]$PhpPath = "php",
    [string]$Filter = "",
    [switch]$V1Only,
    [switch]$V2Only,
    [switch]$SyncDB
)

# Billing / GatewayIntegration Dusk runner.
# NOTE: GatewayIntegration is a PLANNED / NOT-IMPLEMENTED feature. This suite
# asserts current reality (schema/route-absence/composer/config/UI) and marks
# every planned contract clause as skipped. Expect many "S" (skipped) results.
# Prerequisite: Billing module ENABLED in modules_statuses.json; prime_ai cloned
# alongside the runner; APP_ENV=testing.

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..\..")
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
    $duskFilter = "bil_GatewayIntegrationV1_TestCas"
} elseif ($V2Only) {
    $duskFilter = "bil_GatewayIntegrationV2_TestCas"
} else {
    $duskFilter = "bil_GatewayIntegration"
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
        $failCount = 0
    } elseif ($content -match "FAILURES!") {
        $totalCount = "?"; $passCount = "?"; $failCount = "?"
    }

    if ($totalCount -ne 0) {
        Write-Host "`n============================================" -ForegroundColor Cyan
        Write-Host "  RESULTS: Total: $totalCount, Passed: $passCount, Failed: $failCount" -ForegroundColor Cyan
        if ($failCount -eq 0) {
            Write-Host "  STATUS: ALL PASSED (skipped = planned/not-implemented)" -ForegroundColor Green
        } else {
            Write-Host "  STATUS: SOME FAILED" -ForegroundColor Red
        }
        Write-Host "============================================`n" -ForegroundColor Cyan
    }

    Write-Host "Proof saved at: $proofFile" -ForegroundColor Gray
    exit $exitCode
}
finally {
    Pop-Location
    Remove-Item Env:\APP_ENV -ErrorAction SilentlyContinue
}
