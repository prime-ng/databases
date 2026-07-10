# Run the MarksheetGeneration - Components & Weightages Dusk suite (single file).
# Usage: .\run-ComponentsAndWeightages-tests.ps1 [-Filter <pattern>] [-Php <php>] [-SyncDb]
param(
    [string]$Filter = "msh_ComponentsAndWeightages_TestCas",
    [string]$Php    = "php",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

# Resolve the prime_testing runner root.
$RunnerRoot = if ($env:MAIN_PROJECT_PATH) { $env:MAIN_PROJECT_PATH } else { "C:\Herd\prime_testing" }
if (-not (Test-Path $RunnerRoot)) { Write-Error "Runner root not found: $RunnerRoot"; exit 1 }
Set-Location $RunnerRoot

$env:APP_ENV = "testing"

$Ts        = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir  = Join-Path $RunnerRoot "tests\Browser\Modules\MarksheetGeneration\ComponentsAndWeightages\proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "run_$Ts.log"

# Clean old screenshots.
$ShotDir = Join-Path $RunnerRoot "tests\Browser\Modules\MarksheetGeneration\ComponentsAndWeightages\screenshots"
if (Test-Path $ShotDir) { Get-ChildItem -Path $ShotDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue }

if ($SyncDb) {
    "Refreshing tenant test DB..." | Tee-Object -FilePath $ProofFile -Append
    & $Php artisan migrate:fresh --seed 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

"Running dusk --filter=$Filter" | Tee-Object -FilePath $ProofFile -Append
& $Php artisan dusk --filter=$Filter 2>&1 | Tee-Object -FilePath $ProofFile -Append
$DuskExit = $LASTEXITCODE

"" | Tee-Object -FilePath $ProofFile -Append
"===== SUMMARY =====" | Tee-Object -FilePath $ProofFile -Append
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|Errors:|OK \(" | Select-Object -Last 5 | ForEach-Object { $_.Line } | Tee-Object -FilePath $ProofFile -Append

Write-Host "Proof: $ProofFile"
Write-Host "Dusk exit code: $DuskExit"
exit $DuskExit
