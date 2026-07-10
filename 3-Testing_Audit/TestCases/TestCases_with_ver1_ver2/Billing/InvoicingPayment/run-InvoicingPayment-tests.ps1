<#
=============================================================================
 Invoice Payments (Billing / InvoicingPayment) — Dusk runner (Windows/PowerShell)

 Central prime_db feature. Mirrors the committed BillingDuskTestCase siblings.
 Requires: Billing module ENABLED in modules_statuses.json; APP_ENV=testing;
           app served at http://127.0.0.1:8000 (Prime tests enforce this host).

 Usage:
   ./run-InvoicingPayment-tests.ps1 [-Php <path>] [-Filter <name>]
                                    [-V1Only] [-V2Only] [-SyncDb]
=============================================================================
#>
param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$V1Only,
    [switch]$V2Only,
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

$ProjectRoot = $env:MAIN_PROJECT_PATH
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = "C:\Herd\prime_testing" }
Set-Location $ProjectRoot

$TestDir  = "tests/Browser/Modules/Prime/Billing/InvoicingPayment"
$ProofDir = Join-Path $TestDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir, (Join-Path $TestDir "screenshots"), (Join-Path $TestDir "report") | Out-Null

# Clean stale screenshots.
Get-ChildItem -Path (Join-Path $TestDir "screenshots") -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

$env:APP_ENV = "testing"

if ($SyncDb) {
    Write-Host "==> Syncing test DB (migrate)..."
    & $Php artisan migrate --force | Out-Null
}

$Ts        = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "invoicing_payment_run_$Ts.log"

if     ($Filter -ne "") { $FilterArg = "--filter=$Filter" }
elseif ($V1Only)        { $FilterArg = "--filter=bil_InvoicingPaymentV1_TestCas" }
elseif ($V2Only)        { $FilterArg = "--filter=bil_InvoicingPaymentV2_TestCas" }
else                    { $FilterArg = "--filter=InvoicingPayment" }

Write-Host "==> Running: artisan dusk $FilterArg"
Write-Host "    Proof:   $ProofFile"

& $Php artisan dusk $FilterArg 2>&1 | Tee-Object -FilePath $ProofFile
$DuskExit = $LASTEXITCODE

Write-Host ""
Write-Host "==> Summary"
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|OK|FAIL" | Select-Object -Last 5 | ForEach-Object { $_.Line }

Write-Host "==> Dusk exit code: $DuskExit"
exit $DuskExit
