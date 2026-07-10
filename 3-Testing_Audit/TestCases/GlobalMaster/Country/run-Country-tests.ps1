# ---------------------------------------------------------------------------
# GlobalMaster Country - Dusk test runner (Windows PowerShell)
# CENTRAL prime-side feature. Mirrors the golden-reference runner idiom.
# ONE comprehensive test class - no V1/V2 split.
#
# Usage:
#   .\run-Country-tests.ps1 [-Php <path>] [-Filter <name>] [-SyncDb]
#
# Prerequisites (env, NOT code fixes):
#   * GlobalMaster AND Prime modules ENABLED in modules_statuses.json
#     (both default false -> 404 on all /global-master/country routes).
#   * APP_ENV=testing  (CSRF bypass for toggle-status AJAX / JSON asserts)
#   * Central dev server reachable on http://127.0.0.1:8000
#   * global_master_mysql connection reachable; glb_countries.deleted_at present
# ---------------------------------------------------------------------------
param(
    [string]$Php = "php",
    [string]$Filter = "",
    [switch]$SyncDb
)

$ErrorActionPreference = "Continue"

# Resolve the prime_testing runner root.
$RunnerRoot = $env:MAIN_PROJECT_PATH
if ([string]::IsNullOrWhiteSpace($RunnerRoot)) {
    $RunnerRoot = "C:\Herd\prime_testing"
}
if (-not (Test-Path $RunnerRoot)) {
    Write-Error "Runner root not found at $RunnerRoot (set MAIN_PROJECT_PATH)."
    exit 1
}
Set-Location $RunnerRoot

$env:APP_ENV = "testing"

$Ts = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir = "tests/Browser/Modules/GlobalMaster/Country/proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$ProofFile = Join-Path $ProofDir "glb_country_dusk_$Ts.log"

# Clean stale screenshots.
$ShotDir = "tests/Browser/Modules/GlobalMaster/Country/screenshots"
if (Test-Path $ShotDir) {
    Get-ChildItem -Path $ShotDir -Filter *.png -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
}

# Optional: refresh the central schema before running.
if ($SyncDb) {
    Write-Host "Syncing central schema (migrate) ..."
    & $Php artisan migrate --force 2>&1 | Tee-Object -FilePath $ProofFile -Append
}

# Build the --filter argument (defaults to the single Country class).
if (-not [string]::IsNullOrWhiteSpace($Filter)) {
    $FilterArg = "--filter=$Filter"
} else {
    $FilterArg = "--filter=glb_Country_TestCas"
}

Write-Host "==================================================================="
Write-Host " GlobalMaster Country Dusk run (CENTRAL / http://127.0.0.1:8000)"
Write-Host " Runner : $RunnerRoot"
Write-Host " PHP    : $Php"
Write-Host " Filter : $FilterArg"
Write-Host " Proof  : $ProofFile"
Write-Host "==================================================================="

& $Php artisan dusk $FilterArg 2>&1 | Tee-Object -FilePath $ProofFile -Append
$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "------------------------- SUMMARY -------------------------"
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|OK|FAILURES|Failed|Error" |
    Select-Object -Last 10 | ForEach-Object { $_.Line }
Write-Host "-----------------------------------------------------------"
Write-Host "Dusk exit code: $ExitCode  (proof: $ProofFile)"

exit $ExitCode
