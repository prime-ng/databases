# ---------------------------------------------------------------------------
# Student Leave Type - Dusk runner (Windows PowerShell)
# Runs the single comprehensive suite std_StudentLeaveType_TestCas.
#
# Prerequisites:
#   - prime_testing runner configured (MAIN_PROJECT_PATH -> prime_ai)
#   - StudentProfile module ENABLED in modules_statuses.json (else all routes 404)
#   - APP_ENV=testing ; tenant host reachable at DUSK_TENANT_URL (http://test.localhost:8000)
#
# Usage:
#   ./run-StudentLeaveType-tests.ps1 [-Php <php.exe>] [-Filter <method>] [-SyncDb]
# ---------------------------------------------------------------------------
param(
    [string]$Php    = "php",
    [string]$Filter = "std_StudentLeaveType_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Resolve the test runner root (prime_testing). Override with $env:TEST_REPO if needed.
$TestRepo = if ($env:TEST_REPO) { $env:TEST_REPO } else { "C:\Herd\prime_testing" }
if (-not (Test-Path $TestRepo)) { Write-Error "TEST_REPO not found: $TestRepo"; exit 1 }
Set-Location $TestRepo

$env:APP_ENV = "testing"

$ProofDir = Join-Path $ScriptDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "StudentLeaveType_$Stamp.log"

# Clean old screenshots for this feature
$ShotDir = Join-Path $TestRepo "tests\Browser\console\screenshots"
if (Test-Path $ShotDir) {
    Get-ChildItem $ShotDir -Filter "leave-type-fail-*.png" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

if ($SyncDb) {
    "Syncing tenant DB..." | Tee-Object -FilePath $ProofFile -Append
    & $Php artisan migrate --database=tenant --force 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

"Running Dusk filter: $Filter" | Tee-Object -FilePath $ProofFile -Append
& $Php artisan dusk --filter="$Filter" 2>&1 | Tee-Object -FilePath $ProofFile -Append
$DuskExit = $LASTEXITCODE

"" | Tee-Object -FilePath $ProofFile -Append
"----- SUMMARY -----" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES" |
    Select-Object -Last 5 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append

Write-Host "Proof: $ProofFile"
Write-Host "Dusk exit code: $DuskExit"
exit $DuskExit
