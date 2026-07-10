<#
    Runner for the Prime > TenantGroup Dusk suite (single file: prm_TenantGroup_TestCas.php).
    Central feature — runs against http://127.0.0.1:8000 (prime_db).
    Requires the Prime module ENABLED in modules_statuses.json and APP_ENV=testing.

    Usage:
        ./run-TenantGroup-tests.ps1 [-Filter test_tenantgroup_10_store_creates_group_and_logs_created_event]
                                    [-PhpBin php] [-RunnerRoot C:\path\to\prime_testing]
#>
param(
    [string]$Filter    = "",
    [string]$PhpBin    = "php",
    [string]$RunnerRoot = "C:\Herd\prime_testing"
)

$ErrorActionPreference = "Continue"

$TestFile  = "tests/Browser/Modules/Prime/TenantGroup/prm_TenantGroup_TestCas.php"
$Stamp     = Get-Date -Format "yyyyMMdd_HHmmss"
$ProofDir  = "tests/Browser/Modules/Prime/TenantGroup/proof"
$ProofFile = Join-Path $ProofDir "tenantgroup_run_$Stamp.log"

if (-not (Test-Path $RunnerRoot)) { Write-Error "Runner root not found: $RunnerRoot"; exit 2 }
Set-Location $RunnerRoot

New-Item -ItemType Directory -Force -Path $ProofDir | Out-Null

# Clean old screenshots for this feature.
$ShotDir = "tests/Browser/Modules/Prime/TenantGroup/screenshots"
if (Test-Path $ShotDir) { Remove-Item "$ShotDir/*" -Recurse -Force -ErrorAction SilentlyContinue }

$env:APP_ENV = "testing"

$Args = @("artisan", "dusk", $TestFile)
if ($Filter -ne "") { $Args += @("--filter", $Filter) }

Write-Host "Running: $PhpBin $($Args -join ' ')"
& $PhpBin @Args 2>&1 | Tee-Object -FilePath $ProofFile
$ExitCode = $LASTEXITCODE

Write-Host ""
Write-Host "==================== SUMMARY ===================="
Select-String -Path $ProofFile -Pattern "Tests:|Assertions:|Failures:|OK|FAILURES|Errors:" |
    Select-Object -Last 5 | ForEach-Object { $_.Line }
Write-Host "Proof: $ProofFile"
Write-Host "Exit code: $ExitCode"
Write-Host "================================================="

exit $ExitCode
