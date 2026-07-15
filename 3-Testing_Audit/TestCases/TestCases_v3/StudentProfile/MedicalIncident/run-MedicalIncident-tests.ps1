<#
    Runner - StudentProfile / MedicalIncident Dusk suite (single file std_MedicalIncident_TestCas.php)

    Usage:
      ./run-MedicalIncident-tests.ps1 -Php "C:\php\php.exe" -Filter "test_medical_incident_10" -SyncDb

    Prerequisites:
      - Module STUDENT enabled in prime_testing/modules_statuses.json (disabled => 404 on all routes)
      - APP_ENV=testing, Chrome + Dusk driver, MAIN_PROJECT_PATH set, prime_ai cloned alongside
#>
param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"
$TestClass = "std_MedicalIncident_TestCas"

$ProjectRoot = $env:MAIN_PROJECT_PATH
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = "/Users/bkwork/Herd/prime_testing" }
Set-Location $ProjectRoot

$env:APP_ENV = "testing"

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir = Join-Path $ProjectRoot "tests/Browser/Modules/StudentProfile/proof"
if (-not (Test-Path $ProofDir)) { New-Item -ItemType Directory -Path $ProofDir | Out-Null }
$ProofFile = Join-Path $ProofDir "MedicalIncident_$Stamp.log"

# Clean old screenshots.
Get-ChildItem -Path (Join-Path $ProjectRoot "tests/Browser/console/screenshots") -Filter "medical-incident-fail-*.png" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

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
