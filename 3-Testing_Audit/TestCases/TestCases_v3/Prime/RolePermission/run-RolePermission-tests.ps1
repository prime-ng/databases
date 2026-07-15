# Run the Prime RolePermission Dusk suite (central / 127.0.0.1:8000).
# Usage: .\run-RolePermission-tests.ps1 [-Php php] [-Filter test_name] [-SyncDb]
param(
    [string]$Php = "php",
    [string]$Filter = "sys_RolePermission_TestCas",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

$RunnerRoot = if ($env:MAIN_PROJECT_PATH) { $env:MAIN_PROJECT_PATH } else { "C:\Herd\prime_testing" }
if (-not (Test-Path $RunnerRoot)) { Write-Error "Runner root not found: $RunnerRoot"; exit 1 }
Set-Location $RunnerRoot

$env:APP_ENV = "testing"
$Ts = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir = "tests\Browser\Modules\Prime\RolePermission\proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "rolepermission_$Ts.log"

# Clean stale screenshots.
Get-ChildItem -Path "tests\Browser\Modules\Prime\RolePermission" -Recurse -Directory -Filter "screenshots" -ErrorAction SilentlyContinue |
    ForEach-Object { Get-ChildItem -Path $_.FullName -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }

if ($SyncDb) {
    "Syncing test DB..." | Tee-Object -FilePath $ProofFile -Append
    & $Php artisan migrate --env=testing 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

"Running: $Php artisan dusk --filter=$Filter" | Tee-Object -FilePath $ProofFile -Append
& $Php artisan dusk --filter=$Filter 2>&1 | Tee-Object -FilePath $ProofFile -Append
$DuskExit = $LASTEXITCODE

"" | Tee-Object -FilePath $ProofFile -Append
"==== Summary ====" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|OK|FAIL|Error" | Select-Object -Last 5 | ForEach-Object { $_.Line }
Write-Host "Proof written to: $ProofFile"
Write-Host "Exit code: $DuskExit"
exit $DuskExit
