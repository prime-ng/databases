<#
    Runner: GlobalMaster / Activity Log Dusk suite (Prime-central, READ-ONLY viewer).
    Mirrors the golden reference: clean screenshots -> run filtered dusk -> tee proof -> parse -> summarise.

    Prereqs (see Validation Report §7):
      - GlobalMaster AND Prime ENABLED in prime_testing/modules_statuses.json (else 404)
      - Central app served on http://127.0.0.1:8000 with APP_ENV=testing
      - sys_central_activity_logs table exists (central migration run) — else DB/render tests self-skip
      - Test file copied to: tests/Browser/Modules/GlobalMaster/ActivityLog/sys_ActivityLog_TestCas.php

    Usage:
      ./run-ActivityLog-tests.ps1 [-Php C:\php\php.exe] [-Filter test_activitylog_60] [-SyncDb]
#>

param(
    [string]$Php    = "php",
    [string]$Filter = "sys_ActivityLog_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Definition
$RunnerRoot = if ($env:TEST_FILE_REPO) { $env:TEST_FILE_REPO } else { "/Users/bkwork/Herd/prime_testing" }

if (-not (Test-Path $RunnerRoot)) {
    Write-Error "Runner root not found: $RunnerRoot"
    exit 2
}
Set-Location $RunnerRoot
$env:APP_ENV = "testing"

$Ts        = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir  = Join-Path $ScriptDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "activity-log_$Ts.log"

Write-Host "== Activity Log Dusk run =="
Write-Host "Runner root : $RunnerRoot"
Write-Host "PHP         : $Php"
Write-Host "Filter      : $Filter"
Write-Host "Proof       : $ProofFile"

$ShotDir = Join-Path $RunnerRoot "tests/Browser/Modules/GlobalMaster/ActivityLog/screenshots"
if (Test-Path $ShotDir) {
    Get-ChildItem -Path $ShotDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

if ($SyncDb) {
    Write-Host "-- Syncing migrations (dusk env) --"
    & $Php artisan migrate --env=testing --force 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

Write-Host "-- Running dusk --filter=$Filter --"
& $Php artisan dusk --filter=$Filter 2>&1 | Tee-Object -FilePath $ProofFile -Append
$DuskExit = $LASTEXITCODE

$SummaryLine = Select-String -Path $ProofFile -Pattern "Tests:\s+\d+" | Select-Object -Last 1

Write-Host ""
Write-Host "== Summary =="
if ($SummaryLine) {
    Write-Host $SummaryLine.Line
} else {
    Write-Host "(no PHPUnit summary line parsed — check $ProofFile)"
}
Write-Host "Dusk exit code: $DuskExit"
Write-Host "Proof: $ProofFile"

exit $DuskExit
