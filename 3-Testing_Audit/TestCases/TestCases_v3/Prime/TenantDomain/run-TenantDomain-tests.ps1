<#
    Runner for the PRIME (central) TenantDomain Dusk suite (Windows / PowerShell).
    Feature runs on http://127.0.0.1:8000 (central) - NO tenant init.

    Usage:
      ./run-TenantDomain-tests.ps1 -Php "C:\php\php.exe" -Filter "test_tenantdomain_11"
#>
param(
    [string]$Php    = "php",
    [string]$Filter = "",
    [string]$Repo   = $(if ($env:TEST_FILE_REPO) { $env:TEST_FILE_REPO } else { "C:\Herd\prime_testing" })
)

$ErrorActionPreference = "Continue"
$TestClass = "prm_TenantDomain_TestCas"

if (-not (Test-Path $Repo)) { Write-Error "Repo not found: $Repo"; exit 1 }
Set-Location $Repo

$env:APP_ENV = "testing"

$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir  = "tests/Browser/Modules/Prime/TenantDomain/proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "tenantdomain_$Stamp.log"

# Clean prior screenshots.
$Shots = "tests/Browser/Modules/Prime/TenantDomain/screenshots"
if (Test-Path $Shots) { Remove-Item "$Shots/*.png" -Force -ErrorAction SilentlyContinue }

"=== TenantDomain (PRIME/central) Dusk run @ $Stamp ===" | Tee-Object -FilePath $ProofFile
"Host: http://127.0.0.1:8000 | Repo: $Repo"              | Tee-Object -FilePath $ProofFile -Append
"NOTE: Ensure Prime module is ENABLED in modules_statuses.json." | Tee-Object -FilePath $ProofFile -Append

$DuskFilter = $TestClass
if ($Filter -ne "") { $DuskFilter = $Filter }

& $Php artisan dusk --filter="$DuskFilter" 2>&1 | Tee-Object -FilePath $ProofFile -Append
$ExitCode = $LASTEXITCODE

"" | Tee-Object -FilePath $ProofFile -Append
"=== Summary ===" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|Errors:|OK" | Select-Object -Last 5 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append

Write-Host "Proof: $ProofFile"
Write-Host "Exit code: $ExitCode"
exit $ExitCode
