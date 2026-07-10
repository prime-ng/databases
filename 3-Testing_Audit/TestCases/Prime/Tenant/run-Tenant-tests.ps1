<#
    Run the Prime "Tenant" Dusk suite (central prime_db scope, host 127.0.0.1:8000).

    Usage:
      ./run-Tenant-tests.ps1 -Php "C:\php\php.exe" -Filter "test_tenant_10" -SyncDb

    Prerequisites:
      - Prime module ENABLED in prime_testing/modules_statuses.json (else /prime/* -> 404)
      - App served at http://127.0.0.1:8000
      - APP_ENV=testing ; central super-admin present
#>
param(
    [string]$Php = "php",
    [string]$Filter = "prm_Tenant_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

$RunnerRoot = if ($env:MAIN_PROJECT_PATH) { $env:MAIN_PROJECT_PATH } else { "/Users/bkwork/Herd/prime_testing" }
$TestPath   = "tests/Browser/Modules/Prime/Tenant/prm_Tenant_TestCas.php"
$ProofDir   = Join-Path $PSScriptRoot "proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$Stamp      = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile  = Join-Path $ProofDir "tenant_dusk_$Stamp.log"

Set-Location $RunnerRoot

if ($SyncDb) {
    "==> Syncing test DB (migrate --force)..." | Tee-Object -FilePath $ProofFile -Append
    & $Php artisan migrate --force 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

"==> Cleaning old screenshots..." | Tee-Object -FilePath $ProofFile -Append
Remove-Item "tests/Browser/Modules/Prime/Tenant/screenshots/*.png" -ErrorAction SilentlyContinue

"==> Running Dusk: --filter=$Filter" | Tee-Object -FilePath $ProofFile -Append
$env:APP_ENV = "testing"
& $Php artisan dusk $TestPath --filter=$Filter 2>&1 | Tee-Object -FilePath $ProofFile -Append
$ExitCode = $LASTEXITCODE

"" | Tee-Object -FilePath $ProofFile -Append
"==> Summary" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|OK|FAILURES|Error" | Select-Object -Last 5 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile"
exit $ExitCode
