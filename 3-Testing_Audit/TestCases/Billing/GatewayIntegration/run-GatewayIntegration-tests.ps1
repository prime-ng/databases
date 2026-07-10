<#
    Runner: Billing / GatewayIntegration Dusk suite (PLANNING-STAGE STUB SET)
    -------------------------------------------------------------------------
    NOTE: This feature is NOT IMPLEMENTED (planning stage). The suite is designed
    to be GREEN: test_01 asserts the current reality (the gap); every planned
    behavioural test is markTestSkipped(). Expect: 1 passing, 38 skipped.

    Prerequisites:
      - prime_ai cloned alongside prime_testing; MAIN_PROJECT_PATH set.
      - Billing module ENABLED in prime_testing/modules_statuses.json (else 404). [E19]
      - APP_ENV=testing (bypasses CSRF for Dusk). [E20]
      - Central/prime host reachable at http://127.0.0.1:8000. [E21]
#>
param(
    [string]$PhpBin  = "php",
    [string]$Filter  = "bil_GatewayIntegration_TestCas",
    [string]$TestRepo = "C:\Herd\prime_testing"
)

$ErrorActionPreference = "Continue"
$TestPath = "tests/Browser/Modules/Prime/Billing/GatewayIntegration/bil_GatewayIntegration_TestCas.php"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ProofDir  = Join-Path $ScriptDir "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "GatewayIntegration_$Stamp.log"

Write-Host "== Billing/GatewayIntegration Dusk run (planning-stage) =="
Write-Host "Runner repo : $TestRepo"
Write-Host "Filter      : $Filter"
Write-Host "Proof file  : $ProofFile"
Write-Host "Expectation : 1 passed, 38 skipped (feature not implemented)."
Write-Host ""

$FullTestPath = Join-Path $TestRepo $TestPath
if (-not (Test-Path $FullTestPath)) {
    Write-Host "WARN: $TestPath not found under $TestRepo."
    Write-Host "      Copy the .php into the runner (or set -TestRepo) before executing. Skipping run."
    exit 0
}

# Clean old screenshots for this feature.
$ShotDir = Join-Path $TestRepo "tests/Browser/Modules/Prime/Billing/GatewayIntegration/screenshots"
if (Test-Path $ShotDir) { Remove-Item "$ShotDir/*.png" -ErrorAction SilentlyContinue }

Push-Location $TestRepo
$env:APP_ENV = "testing"
& $PhpBin artisan dusk --filter=$Filter 2>&1 | Tee-Object -FilePath $ProofFile
$DuskExit = $LASTEXITCODE
Pop-Location

Write-Host ""
Write-Host "== Summary =="
Select-String -Path $ProofFile -Pattern 'Tests:|OK|FAIL|Skipped|Risky' | Select-Object -Last 5 | ForEach-Object { $_.Line }
Write-Host "Dusk exit code: $DuskExit"
exit $DuskExit
