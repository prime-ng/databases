<#
    Billing Cycle - Dusk test runner (Windows PowerShell)

    Prereqs:
      - Copy prm_BillingCycle_TestCas.php into:
          prime_testing\tests\Browser\Modules\Prime\Billing\BillingCycle\
      - Billing module ENABLED in prime_testing\modules_statuses.json
      - Central app served at http://127.0.0.1:8000 ; ChromeDriver running
      - prm_billing_cycles.deleted_at column present (see MIG-BIL-001)

    Usage:
      .\run-BillingCycle-tests.ps1 [-Php <php.exe>] [-Filter <method-or-pattern>] [-Repo <path>]
#>

param(
    [string]$Php    = "php",
    [string]$Filter = "prm_BillingCycle_TestCas",
    [string]$Repo   = $(if ($env:TEST_FILE_REPO) { $env:TEST_FILE_REPO } else { "C:\Herd\prime_testing" })
)

$ErrorActionPreference = "Continue"
$env:APP_ENV = "testing"

$TestPath = "tests/Browser/Modules/Prime/Billing/BillingCycle/prm_BillingCycle_TestCas.php"

if (-not (Test-Path $Repo)) {
    Write-Error "Cannot find test repo at $Repo"
    exit 1
}
Set-Location $Repo

$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir  = Join-Path $Repo "tests/Browser/Modules/Prime/Billing/BillingCycle/proof"
$ShotDir   = Join-Path $Repo "tests/Browser/Modules/Prime/Billing/BillingCycle/screenshots"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "billing_cycle_run_$Stamp.log"

if (Test-Path $ShotDir) {
    Get-ChildItem -Path $ShotDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

"=== Billing Cycle Dusk run $Stamp ===" | Tee-Object -FilePath $ProofFile
"PHP:    $Php"      | Tee-Object -FilePath $ProofFile -Append
"Filter: $Filter"  | Tee-Object -FilePath $ProofFile -Append
"Path:   $TestPath" | Tee-Object -FilePath $ProofFile -Append
"" | Tee-Object -FilePath $ProofFile -Append

& $Php artisan dusk --filter="$Filter" $TestPath 2>&1 | Tee-Object -FilePath $ProofFile -Append
$ExitCode = $LASTEXITCODE

"" | Tee-Object -FilePath $ProofFile -Append
"----- Summary -----" | Tee-Object -FilePath $ProofFile -Append
$Summary = Select-String -Path $ProofFile -Pattern 'Tests:|Assertions:|OK \(|FAILURES|Errors:' | Select-Object -Last 5
if ($Summary) { $Summary.Line | Tee-Object -FilePath $ProofFile -Append }
else { "<no summary line parsed>" | Tee-Object -FilePath $ProofFile -Append }
"Exit code: $ExitCode" | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile"

exit $ExitCode
