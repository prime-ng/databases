# Runner: Prime (central) Academic Session Dusk suite (Windows PowerShell).
# One comprehensive file: glb_AcademicSession_TestCas.php
param(
    [string]$Filter = "glb_AcademicSession_TestCas",
    [string]$PhpBin = "php",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

$RunnerRoot = if ($env:TEST_FILE_REPO) { $env:TEST_FILE_REPO } else { "C:\Herd\prime_testing" }
$TestPath   = "tests/Browser/Modules/Prime/AcademicSession/glb_AcademicSession_TestCas.php"
$ProofDir   = Join-Path $RunnerRoot "tests/Browser/Modules/Prime/AcademicSession/proof"
$ShotDir    = Join-Path $RunnerRoot "tests/Browser/Modules/Prime/AcademicSession/screenshots"
$Stamp      = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile  = Join-Path $ProofDir "academicsession_dusk_$Stamp.log"

New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
Write-Host "[i] Cleaning old screenshots in $ShotDir"
if (Test-Path $ShotDir) { Remove-Item (Join-Path $ShotDir "*.png") -ErrorAction SilentlyContinue }

Write-Host "[i] Academic Session is CENTRAL (global_master DB) - expects host http://127.0.0.1:8000 and APP_ENV=testing."
Write-Host "[i] Ensure the Prime module is ENABLED in modules_statuses.json (else all /prime/* routes 404)."
Write-Host "[i] Ensure the global_master_mysql connection is configured and glb_academic_sessions exists."

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
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES" | Select-Object -Last 5
Write-Host "Proof: $ProofFile"
Write-Host "Exit code: $DuskExit"
Write-Host "================================================="
exit $DuskExit
