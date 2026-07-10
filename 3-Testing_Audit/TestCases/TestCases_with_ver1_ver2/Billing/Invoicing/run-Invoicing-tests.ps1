# ---------------------------------------------------------------------------
# Invoicing (Invoice Generation) - Dusk test runner (Windows PowerShell)
# Central prime_db feature (Invoicing tab of Billing Management).
# Mirrors the golden-reference runner idiom.
#
# Usage:
#   .\run-Invoicing-tests.ps1 [-Php <path>] [-Filter <name>] [-V1] [-V2]
#
# Prerequisites:
#   * Billing module ENABLED in modules_statuses.json (else 404 on all routes)
#   * APP_ENV=testing  (CSRF bypass for generate / remarks AJAX posts)
#   * Central dev server reachable on http://127.0.0.1:8000
#   * bil_tenant_invoices.deleted_at present (MIG-BIL-001 dev patch)
# ---------------------------------------------------------------------------
param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$V1,
    [switch]$V2
)

$ErrorActionPreference = "Continue"

$V1Class = "bil_InvoicingV1_TestCas"
$V2Class = "bil_InvoicingV2_TestCas"

# Resolve the prime_testing runner root.
$RunnerRoot = $env:MAIN_PROJECT_PATH
if ([string]::IsNullOrWhiteSpace($RunnerRoot)) {
    $RunnerRoot = "C:\Herd\prime_testing"
}
if (-not (Test-Path $RunnerRoot)) {
    Write-Error "Runner root not found at $RunnerRoot (set MAIN_PROJECT_PATH)."
    exit 1
}
Set-Location $RunnerRoot

$env:APP_ENV = "testing"

$Ts = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir = "tests/Browser/Modules/Prime/Billing/Invoicing/proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "billing_invoicing_dusk_$Ts.log"

# Clean stale screenshots.
$ShotDir = "tests/Browser/Modules/Prime/Billing/Invoicing/screenshots"
if (Test-Path $ShotDir) {
    Get-ChildItem -Path $ShotDir -Filter *.png -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

# Build the --filter argument.
if (-not [string]::IsNullOrWhiteSpace($Filter)) {
    $FilterArg = "--filter=$Filter"
} elseif ($V1) {
    $FilterArg = "--filter=$V1Class"
} elseif ($V2) {
    $FilterArg = "--filter=$V2Class"
} else {
    $FilterArg = "--filter=Invoicing(V1|V2)_TestCas"
}

Write-Host "==================================================================="
Write-Host " Invoicing (Invoice Generation) Dusk run"
Write-Host " Runner : $RunnerRoot"
Write-Host " PHP    : $Php"
Write-Host " Filter : $FilterArg"
Write-Host " Proof  : $ProofFile"
Write-Host "==================================================================="

& $Php artisan dusk $FilterArg 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "------------------------- SUMMARY -------------------------"
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|OK|FAILURES|Failed|Error" |
    Select-Object -Last 10 | ForEach-Object { $_.Line }
Write-Host "-----------------------------------------------------------"
Write-Host "Dusk exit code: $ExitCode  (proof: $ProofFile)"

exit $ExitCode
