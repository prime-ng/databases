<#
    Runner — Student Leave Management Dusk suite (std_StudentLeave_TestCas).
    Mirrors the committed StudentProfile sibling runners.

    Usage:
      ./run-StudentLeave-tests.ps1 [-Php C:\php\php.exe] [-Filter test_student_leave_20] [-SyncDb]

    Prerequisites:
      - StudentProfile module ENABLED in prime_testing/modules_statuses.json (else routes 404).
      - APP_ENV=testing (CSRF bypass).
      - Chrome/Chromedriver available; tenant server reachable at DUSK_TENANT_URL.
#>
param(
    [string]$Php    = "php",
    [string]$Filter = "std_StudentLeave_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Stop"

$TestRepo = if ($env:MAIN_PROJECT_PATH) { $env:MAIN_PROJECT_PATH } else { "C:\Herd\prime_testing" }
Set-Location $TestRepo

$Ts        = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir  = "tests/Browser/Modules/StudentProfile/StudentLeave/proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "StudentLeave_$Ts.log"

Write-Host "== Student Leave Dusk run =="
Write-Host "PHP    : $Php"
Write-Host "Filter : $Filter"
Write-Host "Proof  : $ProofFile"

# Clean stale screenshots.
Get-ChildItem "tests/Browser/console/screenshots" -Filter "student-leave-fail-*.png" -ErrorAction SilentlyContinue |
    Remove-Item -Force -ErrorAction SilentlyContinue

if ($SyncDb) {
    Write-Host "== Syncing tenant DB =="
    & $Php artisan migrate --force
}

& $Php artisan dusk --filter="$Filter" 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

Write-Host "== Summary =="
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES" |
    Select-Object -Last 5 | ForEach-Object { $_.Line }

Write-Host "Exit code: $ExitCode"
exit $ExitCode
