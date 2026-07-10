# run-Board-tests.ps1 — Prime (PRM) Board feature Dusk runner (Windows)
#
# Single comprehensive suite: glb_Board_TestCas.php (class glb_Board_TestCas).
# Prime is CENTRAL — tests run against http://127.0.0.1:8000 (no tenant subdomain).
#
# Prerequisites:
#   * Prime module ENABLED in prime_testing/modules_statuses.json (else 404).
#   * APP_ENV=testing ; central app served at http://127.0.0.1:8000.
#   * global_master DB reachable via the global_master_mysql connection.
#
# Usage:
#   ./run-Board-tests.ps1 [-PhpPath php] [-Filter test_board_10] [-SyncDb]

param(
    [string]$PhpPath = "php",
    [string]$Filter  = "",
    [switch]$SyncDb
)

$ErrorActionPreference = "Stop"

# Resolve the prime_testing runner root (script may live in the OLD_REPO TestCases tree).
$RunnerRoot = $env:PRIME_TESTING_PATH
if ([string]::IsNullOrEmpty($RunnerRoot)) { $RunnerRoot = "C:\Herd\prime_testing" }
if (-not (Test-Path $RunnerRoot)) { $RunnerRoot = (Get-Location).Path }

Set-Location $RunnerRoot
Write-Host "Runner root : $RunnerRoot" -ForegroundColor Cyan

$TestClassPath = "tests/Browser/Modules/Prime/Board/glb_Board_TestCas.php"

# Clean old screenshots.
$ShotDir = Join-Path $RunnerRoot "tests/Browser/Modules/Prime/Board/screenshots"
if (Test-Path $ShotDir) {
    Get-ChildItem -Path $ShotDir -Filter *.png -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "Cleaned screenshots in $ShotDir" -ForegroundColor DarkGray
}

if ($SyncDb) {
    Write-Host "Syncing test DB (migrate)..." -ForegroundColor Yellow
    & $PhpPath artisan migrate --env=testing --force
}

# Proof directory + timestamped log.
$ProofDir = Join-Path $RunnerRoot "tests/Browser/Modules/Prime/Board/proof"
New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null
$Stamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofFile = Join-Path $ProofDir "board_dusk_$Stamp.log"

$DuskArgs = @("artisan", "dusk", $TestClassPath)
if (-not [string]::IsNullOrEmpty($Filter)) { $DuskArgs += "--filter=$Filter" }

Write-Host "Running: $PhpPath $($DuskArgs -join ' ')" -ForegroundColor Green
& $PhpPath @DuskArgs 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

# Parse summary.
$summary = Select-String -Path $ProofFile -Pattern "Tests:\s+\d+|Failures:\s+\d+|Assertions:\s+\d+|OK\s+\(|Skipped:" -ErrorAction SilentlyContinue
Write-Host "`n===== SUMMARY =====" -ForegroundColor Cyan
if ($summary) { $summary | ForEach-Object { Write-Host $_.Line } } else { Write-Host "(no summary line parsed; see $ProofFile)" }
Write-Host "Proof: $ProofFile" -ForegroundColor Cyan
Write-Host "Exit code: $ExitCode" -ForegroundColor Cyan

exit $ExitCode
