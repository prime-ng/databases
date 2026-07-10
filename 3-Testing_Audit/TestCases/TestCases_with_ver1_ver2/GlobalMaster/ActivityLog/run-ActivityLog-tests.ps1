param(
    [string]$PhpPath = "C:\laragon\bin\php\php-8.3.30-Win32-vs16-x64\php.exe",
    [string]$Filter = "",
    [switch]$V1Only,
    [switch]$V2Only,
    [switch]$SyncDB
)

# ActivityLog (GlobalMaster / central) Dusk runner.
# Intended location: prime_testing/tests/Browser/Modules/Prime/GlobalMaster/ActivityLog/
# Prereqs:
#   - GlobalMaster AND Prime enabled in prime_testing/modules_statuses.json (else 404 on all routes).
#   - Central tests run against http://127.0.0.1:8000 (enforced by PrimeDuskTestCase).

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..\..\..")   # Prime/GlobalMaster/ActivityLog = 6 up
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
    $duskFilter = "sys_ActivityLogV1_TestCas"
} elseif ($V2Only) {
    $duskFilter = "sys_ActivityLogV2_TestCas"
} else {
    $duskFilter = "sys_ActivityLog"
}

$proofFile = Join-Path $proofDir "dusk_run_$timestamp.txt"
$latestFile = Join-Path $proofDir "dusk_run_latest.txt"

Push-Location $projectRoot
try {
    if ($SyncDB) {
        Write-Host "Detecting ChromeDriver..." -ForegroundColor Cyan
        & $PhpPath artisan dusk:chrome-driver --detect 2>&1 | Out-Null
    }

    $env:APP_ENV = "testing"
    Write-Host "Running Dusk with filter: $duskFilter" -ForegroundColor Cyan

    & $PhpPath artisan dusk --filter=$duskFilter 2>&1 | Tee-Object -FilePath $proofFile
    $exitCode = $LASTEXITCODE

    Copy-Item -Path $proofFile -Destination $latestFile -Force

    $passCount = 0; $failCount = 0; $totalCount = 0
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
        Write-Host "  ActivityLog RESULTS:" -ForegroundColor Cyan
        Write-Host "  Total: $totalCount, Passed: $passCount, Failed: $failCount" -ForegroundColor Cyan
        if ($failCount -eq 0) {
            Write-Host "  STATUS: ALL PASSED!" -ForegroundColor Green
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
