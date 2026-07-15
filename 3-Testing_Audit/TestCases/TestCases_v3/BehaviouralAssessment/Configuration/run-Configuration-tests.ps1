<#
    Runner - BehaviouralAssessment / Configuration Dusk suite (single file bha_Configuration_TestCas.php)

    Usage:
      ./run-Configuration-tests.ps1 -Php "C:\php\php.exe" -Filter "test_configuration_10" -SyncDb

    Prerequisites:
      - Module BehaviouralAssessment ENABLED in prime_testing/modules_statuses.json (disabled => 404 on all routes)
      - APP_ENV=testing, Chrome + Dusk driver, MAIN_PROJECT_PATH set, prime_ai cloned alongside
      - Tenant DB has >=1 academic session (sch_org_academic_sessions_jnt) with no existing ba_config
#>
param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"
$TestClass = "bha_Configuration_TestCas"

$ProjectRoot = $env:MAIN_PROJECT_PATH
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = "/Users/bkwork/Herd/prime_testing" }
Set-Location $ProjectRoot

$env:APP_ENV = "testing"

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir = Join-Path $ProjectRoot "tests/Browser/Modules/BehaviouralAssessment/proof"
if (-not (Test-Path $ProofDir)) { New-Item -ItemType Directory -Path $ProofDir | Out-Null }
$ProofFile = Join-Path $ProofDir "Configuration_$Stamp.log"

# Clean old screenshots (suite writes configuration-{pass,fail}-*.png).
Get-ChildItem -Path (Join-Path $ProjectRoot "tests/Browser/Modules/BehaviouralAssessment/Configuration/screenshots") -Filter "configuration-*.png" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

if ($SyncDb) {
    "Syncing tenant DB (migrate --force)..." | Tee-Object -FilePath $ProofFile -Append
    & $Php artisan migrate --force 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

$DuskFilter = $TestClass
if (-not [string]::IsNullOrWhiteSpace($Filter)) { $DuskFilter = $Filter }

"Running: $Php artisan dusk --filter=$DuskFilter" | Tee-Object -FilePath $ProofFile -Append
& $Php artisan dusk --filter=$DuskFilter 2>&1 | Tee-Object -FilePath $ProofFile -Append
$ExitCode = $LASTEXITCODE

"" | Tee-Object -FilePath $ProofFile -Append
"===== SUMMARY =====" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|Errors:|OK|FAILURES" | Select-Object -Last 5 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile" | Tee-Object -FilePath $ProofFile -Append
"Exit code: $ExitCode" | Tee-Object -FilePath $ProofFile -Append

exit $ExitCode
