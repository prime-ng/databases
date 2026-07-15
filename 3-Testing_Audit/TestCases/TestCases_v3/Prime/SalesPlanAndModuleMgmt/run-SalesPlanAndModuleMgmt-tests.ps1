# -----------------------------------------------------------------------------
# run-SalesPlanAndModuleMgmt-tests.ps1 - Prime (PRM) Sales Plan & Module Mgmt (Windows)
# Single comprehensive suite: prm_SalesPlanAndModuleMgmt_TestCas.php (no V1/V2).
# Prime = CENTRAL. Host http://127.0.0.1:8000. APP_ENV=testing.
# Prereq: "Prime": true in prime_testing\modules_statuses.json (else 404).
# -----------------------------------------------------------------------------
param(
    [string]$PhpBin  = "php",
    [string]$Filter  = "prm_SalesPlanAndModuleMgmt_TestCas",
    [string]$RunnerDir = "C:\Herd\prime_testing",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

if (-not (Test-Path $RunnerDir)) {
    Write-Error "Runner dir not found: $RunnerDir"
    exit 2
}
Set-Location $RunnerDir

$env:APP_ENV = "testing"

$stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$proofDir = Join-Path $RunnerDir "tests\Browser\Modules\Prime\SalesPlanAndModuleMgmt\proof"
if (-not (Test-Path $proofDir)) { New-Item -ItemType Directory -Path $proofDir | Out-Null }
$proofFile = Join-Path $proofDir "salesplanandmodulemgmt_dusk_$stamp.log"

# Clean old screenshots.
$shotDir = Join-Path $RunnerDir "tests\Browser\Modules\Prime\SalesPlanAndModuleMgmt\screenshots"
if (Test-Path $shotDir) { Get-ChildItem -Path $shotDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }

if ($SyncDb) {
    "[info] migrating test DB..." | Tee-Object -FilePath $proofFile -Append
    & $PhpBin artisan migrate --force 2>&1 | Tee-Object -FilePath $proofFile -Append
}

"[info] running: artisan dusk --filter=$Filter" | Tee-Object -FilePath $proofFile -Append
& $PhpBin artisan dusk --filter=$Filter 2>&1 | Tee-Object -FilePath $proofFile -Append
$duskExit = $LASTEXITCODE

"" | Tee-Object -FilePath $proofFile -Append
"===== SUMMARY =====" | Tee-Object -FilePath $proofFile -Append
Select-String -Path $proofFile -Pattern "Tests:|Assertions:|Failures:|Errors:|OK \(" | Select-Object -Last 5 | ForEach-Object { $_.Line } | Tee-Object -FilePath $proofFile -Append

Write-Host "Proof: $proofFile"
Write-Host "Dusk exit code: $duskExit"
exit $duskExit
