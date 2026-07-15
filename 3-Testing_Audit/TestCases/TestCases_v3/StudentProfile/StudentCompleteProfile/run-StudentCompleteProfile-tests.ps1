<#
    run-StudentCompleteProfile-tests.ps1
    Runs the StudentProfile / StudentCompleteProfile Dusk suite (ONE file: std_StudentCompleteProfile_TestCas.php).

    Prerequisites:
      - prime_ai cloned alongside prime_testing; MAIN_PROJECT_PATH set (see TEST_SETUP.md)
      - STUDENT module ENABLED in prime_testing/modules_statuses.json (else all routes 404)
      - APP_ENV=testing (bypasses CSRF for authenticated flows)

    Usage:
      ./run-StudentCompleteProfile-tests.ps1 [-Php <path>] [-Filter <method>] [-SyncDb]
#>
param(
    [string]$Php    = "php",
    [string]$Filter = "",
    [switch]$SyncDb
)

$ErrorActionPreference = "Stop"
$TestFile  = "tests/Browser/Modules/StudentProfile/Testcases/std_StudentCompleteProfile_TestCas.php"
$ProofDir  = "tests/Browser/Modules/StudentProfile/StudentCompleteProfile/proof"
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "std_StudentCompleteProfile_$Stamp.txt"

New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null

Write-Host "Cleaning old screenshots..." -ForegroundColor Cyan
Get-ChildItem -Path "tests/Browser/console/screenshots" -Filter "*complete-profile*" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

if ($SyncDb) {
    Write-Host "Syncing tenant test DB..." -ForegroundColor Cyan
    & $Php artisan migrate --env=testing
}

$env:APP_ENV = "testing"

$duskArgs = @("artisan", "dusk", $TestFile)
if ($Filter -ne "") { $duskArgs += "--filter=$Filter" }

Write-Host "Running: $Php $($duskArgs -join ' ')" -ForegroundColor Green
& $Php @duskArgs 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

$summary = Select-String -Path $ProofFile -Pattern "Tests:\s+\d+" | Select-Object -Last 1
Write-Host "----------------------------------------" -ForegroundColor Yellow
if ($summary) { Write-Host $summary.Line -ForegroundColor Yellow } else { Write-Host "No test summary parsed." -ForegroundColor Red }
Write-Host "Proof: $ProofFile" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Yellow

exit $ExitCode
