<#
    Run the StudentProfile / Attendance Dusk suite (single comprehensive file).
    Usage:
      .\run-Attendance-tests.ps1 [-Php C:\php\php.exe] [-Filter test_attendance_14] [-SyncDb]
#>
param(
    [string]$Php    = "php",
    [string]$Filter = "std_Attendance_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Stop"

$RunnerRoot = if ($env:MAIN_TEST_PATH) { $env:MAIN_TEST_PATH } else { "C:\Herd\prime_testing" }
Set-Location $RunnerRoot

$env:APP_ENV = "testing"

$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir  = Join-Path $PSScriptRoot "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "attendance_$Stamp.log"

Write-Host "== StudentProfile / Attendance Dusk run =="
Write-Host "Runner : $RunnerRoot"
Write-Host "Filter : $Filter"
Write-Host "Proof  : $ProofFile"

# Clean stale failure screenshots for this feature.
Get-ChildItem -Path "tests/Browser/console/screenshots" -Filter "std-att-fail-*.png" -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

if ($SyncDb) {
    Write-Host "Syncing tenant DB (migrate)..."
    & $Php artisan migrate --force
}

& $Php artisan dusk --filter="$Filter" 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "== Summary =="
Select-String -Path $ProofFile -Pattern 'Tests:|Assertions:|Failures:|OK \(' |
    Select-Object -Last 5 | ForEach-Object { $_.Line }
Write-Host "Exit code: $ExitCode"
exit $ExitCode
