<#
    Payment Reconciliation - Dusk runner (Windows PowerShell)
    Runs the single comprehensive suite: bil_PaymentReconciliation_TestCas.php

    Prerequisites:
      - prime_ai cloned alongside; MAIN_PROJECT_PATH set (see TEST_SETUP.md)
      - Billing module ENABLED in prime_testing/modules_statuses.json
      - APP_ENV=testing ; central host reachable at http://127.0.0.1:8000

    Usage:
      .\run-PaymentReconciliation-tests.ps1 -Php "C:\php\php.exe" -Filter "test_paymentreconciliation_10"
#>

param(
    [string]$Php    = "php",
    [string]$Filter = "bil_PaymentReconciliation_TestCas",
    [string]$Path   = "tests/Browser/Modules/Prime/Billing/PaymentReconciliation/bil_PaymentReconciliation_TestCas.php"
)

$ErrorActionPreference = "Stop"

$ProjectRoot = if ($env:PRIME_TESTING_PATH) { $env:PRIME_TESTING_PATH } else { (Get-Location).Path }
Set-Location $ProjectRoot

$ReportDir = "tests/Browser/Modules/Prime/Billing/PaymentReconciliation/proof"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ReportDir "reconciliation_$Stamp.log"

$Shots = "tests/Browser/Modules/Prime/Billing/PaymentReconciliation/screenshots"
if (Test-Path $Shots) { Remove-Item "$Shots/*.png" -ErrorAction SilentlyContinue }

Write-Host "== Payment Reconciliation Dusk run =="
Write-Host "PHP:     $Php"
Write-Host "Filter:  $Filter"
Write-Host "Proof:   $ProofFile"
Write-Host "======================================"

$env:APP_ENV = "testing"
& $Php artisan dusk --filter="$Filter" $Path 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

Write-Host "--------------------------------------"
$Summary = Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK " | Select-Object -Last 3
Write-Host "Summary:"
if ($Summary) { $Summary | ForEach-Object { Write-Host $_.Line } } else { Write-Host "  (no PHPUnit summary line parsed)" }
Write-Host "Exit code: $ExitCode"

exit $ExitCode
