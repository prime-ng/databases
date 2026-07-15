# ---------------------------------------------------------------------------
# Runner: Prime -> TenantManagement Dusk suite (read/composite dashboard)
# Single test file: prm_TenantManagement_TestCas.php  (24 methods)
# Central feature - runs on http://127.0.0.1:8000. Prime module must be enabled.
# ---------------------------------------------------------------------------
param(
    [string]$PhpBin = "php",
    [string]$Filter = "prm_TenantManagement_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"
$TestPath = "tests/Browser/Modules/Prime/TenantManagement/prm_TenantManagement_TestCas.php"

$ProjectRoot = if ($env:MAIN_PROJECT_PATH) { $env:MAIN_PROJECT_PATH } else { (Get-Location).Path }
Set-Location $ProjectRoot

$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir = "tests/Browser/Modules/Prime/TenantManagement/proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "tenantmanagement_$Stamp.log"

"=== Prime/TenantManagement Dusk run @ $Stamp ===" | Tee-Object -FilePath $ProofFile
"Filter: $Filter"                                   | Tee-Object -FilePath $ProofFile -Append

# Clean old screenshots for this feature
$ShotDir = "tests/Browser/Modules/Prime/TenantManagement/screenshots"
if (Test-Path $ShotDir) { Get-ChildItem $ShotDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }

$env:APP_ENV = "testing"

if ($SyncDb) {
    "Syncing test DB..." | Tee-Object -FilePath $ProofFile -Append
    & $PhpBin artisan migrate --force 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

"--- artisan dusk ---" | Tee-Object -FilePath $ProofFile -Append
& $PhpBin artisan dusk --filter=$Filter $TestPath 2>&1 | Tee-Object -FilePath $ProofFile -Append
$ExitCode = $LASTEXITCODE

"--- summary ---" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|Errors:|OK \(" | Select-Object -Last 5 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append

"Exit code: $ExitCode" | Tee-Object -FilePath $ProofFile -Append
"Proof: $ProofFile"
exit $ExitCode
