# Runner: Prime (central) System Config -> Setting Dusk suite (PowerShell).
# One comprehensive file: sys_Setting_TestCas.php
param(
    [string]$PhpBin  = "php",
    [string]$Filter  = "sys_Setting_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

$RunnerRoot = if ($env:TEST_FILE_REPO) { $env:TEST_FILE_REPO } else { "/Users/bkwork/Herd/prime_testing" }
$TestPath   = "tests/Browser/Modules/Prime/Setting/sys_Setting_TestCas.php"
$ProofDir   = Join-Path $RunnerRoot "tests/Browser/Modules/Prime/Setting/proof"
$ShotDir    = Join-Path $RunnerRoot "tests/Browser/Modules/Prime/Setting/screenshots"
$Stamp      = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile  = Join-Path $ProofDir "setting_dusk_$Stamp.log"

New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
Write-Host "[i] Cleaning old screenshots in $ShotDir"
if (Test-Path $ShotDir) { Get-ChildItem -Path $ShotDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }

Write-Host "[i] Prime Setting is CENTRAL - expects host http://127.0.0.1:8000 and APP_ENV=testing."
Write-Host "[i] Ensure the Prime module is ENABLED in modules_statuses.json."

$env:APP_ENV = "testing"

if ($SyncDb) {
    Write-Host "[i] Syncing DB (migrate) ..."
    Push-Location $RunnerRoot
    & $PhpBin artisan migrate --force
    Pop-Location
}

Write-Host "[i] Running: artisan dusk --filter=$Filter"
Push-Location $RunnerRoot
& $PhpBin artisan dusk $TestPath --filter=$Filter 2>&1 | Tee-Object -FilePath $ProofFile
$DuskExit = $LASTEXITCODE
Pop-Location

Write-Host ""
Write-Host "==================== SUMMARY ===================="
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES" | Select-Object -Last 5 | ForEach-Object { $_.Line }
Write-Host "Proof: $ProofFile"
Write-Host "Exit code: $DuskExit"
Write-Host "================================================="
exit $DuskExit
