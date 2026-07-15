param(
    [string]$PhpPath = "C:\laragon\bin\php\php-8.3.30-Win32-vs16-x64\php.exe",
    [string]$Filter = "",
    [switch]$SyncDB
)

# Single comprehensive test file per screen — no V1/V2 split.
# Class name = bha_ReportsHub_TestCas. Default filter targets that class.

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..\..")
$screenshotsDir = Join-Path $PSScriptRoot "screenshots"
$proofDir = Join-Path $PSScriptRoot "proof"
New-Item -ItemType Directory -Force -Path $proofDir | Out-Null

# Clean old screenshots
if (Test-Path $screenshotsDir) {
    Remove-Item -Path "$screenshotsDir\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned old screenshots" -ForegroundColor Yellow
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if ($Filter) {
    $duskFilter = $Filter
} else {
    $duskFilter = "bha_ReportsHub_TestCas"
}

$proofFile = Join-Path $proofDir "dusk_run_$timestamp.txt"
$latestFile = Join-Path $proofDir "dusk_run_latest.txt"

Push-Location $projectRoot
try {
    if ($SyncDB) {
        Write-Host "Detecting matching ChromeDriver..." -ForegroundColor Cyan
        & $PhpPath artisan dusk:chrome-driver --detect 2>&1 | Out-Null
    }

    $env:APP_ENV = "testing"
    Write-Host "Running Dusk with filter: $duskFilter" -ForegroundColor Cyan
    Write-Host "Prerequisite: BehaviouralAssessment must be enabled in modules_statuses.json" -ForegroundColor DarkYellow

    & $PhpPath artisan dusk --filter=$duskFilter 2>&1 | Tee-Object -FilePath $proofFile
    $exitCode = $LASTEXITCODE

    Copy-Item -Path $proofFile -Destination $latestFile -Force

    $passCount = 0
    $failCount = 0
    $totalCount = 0
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
        $totalCount = "?"
        $passCount = "?"
        $failCount = "?"
    }

    if ($totalCount -ne 0) {
        Write-Host "`n============================================" -ForegroundColor Cyan
        Write-Host "  RESULTS (ReportsHub):" -ForegroundColor Cyan
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
