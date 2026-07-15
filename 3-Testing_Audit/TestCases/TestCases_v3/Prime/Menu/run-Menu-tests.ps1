<#
    Menu (PRM / Central) Dusk runner — glb_Menu_TestCas.
    Central feature: runs against http://127.0.0.1:8000 (NOT test.localhost).

    Usage:
      ./run-Menu-tests.ps1 -Php "C:\php\php.exe" -Filter "test_menu_20" -SyncDb
#>
param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

$RunnerRoot = if ($env:MAIN_PROJECT_PATH) { $env:MAIN_PROJECT_PATH } else { Join-Path $HOME "Herd/prime_testing" }
if (-not (Test-Path (Join-Path $RunnerRoot "artisan"))) {
    Write-Error "prime_testing runner not found at $RunnerRoot. Set MAIN_PROJECT_PATH."
    exit 1
}
Set-Location $RunnerRoot

$env:APP_ENV = "testing"

$Class = "glb_Menu_TestCas"
$FilterArg = if ($Filter -ne "") { $Filter } else { $Class }

$ShotDir = "tests/Browser/Modules/Prime/Menu/screenshots"
if (Test-Path $ShotDir) { Remove-Item "$ShotDir/*.png" -Force -ErrorAction SilentlyContinue }

if ($SyncDb) {
    Write-Host "[sync-db] refreshing central/global_master schema..."
    & $Php artisan migrate --force *> $null
}

$ProofDir = "tests/Browser/Modules/Prime/Menu/proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "menu_dusk_$Stamp.log"

Write-Host "Running Menu Dusk tests (filter: $FilterArg) ..."
& $Php artisan dusk --filter="$FilterArg" 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "==================== SUMMARY ===================="
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|Errors:|OK|FAILURES|Skipped:" | Select-Object -Last 5 | ForEach-Object { $_.Line }
Write-Host "Proof: $ProofFile"
Write-Host "Exit code: $ExitCode"
Write-Host "================================================="

exit $ExitCode
