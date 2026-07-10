param(
    [string]$PhpPath = "php",
    [string]$Filter = "",
    [switch]$V1Only,
    [switch]$V2Only,
    [switch]$SyncDB
)

# Runs the MarksheetGeneration / Scheduling & Lifecycle Dusk suites.
# Prereq: MarksheetGeneration enabled in modules_statuses.json; APP_ENV=testing; tenant seed data.

$projectRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..\..\..")
$proofDir = Join-Path $PSScriptRoot "proof"
New-Item -ItemType Directory -Force -Path $proofDir | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if ($Filter) {
    $duskFilter = $Filter
} elseif ($V1Only) {
    $duskFilter = "msh_SchedulingAndLifecycleV1_TestCas"
} elseif ($V2Only) {
    $duskFilter = "msh_SchedulingAndLifecycleV2_TestCas"
} else {
    $duskFilter = "msh_SchedulingAndLifecycle"
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
        $totalCount = [int]$Matches[1]; $failCount = [int]$Matches[2]; $passCount = $totalCount - $failCount
    } elseif ($content -match "OK\s+\((\d+)\s+test") {
        $totalCount = [int]$Matches[1]; $passCount = $totalCount; $failCount = 0
    }

    Write-Host "`n============================================" -ForegroundColor Cyan
    Write-Host "  RESULTS: Total=$totalCount Passed=$passCount Failed=$failCount" -ForegroundColor Cyan
    if ($failCount -eq 0 -and $totalCount -gt 0) {
        Write-Host "  STATUS: ALL PASSED" -ForegroundColor Green
    } else {
        Write-Host "  STATUS: REVIEW FAILURES / SKIPS" -ForegroundColor Yellow
    }
    Write-Host "============================================`n" -ForegroundColor Cyan
    Write-Host "Proof: $proofFile" -ForegroundColor Gray
    exit $exitCode
}
finally {
    Pop-Location
    Remove-Item Env:\APP_ENV -ErrorAction SilentlyContinue
}
